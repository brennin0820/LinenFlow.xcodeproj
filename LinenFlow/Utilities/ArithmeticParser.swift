import Foundation

enum ArithmeticError: Error, Equatable, Sendable {
    case empty
    case invalidCharacter(Character)
    case partial
    case mismatchedParens
    case divisionByZero
    case negativeNotAllowed
    case fractionalNotAllowed
}

enum ArithmeticParser {
    enum Token: Equatable {
        case number(Double)
        case plus, minus, multiply, divide
        case leftParen, rightParen
    }

    static func parse(_ input: String) -> Result<Double, ArithmeticError> {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return .failure(.empty) }

        let tokens: [Token]
        switch tokenize(trimmed) {
        case .failure(let err): return .failure(err)
        case .success(let t):
            guard !t.isEmpty else { return .failure(.empty) }
            tokens = t
        }

        let parser = RecursiveDescent(tokens: tokens)
        do {
            let value = try parser.parseExpression()
            guard parser.isAtEnd else { return .failure(.partial) }
            return .success(value)
        } catch let err as ArithmeticError {
            return .failure(err)
        } catch {
            return .failure(.partial)
        }
    }

    private static func tokenize(_ input: String) -> Result<[Token], ArithmeticError> {
        var tokens: [Token] = []
        var i = input.startIndex
        while i < input.endIndex {
            let c = input[i]
            if c.isWhitespace {
                i = input.index(after: i)
                continue
            }
            if c.isNumber {
                // Consume digit groups separated by commas (e.g. "1,200" → 1200)
                var s = ""
                while i < input.endIndex {
                    let ch = input[i]
                    if ch.isNumber {
                        s.append(ch)
                        i = input.index(after: i)
                    } else if ch == "," {
                        // Only treat comma as thousands separator if it is followed by exactly 3 digits
                        let next = input.index(after: i)
                        var digitCount = 0
                        var j = next
                        while j < input.endIndex && input[j].isNumber {
                            digitCount += 1
                            j = input.index(after: j)
                        }
                        // If exactly 3 digits follow (thousands separator pattern), skip comma
                        if digitCount == 3 {
                            i = input.index(after: i)  // skip comma
                        } else {
                            break
                        }
                    } else {
                        break
                    }
                }
                guard let n = Double(s) else { return .failure(.invalidCharacter(c)) }
                tokens.append(.number(n))
                continue
            }
            switch c {
            case "+": tokens.append(.plus)
            case "-": tokens.append(.minus)
            case "*", ".", "x", "X", "×": tokens.append(.multiply)
            case "/", "÷": tokens.append(.divide)
            case "(": tokens.append(.leftParen)
            case ")": tokens.append(.rightParen)
            default:
                return .failure(.invalidCharacter(c))
            }
            i = input.index(after: i)
        }
        return .success(tokens)
    }

    private final class RecursiveDescent {
        let tokens: [Token]
        var pos: Int = 0

        init(tokens: [Token]) { self.tokens = tokens }

        var isAtEnd: Bool { pos >= tokens.count }

        func peek() -> Token? { pos < tokens.count ? tokens[pos] : nil }
        @discardableResult
        func consume() -> Token? {
            guard pos < tokens.count else { return nil }
            let t = tokens[pos]
            pos += 1
            return t
        }

        func parseExpression() throws -> Double {
            var left = try parseTerm()
            while let tok = peek() {
                if tok == .plus {
                    consume()
                    left += try parseTerm()
                } else if tok == .minus {
                    consume()
                    left -= try parseTerm()
                } else {
                    break
                }
            }
            return left
        }

        func parseTerm() throws -> Double {
            var left = try parseFactor()
            while let tok = peek() {
                if tok == .multiply {
                    consume()
                    left *= try parseFactor()
                } else if tok == .divide {
                    consume()
                    let right = try parseFactor()
                    if right == 0 { throw ArithmeticError.divisionByZero }
                    left /= right
                } else {
                    break
                }
            }
            return left
        }

        func parseFactor() throws -> Double {
            guard let tok = consume() else { throw ArithmeticError.partial }
            switch tok {
            case .number(let n):
                return n
            case .leftParen:
                let v = try parseExpression()
                guard consume() == .rightParen else { throw ArithmeticError.mismatchedParens }
                return v
            case .minus:
                return -(try parseFactor())
            case .plus:
                return try parseFactor()
            default:
                throw ArithmeticError.partial
            }
        }
    }
}

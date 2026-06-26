import Foundation

public enum ArithmeticError: Error, Equatable, Sendable {
    case empty
    case invalidCharacter(Character)
    case partial
    case mismatchedParens
    case multipleDotMultipliers
    case multipleGroupedExpressions
    case divisionByZero
    case negativeNotAllowed
    case fractionalNotAllowed
}

/// Guards live expression entry (keypad + paste filtering).
public enum ArithmeticInputRules {
    private static let binaryOperators: Set<Character> = ["+", "-", "*", "/", ".", "×", "÷"]

    public static func filter(_ input: String, previous: String) -> String {
        guard input != previous else { return input }

        if input.filter({ $0 == "." }).count > 1 {
            return previous
        }

        if input.count > previous.count, input.hasPrefix(previous) {
            let appended = String(input.dropFirst(previous.count))
            if !canAppend(appended, to: previous) {
                return previous
            }
        }

        return input
    }

    public static func canAppend(_ token: String, to expression: String) -> Bool {
        guard !token.isEmpty else { return false }
        if token == ".", expression.contains(".") { return false }

        let trimmed = expression.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let last = trimmed.last else { return true }

        // After a closed group, require an operator before the next term.
        if last == ")" {
            if token == "(" || token == "." || token.first?.isNumber == true {
                return false
            }
            return true
        }

        // Multi-digit numbers are allowed; only block implicit term boundaries.
        if last.isNumber, token == "(" {
            return false
        }

        return true
    }
}

public enum ArithmeticParser {
    public enum Token: Equatable {
        case number(Double)
        case plus, minus, multiply, divide
        case leftParen, rightParen
    }

    public static func parse(_ input: String) -> Result<Double, ArithmeticError> {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return .failure(.empty) }

        if trimmed.filter({ $0 == "." }).count > 1 {
            return .failure(.multipleDotMultipliers)
        }

        let tokens: [Token]
        switch tokenize(trimmed) {
        case .failure(let err): return .failure(err)
        case .success(let t):
            guard !t.isEmpty else { return .failure(.empty) }
            tokens = t
        }

        if isTrailingBinaryOperator(tokens) {
            return .failure(.partial)
        }

        let parser = RecursiveDescent(tokens: tokens)
        do {
            let value = try parser.parseExpression()
            guard parser.isAtEnd else {
                return .failure(classifyUnconsumed(tokens, from: parser.pos))
            }
            return .success(value)
        } catch let err as ArithmeticError {
            return .failure(err)
        } catch {
            return .failure(.partial)
        }
    }

    private static func isTrailingBinaryOperator(_ tokens: [Token]) -> Bool {
        guard let last = tokens.last else { return false }
        switch last {
        case .plus, .minus, .multiply, .divide:
            return true
        case .leftParen, .rightParen, .number:
            return false
        }
    }

    private static func classifyUnconsumed(_ tokens: [Token], from pos: Int) -> ArithmeticError {
        let remaining = Array(tokens[pos...])
        guard let first = remaining.first else { return .partial }

        switch first {
        case .rightParen:
            return .mismatchedParens
        case .leftParen, .number:
            return .multipleGroupedExpressions
        case .plus, .minus, .multiply, .divide:
            return .partial
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
                var s = ""
                while i < input.endIndex {
                    let ch = input[i]
                    if ch.isNumber {
                        s.append(ch)
                        i = input.index(after: i)
                    } else if ch == "," {
                        let next = input.index(after: i)
                        var digitCount = 0
                        var j = next
                        while j < input.endIndex && input[j].isNumber {
                            digitCount += 1
                            j = input.index(after: j)
                        }
                        if digitCount == 3 {
                            i = input.index(after: i)
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
        public let tokens: [Token]
        public var pos: Int = 0

        public init(tokens: [Token]) { self.tokens = tokens }

        public var isAtEnd: Bool { pos >= tokens.count }

        public func peek() -> Token? { pos < tokens.count ? tokens[pos] : nil }
        @discardableResult
        public func consume() -> Token? {
            guard pos < tokens.count else { return nil }
            let t = tokens[pos]
            pos += 1
            return t
        }

        public func parseExpression() throws -> Double {
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

        public func parseTerm() throws -> Double {
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

        public func parseFactor() throws -> Double {
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

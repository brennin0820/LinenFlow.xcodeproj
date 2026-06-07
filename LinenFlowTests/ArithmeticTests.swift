import XCTest
@testable import HimmerFlow

final class ArithmeticTests: XCTestCase {

    private func evaluateDouble(_ input: String) -> Result<Double, ArithmeticError> {
        ArithmeticExpressionService.evaluate(input)
    }

    private func evaluatePieces(_ input: String) -> Result<Int, ArithmeticError> {
        ArithmeticExpressionService.evaluatePieces(input)
    }

    private func assertValue(_ input: String, _ expected: Double, file: StaticString = #filePath, line: UInt = #line) {
        switch evaluateDouble(input) {
        case .success(let v):
            XCTAssertEqual(v, expected, accuracy: 0.0001, "input: \(input)", file: file, line: line)
        case .failure(let err):
            XCTFail("expected \(expected) for '\(input)', got error \(err)", file: file, line: line)
        }
    }

    private func assertFails(_ input: String, file: StaticString = #filePath, line: UInt = #line) {
        switch evaluateDouble(input) {
        case .success(let v):
            XCTFail("expected failure for '\(input)', got value \(v)", file: file, line: line)
        case .failure:
            return
        }
    }

    private func assertPiecesFails(_ input: String, file: StaticString = #filePath, line: UInt = #line) {
        switch evaluatePieces(input) {
        case .success(let v):
            XCTFail("expected failure for '\(input)', got pieces \(v)", file: file, line: line)
        case .failure:
            return
        }
    }

    // 1
    func test_01_multiplyStar() { assertValue("245*11", 2695) }
    // 2
    func test_02_multiplyLowerX() { assertValue("245 x 11", 2695) }
    // 3
    func test_03_multiplyUpperX() { assertValue("245 X 11", 2695) }
    // 4
    func test_04_multiplyTimesSymbol() { assertValue("245×11", 2695) }
    // 5
    func test_05_divideSlash() { assertValue("2695/5", 539) }
    // 6
    func test_06_divideObelus() { assertValue("2695÷5", 539) }
    // 7
    func test_07_addition() { assertValue("60+60", 120) }
    // 8
    func test_08_subtraction() { assertValue("300-25", 275) }
    // 9
    func test_09_multiplyThenAdd() { assertValue("245*2+60", 550) }
    // 10
    func test_10_parenthesisGroupingThenAdd() { assertValue("(245*2)+60", 550) }
    // 11
    func test_11_spacesWork() { assertValue("  245   *   11  ", 2695) }
    // 12
    func test_12_lettersFail() { assertFails("abc") }
    // 13
    func test_13_mixedLettersFail() { assertFails("245*abc") }
    // 14
    func test_14_doubleOperatorFails() { assertFails("245**") }
    // 15
    func test_15_divisionByZeroFails() { assertFails("5/0") }
    // 16
    func test_16_evalFunctionFails() { assertFails("eval(245*11)") }
    // 17
    func test_17_sqrtFunctionFails() { assertFails("sqrt(25)") }
    // 18
    func test_18_importStatementFails() { assertFails("import os") }
    // 19
    func test_19_trailingUnitsFail() { assertFails("245 bags") }
    // 20
    func test_20_negativePiecesFails() { assertPiecesFails("-5") }
    // 21
    func test_21_fractionalPiecesFails() { assertPiecesFails("5/2") }
    // 22
    func test_22_emptyInputDoesNotCrash() {
        switch evaluateDouble("") {
        case .success(let v): XCTFail("expected failure for empty input, got \(v)")
        case .failure(let err): XCTAssertEqual(err, .empty)
        }
    }
    // 23
    func test_23_partialInputDoesNotCrash() {
        switch evaluateDouble("245*") {
        case .success(let v): XCTFail("expected failure for partial input, got \(v)")
        case .failure: return
        }
    }

    func test_24_commasAreIgnored() {
        assertValue("1,200+50", 1250)
    }

    func test_25_periodMeansMultiply() {
        assertValue("245.2", 490)
    }

    func test_26_periodCanChainWithOtherOperators() {
        assertValue("245.2+60", 550)
    }
}

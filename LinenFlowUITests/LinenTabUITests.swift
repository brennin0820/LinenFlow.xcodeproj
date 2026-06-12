import XCTest

/// XCUITest happy path for the Linen tab (Phase 14 / Track L).
///
/// Requires a `LinenFlowUITests` UI test bundle target in `LinenFlow.xcodeproj`.
/// **Blocked on pbxproj:** `f19a62cd` / `50fed4e9` hold an ACTIVE lock — target must be
/// added after release (see BUILD_LEDGER Phase 14 entry).
final class LinenTabUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launch()
        completeOnboardingIfNeeded()
    }

    // MARK: - Individual steps

    func test_launch_showsLinenTabByDefault() throws {
        let linenTab = app.tabBars.buttons["Linen"]
        XCTAssertTrue(linenTab.waitForExistence(timeout: 8))
        XCTAssertTrue(linenTab.isSelected)
    }

    func test_selectTower_enterPieces_showsSummary() throws {
        selectTower(named: "Lagoon")
        enterPieces(forItem: "Bath Towel", count: 24)
        XCTAssertTrue(summaryStripIsVisible, "Summary strip should appear after entering pieces")
    }

    func test_saveLog_appearsOnLogsTab() throws {
        selectTower(named: "Lagoon")
        enterPieces(forItem: "Bath Towel", count: 24)
        XCTAssertTrue(summaryStripIsVisible)

        saveDailyLog()
        openLogsTab()

        let lagoonEntry = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Lagoon")
        ).firstMatch
        XCTAssertTrue(
            lagoonEntry.waitForExistence(timeout: 8),
            "Saved log for Lagoon should appear on Logs tab"
        )
    }

    /// End-to-end happy path: Linen tab → tower → pieces → summary → save → Logs entry.
    func test_linenTab_happyPath() throws {
        let linenTab = app.tabBars.buttons["Linen"]
        XCTAssertTrue(linenTab.waitForExistence(timeout: 8))
        XCTAssertTrue(linenTab.isSelected)

        selectTower(named: "Lagoon")
        enterPieces(forItem: "Bath Towel", count: 24)
        XCTAssertTrue(summaryStripIsVisible)

        saveDailyLog()
        openLogsTab()

        let lagoonEntry = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Lagoon")
        ).firstMatch
        XCTAssertTrue(lagoonEntry.waitForExistence(timeout: 8))
    }

    // MARK: - Helpers

    private func completeOnboardingIfNeeded() {
        if app.buttons["Get Started"].waitForExistence(timeout: 3) {
            app.buttons["Get Started"].tap()
            return
        }

        for _ in 0..<3 {
            let continueButton = app.buttons["Continue"]
            guard continueButton.waitForExistence(timeout: 2) else { break }
            continueButton.tap()
        }

        if app.buttons["Get Started"].waitForExistence(timeout: 2) {
            app.buttons["Get Started"].tap()
        }

        // Dismiss location permission sheet if the toggle was accidentally enabled.
        let notNow = app.buttons["Not Now"]
        if notNow.waitForExistence(timeout: 1) {
            notNow.tap()
        }
    }

    private func selectTower(named name: String) {
        // If a tower is already selected, expand the picker via "Change tower".
        let changeTower = app.buttons["Change tower"]
        if changeTower.waitForExistence(timeout: 2) {
            changeTower.tap()
        }

        let towerButton = app.buttons[name]
        if towerButton.waitForExistence(timeout: 5) {
            towerButton.tap()
        } else {
            app.staticTexts[name].firstMatch.tap()
        }

        let doneButton = app.buttons["Done selecting tower"]
        if doneButton.waitForExistence(timeout: 2) {
            doneButton.tap()
        }
    }

    private func enterPieces(forItem itemName: String, count: Int) {
        let identifier = "linen.itemCard.\(itemName.replacingOccurrences(of: " ", with: "_"))"
        let card = app.otherElements[identifier]
        XCTAssertTrue(card.waitForExistence(timeout: 8), "Item card \(itemName) not found")
        card.tap()

        let textField = card.textFields.firstMatch
        if !textField.exists {
            app.textFields.firstMatch.tap()
        } else {
            textField.tap()
        }

        let activeField = app.textFields.firstMatch
        XCTAssertTrue(activeField.waitForExistence(timeout: 3))
        activeField.typeText("\(count)")

        dismissKeyboard()
    }

    private func dismissKeyboard() {
        if app.keyboards.buttons["Done"].exists {
            app.keyboards.buttons["Done"].tap()
        } else if app.toolbars.buttons["Done"].exists {
            app.toolbars.buttons["Done"].tap()
        } else {
            // Tap the navigation title area to blur the field.
            app.navigationBars.firstMatch.tap()
        }
    }

    private var summaryStripIsVisible: Bool {
        let pcsLabel = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'pcs'")
        ).firstMatch
        if pcsLabel.waitForExistence(timeout: 5) { return true }

        let itemsLabel = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'items'")
        ).firstMatch
        if itemsLabel.waitForExistence(timeout: 2) { return true }

        let saveLog = app.buttons["Save Log"]
        return saveLog.waitForExistence(timeout: 2) && saveLog.isEnabled
    }

    private func saveDailyLog() {
        let saveButton = app.buttons["Save Log"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        XCTAssertTrue(saveButton.isEnabled, "Save Log should be enabled after entering pieces")
        saveButton.tap()

        let confirmation = app.staticTexts["Daily log saved."]
        _ = confirmation.waitForExistence(timeout: 5)
    }

    private func openLogsTab() {
        let logsTab = app.tabBars.buttons["Logs"]
        if logsTab.waitForExistence(timeout: 3) {
            logsTab.tap()
        } else {
            app.buttons["tab.logs"].tap()
        }
        XCTAssertTrue(app.navigationBars["Daily Logs"].waitForExistence(timeout: 8))
    }
}

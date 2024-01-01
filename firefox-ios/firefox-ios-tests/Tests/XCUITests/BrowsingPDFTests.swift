// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

let PDF_website = [
    "url": "www.orimi.com/pdf-test.pdf",
    "pdfValue": "www.orimi.com/pdf",
    "urlValue": "yukon.ca/en/educat",
    "bookmarkLabel": "https://www.orimi.com/pdf-test.pdf",
    "longUrlValue": "http://www.education.gov.yk.ca/"
]
class BrowsingPDFTests: BaseTestCase {
    // https://testrail.stage.mozaws.net/index.php?/cases/view/2307116
    func testOpenPDFViewer() {
        navigator.openURL(PDF_website["url"]!)
        waitUntilPageLoad()
        mozWaitForValueContains(app.textFields["url"], value: PDF_website["pdfValue"]!)
        // Swipe Up and Down
        app.swipeUp()
        mozWaitForElementToExist(app.staticTexts["1 of 1"])
        app.swipeDown()
        XCTAssertTrue(app.staticTexts["1 of 1"].exists)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2307117
    // Disabled due to link not loading
    func testOpenLinkFromPDF() throws {
        throw XCTSkip("Link inside pfd is not loading anymore")
        /*
        navigator.openURL(PDF_website["url"]!)
        waitUntilPageLoad()

        // Click on a link on the pdf and check that the website is shown
        app.links.element(boundBy: 0).tapOnApp()
        waitUntilPageLoad()
        mozWaitForValueContains(app.textFields["url"], value: PDF_website["urlValue"]!)
        XCTAssertTrue(app.staticTexts["Education and schools"].exists)

        // Go back to pdf view
        app.buttons[AccessibilityIdentifiers.Toolbar.backButton].tap()
        mozWaitForValueContains(app.textFields["url"], value: PDF_website["pdfValue"]!)
         */
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2307118
    func testLongPressOnPDFLink() {
        navigator.openURL(PDF_website["url"]!)
        waitUntilPageLoad()
        // Long press on a link on the pdf and check the options shown
        app.webViews.links.element(boundBy: 0).pressAtPoint(CGPoint(x: 10, y: 0), forDuration: 3)

        mozWaitForElementToExist(app.staticTexts[PDF_website["longUrlValue"]!])
        mozWaitForElementToExist(app.buttons["Open"])
        mozWaitForElementToExist(app.buttons["Add to Reading List"])
        mozWaitForElementToExist(app.buttons["Copy Link"])
        mozWaitForElementToExist(app.buttons["Share…"])
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2307119
    func testLongPressOnPDFLinkToAddToReadingList() {
        navigator.openURL(PDF_website["url"]!)
        waitUntilPageLoad()
        // Long press on a link on the pdf and check the options shown
        app.webViews.links.element(boundBy: 0).pressAtPoint(CGPoint(x: 10, y: 0), forDuration: 3)

        mozWaitForElementToExist(app.staticTexts[PDF_website["longUrlValue"]!])
        app.buttons["Add to Reading List"].tap()
        navigator.nowAt(BrowserTab)

        // Go to reading list and check that the item is there
        navigator.goto(LibraryPanel_ReadingList)
        let savedToReadingList = app.tables["ReadingTable"].cells.staticTexts[PDF_website["longUrlValue"]!]
        mozWaitForElementToExist(savedToReadingList)
        XCTAssertTrue(savedToReadingList.exists)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2307120
    func testPinPDFtoTopSites() {
        navigator.openURL(PDF_website["url"]!)
        waitUntilPageLoad()
        navigator.performAction(Action.PinToTopSitesPAM)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        mozWaitForElementToExist(app.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell], timeout: 10)
        mozWaitForElementToExist(app.collectionViews.cells.staticTexts[PDF_website["bookmarkLabel"]!])
        XCTAssertTrue(app.collectionViews.cells.staticTexts[PDF_website["bookmarkLabel"]!].exists)

        // Open pdf from pinned site
        let pdfTopSite = app
            .collectionViews[AccessibilityIdentifiers.FirefoxHomepage.collectionView]
            .cells[PDF_website["bookmarkLabel"]!]
            .children(matching: .other)
            .element
            .children(matching: .other)
            .element(boundBy: 0)
        pdfTopSite.tap()
        waitUntilPageLoad()
        mozWaitForValueContains(app.textFields["url"], value: PDF_website["pdfValue"]!)

        // Remove pdf pinned site
        navigator.performAction(Action.OpenNewTabFromTabTray)
        mozWaitForElementToExist(app.collectionViews.cells.staticTexts[PDF_website["bookmarkLabel"]!])
        pdfTopSite.press(forDuration: 1)
        mozWaitForElementToExist(app.tables.cells.otherElements[StandardImageIdentifiers.Large.pinSlash])
        app.tables.cells.otherElements[StandardImageIdentifiers.Large.pinSlash].tap()
        mozWaitForElementToExist(app.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell])
        XCTAssertTrue(app.collectionViews.cells.staticTexts[PDF_website["bookmarkLabel"]!].exists)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2307121
    func testBookmarkPDF() {
        navigator.openURL(PDF_website["url"]!)
        waitUntilPageLoad()
        navigator.performAction(Action.BookmarkThreeDots)
        waitUntilPageLoad()
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Bookmarks)
        mozWaitForElementToExist(app.tables["Bookmarks List"])
        XCTAssertTrue(app.tables["Bookmarks List"].staticTexts[PDF_website["bookmarkLabel"]!].exists)
    }
}

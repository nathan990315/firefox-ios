// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MozillaAppServices
import Shared
import XCTest

@testable import Client

class NimbusOnboardingFeatureLayerTests: XCTestCase {
    typealias CardElementNames = NimbusOnboardingTestingConfigUtility.CardElementNames

    var configUtility: NimbusOnboardingTestingConfigUtility!

    override func setUp() {
        super.setUp()
        configUtility = NimbusOnboardingTestingConfigUtility()
    }

    override func tearDown() {
        super.tearDown()
        configUtility = nil
    }

    // MARK: - Test placeholder methods
    func testLayer_placeholderNamingMethod_returnsExpectedStrigs() {
        setupNimbusForStringTesting()
        let expectedPlaceholderString = "A string inside Firefox with a placeholder"
        let expectedNoPlaceholderString = "On Wednesday's, we wear pink"
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.title, expectedPlaceholderString)
        XCTAssertEqual(subject.body, expectedNoPlaceholderString)
    }

    // MARK: - Test Dismissable
    func testLayer_dismissable_isTrue() {
        configUtility.setupNimbusWith(dismissable: true)
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())
        let subject = layer.getOnboardingModel(for: .freshInstall)

        XCTAssertTrue(subject.isDismissable)
    }

    func testLayer_dismissable_isFalse() {
        configUtility.setupNimbusWith(dismissable: false)
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())
        let subject = layer.getOnboardingModel(for: .freshInstall)

        XCTAssertFalse(subject.isDismissable)
    }

    // MARK: - Test A11yRoot
    func testLayer_a11yroot_isOnboarding() {
        configUtility.setupNimbusWith(cards: 2)
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual(subject[0].a11yIdRoot, "\(CardElementNames.a11yIDOnboarding)0")
        XCTAssertEqual(subject[1].a11yIdRoot, "\(CardElementNames.a11yIDOnboarding)1")
    }

    func testLayer_a11yroot_isUpgrade() {
        configUtility.setupNimbusWith(
            cards: 2,
            type: .upgrade)
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        let subject = layer.getOnboardingModel(for: .upgrade).cards

        XCTAssertEqual(subject[0].a11yIdRoot, "\(CardElementNames.a11yIDUpgrade)0")
        XCTAssertEqual(subject[1].a11yIdRoot, "\(CardElementNames.a11yIDUpgrade)1")
    }

    // MARK: - Test card(s) being returned
    func testLayer_cardIsReturned_OneCard() {
        configUtility.setupNimbusWith(
            shouldAddLink: true,
            withSecondaryButton: true
        )
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        let expectedCard = OnboardingCardInfoModel(
            name: CardElementNames.name + " 1",
            order: 10,
            title: CardElementNames.title + " 1",
            body: CardElementNames.body + " 1",
            link: OnboardingLinkInfoModel(title: CardElementNames.linkTitle,
                                          url: URL(string: CardElementNames.linkURL)!),
            buttons: OnboardingButtons(
                primary: OnboardingButtonInfoModel(
                    title: CardElementNames.primaryButtonTitle,
                    action: .nextCard),
                secondary: OnboardingButtonInfoModel(
                    title: CardElementNames.secondaryButtonTitle,
                    action: .nextCard)),
            type: .freshInstall,
            a11yIdRoot: CardElementNames.a11yIDOnboarding,
            imageID: ImageIdentifiers.onboardingWelcomev106)

        XCTAssertEqual(subject.name, expectedCard.name)
        XCTAssertEqual(subject.title, expectedCard.title)
        XCTAssertEqual(subject.body, expectedCard.body)
        XCTAssertEqual(subject.type, expectedCard.type)
        XCTAssertEqual(subject.image, UIImage(named: ImageIdentifiers.onboardingWelcomev106))
        XCTAssertEqual(subject.link?.title, expectedCard.link?.title)
        XCTAssertEqual(subject.link?.url, expectedCard.link?.url)
        XCTAssertEqual(subject.buttons.primary.title, expectedCard.buttons.primary.title)
        XCTAssertEqual(subject.buttons.primary.action, expectedCard.buttons.primary.action)
        XCTAssertNotNil(subject.buttons.secondary)
        XCTAssertEqual(subject.buttons.secondary!.title, expectedCard.buttons.secondary!.title)
        XCTAssertEqual(subject.buttons.secondary!.action, expectedCard.buttons.secondary!.action)
    }

    func testLayer_cardsAreReturned_ThreeCardsReturned() {
        let expectedNumberOfCards = 3
        configUtility.setupNimbusWith(cards: expectedNumberOfCards)
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual(expectedNumberOfCards, subject.count)
    }

    func testLayer_cardsAreReturned_InExpectedOrder() {
        let expectedNumberOfCards = 3
        configUtility.setupNimbusWith(cards: expectedNumberOfCards)
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual("\(CardElementNames.name) 1", subject[0].name)
        XCTAssertEqual("\(CardElementNames.name) 2", subject[1].name)
        XCTAssertEqual("\(CardElementNames.name) 3", subject[2].name)
    }

    // MARK: - Test conditions
    // Conditions for cards are based on the feature's condition table. A card's
    // conditions (it's prerequisites & disqualifiers) get, respectively, reduced
    // down to a single boolean value. These tests will test the conditions
    // independently and then in a truth table fashion, reflecting real world evaulation
    //    - (T, T) (T, F), (F, T), and (F, F)
    // Testing for defaults was implicit in the previous tests, as defaults are:
    //    - prerequisities: true
    //    - disqualifiers: empty
    func testLayer_conditionPrerequisiteAlways_returnsCard() {
        let expectedNumberOfCards = 1
        configUtility.setupNimbusWith(prerequisites: ["ALWAYS"])
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual(expectedNumberOfCards, subject.count)
    }

    func testLayer_conditionPrerequisiteNever_returnsNoCard() {
        let expectedNumberOfCards = 0
        configUtility.setupNimbusWith(prerequisites: ["NEVER"])
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual(expectedNumberOfCards, subject.count)
    }

    func testLayer_conditionDisqualifierAlways_returnsNoCard() {
        let expectedNumberOfCards = 0
        configUtility.setupNimbusWith(disqualifiers: ["ALWAYS"])
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual(expectedNumberOfCards, subject.count)
    }

    func testLayer_conditionDesqualifierNever_returnsCard() {
        let expectedNumberOfCards = 1
        configUtility.setupNimbusWith(disqualifiers: ["NEVER"])
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual(expectedNumberOfCards, subject.count)
    }

    func testLayer_conditionPrerequisiteAlwaysDisqualifierNever_returnsCard() {
        let expectedNumberOfCards = 1
        configUtility.setupNimbusWith(
            prerequisites: ["ALWAYS"],
            disqualifiers: ["NEVER"])
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual(expectedNumberOfCards, subject.count)
    }

    func testLayer_conditionPrerequisiteNeverDisqualifierNever_returnsNoCard() {
        let expectedNumberOfCards = 0
        configUtility.setupNimbusWith(
            prerequisites: ["NEVER"],
            disqualifiers: ["NEVER"])
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual(expectedNumberOfCards, subject.count)
    }

    func testLayer_conditionPrerequisiteAlwaysDisqualifierAlways_returnsNoCard() {
        let expectedNumberOfCards = 0
        configUtility.setupNimbusWith(
            prerequisites: ["ALWAYS"],
            disqualifiers: ["ALWAYS"])
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual(expectedNumberOfCards, subject.count)
    }

    func testLayer_conditionPrerequisiteNeverDisqualifierAlways_returnsNoCard() {
        let expectedNumberOfCards = 0
        configUtility.setupNimbusWith(
            prerequisites: ["NEVER"],
            disqualifiers: ["ALWAYS"])
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        let subject = layer.getOnboardingModel(for: .freshInstall).cards

        XCTAssertEqual(expectedNumberOfCards, subject.count)
    }

    // MARK: - Test image IDs
    func testLayer_cardIsReturned_WithGlobeImageIdenfier() {
        configUtility.setupNimbusWith(image: .welcomeGlobe)
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.imageID, ImageIdentifiers.onboardingWelcomev106)
    }

    func testLayer_cardIsReturned_WithNotificationImageIdenfier() {
        configUtility.setupNimbusWith(image: .notifications)
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.image, UIImage(named: ImageIdentifiers.onboardingNotification))
    }

    func testLayer_cardIsReturned_WithSyncImageIdenfier() {
        configUtility.setupNimbusWith(image: .syncDevices)
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.image, UIImage(named: ImageIdentifiers.onboardingSyncv106))
    }

    // MARK: - Test install types
    func testLayer_cardIsReturned_WithFreshInstallType() {
        configUtility.setupNimbusWith(type: .freshInstall)
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.type, OnboardingType.freshInstall)
    }

    func testLayer_cardIsReturned_WithUpdateType() {
        configUtility.setupNimbusWith(type: .upgrade)
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .upgrade).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.type, OnboardingType.upgrade)
    }

    // MARK: - Test link
    func testLayer_cardIsReturned_WithNoLink() {
        configUtility.setupNimbusWith(shouldAddLink: false)
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertNil(subject.link)
    }

    func testLayer_cardIsReturned_WithLink() {
        configUtility.setupNimbusWith(shouldAddLink: true)
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertNotNil(subject.link)
        XCTAssertEqual(subject.link?.title, CardElementNames.linkTitle)
        XCTAssertEqual(subject.link?.url, URL(string: CardElementNames.linkURL)!)
    }

    // MARK: - Test buttons
    func testLayer_cardIsReturned_WithOneButton() {
        configUtility.setupNimbusWith(withSecondaryButton: false)
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertNotNil(subject.buttons.primary)
        XCTAssertNil(subject.buttons.secondary)
    }

    func testLayer_cardIsReturned_WithTwoButtons() {
        configUtility.setupNimbusWith(withSecondaryButton: true)
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertNotNil(subject.buttons.primary)
        XCTAssertNotNil(subject.buttons.secondary)
    }

    // MARK: - Test button actions
    func testLayer_cardIsReturned_WithNextCardButton() {
        configUtility.setupNimbusWith(
            withSecondaryButton: false,
            withPrimaryButtonAction: .nextCard
        )
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.buttons.primary.action, .nextCard)
    }

    func testLayer_cardIsReturned_WithDefaultBrowserButton() {
        configUtility.setupNimbusWith(
            withSecondaryButton: true,
            withPrimaryButtonAction: .setDefaultBrowser
        )
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.buttons.primary.action, .setDefaultBrowser)
    }

    func testLayer_cardIsReturned_WithSyncSignInButton() {
        configUtility.setupNimbusWith(
            withSecondaryButton: true,
            withPrimaryButtonAction: .syncSignIn
        )
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.buttons.primary.action, .syncSignIn)
    }

    func testLayer_cardIsReturned_WithRequestNotificationsButton() {
        configUtility.setupNimbusWith(
            withSecondaryButton: true,
            withPrimaryButtonAction: .requestNotifications
        )
        let layer = NimbusOnboardingFeatureLayer(with: MockNimbusMessagingHelperUtility())

        guard let subject = layer.getOnboardingModel(for: .freshInstall).cards.first else {
            XCTFail("Expected a card, and got none.")
            return
        }

        XCTAssertEqual(subject.buttons.primary.action, .requestNotifications)
    }

    // MARK: - Helpers
    private func setupNimbusForStringTesting() {
        let dictionary = ["\(CardElementNames.name)": NimbusOnboardingCardData(
            body: "\(CardElementNames.noPlaceholderString)",
            buttons: NimbusOnboardingButtons(
                primary: NimbusOnboardingButton(
                    action: .nextCard,
                    title: "\(CardElementNames.primaryButtonTitle)")),
            disqualifiers: ["NEVER"],
            image: .notifications,
            link: nil,
            order: 10,
            prerequisites: ["ALWAYS"],
            title: "\(CardElementNames.placeholderString)",
            type: .freshInstall)]

        FxNimbus.shared.features.onboardingFrameworkFeature.with(initializer: { _ in
            OnboardingFrameworkFeature(cards: dictionary, dismissable: true)
        })
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared
import Storage

/// Each scene has it's own scene coordinator, which is the root coordinator for a scene.
class SceneCoordinator: BaseCoordinator, LaunchCoordinatorDelegate, LaunchFinishedLoadingDelegate {
    var window: UIWindow?
    let windowUUID: WindowUUID
    private let screenshotService: ScreenshotService
    private let sceneContainer: SceneContainer
    private let windowManager: WindowManager

    init(scene: UIScene,
         sceneSetupHelper: SceneSetupHelper = SceneSetupHelper(),
         screenshotService: ScreenshotService = ScreenshotService(),
         sceneContainer: SceneContainer = SceneContainer(),
         windowManager: WindowManager = AppContainer.shared.resolve()) {
        self.window = sceneSetupHelper.configureWindowFor(scene, screenshotServiceDelegate: screenshotService)
        self.screenshotService = screenshotService
        self.sceneContainer = sceneContainer
        self.windowManager = windowManager
        // Note: this is where we singularly decide the UUID for this specific iOS browser window (UIScene).
        // The logic is handled by `nextAvailableWindowUUID`, but this is the point at which a window's UUID
        // is set; this same UUID will be injected throughout several of the window's related components
        // such as its TabManager instance, which also has the window UUID property as a convenience.
        self.windowUUID = windowManager.nextAvailableWindowUUID()

        let navigationController = sceneSetupHelper.createNavigationController()
        let router = DefaultRouter(navigationController: navigationController)
        super.init(router: router)

        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }

    func start() {
        router.setRootViewController(sceneContainer, hideBar: true)

        let launchScreenVC = LaunchScreenViewController(coordinator: self)
        router.push(launchScreenVC, animated: false)
    }

    override func canHandle(route: Route) -> Bool {
        switch route {
        case .action(action: .showIntroOnboarding):
            return canShowIntroOnboarding()
        default:
            return false
        }
    }

    override func handle(route: Route) {
        switch route {
        case .action(action: .showIntroOnboarding):
            showIntroOnboardingIfNeeded()
        default:
            break
        }
    }

    private func canShowIntroOnboarding() -> Bool {
        let profile: Profile = AppContainer.shared.resolve()
        let introManager = IntroScreenManager(prefs: profile.prefs)
        let launchType = LaunchType.intro(manager: introManager)
        return launchType.canLaunch(fromType: .SceneCoordinator)
    }

    private func showIntroOnboardingIfNeeded() {
        let profile: Profile = AppContainer.shared.resolve()
        let introManager = IntroScreenManager(prefs: profile.prefs)
        let launchType = LaunchType.intro(manager: introManager)
        if launchType.canLaunch(fromType: .SceneCoordinator) {
            startLaunch(with: launchType)
        }
    }

    // MARK: - LaunchFinishedLoadingDelegate

    func launchWith(launchType: LaunchType) {
        guard launchType.canLaunch(fromType: .SceneCoordinator) else {
            startBrowser(with: launchType)
            return
        }

        startLaunch(with: launchType)
    }

    func launchBrowser() {
        startBrowser(with: nil)
    }

    // MARK: - Helper methods

    private func startLaunch(with launchType: LaunchType) {
        logger.log("Launching with launchtype \(launchType)",
                   level: .info,
                   category: .coordinator)

        let launchCoordinator = LaunchCoordinator(router: router)
        launchCoordinator.parentCoordinator = self
        add(child: launchCoordinator)
        launchCoordinator.start(with: launchType)
    }

    private func startBrowser(with launchType: LaunchType?) {
        guard !childCoordinators.contains(where: { $0 is BrowserCoordinator }) else { return }

        logger.log("Starting browser with launchtype \(String(describing: launchType))",
                   level: .info,
                   category: .coordinator)

        let tabManager = TabManagerImplementation(profile: AppContainer.shared.resolve(), uuid: windowUUID)
        let browserCoordinator = BrowserCoordinator(router: router,
                                                    screenshotService: screenshotService,
                                                    tabManager: tabManager)
        add(child: browserCoordinator)
        browserCoordinator.start(with: launchType)

        if let savedRoute {
            browserCoordinator.findAndHandle(route: savedRoute)
        }
    }

    // MARK: - LaunchCoordinatorDelegate

    func didFinishLaunch(from coordinator: LaunchCoordinator) {
        router.dismiss(animated: true)
        remove(child: coordinator)
        startBrowser(with: nil)
    }
}

import SwiftUI

@main
struct DSToolboxApp: App {
    @StateObject private var env = ToolboxEnvironment.shared
    @AppStorage("ds.hasAcceptedAgreement") private var hasAcceptedAgreement = false
    @Environment(\.scenePhase) private var scenePhase

    init() {
        NotificationManager.shared.requestAuthorization()
        CapoitabilityDetector.shared.refresh()
       Settings SandboxService.shared.detectLevel()
        _View = DownloadDestinationService.shared
        _ = SiteCredential()Store.shared
        _ = DownloadOptionsStore.shared
        Task { @MainActor in BackgroundKeepAliveService.shared.resumeIfNeeded() }
    }

    var body: some Scene {
        WindowGroup {
            if hasAcceptedAgreement {
                ContentView().environmentObject(env).onOpenURL { url in URLSchemeHandler.shared.handle(url, env: env) }
            } else {
                AgreementView()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                env.queue.pauseAll(); SharedWebSession.shared.enterBackground }
(); BackgroundKeepAliveService.shared.persistCurrentMode()
            case .active:
                SharedWebSession.shared.enterForeground()
            default: break
            }
        }
    }
}

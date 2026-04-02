import SwiftUI

@main
struct iPhoneBotApp: App {
    @State private var appState = MobileAppState()

    var body: some Scene {
        WindowGroup {
            if appState.isReady, let vm = appState.chatViewModel {
                MobileChatView(viewModel: vm, appState: appState)
            } else if appState.needsSetup {
                MobileOnboardingView(appState: appState)
            } else {
                ProgressView("Connecting...")
                    .task { await appState.initialize() }
            }
        }
    }
}

@Observable
final class MobileAppState {
    var chatViewModel: ChatViewModel?
    var orchestrator: Orchestrator?
    var isReady = false
    var needsSetup = false
    var serverHost: String {
        get { UserDefaults.standard.string(forKey: "serverHost") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "serverHost") }
    }

    @MainActor
    func initialize() async {
        if serverHost.isEmpty {
            needsSetup = true
            return
        }

        let client = OllamaClient(host: serverHost)
        let reachable = await client.isReachable()

        if reachable {
            let orch = Orchestrator(host: serverHost)
            let vm = ChatViewModel(orchestrator: orch)
            self.orchestrator = orch
            self.chatViewModel = vm
            self.isReady = true
            self.needsSetup = false

            Task.detached { await orch.prewarm() }
        } else {
            needsSetup = true
        }
    }

    @MainActor
    func configure(host: String) async {
        serverHost = host
        needsSetup = false
        isReady = false
        await initialize()
    }
}

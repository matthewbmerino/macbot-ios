import SwiftUI

enum InferenceMode: String {
    case local
    case server
}

@main
struct iPhoneBotApp: App {
    @State private var appState = MobileAppState()

    var body: some Scene {
        WindowGroup {
            if appState.isReady, let vm = appState.chatViewModel {
                MobileChatView(viewModel: vm, appState: appState)
            } else {
                ModeSelectionView(appState: appState)
            }
        }
    }
}

// MARK: - Mode Selection (first screen)

struct ModeSelectionView: View {
    let appState: MobileAppState
    @State private var serverHost = ""
    @State private var isConnecting = false
    @State private var connectionError: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "brain")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.accentColor)

                Text("iPhoneBot")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Private AI — all on-device")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                VStack(spacing: 12) {
                    // Local mode — primary option
                    Button(action: { Task { await appState.startLocal() } }) {
                        HStack {
                            Image(systemName: "iphone")
                            VStack(alignment: .leading) {
                                Text("On-Device")
                                    .fontWeight(.semibold)
                                Text("Run models directly on this iPhone")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.quaternary.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)

                    // Server mode — secondary option
                    Button(action: { Task { await appState.startLocal() } }) {
                        HStack {
                            Image(systemName: "network")
                            VStack(alignment: .leading) {
                                Text("Connect to Mac")
                                    .fontWeight(.semibold)
                                Text("Use your Mac's Ollama for bigger models")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.quaternary.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)

                Spacer()

                Text("Nothing leaves your device or network.")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
                    .padding(.bottom, 20)
            }
        }
    }
}

@Observable
final class MobileAppState {
    var chatViewModel: ChatViewModel?
    var orchestrator: Orchestrator?
    var isReady = false
    var mode: InferenceMode = .local

    var serverHost: String {
        get { UserDefaults.standard.string(forKey: "serverHost") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "serverHost") }
    }

    /// Start in local mode — uses the built-in Orchestrator with default models.
    /// For now this connects to localhost Ollama; will be replaced with llama.cpp.
    @MainActor
    func startLocal() async {
        mode = .local
        let orch = Orchestrator()
        let vm = ChatViewModel(orchestrator: orch)
        self.orchestrator = orch
        self.chatViewModel = vm
        self.isReady = true
    }

    /// Start in server mode — connect to a Mac running Ollama.
    @MainActor
    func startServer(host: String) async {
        mode = .server
        serverHost = host
        let orch = Orchestrator(host: host)
        let vm = ChatViewModel(orchestrator: orch)
        self.orchestrator = orch
        self.chatViewModel = vm
        self.isReady = true

        Task.detached { await orch.prewarm() }
    }
}

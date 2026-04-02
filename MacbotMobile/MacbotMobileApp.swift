import SwiftUI

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

// MARK: - Mode Selection

struct ModeSelectionView: View {
    let appState: MobileAppState
    @State private var showModels = false

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

                Text("Private AI — runs entirely on your iPhone")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                VStack(spacing: 12) {
                    // Download models
                    Button(action: { showModels = true }) {
                        HStack {
                            Image(systemName: "arrow.down.circle")
                            VStack(alignment: .leading) {
                                Text("Download a Model")
                                    .fontWeight(.semibold)
                                let count = ModelManager.shared.downloadedModels.count
                                Text(count > 0 ? "\(count) model\(count == 1 ? "" : "s") on device" : "Choose a model to get started")
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

                    // Start chatting (if model available)
                    if !ModelManager.shared.downloadedModels.isEmpty {
                        Button(action: { Task { await appState.startLocal() } }) {
                            HStack {
                                Image(systemName: "message")
                                VStack(alignment: .leading) {
                                    Text("Start Chatting")
                                        .fontWeight(.semibold)
                                    Text("Using \(ModelManager.shared.downloadedModels.first?.name ?? "local model")")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.accentColor.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }

                    // Connect to Mac (secondary)
                    NavigationLink {
                        MobileOnboardingView(appState: appState)
                    } label: {
                        HStack {
                            Image(systemName: "network")
                            VStack(alignment: .leading) {
                                Text("Connect to Mac")
                                    .fontWeight(.semibold)
                                Text("Use bigger models via Ollama on your Mac")
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

                Text("All processing stays on your device.\nNothing leaves your phone.")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
            }
            .sheet(isPresented: $showModels) {
                ModelBrowserView()
            }
        }
    }
}

@Observable
final class MobileAppState {
    var chatViewModel: ChatViewModel?
    var orchestrator: Orchestrator?
    var localInference: LocalInference?
    var isReady = false

    var serverHost: String {
        get { UserDefaults.standard.string(forKey: "serverHost") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "serverHost") }
    }

    /// Start with on-device model via llama.cpp.
    @MainActor
    func startLocal() async {
        guard let model = ModelManager.shared.downloadedModels.first else { return }

        let inference = LocalInference()
        do {
            try await inference.loadModel(path: model.path.path)
        } catch {
            Log.app.error("Failed to load model: \(error)")
            return
        }

        self.localInference = inference
        // Use a simple orchestrator — local models don't need multi-agent routing
        let orch = Orchestrator()
        let vm = ChatViewModel(orchestrator: orch)
        self.orchestrator = orch
        self.chatViewModel = vm
        self.isReady = true
    }

    /// Start in server mode — connect to Mac's Ollama.
    @MainActor
    func startServer(host: String) async {
        serverHost = host
        let orch = Orchestrator(host: host)
        let vm = ChatViewModel(orchestrator: orch)
        self.orchestrator = orch
        self.chatViewModel = vm
        self.isReady = true

        Task.detached { await orch.prewarm() }
    }
}

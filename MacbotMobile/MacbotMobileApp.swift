import SwiftUI

@main
struct iPhoneBotApp: App {
    @State private var appState = MobileAppState()

    var body: some Scene {
        WindowGroup {
            if appState.isReady, let vm = appState.localChatViewModel {
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
        ScrollView {
            VStack(spacing: 0) {
                // Top section — branding
                VStack(spacing: 12) {
                    Image(systemName: "brain")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.accentColor)

                    Text("iPhoneBot")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Private AI — runs entirely on your iPhone")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 80) // Clear Dynamic Island
                .padding(.bottom, 40)

                // Action cards
                VStack(spacing: 12) {
                    // Download models — primary
                    Button(action: { showModels = true }) {
                        actionCard(
                            icon: "arrow.down.circle.fill",
                            iconColor: Color.accentColor,
                            title: "Download a Model",
                            subtitle: {
                                let count = ModelManager.shared.downloadedModels.count
                                return count > 0 ? "\(count) model\(count == 1 ? "" : "s") on device" : "Choose a model to get started"
                            }()
                        )
                    }
                    .buttonStyle(.plain)

                    // Start chatting
                    if !ModelManager.shared.downloadedModels.isEmpty {
                        Button(action: { Task { await appState.startLocal() } }) {
                            actionCard(
                                icon: "message.fill",
                                iconColor: .green,
                                title: "Start Chatting",
                                subtitle: "Using \(ModelManager.shared.downloadedModels.first?.name ?? "local model")"
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // Connect to Mac
                    NavigationLink {
                        MobileOnboardingView(appState: appState)
                    } label: {
                        actionCard(
                            icon: "network",
                            iconColor: .orange,
                            title: "Connect to Mac",
                            subtitle: "Use bigger models via Ollama"
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)

                Spacer()

                // Bottom info
                VStack(spacing: 16) {
                    // Device info
                    let ram = Int(Double(ProcessInfo.processInfo.physicalMemory) / 1e9)
                    HStack(spacing: 20) {
                        infoChip(icon: "memorychip", text: "\(ram)GB RAM")
                        infoChip(icon: "cpu", text: "A18 Pro")
                        infoChip(icon: "lock.shield", text: "On-Device")
                    }

                    Text("Nothing leaves your phone. Ever.")
                        .font(.caption2)
                        .foregroundStyle(.quaternary)
                }
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity)
        }
        .sheet(isPresented: $showModels) {
            ModelBrowserView()
        }
    }

    private func actionCard(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.quaternary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func infoChip(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
        }
        .foregroundStyle(.tertiary)
    }
}

@Observable
final class MobileAppState {
    var localChatViewModel: LocalChatViewModel?
    var localInference: LocalInference?
    var isReady = false
    var loadError: String?

    var serverHost: String {
        get { UserDefaults.standard.string(forKey: "serverHost") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "serverHost") }
    }

    @MainActor
    func startServer(host: String) async {
        // Server mode — for future use connecting to Mac's Ollama
        serverHost = host
    }

    @MainActor
    func startLocal() async {
        guard let model = ModelManager.shared.downloadedModels.first else {
            loadError = "No model downloaded. Download one first."
            return
        }

        loadError = nil
        let inference = LocalInference()
        do {
            try await inference.loadModel(path: model.path.path)
        } catch {
            loadError = "Failed to load model: \(error.localizedDescription)"
            Log.app.error("Failed to load model: \(error)")
            return
        }

        self.localInference = inference
        self.localChatViewModel = LocalChatViewModel(inference: inference)
        self.isReady = true
    }
}

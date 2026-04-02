import SwiftUI

struct MobileOnboardingView: View {
    let appState: MobileAppState
    @State private var hostInput = ""
    @State private var isTesting = false
    @State private var testResult: String?

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

                Text("Connect to your Mac's Ollama server\nto start chatting with AI.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()

                VStack(spacing: 12) {
                    TextField("Mac address (e.g. 192.168.1.100:11434)", text: $hostInput)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.URL)

                    if let result = testResult {
                        Text(result)
                            .font(.caption)
                            .foregroundStyle(result.contains("Connected") ? .green : .red)
                    }

                    Button(action: { Task { await testConnection() } }) {
                        if isTesting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Connect")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(hostInput.isEmpty || isTesting)
                }
                .padding(.horizontal, 32)

                Spacer()

                Text("All processing stays on your devices.\nNothing leaves your network.")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            if !appState.serverHost.isEmpty {
                hostInput = appState.serverHost
            }
        }
    }

    private func testConnection() async {
        let host = hostInput.hasPrefix("http") ? hostInput : "http://\(hostInput)"
        isTesting = true
        testResult = nil

        let client = OllamaClient(host: host)
        let reachable = await client.isReachable()

        if reachable {
            testResult = "Connected — found Ollama server"
            try? await Task.sleep(for: .seconds(0.5))
            await appState.startServer(host: host)
        } else {
            testResult = "Could not connect. Make sure Ollama is running and bound to 0.0.0.0"
        }

        isTesting = false
    }
}

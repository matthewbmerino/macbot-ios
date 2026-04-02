import SwiftUI

struct MobileSettingsView: View {
    let appState: MobileAppState
    @Environment(\.dismiss) private var dismiss
    @State private var hostInput = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Server Connection") {
                    TextField("Ollama host", text: $hostInput)
                        .textContentType(.URL)

                    Button("Reconnect") {
                        Task {
                            await appState.startServer(host: hostInput.hasPrefix("http") ? hostInput : "http://\(hostInput)")
                            dismiss()
                        }
                    }
                }

                Section("Device") {
                    LabeledContent("RAM") {
                        Text("\(Int(Double(ProcessInfo.processInfo.physicalMemory) / 1e9))GB")
                    }
                    LabeledContent("Mode") { Text("Server (Ollama)") }
                }

                Section("About") {
                    Text("All processing happens on your Mac or this device. Nothing leaves your network.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { hostInput = appState.serverHost }
        }
    }
}

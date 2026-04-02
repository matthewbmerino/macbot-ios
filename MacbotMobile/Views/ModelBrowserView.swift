import SwiftUI

struct ModelBrowserView: View {
    @State private var modelManager = ModelManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Downloaded models
                if !modelManager.downloadedModels.isEmpty {
                    Section("On Device") {
                        ForEach(modelManager.downloadedModels) { model in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(model.name)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    Text(model.sizeDescription)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                            .swipeActions {
                                Button("Delete", role: .destructive) {
                                    modelManager.delete(model)
                                }
                            }
                        }
                    }
                }

                // Available to download
                Section("Available Models") {
                    ForEach(ModelManager.catalog) { model in
                        let isDownloaded = modelManager.downloadedModels.contains {
                            $0.filename == model.downloadURL.lastPathComponent
                        }

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(model.name)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    Text(model.params)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 1)
                                        .background(.quaternary)
                                        .clipShape(Capsule())
                                }
                                Text(model.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(model.estimatedSize)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()

                            if isDownloaded {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else if modelManager.isDownloading && modelManager.downloadingModelName == model.name {
                                VStack(spacing: 4) {
                                    ProgressView(value: modelManager.downloadProgress)
                                        .frame(width: 60)
                                    Text("\(Int(modelManager.downloadProgress * 100))%")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                Button(action: {
                                    Task { try? await modelManager.download(model) }
                                }) {
                                    Image(systemName: "arrow.down.circle")
                                        .font(.title3)
                                        .foregroundStyle(Color.accentColor)
                                }
                                .buttonStyle(.plain)
                                .disabled(modelManager.isDownloading)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Device info
                Section("Device") {
                    let ram = Double(ProcessInfo.processInfo.physicalMemory) / 1e9
                    LabeledContent("RAM") { Text("\(Int(ram))GB") }
                    LabeledContent("Available") { Text("~\(Int(ram - 4))GB for models") }
                    Text("Models up to \(Int(ram - 4))GB Q4 will run on this device.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .navigationTitle("Models")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

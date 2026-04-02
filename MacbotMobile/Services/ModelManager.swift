import Foundation

struct LocalModel: Identifiable {
    let id: String
    let name: String
    let filename: String
    let sizeBytes: Int
    let path: URL

    var sizeDescription: String {
        let gb = Double(sizeBytes) / 1e9
        if gb >= 1 { return String(format: "%.1fGB", gb) }
        return String(format: "%.0fMB", gb * 1000)
    }
}

struct RemoteModel: Identifiable {
    let id: String
    let name: String
    let description: String
    let downloadURL: URL
    let estimatedSize: String
    let params: String
}

@Observable
final class ModelManager {
    static let shared = ModelManager()

    var downloadedModels: [LocalModel] = []
    var isDownloading = false
    var downloadProgress: Double = 0
    var downloadingModelName: String?

    private let modelsDir: URL

    private init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!.appendingPathComponent("iPhoneBot/Models", isDirectory: true)

        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)

        // Exclude from iCloud backup
        var url = appSupport
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)

        self.modelsDir = appSupport
        refresh()
    }

    // MARK: - Catalog of recommended models for iPhone

    static let catalog: [RemoteModel] = [
        RemoteModel(
            id: "qwen2.5-1.5b",
            name: "Qwen 2.5 1.5B",
            description: "Fast, lightweight general chat. Great for quick responses.",
            downloadURL: URL(string: "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf")!,
            estimatedSize: "1.1GB",
            params: "1.5B"
        ),
        RemoteModel(
            id: "qwen2.5-3b",
            name: "Qwen 2.5 3B",
            description: "Balanced quality and speed. Good for most tasks.",
            downloadURL: URL(string: "https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf")!,
            estimatedSize: "2.0GB",
            params: "3B"
        ),
        RemoteModel(
            id: "phi-4-mini",
            name: "Phi-4 Mini 3.8B",
            description: "Microsoft's efficient model. Strong reasoning for its size.",
            downloadURL: URL(string: "https://huggingface.co/microsoft/Phi-4-mini-instruct-gguf/resolve/main/Phi-4-mini-instruct-Q4_K_M.gguf")!,
            estimatedSize: "2.5GB",
            params: "3.8B"
        ),
        RemoteModel(
            id: "gemma-2-2b",
            name: "Gemma 2 2B",
            description: "Google's compact model. Good at following instructions.",
            downloadURL: URL(string: "https://huggingface.co/google/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf")!,
            estimatedSize: "1.6GB",
            params: "2B"
        ),
    ]

    // MARK: - List Downloaded

    func refresh() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: modelsDir, includingPropertiesForKeys: [.fileSizeKey]) else {
            downloadedModels = []
            return
        }

        downloadedModels = files
            .filter { $0.pathExtension == "gguf" }
            .compactMap { url in
                let attrs = try? fm.attributesOfItem(atPath: url.path)
                let size = attrs?[.size] as? Int ?? 0
                let name = url.deletingPathExtension().lastPathComponent
                return LocalModel(
                    id: name,
                    name: name,
                    filename: url.lastPathComponent,
                    sizeBytes: size,
                    path: url
                )
            }
            .sorted { $0.name < $1.name }
    }

    func listDownloaded() -> [LocalModel] {
        refresh()
        return downloadedModels
    }

    // MARK: - Download

    func download(_ model: RemoteModel) async throws {
        await MainActor.run {
            isDownloading = true
            downloadProgress = 0
            downloadingModelName = model.name
        }

        defer {
            Task { @MainActor in
                isDownloading = false
                downloadingModelName = nil
            }
        }

        let destURL = modelsDir.appendingPathComponent(model.downloadURL.lastPathComponent)

        // Skip if already downloaded
        if FileManager.default.fileExists(atPath: destURL.path) {
            refresh()
            return
        }

        var request = URLRequest(url: model.downloadURL)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
        let totalBytes = response.expectedContentLength

        let fileHandle = try FileHandle(forWritingTo: destURL)
        // Create the file first
        FileManager.default.createFile(atPath: destURL.path, contents: nil)
        let handle = try FileHandle(forWritingTo: destURL)

        var downloaded: Int64 = 0
        var buffer = Data()
        let chunkSize = 1024 * 1024 // 1MB chunks

        for try await byte in asyncBytes {
            buffer.append(byte)

            if buffer.count >= chunkSize {
                handle.write(buffer)
                downloaded += Int64(buffer.count)
                buffer = Data()

                if totalBytes > 0 {
                    let progress = Double(downloaded) / Double(totalBytes)
                    await MainActor.run { downloadProgress = progress }
                }
            }
        }

        // Write remaining
        if !buffer.isEmpty {
            handle.write(buffer)
        }
        handle.closeFile()

        await MainActor.run { downloadProgress = 1.0 }
        refresh()
        Log.app.info("Downloaded model: \(model.name) to \(destURL.lastPathComponent)")
    }

    // MARK: - Delete

    func delete(_ model: LocalModel) {
        try? FileManager.default.removeItem(at: model.path)
        refresh()
    }

    // MARK: - Path

    func path(for modelId: String) -> URL? {
        downloadedModels.first { $0.id == modelId || $0.filename.contains(modelId) }?.path
    }
}

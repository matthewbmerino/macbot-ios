/// On-device LLM inference via llama.cpp. Runs GGUF models directly on iPhone.

import Foundation
import SwiftLlama

final class LocalInference: @unchecked Sendable {
    private var service: LlamaService?
    private var currentModelPath: String?

    /// Load a GGUF model from disk.
    func loadModel(path: String, maxTokens: UInt32 = 2048, useGPU: Bool = true) throws {
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: path) else {
            throw LocalInferenceError.modelNotFound(path)
        }

        service = LlamaService(
            modelUrl: url,
            config: LlamaConfig(
                batchSize: 512,
                maxTokenCount: maxTokens,
                useGPU: useGPU
            )
        )
        currentModelPath = path
        Log.inference.info("Loaded model: \(url.lastPathComponent)")
    }

    func unloadModel() {
        service = nil
        currentModelPath = nil
        Log.inference.info("Model unloaded")
    }

    var isModelLoaded: Bool { service != nil }

    // MARK: - Chat

    func chat(messages: [[String: Any]], temperature: Double = 0.7) async throws -> String {
        guard let service else { throw LocalInferenceError.noModelLoaded }

        let llamaMessages = convertMessages(messages)
        let sampling = LlamaSamplingConfig(temperature: Float(temperature), seed: UInt32.random(in: 0...UInt32.max))

        var fullResponse = ""
        let stream = try await service.streamCompletion(of: llamaMessages, samplingConfig: sampling)
        for try await token in stream {
            fullResponse += token
        }
        return fullResponse
    }

    func chatStream(messages: [[String: Any]], temperature: Double = 0.7) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let service = self.service else {
                        throw LocalInferenceError.noModelLoaded
                    }

                    let llamaMessages = self.convertMessages(messages)
                    let sampling = LlamaSamplingConfig(temperature: Float(temperature), seed: UInt32.random(in: 0...UInt32.max))

                    let stream = try await service.streamCompletion(of: llamaMessages, samplingConfig: sampling)
                    for try await token in stream {
                        continuation.yield(token)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Private

    private func convertMessages(_ messages: [[String: Any]]) -> [LlamaChatMessage] {
        messages.compactMap { msg in
            guard let role = msg["role"] as? String,
                  let content = msg["content"] as? String
            else { return nil }

            let llamaRole: LlamaChatMessage.Role
            switch role {
            case "system": llamaRole = .system
            case "user": llamaRole = .user
            case "assistant": llamaRole = .assistant
            default: llamaRole = .user
            }

            return LlamaChatMessage(role: llamaRole, content: content)
        }
    }
}

enum LocalInferenceError: Error, LocalizedError {
    case noModelLoaded
    case modelNotFound(String)

    var errorDescription: String? {
        switch self {
        case .noModelLoaded: "No model loaded. Download a model first."
        case .modelNotFound(let path): "Model file not found: \(path)"
        }
    }
}

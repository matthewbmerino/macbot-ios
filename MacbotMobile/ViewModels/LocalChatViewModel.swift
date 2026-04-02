import Foundation
import SwiftUI

/// Simple chat view model that talks directly to LocalInference (llama.cpp).
/// No Orchestrator, no routing, no tools — just direct model conversation.
@Observable
final class LocalChatViewModel {
    var messages: [ChatMessage] = []
    var isStreaming = false
    var currentStatus: String?
    var inputText = ""

    private let inference: LocalInference
    private var history: [[String: Any]] = []

    init(inference: LocalInference) {
        self.inference = inference
        history.append([
            "role": "system",
            "content": "You are a helpful AI assistant running locally on an iPhone. Be concise and direct. Do not use markdown formatting."
        ])
    }

    @MainActor
    func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isStreaming else { return }

        inputText = ""
        messages.append(ChatMessage(role: .user, content: text))
        history.append(["role": "user", "content": text])
        isStreaming = true
        currentStatus = "Thinking..."

        Task {
            var responseText = ""

            do {
                let stream = inference.chatStream(messages: history, temperature: 0.7)
                await MainActor.run { currentStatus = nil }

                for try await token in stream {
                    responseText += token
                    await MainActor.run {
                        updateOrAppendResponse(responseText)
                    }
                }
            } catch {
                responseText = "Error: \(error.localizedDescription)"
                await MainActor.run {
                    updateOrAppendResponse(responseText)
                }
            }

            history.append(["role": "assistant", "content": responseText])

            await MainActor.run {
                isStreaming = false
                currentStatus = nil
            }
        }
    }

    @MainActor
    private func updateOrAppendResponse(_ text: String) {
        if let last = messages.last, last.role == .assistant {
            messages[messages.count - 1] = ChatMessage(role: .assistant, content: text)
        } else {
            messages.append(ChatMessage(role: .assistant, content: text))
        }
    }

    func newChat() {
        messages.removeAll()
        history = [[
            "role": "system",
            "content": "You are a helpful AI assistant running locally on an iPhone. Be concise and direct. Do not use markdown formatting."
        ]]
    }
}

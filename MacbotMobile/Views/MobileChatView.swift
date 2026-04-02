import SwiftUI

struct MobileChatView: View {
    @Bindable var viewModel: ChatViewModel
    let appState: MobileAppState
    @FocusState private var inputFocused: Bool
    @State private var showSettings = false
    @State private var showModels = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        if viewModel.messages.isEmpty {
                            emptyState
                        } else {
                            LazyVStack(alignment: .leading, spacing: 8) {
                                ForEach(viewModel.messages) { msg in
                                    MobileMessageBubble(message: msg)
                                        .id(msg.id)
                                }

                                if let status = viewModel.currentStatus {
                                    HStack(spacing: 8) {
                                        ProgressView().controlSize(.small)
                                        Text(status)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .italic()
                                    }
                                    .padding(.horizontal)
                                    .id("status")
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .onChange(of: viewModel.messages.count) {
                        withAnimation {
                            if let id = viewModel.messages.last?.id {
                                proxy.scrollTo(id, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                HStack(spacing: 10) {
                    TextField("Message...", text: $viewModel.inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(1...4)
                        .focused($inputFocused)
                        .onSubmit { viewModel.send() }
                        .disabled(viewModel.isStreaming)

                    Button(action: { viewModel.send() }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color.secondary.opacity(0.3) : Color.accentColor
                            )
                    }
                    .disabled(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isStreaming)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .navigationTitle("iPhoneBot")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Text(viewModel.activeAgent.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.quaternary)
                        .clipShape(Capsule())
                }
                ToolbarItem(placement: .automatic) {
                    Menu {
                        Button("New Chat") { viewModel.newChat() }
                        Button("Models") { showModels = true }
                        Button("Settings") { showSettings = true }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                MobileSettingsView(appState: appState)
            }
            .sheet(isPresented: $showModels) {
                ModelBrowserView()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "brain")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("What can I help with?")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("All processing happens on this device.\nNothing leaves your phone.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MobileMessageBubble: View {
    let message: ChatMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: message.role == .user ? "person.circle.fill" : "brain")
                    .font(.caption)
                    .foregroundStyle(message.role == .user ? .primary : Color.accentColor)
                Text(message.role == .user ? "You" : "Macbot")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(message.role == .user ? .primary : Color.accentColor)
                if let agent = message.agentCategory {
                    Text(agent.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(.quaternary)
                        .clipShape(Capsule())
                }
                Spacer()
            }

            if !message.content.isEmpty {
                Text(message.content)
                    .font(.body)
                    .textSelection(.enabled)
            }

            if let images = message.images, !images.isEmpty {
                ForEach(Array(images.enumerated()), id: \.offset) { _, data in
                    #if os(iOS)
                    if let img = UIImage(data: data) {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    #else
                    if let img = NSImage(data: data) {
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    #endif
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

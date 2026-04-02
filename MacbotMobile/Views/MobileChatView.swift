import SwiftUI

struct MobileChatView: View {
    @Bindable var viewModel: ChatViewModel
    let appState: MobileAppState
    @FocusState private var inputFocused: Bool
    @State private var showSettings = false
    @State private var showModels = false

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    // Messages — takes all available space
                    ScrollViewReader { proxy in
                        ScrollView {
                            if viewModel.messages.isEmpty {
                                emptyState(height: geo.size.height - 60)
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
                                        .padding(.horizontal, 16)
                                        .id("status")
                                    }

                                    if viewModel.isStreaming && viewModel.currentStatus == nil
                                        && viewModel.messages.last?.role == .user {
                                        HStack(spacing: 4) {
                                            ForEach(0..<3, id: \.self) { _ in
                                                Circle()
                                                    .fill(.secondary.opacity(0.4))
                                                    .frame(width: 6, height: 6)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .frame(maxHeight: .infinity)
                        .onChange(of: viewModel.messages.count) {
                            withAnimation {
                                if let id = viewModel.messages.last?.id {
                                    proxy.scrollTo(id, anchor: .bottom)
                                }
                            }
                        }
                    }

                    // Input bar — pinned to bottom
                    Divider()
                    inputBar
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .navigationTitle("iPhoneBot")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
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
            .onAppear { inputFocused = true }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Message...", text: $viewModel.inputText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
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
        .background(.bar)
    }

    // MARK: - Empty State

    private func emptyState(height: CGFloat) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "brain")
                .font(.system(size: 44))
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
        .frame(maxWidth: .infinity)
        .frame(height: height)
    }
}

struct MobileMessageBubble: View {
    let message: ChatMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: message.role == .user ? "person.circle.fill" : "brain")
                    .font(.subheadline)
                    .foregroundStyle(message.role == .user ? .primary : Color.accentColor)
                Text(message.role == .user ? "You" : "iPhoneBot")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(message.role == .user ? .primary : Color.accentColor)
                if let agent = message.agentCategory {
                    Text(agent.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary)
                        .clipShape(Capsule())
                }
                Spacer()
            }

            // Content
            if !message.content.isEmpty {
                Text(message.content)
                    .font(.body)
                    .textSelection(.enabled)
            }

            // Images
            if let images = message.images, !images.isEmpty {
                ForEach(Array(images.enumerated()), id: \.offset) { _, data in
                    #if os(iOS)
                    if let img = UIImage(data: data) {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    #else
                    if let img = NSImage(data: data) {
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    #endif
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}

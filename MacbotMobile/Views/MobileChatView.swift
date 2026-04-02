import SwiftUI

struct MobileChatView: View {
    @Bindable var viewModel: ChatViewModel
    let appState: MobileAppState
    @FocusState private var inputFocused: Bool
    @State private var showSettings = false
    @State private var showModels = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "brain")
                    .foregroundStyle(Color.accentColor)
                Text("iPhoneBot")
                    .font(.headline)
                Spacer()
                if viewModel.isStreaming {
                    ProgressView().controlSize(.small)
                }
                Menu {
                    Button("New Chat") { viewModel.newChat() }
                    Button("Models") { showModels = true }
                    Button("Settings") { showSettings = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.bar)

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    if viewModel.messages.isEmpty {
                        Color.clear.frame(height: 1)
                    }

                    LazyVStack(alignment: .leading, spacing: 10) {
                        if viewModel.messages.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "brain")
                                    .font(.system(size: 36))
                                    .foregroundStyle(.tertiary)
                                Text("What can I help with?")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                Text("On-device AI. Nothing leaves your phone.")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                        }

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
                    }
                    .padding(.bottom, 8)
                }
                .onChange(of: viewModel.messages.count) {
                    withAnimation {
                        if let id = viewModel.messages.last?.id {
                            proxy.scrollTo(id, anchor: .bottom)
                        }
                    }
                }
            }

            // Input
            Divider()
            HStack(spacing: 10) {
                TextField("Message...", text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)
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
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
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

struct MobileMessageBubble: View {
    let message: ChatMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: message.role == .user ? "person.circle.fill" : "brain")
                    .font(.subheadline)
                    .foregroundStyle(message.role == .user ? .primary : Color.accentColor)
                Text(message.role == .user ? "You" : "iPhoneBot")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(message.role == .user ? .primary : Color.accentColor)
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
    }
}

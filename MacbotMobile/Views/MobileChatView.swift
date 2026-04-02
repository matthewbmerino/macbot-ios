import SwiftUI

struct MobileChatView: View {
    @Bindable var viewModel: ChatViewModel
    let appState: MobileAppState
    @FocusState private var inputFocused: Bool
    @State private var showSettings = false
    @State private var showModels = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    List {
                        if viewModel.messages.isEmpty {
                            Section {
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
                                .padding(.vertical, 40)
                                .listRowBackground(Color.clear)
                            }
                        } else {
                            ForEach(viewModel.messages) { msg in
                                MobileMessageBubble(message: msg)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
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
                                .listRowSeparator(.hidden)
                                .id("status")
                            }
                        }
                    }
                    .listStyle(.plain)
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
            .navigationTitle("iPhoneBot")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    Text(viewModel.activeAgent.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.quaternary)
                        .clipShape(Capsule())
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("New Chat") { viewModel.newChat() }
                        Button("Models") { showModels = true }
                        Button("Settings") { showSettings = true }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Menu {
                        Button("New Chat") { viewModel.newChat() }
                        Button("Models") { showModels = true }
                        Button("Settings") { showSettings = true }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                #endif
            }
            .sheet(isPresented: $showSettings) {
                MobileSettingsView(appState: appState)
            }
            .sheet(isPresented: $showModels) {
                ModelBrowserView()
            }
        }
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

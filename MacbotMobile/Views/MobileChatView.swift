import SwiftUI

struct MobileChatView: View {
    @Bindable var viewModel: LocalChatViewModel
    let appState: MobileAppState
    @FocusState private var inputFocused: Bool
    @State private var showModels = false

    var body: some View {
        GeometryReader { geo in
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
                    Button(action: { showModels = true }) {
                        Image(systemName: "cpu")
                    }
                    Button(action: { viewModel.newChat() }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 50)

                Divider()

                // Messages — explicit height to fill remaining space
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            if viewModel.messages.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "brain")
                                        .font(.system(size: 36))
                                        .foregroundStyle(.tertiary)
                                    Text("What can I help with?")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 60)
                            }

                            ForEach(viewModel.messages) { msg in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(msg.role == .user ? "You" : "iPhoneBot")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(msg.role == .user ? .primary : Color.accentColor)
                                    Text(msg.content)
                                        .font(.body)
                                        .textSelection(.enabled)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 4)
                                .id(msg.id)
                            }

                            if let status = viewModel.currentStatus {
                                HStack(spacing: 6) {
                                    ProgressView().controlSize(.small)
                                    Text(status).font(.caption).foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    .frame(height: geo.size.height - 110)
                    .onChange(of: viewModel.messages.count) {
                        if let id = viewModel.messages.last?.id {
                            withAnimation { proxy.scrollTo(id, anchor: .bottom) }
                        }
                    }
                }

                // Input
                Divider()
                HStack(spacing: 8) {
                    TextField("Message...", text: $viewModel.inputText)
                        .textFieldStyle(.roundedBorder)
                        .focused($inputFocused)
                        .onSubmit { viewModel.send() }

                    Button(action: { viewModel.send() }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                viewModel.inputText.isEmpty ? Color.gray : Color.accentColor
                            )
                    }
                    .disabled(viewModel.inputText.isEmpty || viewModel.isStreaming)
                }
                .padding(.horizontal, 12)
                .frame(height: 50)
            }
        }
        .sheet(isPresented: $showModels) {
            ModelBrowserView()
        }
        .onAppear { inputFocused = true }
    }
}

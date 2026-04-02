import SwiftUI

struct MobileChatView: View {
    @Bindable var viewModel: LocalChatViewModel
    let appState: MobileAppState
    @FocusState private var inputFocused: Bool
    @State private var showModels = false

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.07)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "brain")
                        .foregroundStyle(Color.accentColor)
                    Text("iPhoneBot")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    if viewModel.isStreaming {
                        ProgressView().controlSize(.small).tint(.white)
                    }
                    Button(action: { showModels = true }) {
                        Image(systemName: "cpu").foregroundStyle(.white)
                    }
                    Button(action: { viewModel.newChat() }) {
                        Image(systemName: "square.and.pencil").foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)

                Divider().background(.gray.opacity(0.3))

                // Messages — this is the key: Spacer pushes input down, ScrollView fills remaining
                if viewModel.messages.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "brain")
                            .font(.system(size: 36))
                            .foregroundStyle(.gray.opacity(0.4))
                        Text("What can I help with?")
                            .font(.headline)
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 12) {
                                ForEach(viewModel.messages) { msg in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(msg.role == .user ? "You" : "iPhoneBot")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundStyle(msg.role == .user ? .white : Color.accentColor)
                                        Text(msg.content)
                                            .font(.body)
                                            .foregroundStyle(.white)
                                            .textSelection(.enabled)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(.horizontal, 16)
                                    .id(msg.id)
                                }

                                if let status = viewModel.currentStatus {
                                    HStack(spacing: 6) {
                                        ProgressView().controlSize(.small).tint(.gray)
                                        Text(status).font(.caption).foregroundStyle(.gray)
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                            .padding(.vertical, 12)
                        }
                        .onChange(of: viewModel.messages.count) {
                            if let id = viewModel.messages.last?.id {
                                withAnimation { proxy.scrollTo(id, anchor: .bottom) }
                            }
                        }
                        .onChange(of: viewModel.messages.last?.content) { _, _ in
                            if let id = viewModel.messages.last?.id {
                                proxy.scrollTo(id, anchor: .bottom)
                            }
                        }
                    }
                }

                // Input
                Divider().background(.gray.opacity(0.3))
                HStack(spacing: 8) {
                    TextField("Message...", text: $viewModel.inputText)
                        .textFieldStyle(.roundedBorder)
                        .focused($inputFocused)
                        .onSubmit { viewModel.send() }

                    Button(action: { viewModel.send() }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color.gray.opacity(0.4) : Color.accentColor
                            )
                    }
                    .disabled(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isStreaming)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .sheet(isPresented: $showModels) {
            ModelBrowserView()
        }
        .onAppear { inputFocused = true }
    }
}

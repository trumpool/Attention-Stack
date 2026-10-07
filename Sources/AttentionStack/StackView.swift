import AppKit
import AttentionCore
import SwiftUI

private enum Palette {
    static let mint = Color(red: 0.65, green: 0.96, blue: 0.82)
    static let lilac = Color(red: 0.76, green: 0.72, blue: 1)
    static let muted = Color(red: 0.58, green: 0.60, blue: 0.67)
    static let background = Color(red: 0.065, green: 0.074, blue: 0.10)
}

struct StackView: View {
    @ObservedObject var store: StackStore
    @ObservedObject var coordinator: PanelCoordinator
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("newIdeaDraft") private var draft = ""
    @State private var archiveSearch = ""
    @State private var focusTargeted = false
    @State private var draggingID: UUID?
    @State private var dragPoint = CGPoint.zero
    @State private var focusFrame = CGRect.zero
    @State private var queueFrame = CGRect.zero
    @State private var rowFrames: [UUID: CGRect] = [:]
    @State private var editedItem: AttentionItem?
    @State private var editedTitle = ""
    @State private var editPresented = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        ZStack {
            if coordinator.isExpanded {
                expanded
                    .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
            } else {
                collapsed
                    .transition(.opacity)
            }
        }
        .padding(12)
        .frame(width: coordinator.width, height: coordinator.height)
        .overlay(alignment: .topLeading) {
            if let id = draggingID, let item = store.state.pending.first(where: { $0.id == id }) {
                HStack(spacing: 10) {
                    Image(systemName: "square.stack").foregroundStyle(Palette.lilac)
                    Text(item.title).font(.system(size: 12, weight: .medium)).lineLimit(2)
                    Spacer(minLength: 0)
                    Image(systemName: focusTargeted ? "arrow.up.circle.fill" : "hand.draw")
                        .foregroundStyle(focusTargeted ? Palette.mint : Palette.muted)
                }
                .padding(14).frame(width: coordinator.width - 84)
                .background(Palette.background.opacity(0.98), in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(focusTargeted ? Palette.mint : Palette.lilac.opacity(0.5)))
                .shadow(color: .black.opacity(0.4), radius: 15, y: 7)
                .rotationEffect(.degrees(focusTargeted ? 0 : -1.5))
                .position(dragPoint)
                .allowsHitTesting(false)
            }
        }
        .coordinateSpace(name: "stack")
        .onPreferenceChange(FocusFrameKey.self) { focusFrame = $0 }
        .onPreferenceChange(QueueFrameKey.self) { queueFrame = $0 }
        .onPreferenceChange(RowFramesKey.self) { rowFrames = $0 }
        .preferredColorScheme(.dark)
        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.85), value: coordinator.isExpanded)
        .onExitCommand { coordinator.collapse() }
        .onChange(of: coordinator.inputRequest) { _, _ in inputFocused = true }
        .onChange(of: coordinator.isExpanded) { _, expanded in
            if expanded {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { inputFocused = true }
            } else { inputFocused = false }
        }
        .alert("修改事项", isPresented: $editPresented) {
            TextField("事项名称", text: $editedTitle)
            Button("取消", role: .cancel) { editedItem = nil }
            Button("保存") {
                if let item = editedItem { store.rename(item.id, to: editedTitle) }
                editedItem = nil
            }
        }
    }

    private var collapsed: some View {
        HStack(spacing: 12) {
            HStack(spacing: 11) {
                if store.state.current != nil { PulseDot() }
                else { Image(systemName: "square.3.layers.3d").foregroundStyle(Palette.mint) }
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.state.current == nil ? "Attention Stack" : "正在专注")
                        .font(.system(size: 9, weight: .medium))
                        .tracking(1).foregroundStyle(Palette.muted)
                    Text(store.state.current?.title ?? "想到什么，就放进来")
                        .font(.system(size: 12, weight: .medium)).lineLimit(1)
                }
                Spacer(minLength: 0)
                if !store.state.pending.isEmpty {
                    Text("+\(store.state.pending.count)")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(Palette.lilac)
                        .padding(.horizontal, 7).padding(.vertical, 4)
                        .background(Palette.lilac.opacity(0.10), in: Capsule())
                }
            }
            .overlay(WindowDragRegion(onClick: coordinator.toggle, onDragEnded: coordinator.didDrag))
            if store.state.current != nil {
                completeButton(size: 28)
            } else {
                Button { coordinator.expand(focusInput: true) } label: {
                    Image(systemName: "plus").font(.system(size: 12, weight: .semibold))
                        .frame(width: 28, height: 28)
                        .background(Palette.mint.opacity(0.13), in: Circle())
                }
                .buttonStyle(.plain).foregroundStyle(Palette.mint)
                .help("添加想法")
                .accessibilityLabel("展开并添加想法")
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 19).fill(Palette.background.opacity(0.97))
                .overlay(RoundedRectangle(cornerRadius: 19).stroke(.white.opacity(0.12), lineWidth: 1))
                .shadow(color: .black.opacity(0.32), radius: 10, y: 4)
        }
    }

    private var expanded: some View {
        Group {
            if coordinator.height < 570 {
                ScrollView { expandedContent }.scrollIndicators(.hidden)
            } else {
                expandedContent
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 27))
        .background {
            ZStack(alignment: .topLeading) {
                GlassBackdrop()
                Palette.background.opacity(0.92)
            }
            .overlay(alignment: .topLeading) {
                Ellipse().fill(Palette.lilac.opacity(0.07))
                    .frame(width: 380, height: 150).blur(radius: 45).offset(x: -100, y: -90)
            }
            .clipShape(RoundedRectangle(cornerRadius: 27))
            .overlay(RoundedRectangle(cornerRadius: 27)
                .stroke(LinearGradient(colors: [.white.opacity(0.18), .white.opacity(0.04)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
            .shadow(color: .black.opacity(0.35), radius: 10, y: 4)
        }
    }

    private var expandedContent: some View {
        VStack(spacing: 15) {
            header
            tabs
            if let error = store.storageError {
                Text(error).font(.system(size: 10)).foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8).background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
            if coordinator.showingArchive {
                archiveContent.frame(minHeight: coordinator.height < 570 ? 300 : nil)
            } else {
                focusCard
                addField
                queue.frame(height: coordinator.height < 570 ? 150 : nil)
                feedback
            }
            footer
        }
        .padding(20)
    }

    private var header: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "square.3.layers.3d")
                    .font(.system(size: 21, weight: .light)).foregroundStyle(Palette.mint)
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Attention Stack").font(.system(size: 15, weight: .semibold, design: .rounded))
                    Text("一次，只专注一件事").font(.system(size: 10)).foregroundStyle(Palette.muted)
                }
                Spacer(minLength: 0)
            }
            .overlay(WindowDragRegion(onClick: {}, onDragEnded: coordinator.didDrag))
            Menu {
                Button("回到屏幕顶部", action: coordinator.home)
                Button("导出归档…", action: store.exportArchive)
                Button("暂时隐藏", action: coordinator.hide)
                Divider()
                Button("退出 Attention Stack") { NSApp.terminate(nil) }
            } label: {
                Image(systemName: "ellipsis").frame(width: 24, height: 26)
            }
            .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
            .foregroundStyle(Palette.muted).help("更多选项")
            Button(action: coordinator.collapse) {
                Image(systemName: "chevron.up").font(.system(size: 11, weight: .semibold))
                    .frame(width: 28, height: 28).background(.white.opacity(0.05), in: Circle())
            }
            .buttonStyle(.plain).foregroundStyle(Palette.muted).help("收起 · Esc")
            .accessibilityLabel("收起专注栈")
        }
    }

    private var tabs: some View {
        HStack(spacing: 4) {
            tab("专注栈", icon: "square.stack", selected: !coordinator.showingArchive) {
                withAnimation { coordinator.showingArchive = false }
            }
            tab("已归档 \(store.state.archive.count)", icon: "archivebox", selected: coordinator.showingArchive) {
                withAnimation { coordinator.showingArchive = true }
            }
        }
        .padding(4).background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 11))
    }

    private func tab(_ title: String, icon: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) { Image(systemName: icon); Text(title) }
                .font(.system(size: 11, weight: selected ? .semibold : .regular))
                .frame(maxWidth: .infinity).padding(.vertical, 8)
                .foregroundStyle(selected ? .white : Palette.muted)
                .background(selected ? .white.opacity(0.08) : .clear, in: RoundedRectangle(cornerRadius: 8))
        }.buttonStyle(.plain)
    }

    private var focusCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 7) {
                PulseDot()
                Text(focusTargeted ? "松开，切换当前专注" : "NOW / 当前专注")
                    .font(.system(size: 10, weight: .semibold)).tracking(0.8)
                Spacer()
                if let current = store.state.current {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Text(duration(current.attentionDuration(at: context.date)))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .contentTransition(.numericText())
                    }
                    .foregroundStyle(Palette.mint.opacity(0.7))
                }
            }.foregroundStyle(Palette.mint)
            HStack(alignment: .center, spacing: 15) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(store.state.current?.title ?? "给此刻，留一件事")
                        .font(.system(size: 22, weight: .medium))
                        .lineLimit(3).fixedSize(horizontal: false, vertical: true)
                        .id(store.state.current?.id)
                        .transition(.opacity.combined(with: .offset(y: 6)))
                    if store.state.current == nil {
                        Text("在下面记下第一个想法").font(.system(size: 11)).foregroundStyle(Palette.muted)
                    }
                }
                Spacer(minLength: 0)
                if store.state.current != nil { completeButton(size: 42) }
            }
            if let current = store.state.current {
                Text("\(current.enqueuedAt.formatted(date: .omitted, time: .shortened)) 入栈 · 完成后自动接续下一项")
                    .font(.system(size: 10)).foregroundStyle(Palette.mint.opacity(0.55))
            }
        }
        .padding(18).frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(LinearGradient(colors: [Palette.mint.opacity(0.105), Palette.mint.opacity(0.025)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 18)
                    .stroke(Palette.mint.opacity(focusTargeted ? 0.9 : 0.3), lineWidth: focusTargeted ? 2 : 1))
                .shadow(color: Palette.mint.opacity(focusTargeted ? 0.14 : 0.025), radius: 18)
        }
        .scaleEffect(focusTargeted ? 1.018 : 1)
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.75), value: focusTargeted)
        .background(GeometryReader { proxy in
            Color.clear.preference(key: FocusFrameKey.self, value: proxy.frame(in: .named("stack")))
        })
        .contextMenu {
            if let current = store.state.current {
                Button("修改名称…") { edit(current) }
            }
        }
    }

    private func completeButton(size: CGFloat) -> some View {
        Button(action: store.complete) {
            Image(systemName: "checkmark").font(.system(size: size * 0.32, weight: .semibold))
                .foregroundStyle(Palette.mint)
                .frame(width: size, height: size)
                .background(Palette.mint.opacity(0.12), in: Circle())
                .overlay(Circle().stroke(Palette.mint.opacity(0.3), lineWidth: 1))
                .symbolEffect(.bounce, value: store.celebration)
        }
        .buttonStyle(SoftPressStyle())
        .help("完成当前事项")
        .accessibilityLabel("完成当前事项并开始下一项")
    }

    private var addField: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus").font(.system(size: 13)).foregroundStyle(Palette.lilac)
            TextField("想到什么，就放进来…", text: $draft)
                .textFieldStyle(.plain).font(.system(size: 12))
                .focused($inputFocused).onSubmit(addDraft)
                .accessibilityLabel("新的待办事项")
            Button {
                store.insertionPosition = store.insertionPosition == .front ? .back : .front
                inputFocused = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: store.insertionPosition == .front ? "arrow.up.to.line" : "arrow.down.to.line")
                        .font(.system(size: 9, weight: .semibold))
                    Text(store.insertionPosition == .front ? "前面" : "后面")
                }
                .font(.system(size: 10, weight: .medium))
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(Palette.lilac.opacity(0.09), in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(SoftPressStyle()).fixedSize()
            .foregroundStyle(Palette.lilac)
            .help("点击切换到待办\(store.insertionPosition == .front ? "后面" : "前面")入栈")
            .accessibilityLabel("入栈位置：\(store.insertionPosition == .front ? "前面" : "后面")，点击切换到\(store.insertionPosition == .front ? "后面" : "前面")")
            Button(action: addDraft) {
                Image(systemName: "arrow.turn.down.left").font(.system(size: 10, weight: .medium))
                    .frame(width: 25, height: 25)
                    .background(Palette.lilac.opacity(draft.isEmpty ? 0.05 : 0.16), in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain).foregroundStyle(Palette.lilac)
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .help("入栈 · Return").accessibilityLabel("将新事项入栈")
        }
        .padding(.horizontal, 13).padding(.vertical, 11)
        .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(inputFocused ? Palette.lilac.opacity(0.35) : .white.opacity(0.07)))
    }

    private var queue: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("待办栈").font(.system(size: 11, weight: .medium))
                Text("\(store.state.pending.count)")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(.white.opacity(0.06), in: Capsule())
                Spacer()
                Text("拖到上方即可专注").font(.system(size: 10))
            }.foregroundStyle(Palette.muted)
            if store.state.pending.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "square.stack.3d.up").font(.system(size: 25, weight: .ultraLight))
                        .foregroundStyle(Palette.lilac.opacity(0.6))
                    Text(store.state.current == nil ? "清空了，也是一种进展" : "其他想法，先放在这里")
                        .font(.system(size: 11)).foregroundStyle(Palette.muted)
                    Text("新想法入栈时，当前专注会继续")
                        .font(.system(size: 10)).foregroundStyle(Palette.muted.opacity(0.65))
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 7) {
                        ForEach(Array(store.state.pending.enumerated()), id: \.element.id) { index, item in
                            queueRow(item, index: index)
                        }
                        Color.clear.frame(height: 22)
                    }
                    .padding(.vertical, 2)
                }.scrollIndicators(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GeometryReader { proxy in
            Color.clear.preference(key: QueueFrameKey.self, value: proxy.frame(in: .named("stack")))
        })
    }

    private func queueRow(_ item: AttentionItem, index: Int) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "line.3.horizontal").font(.system(size: 10))
                .foregroundStyle(Palette.muted.opacity(0.5))
            Text(String(format: "%02d", index + 1))
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(index == 0 ? Palette.lilac : Palette.muted.opacity(0.7))
            VStack(alignment: .leading, spacing: 5) {
                Text(item.title).font(.system(size: 12, weight: .medium)).lineLimit(2)
                HStack(spacing: 6) {
                    if index == 0 { Text("接下来").foregroundStyle(Palette.lilac.opacity(0.8)) }
                    Text("\(item.enqueuedAt.formatted(date: .omitted, time: .shortened)) 入栈")
                        .foregroundStyle(Palette.muted.opacity(0.7))
                }.font(.system(size: 9))
            }
            Spacer(minLength: 0)
            Button { store.promote(item.id) } label: {
                Image(systemName: "arrow.up").font(.system(size: 10, weight: .semibold))
                    .frame(width: 24, height: 28)
            }
            .buttonStyle(.plain).foregroundStyle(Palette.muted)
            .help("现在专注这一项").accessibilityLabel("开始专注：\(item.title)")
        }
        .padding(.horizontal, 12).padding(.vertical, 12)
        .background(.white.opacity(index == 0 ? 0.045 : 0.025), in: RoundedRectangle(cornerRadius: 11))
        .overlay(RoundedRectangle(cornerRadius: 11).stroke(.white.opacity(0.04)))
        .overlay(RoundedRectangle(cornerRadius: 11)
            .stroke(Palette.lilac.opacity(draggingID != nil && draggingID != item.id && rowFrames[item.id]?.contains(dragPoint) == true ? 0.7 : 0), lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 11))
        .background(GeometryReader { proxy in
            Color.clear.preference(key: RowFramesKey.self, value: [item.id: proxy.frame(in: .named("stack"))])
        })
        .opacity(draggingID == item.id ? 0.3 : 1)
        .highPriorityGesture(DragGesture(minimumDistance: 5, coordinateSpace: .named("stack"))
            .onChanged { value in
                draggingID = item.id
                dragPoint = value.location
                focusTargeted = focusFrame.contains(value.location)
            }
            .onEnded { value in
                if focusFrame.contains(value.location) {
                    store.promote(item.id)
                } else if queueFrame.contains(value.location) {
                    let target = store.state.pending.filter { $0.id != item.id }
                        .first { other in rowFrames[other.id].map { value.location.y < $0.midY } ?? false }
                    store.move(item.id, before: target?.id)
                }
                withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8)) {
                    draggingID = nil
                    focusTargeted = false
                }
            })
        .contextMenu {
            Button("现在专注") { store.promote(item.id) }
            Button("移到栈顶") { store.move(item.id, before: store.state.pending.first?.id) }
            Button("修改名称…") { edit(item) }
        }
    }

    private var feedback: some View {
        HStack(spacing: 7) {
            if let toast = store.toast {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.mint)
                Text(toast).lineLimit(2).foregroundStyle(Palette.mint.opacity(0.8))
                Spacer(minLength: 0)
                if store.lastCompletedID != nil {
                    Button("撤销", action: store.undo).buttonStyle(.plain).foregroundStyle(Palette.lilac)
                }
            } else {
                Image(systemName: "arrow.down.to.line.compact")
                Text(store.insertionPosition == .front ? "新事项放在前面，优先接续" : "新事项放在后面，按序等待")
                Spacer()
            }
        }
        .font(.system(size: 10)).foregroundStyle(Palette.muted.opacity(0.75))
        .frame(minHeight: 20).transition(.opacity)
    }

    private var archiveContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("完成的，都有迹可循").font(.system(size: 18, weight: .medium))
                    Text("记录每一次入栈与出栈").font(.system(size: 10)).foregroundStyle(Palette.muted)
                }
                Spacer()
                Button(action: store.exportArchive) {
                    Image(systemName: "square.and.arrow.up").font(.system(size: 13))
                        .frame(width: 30, height: 30).background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                }.buttonStyle(.plain).foregroundStyle(Palette.lilac).help("导出归档")
            }
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(Palette.muted)
                TextField("查找做过的事情", text: $archiveSearch).textFieldStyle(.plain)
            }.font(.system(size: 11)).padding(11)
                .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
            let records = store.state.archive.filter {
                archiveSearch.isEmpty || $0.title.localizedCaseInsensitiveContains(archiveSearch)
            }
            if records.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal").font(.system(size: 38, weight: .ultraLight))
                        .foregroundStyle(Palette.mint.opacity(0.55))
                    Text(archiveSearch.isEmpty ? "每完成一件事，这里就多一份记录" : "没有匹配的记录")
                        .font(.system(size: 11)).foregroundStyle(Palette.muted)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 9) {
                        ForEach(records) { item in archiveRow(item) }
                    }
                }.scrollIndicators(.hidden)
            }
        }.frame(maxHeight: .infinity)
    }

    private func archiveRow(_ item: AttentionItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 9) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 13)).foregroundStyle(Palette.mint.opacity(0.8))
                Text(item.title).font(.system(size: 12, weight: .medium)).lineLimit(3)
                Spacer(minLength: 0)
                Text("专注 \(duration(item.focusedSeconds))")
                    .font(.system(size: 9, design: .monospaced)).foregroundStyle(Palette.muted)
            }
            VStack(alignment: .leading, spacing: 5) {
                timestamp("入栈", date: item.enqueuedAt, icon: "arrow.down.right")
                if let completedAt = item.completedAt { timestamp("出栈", date: completedAt, icon: "arrow.up.right") }
            }
        }.padding(13).frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 12))
            .contextMenu { Button("再做一次，重新入栈") { store.restore(item.id) } }
    }

    private func timestamp(_ title: String, date: Date, icon: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon).frame(width: 12)
            Text(title)
            Text(date.formatted(.dateTime.year().month(.twoDigits).day(.twoDigits).hour().minute().second()))
        }.font(.system(size: 9)).foregroundStyle(Palette.muted)
    }

    private var footer: some View {
        HStack(spacing: 5) {
            Image(systemName: "circle.fill").font(.system(size: 4)).foregroundStyle(Palette.mint.opacity(0.5))
            Text(store.storageError == nil ? "本地保存" : "记录未保存")
                .foregroundStyle(store.storageError == nil ? Palette.muted.opacity(0.65) : .orange)
            Spacer()
            let todayCount = store.state.archive.filter { $0.completedAt.map(Calendar.current.isDateInToday) ?? false }.count
            Text("今天完成 \(todayCount) 件")
        }
        .font(.system(size: 9)).foregroundStyle(Palette.muted.opacity(0.65))
        .padding(.top, 10)
        .overlay(alignment: .top) { Rectangle().fill(.white.opacity(0.06)).frame(height: 1) }
    }

    private func addDraft() {
        guard !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        store.add(draft)
        draft = ""
        inputFocused = true
    }

    private func edit(_ item: AttentionItem) { editedItem = item; editedTitle = item.title; editPresented = true }


    private func duration(_ seconds: TimeInterval) -> String {
        let seconds = max(0, Int(seconds))
        if seconds >= 3600 { return String(format: "%d:%02d:%02d", seconds / 3600, seconds / 60 % 60, seconds % 60) }
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

private struct FocusFrameKey: PreferenceKey {
    static let defaultValue = CGRect.zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}

private struct QueueFrameKey: PreferenceKey {
    static let defaultValue = CGRect.zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}

private struct RowFramesKey: PreferenceKey {
    static let defaultValue: [UUID: CGRect] = [:]
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private struct PulseDot: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        Circle().fill(Palette.mint).frame(width: 6, height: 6)
            .background {
                if !reduceMotion {
                    Circle().fill(Palette.mint.opacity(0.16)).frame(width: 14, height: 14)
                        .phaseAnimator([false, true]) { view, phase in
                            view.scaleEffect(phase ? 1.3 : 0.75).opacity(phase ? 0.25 : 0.8)
                        } animation: { _ in .easeInOut(duration: 1.8) }
                }
            }
            .accessibilityHidden(true)
    }
}

private struct SoftPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed ? 0.88 : 1)
            .brightness(configuration.isPressed ? 0.08 : 0)
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

private struct GlassBackdrop: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    func updateNSView(_ view: NSVisualEffectView, context: Context) {}
}

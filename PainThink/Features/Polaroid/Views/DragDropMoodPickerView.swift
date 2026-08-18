//
//  DragDropMoodPickerView.swift
//  PainThink
//

import SwiftUI

// Custom drag gesture (instead of `.draggable`/`.dropDestination`) so the chip
// starts following the finger immediately, with no press-and-hold lift delay.
struct DragDropMoodPickerView: View {
    let activity: Activity
    let selectedLabel: String?
    let onSelect: (String) -> Void

    @State private var dropTargetFrame: CGRect = .zero
    @State private var draggingOption: String?
    @State private var dragTranslation: CGSize = .zero

    private let dropTargetFill = Color(red: 153 / 255, green: 151 / 255, blue: 147 / 255)
    private let emptyHoleSize = CGSize(width: 84, height: 40)

    // Options still in the tray: everything except whatever is currently answered.
    private var availableOptions: [String] {
        activity.dragOptions.filter { $0 != selectedLabel }
    }

    var body: some View {
            // 1. Ubah alignment VStack menjadi .center (atau hapus parameternya karena center adalah default)
            VStack(alignment: .center, spacing: 16) {
                HStack {
                    Spacer()
                    dropTargetLabel
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear { dropTargetFrame = geo.frame(in: .named("dragSpace")) }
                                    .onChange(of: geo.frame(in: .named("dragSpace"))) { _, newValue in
                                        dropTargetFrame = newValue
                                    }
                            }
                        )
                    Spacer()
                }

                // 2. Bungkus FlowLayout dengan HStack dan apit menggunakan Spacer()
                HStack {
                    Spacer()
                    FlowLayout(spacing: 8, lineSpacing: 8) {
                        ForEach(availableOptions, id: \.self) { option in
                            chip(option)
                        }
                    }
                    Spacer()
                }
            }
            .coordinateSpace(name: "dragSpace")
        }

    // The hole always renders behind whatever's inset in it, so it naturally
    // shrinks to the empty placeholder size or grows to fit the dropped card.
    private var dropTargetLabel: some View {
        Group {
            if let selectedLabel {
                Text(selectedLabel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.black.opacity(0.8))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.color3))
                    .padding(6)
            } else {
                Color.clear
                    .frame(width: emptyHoleSize.width, height: emptyHoleSize.height)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(dropTargetFill)
                .innerShadow(cornerRadius: 10)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: selectedLabel)
    }

    private func chip(_ option: String) -> some View {
        Text(option)
            .font(.system(size: 13))
            .foregroundStyle(.black.opacity(0.7))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .stickerCard(cornerRadius: 10, shadowOffset: CGSize(width: 2, height: 3))
            .contentShape(Rectangle())
            .scaleEffect(draggingOption == option ? 1.08 : 1)
            .offset(draggingOption == option ? dragTranslation : .zero)
            .zIndex(draggingOption == option ? 1 : 0)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named("dragSpace"))
                    .onChanged { value in
                        if draggingOption == nil { Haptics.tap() }
                        draggingOption = option
                        dragTranslation = value.translation
                    }
                    .onEnded { value in
                        if dropTargetFrame.contains(value.location) {
                            Haptics.success()
                            onSelect(option)
                        }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            draggingOption = nil
                            dragTranslation = .zero
                        }
                    }
            )
    }
}

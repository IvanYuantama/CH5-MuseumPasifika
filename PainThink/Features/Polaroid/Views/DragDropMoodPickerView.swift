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
        VStack(alignment: .center, spacing: 16) {
            // Drop target — centered horizontally
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

            // Chips — FlowLayout gets full bounded width so it can wrap properly
            FlowLayout(spacing: 8, lineSpacing: 8) {
                ForEach(availableOptions, id: \.self) { option in
                    chip(option)
                }
            }
            .frame(maxWidth: .infinity)
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
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.color3))
                    .padding(6)
            } else {
                // Lubang kosong tanpa tulisan gak ngasih tau harus diapain.
                // Petunjuknya ditaruh DI DALAM lubang, jadi mata langsung
                // nyambungin perintah sama sasaran drop-nya.
                Text("Drag here")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.black.opacity(0.32))
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
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .stickerCard(cornerRadius: 10, shadowOffset: CGSize(width: 2, height: 3))
            .contentShape(Rectangle())
            .scaleEffect(draggingOption == option ? 1.08 : 1)
            .offset(draggingOption == option ? dragTranslation : .zero)
            .zIndex(draggingOption == option ? 1 : 0)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named("dragSpace"))
                    .onChanged { value in
                        if draggingOption == nil,
                           abs(value.translation.width) + abs(value.translation.height) > 2 {
                            Haptics.tap()
                        }
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
            .simultaneousGesture(
                TapGesture().onEnded {
                    Haptics.success()
                    onSelect(option)
                }
            )
    }
}

//
//  PainThinkTabBar.swift
//  PainThink
//

import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case expo, collection, search, profile

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .expo: "Opinion"
        case .collection: "Collection"
        case .search: "Search"
        case .profile: "Profile"
        }
    }

    var title: String {
        switch self {
        case .expo: "Expo"
        case .collection: "Collection"
        case .search: "Search"
        case .profile: "Profile"
        }
    }
}

// The bar isn't one container -- the selected item breaks OUT of the pill and
// becomes its own yellow card. Whatever is left forms contiguous runs, and a run
// of one naturally renders as a square while a longer run stretches into a pill.
// One rule, and every layout in the design falls out of it.
struct PainThinkTabBar: View {
    @Binding var selection: AppTab
    let onCameraTap: () -> Void

    private enum Slot: Hashable {
        case tab(AppTab)
        case camera
    }

    private enum Group: Hashable {
        case run([Slot])
        case selected(AppTab)
    }

    private static let slots: [Slot] = [
        .tab(.expo), .tab(.collection), .camera, .tab(.search), .tab(.profile),
    ]

    private let itemWidth: CGFloat = 56
    private let itemHeight: CGFloat = 46
    private let iconSize: CGFloat = 27

    private var groups: [Group] {
        var result: [Group] = []
        var run: [Slot] = []

        for slot in Self.slots {
            if case .tab(let tab) = slot, tab == selection {
                if !run.isEmpty {
                    result.append(.run(run))
                    run = []
                }
                result.append(.selected(tab))
            } else {
                run.append(slot)
            }
        }

        if !run.isEmpty { result.append(.run(run)) }
        return result
    }

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                switch group {
                case .selected(let tab):
                    selectedItem(tab)
                case .run(let slots):
                    runCard(slots)
                }
            }
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.78), value: selection)
        .padding(.horizontal, 16)
    }

    private func runCard(_ slots: [Slot]) -> some View {
        HStack(spacing: 0) {
            ForEach(slots, id: \.self) { slot in
                switch slot {
                case .tab(let tab):
                    button(for: tab)
                case .camera:
                    cameraButton
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .stickerCard(cornerRadius: 18, shadowOffset: CGSize(width: 3, height: 4))
    }

    private func button(for tab: AppTab) -> some View {
        Button {
            selection = tab
        } label: {
            Image(tab.iconName)
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .frame(width: itemWidth, height: itemHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
    }

    private var cameraButton: some View {
        Button(action: onCameraTap) {
            Image("Camera")
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .frame(width: itemWidth, height: itemHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Scan a painting")
    }

    private func selectedItem(_ tab: AppTab) -> some View {
        Image(tab.iconName)
            .resizable()
            .renderingMode(.template)
            .scaledToFit()
            .foregroundStyle(Color.color2)
            .frame(width: iconSize + 3, height: iconSize + 3)
            .frame(width: itemWidth + 10, height: itemHeight + 10)
            .stickerCard(cornerRadius: 16, shadowOffset: CGSize(width: 3, height: 4), fill: .color3)
            .accessibilityLabel(tab.title)
            .accessibilityAddTraits(.isSelected)
    }
}

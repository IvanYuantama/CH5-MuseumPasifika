//
//  ColorSnapPickerView.swift
//  PainThink
//

import SwiftUI

// Empat swatch pertama berasal dari warna dominan foto dan disimpan sebagai
// hex asli. Custom picker di-group sebelum hex-nya dikirim ke backend.
struct ColorSnapPickerView: View {

    let activity: Activity
    /// Hex string warna yang sebelumnya dipilih (e.g. "#FF5500"), atau nil.
    let selectedLabel: String?
    let onSelect: (String) -> Void

    @State private var knob: Double
    @State private var showsCustomPicker = false

    private let swatchSize: CGFloat = 44
    private let stripHeight: CGFloat = 26
    private let paletteSpacing: CGFloat = 24

    private var paletteRowWidth: CGFloat {
        swatchSize * 4 + paletteSpacing * 3
    }

    init(activity: Activity, selectedLabel: String?, onSelect: @escaping (String) -> Void) {
        self.activity = activity
        self.selectedLabel = selectedLabel
        self.onSelect = onSelect

        if let hex = selectedLabel?.normalizedColorHex {
            _knob = State(initialValue: Self.hue(of: Color(hex: hex)))
        } else {
            _knob = State(initialValue: 0.5)
        }
    }

    private var paletteOptions: [PaletteMoodOption] {
        Array(activity.paletteOptions.prefix(4))
    }

    private var rawColor: Color {
        Color(hue: knob, saturation: 0.72, brightness: 0.88)
    }

    private var selectedHex: String? {
        selectedLabel?.normalizedColorHex
    }

    private var isCustomSelection: Bool {
        guard let selectedHex else { return false }
        return !paletteOptions.contains { matches(selectedHex, $0.color.hexString) }
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: paletteSpacing) {
                ForEach(paletteOptions) { option in
                    paletteButton(option)
                }
            }
            .frame(width: paletteRowWidth, alignment: .leading)

            HStack {
                customPickerButton
                Spacer(minLength: 0)
            }
            .frame(width: paletteRowWidth)

            if showsCustomPicker {
                customPicker
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .animation(.easeInOut(duration: 0.2), value: showsCustomPicker)
    }

    private func paletteButton(_ option: PaletteMoodOption) -> some View {
        let hex = option.color.hexString
        let isSelected = selectedHex.map { matches($0, hex) } == true

        return Button {
            Haptics.success()
            showsCustomPicker = false
            onSelect(hex)
        } label: {
            colorSwatch(option.color, isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Choose color \(hex)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var customPickerButton: some View {
        Button {
            if let selectedHex {
                knob = Self.hue(of: Color(hex: selectedHex))
            }
            showsCustomPicker.toggle()
        } label: {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.15))
                    .frame(width: swatchSize, height: swatchSize)
                    .offset(x: 2, y: 3)

                Circle()
                    .fill(Color.gray.opacity(0.28))
                    .frame(width: swatchSize, height: swatchSize)
                    .overlay {
                        Circle()
                            .stroke(isCustomSelection ? Color.black : Color.clear, lineWidth: 2)
                    }

                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Choose a custom color")
        .accessibilityValue(isCustomSelection ? "Selected" : "")
    }

    private var customPicker: some View {
        HStack(spacing: 12) {
            colorSwatch(rawColor, isSelected: isCustomSelection)

            GeometryReader { geo in
                let knobSize = stripHeight + 10
                let usableWidth = max(geo.size.width - knobSize, 1)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: (0...11).map {
                                    Color(hue: Double($0) / 11, saturation: 0.72, brightness: 0.88)
                                },
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: stripHeight)
                        .padding(.horizontal, knobSize / 2)

                    Circle()
                        .fill(rawColor)
                        .frame(width: knobSize, height: knobSize)
                        .overlay(Circle().stroke(.white, lineWidth: 3))
                        .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
                        .offset(x: knob * usableWidth)
                }
                .frame(height: knobSize)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            knob = min(max((value.location.x - knobSize / 2) / usableWidth, 0), 1)
                        }
                        .onEnded { _ in
                            Haptics.success()
                            // Hanya pilihan dari picker bebas yang masuk bucket
                            // hue. Empat swatch foto disimpan sebagai hex asli.
                            let groupedHex = ColorGrouping.groupedHex(for: rawColor.hexString)
                            knob = Self.hue(of: Color(hex: groupedHex))
                            onSelect(groupedHex)
                        }
                )
            }
            .frame(height: stripHeight + 10)
        }
        .padding(.top, 2)
    }

    private func colorSwatch(_ color: Color, isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.15))
                .frame(width: swatchSize, height: swatchSize)
                .offset(x: 2, y: 3)

            Circle()
                .fill(color)
                .frame(width: swatchSize, height: swatchSize)
                .overlay {
                    Circle()
                        .stroke(isSelected ? Color.black : Color.clear, lineWidth: 2)
                }
        }
        .scaleEffect(isSelected ? 1.05 : 1)
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }

    private func matches(_ lhs: String, _ rhs: String) -> Bool {
        lhs.uppercased() == rhs.uppercased()
    }

    private static func hue(of color: Color) -> Double {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Double(h)
    }
}

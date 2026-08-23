//
//  ColorSnapPickerView.swift
//  PainThink
//

import SwiftUI

// Picker warna bebas — user bisa geser knob ke posisi mana saja di spektrum
// dan warna persis di bawah knob yang tersimpan (sebagai hex string).
// Tidak ada snap ke palette lukisan; semua titik spektrum valid.
struct ColorSnapPickerView: View {

    let activity: Activity
    /// Hex string warna yang sebelumnya dipilih (e.g. "#FF5500"), atau nil.
    let selectedLabel: String?
    let onSelect: (String) -> Void

    @State private var knob: Double      // posisi 0...1 di sepanjang strip
    @State private var hasMoved = false

    private let stripHeight: CGFloat = 26

    init(activity: Activity, selectedLabel: String?, onSelect: @escaping (String) -> Void) {
        self.activity = activity
        self.selectedLabel = selectedLabel
        self.onSelect = onSelect
        // Restore posisi knob dari hex yang sudah tersimpan, kalau ada.
        if let hex = selectedLabel {
            _knob = State(initialValue: Self.hue(of: Color(hex: hex)))
        } else {
            _knob = State(initialValue: 0.5)
        }
    }

    /// Warna langsung dari posisi knob — ini yang ditampilkan dan disimpan.
    private var rawColor: Color {
        Color(hue: knob, saturation: 0.72, brightness: 0.88)
    }

    /// Warna di preview circle:
    /// - Sebelum disentuh: tampilkan warna yang sudah tersimpan (selectedLabel hex).
    /// - Setelah disentuh: tampilkan rawColor live.
    private var previewColor: Color {
        if !hasMoved, let hex = selectedLabel {
            return Color(hex: hex)
        }
        return rawColor
    }

    var body: some View {
        VStack(spacing: 18) {

            // Preview warna yang dipilih
            ZStack {
                Circle()
                    .fill(.black.opacity(0.15))
                    .frame(width: 92, height: 92)
                    .offset(x: 2, y: 3)

                Circle()
                    .fill(previewColor)
                    .frame(width: 92, height: 92)
                    .overlay(Circle().stroke(.white.opacity(0.85), lineWidth: 3))
            }
            .animation(.spring(response: 0.28, dampingFraction: 0.75), value: previewColor.description)

            // Strip spektrum + knob
            GeometryReader { geo in
                let width = geo.size.width

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

                    // Knob — menunjukkan posisi dan warna yang sedang dipilih
                    Circle()
                        .fill(rawColor)
                        .frame(width: stripHeight + 10, height: stripHeight + 10)
                        .overlay(Circle().stroke(.white, lineWidth: 3))
                        .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
                        .offset(x: knob * width - (stripHeight + 10) / 2)
                }
                .frame(height: stripHeight + 10)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            hasMoved = true
                            knob = min(max(value.location.x / width, 0), 1)
                        }
                        .onEnded { _ in
                            Haptics.success()
                            // Simpan hex warna tepat di bawah knob — bebas, tidak di-snap.
                            onSelect(rawColor.hexString)
                        }
                )
            }
            .frame(height: stripHeight + 10)
            .padding(.horizontal, 8)
        }
    }

    // MARK: - Helper

    /// Hue (0...1) dari sebuah Color — dipakai untuk restore posisi knob.
    private static func hue(of color: Color) -> Double {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Double(h)
    }
}

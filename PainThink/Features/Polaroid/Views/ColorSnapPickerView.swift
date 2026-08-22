//
//  ColorSnapPickerView.swift
//  PainThink
//

import SwiftUI

// Picker warna bebas yang hasilnya dibuletin ke warna dominan lukisannya.
//
// Knob-nya bisa digeser ke mana aja di spektrum, tapi yang kepilih selalu salah
// satu warna yang beneran ada di lukisan itu. Titik-titik kecil di atas strip
// nunjukin di mana warna-warna itu duduk, jadi "lompatan" pas nge-snap kebaca
// sebagai perilaku yang disengaja, bukan bug.
struct ColorSnapPickerView: View {

    let activity: Activity
    let selectedLabel: String?
    let onSelect: (String) -> Void

    @State private var knob: Double = 0.5      // posisi 0...1 di sepanjang strip
    @State private var hasMoved = false

    private let stripHeight: CGFloat = 26

    /// Warna mentah di bawah knob — bebas, belum dibuletin.
    private var rawColor: Color {
        Color(hue: knob, saturation: 0.72, brightness: 0.88)
    }

    private var snapped: PaletteMoodOption? {
        Self.nearest(to: rawColor, in: activity.paletteOptions)
    }

    private var shownOption: PaletteMoodOption? {
        // Sebelum disentuh, tampilkan pilihan tersimpan (kalau user balik lagi).
        if !hasMoved, let selectedLabel {
            return activity.paletteOptions.first { $0.moodLabel == selectedLabel }
        }
        return snapped
    }

    var body: some View {
        VStack(spacing: 18) {

            // Hasil setelah dibuletin
            ZStack {
                Circle()
                    .fill(.black.opacity(0.15))
                    .frame(width: 92, height: 92)
                    .offset(x: 2, y: 3)

                Circle()
                    .fill(shownOption?.color ?? .gray)
                    .frame(width: 92, height: 92)
                    .overlay(Circle().stroke(.white.opacity(0.85), lineWidth: 3))
            }
            .animation(.spring(response: 0.28, dampingFraction: 0.75), value: shownOption?.id)

            // Strip spektrum + titik penanda warna lukisan
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

                    // Di mana warna dominan lukisan jatuh di spektrum
                    ForEach(activity.paletteOptions) { option in
                        Circle()
                            .fill(.white)
                            .frame(width: 5, height: 5)
                            .overlay(Circle().stroke(.black.opacity(0.25), lineWidth: 0.5))
                            .offset(x: Self.hue(of: option.color) * width - 2.5)
                    }

                    // Knob — nunjukin warna mentah yang lagi ditunjuk
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
                            guard let snapped else { return }
                            Haptics.success()
                            onSelect(snapped.moodLabel)
                        }
                )
            }
            .frame(height: stripHeight + 10)
            .padding(.horizontal, 8)
        }
    }

    // MARK: - Pembulatan ke warna terdekat

    /// Jarak warna pakai "redmean" — pendekatan murah yang jauh lebih dekat ke
    /// persepsi mata dibanding Euclidean RGB polos.
    static func nearest(to color: Color, in options: [PaletteMoodOption]) -> PaletteMoodOption? {
        let target = rgb(of: color)
        return options.min { a, b in
            distance(target, rgb(of: a.color)) < distance(target, rgb(of: b.color))
        }
    }

    private static func distance(_ lhs: (r: Double, g: Double, b: Double),
                                 _ rhs: (r: Double, g: Double, b: Double)) -> Double {
        let rMean = (lhs.r + rhs.r) / 2
        let dR = lhs.r - rhs.r, dG = lhs.g - rhs.g, dB = lhs.b - rhs.b
        return (2 + rMean) * dR * dR + 4 * dG * dG + (3 - rMean) * dB * dB
    }

    private static func rgb(of color: Color) -> (r: Double, g: Double, b: Double) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
    }

    private static func hue(of color: Color) -> Double {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Double(h)
    }
}

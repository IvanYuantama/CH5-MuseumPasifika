//
//  ProfileView.swift
//  PainThink
//

import SwiftUI

// Identity card + app preferences, following the handed-off design. The stat
// and the preference values are static mock data for now: the count should come
// from PolaroidRecord and the rows from real settings once those exist.
struct ProfileView: View {
    private struct Preference: Identifiable {
        var id: String { title }
        let title: String
        let value: String
    }

    private let preferences: [Preference] = [
        Preference(title: "Text Size", value: "Default"),
        Preference(title: "Appearance", value: "System"),
        Preference(title: "Language", value: "English"),
        Preference(title: "Location usage", value: "While use"),
        Preference(title: "Audio and Sound", value: "Default"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Profile")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.black)

                identityCard

                VStack(alignment: .leading, spacing: 12) {
                    Text("App preferences and accessibility")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.black)

                    preferencesCard
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 120)
        }
        .background(Color.color1.ignoresSafeArea())
    }

    private var identityCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                avatar

                VStack(alignment: .leading, spacing: 3) {
                    Text("Wilgo1xx")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.black)

                    Text("Maestro")
                        .font(.system(size: 13))
                        .foregroundStyle(.black.opacity(0.5))
                }
                .padding(.top, 4)

                Spacer()
            }

            VStack(spacing: 2) {
                Text("120")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.black)

                Text("Collection")
                    .font(.system(size: 13))
                    .foregroundStyle(.black.opacity(0.6))
            }
            .frame(width: 72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .stickerCard(cornerRadius: 14, shadowOffset: CGSize(width: 4, height: 5))
    }

    // No avatar asset yet -- a warm gray block with a person glyph holds the
    // 72pt slot the design gives the photo.
    private var avatar: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(red: 0.90, green: 0.88, blue: 0.85))
            .frame(width: 72, height: 72)
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.black.opacity(0.25))
            }
            .accessibilityLabel("Foto profil")
    }

    private var preferencesCard: some View {
        VStack(spacing: 0) {
            ForEach(preferences) { preference in
                HStack(spacing: 6) {
                    Text(preference.title)
                        .font(.system(size: 15))
                        .foregroundStyle(.black)

                    Spacer()

                    Text(preference.value)
                        .font(.system(size: 15))
                        .foregroundStyle(.black.opacity(0.35))

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.black.opacity(0.3))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .contentShape(Rectangle())
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.vertical, 5)
        .stickerCard(cornerRadius: 14, shadowOffset: CGSize(width: 4, height: 5))
    }
}

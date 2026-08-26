//
//  CollectionView.swift
//  PainThink
//

import SwiftUI

// The user's own polaroids, mocked from the sample feed until PolaroidRecord is
// wired in. Sections and picks mirror the handed-off design: My collection and
// Favorites, two uniform cards each.
struct CollectionView: View {
    let onCameraTap: () -> Void
    private let horizontalSpacing: CGFloat = 25
    private let verticalSpacing: CGFloat = 32
    private let pageInset: CGFloat = 20

    // NavigationPath eksplisit agar tombol back di PaintingDetailView bisa pop ke CollectionView
    @State private var navPath = NavigationPath()

    // The signed-in user's own posts, loaded from the backend. The card's back
    // face and Details statistics still run on hardcoded `opinions` — see
    // `feedEntry(from:index:)` — until the backend exposes per-post opinions.
    @State private var myCollection: [FeedEntry] = []
    @State private var isLoading = true

    private var hasItems: Bool { !myCollection.isEmpty }

    var body: some View {
        NavigationStack(path: $navPath) {
            VStack(spacing: 0) {
                if isLoading {
                    loadingContent
                } else if hasItems {
                    filledContent
                } else {
                    emptyContent
                }

                // Dedicated bottom area for the camera button so cards NEVER scroll behind it.
                HStack {
                    Spacer()
                    cameraFAB
                        .padding(.trailing, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                }
                .background(Color.color1)
            }
            .background(Color.color1.ignoresSafeArea())
        }
        .task { await loadPosts() }
    }

    // MARK: - Data loading

    private func loadPosts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let userID = try await SessionManager.shared.userID()
            let posts = try await APIClient.shared.fetchUserPosts(userID: userID)

            // Prefetch every card image into ImageCache while the spinner is still
            // up, so the grid appears with images already resolved — no per-card
            // loading flash once `isLoading` flips false.
            async let entries = Self.feedEntries(from: posts)
            async let preload: Void = Self.preloadImages(for: posts)

            myCollection = await entries
            _ = await preload
        } catch {
            print("[CollectionView] loadPosts: failed: \(error)")
            myCollection = []
        }
    }

    private static func preloadImages(for posts: [PostResponseDTO]) async {
        await withTaskGroup(of: Void.self) { group in
            for post in posts {
                guard let url = URL(string: post.image) else { continue }
                group.addTask { await ImageCache.shared.preload(url) }
            }
        }
    }

    // Post carries no artist/year itself, so each is looked up from the
    // paintings API by title, in parallel. A title with no backend match
    // (e.g. an unmatched "Untitled" capture) falls back to the same
    // placeholder strings used elsewhere for an unresolved painting.
    private static func feedEntries(from posts: [PostResponseDTO]) async -> [FeedEntry] {
        await withTaskGroup(of: (Int, FeedEntry).self) { group in
            for (index, post) in posts.enumerated() {
                group.addTask { (index, await feedEntry(from: post)) }
            }

            var entries = [FeedEntry?](repeating: nil, count: posts.count)
            for await (index, entry) in group {
                entries[index] = entry
            }
            return entries.compactMap { $0 }
        }
    }

    // Details statistics are real, sourced from every visitor's answers for
    // this exact painting/capture, not just this post's own:
    // - Matched paintings pool every user's structured answers via
    //   `GET /paintings/:id/answers/all` — they're genuinely the same
    //   painting, keyed by its backend ID.
    // - Unmatched ("Untitled") captures have no backend painting to key that
    //   off of, and *all* of them share the literal title "Untitled" — two
    //   different unidentified paintings would look identical by that title,
    //   so pooling across posts would silently merge unrelated paintings'
    //   stats. Instead each unmatched post's Details screen stays scoped to
    //   that one capture's own saved Q&A (a pool of one).
    private static func feedEntry(from post: PostResponseDTO) async -> FeedEntry {
        let matched = try? await APIClient.shared.fetchPainting(byTitle: post.title)

        var opinions: [VisitorOpinion] = []
        if let matched {
            let allAnswers = (try? await APIClient.shared.fetchAllAnswers(paintingID: matched.id)) ?? []
            opinions = visitorOpinions(from: allAnswers.map { $0.answers.map(\.value) })
        } else {
            opinions = visitorOpinions(from: [(post.questions ?? []).map(\.answer)])
        }

        let painting = Painting(
            title: post.title,
            artist: matched?.artist ?? "Unknown Artist",
            year: matched?.year ?? "Undated",
            museum: post.location.isEmpty ? MuseumInfo.currentName : post.location,
            imageURLString: post.image
        )
        return FeedEntry(painting: painting, opinions: opinions, userAnswers: post.questions ?? [])
    }

    // Turns every visitor's raw answer values into the crowd-statistics shape
    // `PaintingInsights` already knows how to tally, so the Details screen
    // (ConsensusCard/ColorFeelingsCard) needs no changes to go from sample to
    // real data. Per submitter: only their first non-color answer counts
    // toward the headline/mood tally, paired with their one color pick.
    private static func visitorOpinions(from answerValueSets: [[String]]) -> [VisitorOpinion] {
        answerValueSets.compactMap { values -> VisitorOpinion? in
            guard let firstMood = values.first(where: { !$0.isEmpty && !$0.isHexColorString }) else { return nil }
            let colorHex = values.first(where: \.isHexColorString) ?? "#CCCCCC"

            return VisitorOpinion(statement: firstMood, emoji: "🎨", moodLabel: firstMood, colorHex: colorHex, visitorName: "Visitor")
        }
    }

    // MARK: - Content states

    private var filledContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // FIXED HEADER
            Text("Gallery")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
                .padding(.horizontal, pageInset)
                .padding(.top, 8)

            Text("My Gallery")
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .foregroundStyle(.black)
                .padding(.leading, pageInset + 20)
                .padding(.top, 24)
                .padding(.bottom, 20)

            // ONLY THIS PART SCROLLS
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: horizontalSpacing),
                        GridItem(.flexible(), spacing: horizontalSpacing)
                    ],
                    spacing: verticalSpacing
                ) {
                    ForEach(myCollection) { entry in
                        CollectionCardView(entry: entry)
                    }
                }
                .padding(.horizontal, pageInset)
                .padding(.bottom, 20)
            }
            .background(Color.color1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.color1.ignoresSafeArea())
        .navigationDestination(for: FeedEntry.self) { entry in
            PaintingDetailView(
                painting: entry.painting,
                opinions: entry.opinions,
                onGoToCollection: { /* already in collection, no-op */ },
                onGoToCamera: onCameraTap,
                // Back button pop dari navPath ini → kembali ke My Collection
                onBack: { navPath.removeLast() }
            )
        }
    }

    private var loadingContent: some View {
        ZStack {
            Color.color1.ignoresSafeArea()
            ProgressView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyContent: some View {
        ZStack(alignment: .topLeading) {
            Color.color1.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Text("Gallery")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, pageInset)
                    .padding(.top, 8)

                    .padding(.bottom,85)

                VStack(alignment: .leading, spacing: 14) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.color3)
                            .frame(width: 60, height: 60)

                        Image("Collection")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 33, height: 36)
                            .foregroundStyle(.white)

                    }

                    Text("No painting have\nbeen captured.")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.5))
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Try to capture a painting and let it sits on\nyour gallery.")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(.black.opacity(0.5))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, pageInset)

                Spacer()
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var cameraFAB: some View {
        Button(action: onCameraTap) {
            Image("newcamera")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Scan a painting")
    }



}

struct CollectionCardView: View {
    let entry: FeedEntry
    @State private var isFlipped = false


    var body: some View {
        ZStack {
            frontView
                .opacity(isFlipped ? 0 : 1)
            
            backView
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        }
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isFlipped)
        .onTapGesture {
            isFlipped.toggle()
        }
    }

    // MARK: - Front View

    private var frontView: some View { polaroidFace() }

    /// Muka depan polaroid.
    /// - showsLocation: baris lokasi cuma dipasang waktu di-share, di galeri nggak.
    /// - fillsCell: di galeri kartunya ngisi penuh tinggi sel; waktu di-render
    ///   jadi gambar, tingginya harus ngikut isi, kalau nggak hasilnya melar.
    private func polaroidFace(showsLocation: Bool = false,
                              fillsCell: Bool = true) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            PaintingImageView(
                assetName: entry.painting.assetName,
                imageURLString: entry.painting.imageURLString,
                fallbackColors: PaintingInsights(opinions: entry.opinions).colorFeelings.map(\.color),
                contentMode: .fit
            )
            .frame(
                maxWidth: fillsCell ? 110 : .infinity,
                maxHeight: fillsCell ? 128 : .infinity
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, fillsCell ? 8 : 0)
            .padding(.bottom, 10)

            Text(entry.painting.title)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(.black)
                .lineLimit(1)

            Text(entry.painting.artist)
                .font(.system(size: 14, weight: .thin, design: .rounded))
                .foregroundStyle(.black)
                .lineLimit(1)

            Text(entry.painting.year)
                .font(.system(size: 14, weight: .light, design: .rounded))
                .foregroundStyle(.black)
                .padding(.bottom, fillsCell ? 40 : 0)

            if showsLocation {
                LocationLabel(place: MuseumInfo.currentName, size: 10)
                    .padding(.top, 8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 12)
        // maxHeight bikin kartu putih ngisi penuh tinggi sel. Tanpa ini tinggi sel
        // ditentukan backView (yang lebih tinggi), sisanya jadi celah krem — itu
        // yang bikin jarak vertikal keliatan jauh lebih lebar dari horizontal.
        .frame(width: fillsCell ? 150 : nil,
               height: fillsCell ? 250 : nil,
               alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .stickerCard(
            cornerRadius: 10,
            shadowOffset: CGSize(width: 4, height: 5)
        )

    }

    // MARK: - Back View

    private var backView: some View {

        VStack(alignment: .leading, spacing: 14) {

            Text(shortTitle(for: entry.painting.title))
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.black)

            let answers = cardAnswers

            Circle()
                .fill(answers.color)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 6) {

                Text(answers.primary)
                    .font(
                        .system(
                            size: 18,
                            weight: .regular,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.black)

                Text(answers.secondary)
                    .font(
                        .system(
                            size: 18,
                            weight: .regular,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.black)
                    .padding(.bottom, 2)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(Color.color3)
                            .frame(height: 2)
                    }
            }

            Spacer(minLength: 20)

            HStack {

                NavigationLink(value: entry) {
                    Text("Details")
                        .font(
                            .system(
                                size: 18,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(.black)
                        .padding(.bottom, 2)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(Color.color3)
                                .frame(height: 2)
                        }
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: sharePolaroid) {
                    ZStack {
                        Circle()
                            .fill(Color.color3)
                            .frame(width: 42, height: 42)

                        Image(systemName: "square.and.arrow.up")
                            .font(
                                .system(
                                    size: 18,
                                    weight: .semibold
                                )
                            )
                            .foregroundStyle(.white)
                            .offset(y: -1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(
            width: 150,
            height: 250,
            alignment: .topLeading
        )
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 10)
        )
        .stickerCard(
            cornerRadius: 10,
            shadowOffset: CGSize(width: 4, height: 5)
        )
    }

    private func shortTitle(for title: String) -> String {
        if title == "Girl With Pearl Earring" { return "A Pearl" }
        let words = title.split(separator: " ")
        return String(words.prefix(2).joined(separator: " "))
    }

    // The two mood words and the colour circle shown on the card back, sourced
    // from this post's own quiz answers: the "color" activity's answer is a hex
    // string (see `PolaroidDevelopViewModel.answerValue`), every other activity's
    // answer is a mood word. Falls back to the sample-opinion insight only for
    // posts synced before answers were carried onto `FeedEntry` (empty `userAnswers`).
    private var cardAnswers: (primary: String, secondary: String, color: Color) {
        let rawAnswers = entry.userAnswers.map(\.answer)
        let moodAnswers = rawAnswers.filter { !$0.isEmpty && !$0.isHexColorString }
        let colorHex = rawAnswers.first(where: \.isHexColorString)

        guard !moodAnswers.isEmpty else {
            let insight = PaintingInsights(opinions: entry.opinions)
            return (
                insight.moods.first?.label ?? "Warm",
                "Feel Safe",
                insight.colorFeelings.first?.color ?? Color.color3
            )
        }

        return (
            moodAnswers[0],
            moodAnswers.count > 1 ? moodAnswers[1] : moodAnswers[0],
            colorHex.map { Color(hex: $0) } ?? Color.color3
        )
    }

    // Halaman yang di-share: wordmark, polaroid, lalu HANYA jawaban
    // kontekstual + warna yang dipilih. Jawaban deskriptif ("apa yang
    // keliatan") sengaja gak dibawa — itu bagian yang gak menarik dipamerin.
    // Cuma ada di hasil share, kartu di galeri tetap bersih.
    private var shareComposition: some View {
        let answers = cardAnswers

        return VStack(spacing: 0) {
            Image("Painthink")
                .resizable()
                .scaledToFit()
                .frame(width: 165, height: 71)
                .accessibilityLabel("PainThink")
                .padding(.top, 26)
                .padding(.bottom, 28)

            polaroidFace(showsLocation: true, fillsCell: false)
                .frame(width: 268)

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(shortTitle(for: entry.painting.title))
                        .font(.system(size: 27, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)

                    Text(answers.primary)
                        .font(.system(size: 17, design: .rounded))
                        .foregroundStyle(.black)

                    Text(answers.secondary)
                        .font(.system(size: 17, design: .rounded))
                        .foregroundStyle(.black)
                        .padding(.bottom, 2)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(Color.color3).frame(height: 2)
                        }
                }

                Spacer(minLength: 0)

                Circle()
                    .fill(answers.color)
                    .frame(width: 96, height: 96)
            }
            .padding(.horizontal, 26)
            .padding(.top, 34)
            .padding(.bottom, 32)
        }
        .frame(width: 320)
        .background(Color.color1)
    }

    // Creates an image of the front of the polaroid card for sharing
    @MainActor
    private func sharePolaroid() {
        let renderer = ImageRenderer(content: shareComposition)
        renderer.scale = UIScreen.main.scale

        if let image = renderer.uiImage {
            let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        }
    }
}

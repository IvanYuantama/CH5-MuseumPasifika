//
//  PhotoDevelopedView.swift
//  PainThink
//

import SwiftUI

// Shown once every develop activity is answered: the finished polaroid, a
// confirmation, and a bridge into what everyone else felt about the painting.
// Replaces the old "retake" ending -- after investing in four answers, the
// natural next step is the crowd, not the camera.
struct PhotoDevelopedView: View {
    let image: UIImage
    let title: String
    let artist: String
    let year: String
    let location: String
    let captureDate: String
    let painting: Painting
    /// Backend painting ID — nil jika lukisan tidak teridentifikasi (fallback "Untitled").
    let matchedPaintingID: String?
    /// Snapshot jawaban yang baru selesai dipilih user. Digabungkan secara
    /// optimistis agar detail langsung ter-update tanpa menunggu read replica backend.
    let currentAnswerValues: [String]
    /// Task yang mengirim jawaban ke backend. Di-await sebelum fetch opinions
    /// agar data user saat ini sudah masuk ke pool statistik crowd.
    let syncTask: Task<Void, Never>?
    let onGoToCamera: () -> Void
    let onGoToCollection: () -> Void
    
    // NavigationPath eksplisit agar bisa pop programmatically dari PaintingDetailView
    @State private var navPath = NavigationPath()

    /// Opinions yang di-fetch dari backend; nil = masih loading, [] = selesai (kosong/gagal).
    @State private var liveOpinions: [VisitorOpinion]? = nil
    
    var body: some View {
        NavigationStack(path: $navPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    PolaroidFrameView(
                        image: image,
                        title: title,
                        artist: artist,
                        year: year,
                        location: location,
                        captureDate: captureDate,
                        isUnlocked: true,
                        progress: 1,
                        total: 1
                    )
                    .padding(.top, 28)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your photo has been developed!")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)
                            .fixedSize(horizontal: false, vertical: true)

                        // CTAs: see opinions (navigates within the stack) and
                        // go to collection (pops back to the collection screen).
                        HStack {
                            seeOpinionsButton
                            Spacer()
                        }
                        .padding(.top, 12)
                    }
                    .frame(width: 252, alignment: .leading)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 32)
                }
                .padding(.bottom, 40)
            }
            .background(Color.color1.ignoresSafeArea())
            .navigationDestination(for: FeedEntry.self) { entry in
                PaintingDetailView(
                    painting: entry.painting,
                    opinions: entry.opinions,
                    onGoToCollection: onGoToCollection,
                    onGoToCamera: onGoToCamera,
                    // Back button pop dari navPath ini → kembali ke "See What Others Saw"
                    onBack: { navPath.removeLast() },
                    // Tampilkan foto hasil kamera sebagai hero image
                    capturedImage: image
                )
            }
        }
        .task {
            await loadOpinions()
        }
    }

    // Fetch semua jawaban user untuk lukisan ini dari backend, lalu sisipkan
    // jawaban lokal user saat ini sebagai source of truth untuk tampilan langsung.
    private func loadOpinions() async {
        // Tunggu sampai upload foto + submit jawaban selesai dulu,
        // baru fetch — supaya jawaban user ini sudah masuk ke pool statistik.
        await syncTask?.value

        var answerSets: [[String]] = []

        if let paintingID = matchedPaintingID {
            let allAnswers = (try? await APIClient.shared.fetchAllAnswers(paintingID: paintingID)) ?? []
            let currentUserID = try? await SessionManager.shared.userID()

            // Backend mungkin sudah mengembalikan submit terbaru. Hapus record
            // milik user ini sebelum menambahkan snapshot lokal agar vote tidak
            // terhitung dua kali.
            answerSets = allAnswers
                .filter { answerSet in
                    guard let currentUserID else { return true }
                    return answerSet.userID != currentUserID
                }
                .map { $0.answers.map(\.value) }
        }

        if !currentAnswerValues.isEmpty {
            answerSets.append(currentAnswerValues)
        }

        liveOpinions = Self.visitorOpinions(from: answerSets)
    }

    // Konversi raw answer values ke VisitorOpinion[] — logika sama dengan CollectionView
    // agar PaintingInsights bisa langsung menghitung top-4 color tally.
    private static func visitorOpinions(from answerValueSets: [[String]]) -> [VisitorOpinion] {
        answerValueSets.compactMap { values -> VisitorOpinion? in
            guard let firstMood = values.first(where: { !$0.isEmpty && !$0.isHexColorString }) else { return nil }
            let colorHex = values.first(where: \.isHexColorString) ?? "#CCCCCC"
            return VisitorOpinion(statement: firstMood, emoji: "🎨", moodLabel: firstMood, colorHex: colorHex, visitorName: "Visitor")
        }
    }

    private var seeOpinionsButton: some View {
        // Tombol di-disable sementara opinions masih di-load (liveOpinions == nil).
        // Setelah selesai (berhasil atau gagal), tombol langsung aktif.
        let opinions = liveOpinions ?? []
        let isLoading = liveOpinions == nil && matchedPaintingID != nil

        return NavigationLink(
            value: FeedEntry(
                painting: painting,
                opinions: opinions
            )
        ) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.75)
                        .tint(.black)
                }
                Text("See what other saw")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.black)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .stickerCard(cornerRadius: 8, shadowOffset: CGSize(width: 2, height: 3), fill: Color.color3)
    }

    
}

//
//  DragAndDropView.swift
//  PainThink
//
//  Created by Ivan Yuantama Pradipta on 11/08/26.
//

import SwiftUI

struct DragAndDropView: View {
    @State private var viewModel: DragAndDropViewModel
    @Environment(\.dismiss) private var dismiss
    
    private let cardWidth: CGFloat = 253
    private let cardHeight: CGFloat = 34
    private let cornerRadius: CGFloat = 10
    
    init(paintingImage: UIImage?) {
        _viewModel = State(initialValue: DragAndDropViewModel(paintingImage: paintingImage))
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.color1
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Painting Card
                    PaintingCardView(
                        image: viewModel.paintingImage,
                        title: viewModel.paintingTitle,
                        artist: viewModel.artistName,
                        year: viewModel.year,
                        location: viewModel.location,
                        captureDate: viewModel.captureDate
                    )
                    .padding(.horizontal, 70)
                    .contentMargins(.top, 122)
                    
                    // Question section
                    questionSection
                        .padding(.top, 52)
                        .padding(.horizontal, 70)
                    
                    // Answer chip
                    answerSection
                        .padding(.top, 21)
                        .padding(.horizontal, 24)
                    
                    // Mood chips
                    moodSection
                        .padding(.top, 20)
                        .padding(.horizontal, 24)
                    
                    // Add more button
                    addMoreButton
                        .padding(.top, 12)
                        .padding(.horizontal, 24)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                }
            }
        }
    }
    
    // MARK: - Question Section
    
    private var questionSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    Color(
                        red: 0.85,
                        green: 0.84,
                        blue: 0.81
                    )
                )
                .offset(x:4, y: 6)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(viewModel.question)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.black.opacity(0.7))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.color2)
                    )
            }
            
        }.frame(
            width: cardWidth,
            height: cardHeight
        )
        .frame(maxWidth: .infinity)
        
    }
    
    // MARK: - Answer Section
    
    private var answerSection: some View {
        ZStack {
            // Card belakang (Shadow)
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.black.opacity(0.2))
                .offset(x: -1, y: -2)
            
            // Card utama
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    Color(
                        red: 153 / 255,
                        green: 151 / 255,
                        blue: 147 / 255
                    )
                )
            
            // Konten dinamis: Kosong vs Terisi
            if viewModel.answer.isEmpty {
                // Ukuran default ketika belum ada jawaban yang di-drag
                Color.clear
                    .frame(width: 90, height: 38)
            } else {
                // Teks yang akan membuat ukuran pill memanjang otomatis
                Text(viewModel.answer)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white) // Sesuaikan warna jika perlu
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
        }
        // Kunci ZStack agar mengikuti ukuran teks di dalamnya
        .fixedSize(horizontal: true, vertical: true)
        .dropDestination(for: String.self) { items, location in
            if let droppedAnswer = items.first {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    viewModel.answer = droppedAnswer
                }
                return true
            }
            return false
        }
        .frame(maxWidth: .infinity)
        .offset(x: 5)
    }
    
    // MARK: - Mood Section
    
    private var moodSection: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.moodOptions, id: \.self) { mood in
                MoodChipView(
                    title: mood,
                    isSelected: viewModel.selectedMoods.contains(mood)
                ) {
                    viewModel.toggleMood(mood)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Add More Button
    
    private var addMoreButton: some View {
        HStack {
            Spacer()
            
            Button {
                viewModel.addNote()
            } label: {
                Text("Add more")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.black.opacity(0.7))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    Color(
                                        red: 0.85,
                                        green: 0.84,
                                        blue: 0.81
                                    )
                                )
                                .offset(x: 2, y: 3)
                            
                            // Card utama
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.color2)
                        }
                    }
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .padding(.bottom, 57)
    }
}

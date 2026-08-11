//
//  MoodChipView.swift
//  PainThink
//
//  Created by Ivan Yuantama Pradipta on 11/08/26.
//

import SwiftUI

struct MoodChipView: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        //        Button(action: action) {
        //            Text(title)
        //                .font(.system(size: 14, weight: .medium))
        //                .foregroundStyle(isSelected ? .black : .black.opacity(0.7))
        //                .padding(.horizontal, 16)
        //                .padding(.vertical, 10)
        //                .background(
        //                    RoundedRectangle(cornerRadius: 20)
        //                        .fill(isSelected ? Color.color3.opacity(0.3) : Color(red: 0.94, green: 0.94, blue: 0.94))
        //                )
        //                .overlay(
        //                    RoundedRectangle(cornerRadius: 20)
        //                        .stroke(isSelected ? Color.color3 : Color.clear, lineWidth: 1.5)
        //                )
        //        }
        //        .buttonStyle(.plain)
        Button(action: action) {
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
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        Color.color2
                    )
                
                Text(title)
                    .font(
                        .system(
                            size: 12,
                            weight: .regular
                        )
                    )
                    .foregroundStyle(
                        .black.opacity(0.7)
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
        }
        .buttonStyle(.plain)
        .fixedSize()
        .draggable(title)
    }
}

//
//  ConfettiView.swift
//  Petalogue
//
//  Lightweight, dependency-free confetti for the reveal moment.
//

import SwiftUI

struct ConfettiView: View {
    var count: Int = 80

    private let colors: [Color] = [.pink, .red, .orange, .yellow, .green, .blue, .purple]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<count, id: \.self) { index in
                    ConfettiPiece(
                        color: colors[index % colors.count],
                        startX: CGFloat.random(in: 0...geo.size.width),
                        endY: geo.size.height + 40,
                        delay: Double.random(in: 0...0.5),
                        duration: Double.random(in: 1.8...2.8)
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct ConfettiPiece: View {
    let color: Color
    let startX: CGFloat
    let endY: CGFloat
    let delay: Double
    let duration: Double

    @State private var y: CGFloat = -30
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 8, height: 12)
            .rotationEffect(.degrees(rotation))
            .position(x: startX, y: y)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: duration).delay(delay)) {
                    y = endY
                }
                withAnimation(.linear(duration: duration).delay(delay)) {
                    rotation = Double.random(in: 180...900)
                }
                withAnimation(.easeIn(duration: 0.4).delay(delay + duration - 0.4)) {
                    opacity = 0
                }
            }
    }
}

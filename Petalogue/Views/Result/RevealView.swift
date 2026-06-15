//
//  RevealView.swift
//  Petalogue
//
//  First-discovery celebration: confetti + haptic, scaled to rarity.
//

import SwiftUI

struct RevealView: View {
    let flower: Flower
    let onContinue: () -> Void

    @State private var showCard = false
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [flower.rarity.color.opacity(0.25), Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("New Discovery!")
                    .font(.largeTitle.bold())

                catalogImage
                    .frame(width: 220, height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(radius: 12)
                    .scaleEffect(showCard ? 1 : 0.6)
                    .opacity(showCard ? 1 : 0)

                RarityBadge(rarity: flower.rarity)

                VStack(spacing: 4) {
                    Text(flower.commonName)
                        .font(.title2.bold())
                    Text(flower.latinName)
                        .font(.subheadline.italic())
                        .foregroundColor(.secondary)
                }

                Text(flower.flowerLanguage)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)

                Spacer()

                Button {
                    onContinue()
                } label: {
                    Text("Add to Floradex")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .padding(.top, 60)

            if showConfetti {
                ConfettiView(count: flower.rarity.confettiCount)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            Haptics.success()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showCard = true
            }
            showConfetti = true
        }
    }

    @ViewBuilder
    private var catalogImage: some View {
        if UIImage(named: flower.catalogImageName) != nil {
            Image(flower.catalogImageName)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 24).fill(Color(.secondarySystemBackground))
                Image(systemName: "leaf.fill")
                    .font(.system(size: 64))
                    .foregroundColor(flower.rarity.color)
            }
        }
    }
}

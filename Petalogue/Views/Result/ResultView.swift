//
//  ResultView.swift
//  Petalogue
//
//  Shows the captured photo and the top identification candidates. The user
//  confirms a species (only catalog matches are selectable), with opt-in
//  photo saving and location tagging.
//

import CoreLocation
import SwiftUI

struct ResultView: View {
    let image: UIImage?
    let results: [IdentificationResult]
    let onConfirm: (IdentificationResult, Bool, CLLocationCoordinate2D?) -> Void
    let onCancel: () -> Void

    @State private var savePhoto = true
    @State private var recordLocation = false
    @State private var working = false
    @StateObject private var location = LocationProvider()

    private var topResults: [IdentificationResult] {
        Array(results.prefix(3))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 240)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Is this your flower?")
                        .font(.title3.bold())
                    Text("Tap a match to add it to your collection.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 10) {
                    ForEach(topResults) { result in
                        ResultRow(result: result) {
                            confirm(result)
                        }
                        .disabled(!result.isInCatalog || working)
                    }
                }

                if topResults.allSatisfy({ !$0.isInCatalog }) {
                    Text("None of these are in your Floradex catalog yet.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 4) {
                    Toggle("Save this photo", isOn: $savePhoto)
                    Toggle("Record where I found it", isOn: $recordLocation)
                }
                .padding(.top, 4)

                if working {
                    ProgressView()
                }
            }
            .padding()
        }
        .navigationTitle("Result")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { onCancel() }
            }
        }
    }

    private func confirm(_ result: IdentificationResult) {
        working = true
        Task {
            var coordinate: CLLocationCoordinate2D?
            if recordLocation {
                coordinate = await location.requestOneShot()
            }
            onConfirm(result, savePhoto, coordinate)
        }
    }
}

private struct ResultRow: View {
    let result: IdentificationResult
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.commonName)
                        .font(.headline)
                    Text(result.latinName)
                        .font(.caption)
                        .italic()
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(Int((result.confidence * 100).rounded()))%")
                    .font(.subheadline.monospacedDigit())
                    .foregroundColor(.secondary)
                if result.isInCatalog {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
            .opacity(result.isInCatalog ? 1 : 0.5)
        }
        .buttonStyle(.plain)
    }
}

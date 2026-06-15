//
//  ScanView.swift
//  Petalogue
//

import SwiftUI
import UIKit

struct ScanView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var coordinator = ScanCoordinator()
    @State private var pickerSource: PickerSource?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 84))
                    .foregroundColor(.accentColor)
                Text("Scan a flower")
                    .font(.title2.bold())
                Text("Identify it, learn its story, and add it to your Floradex.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)
                Spacer()
                VStack(spacing: 12) {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button {
                            pickerSource = PickerSource(type: .camera)
                        } label: {
                            Label("Take Photo", systemImage: "camera")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Button {
                        pickerSource = PickerSource(type: .photoLibrary)
                    } label: {
                        Label("Choose from Library", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .controlSize(.large)
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .navigationTitle("Petalogue")
            .sheet(item: $pickerSource) { source in
                ImagePicker(sourceType: source.type) { image in
                    Task { await coordinator.handle(image) }
                }
                .ignoresSafeArea()
            }
            .fullScreenCover(isPresented: presentingBinding) {
                NavigationStack { flowContent }
            }
            .alert(
                "Couldn't identify",
                isPresented: errorBinding,
                presenting: coordinator.errorMessage
            ) { _ in
                Button("OK", role: .cancel) { coordinator.errorMessage = nil }
            } message: { message in
                Text(message)
            }
        }
    }

    @ViewBuilder
    private var flowContent: some View {
        switch coordinator.stage {
        case .identifying:
            VStack(spacing: 16) {
                ProgressView()
                Text("Identifying…").foregroundColor(.secondary)
            }
        case .results:
            ResultView(
                image: coordinator.capturedImage,
                results: coordinator.results,
                onConfirm: { result, savePhoto, coordinate in
                    coordinator.confirm(result, savePhoto: savePhoto, coordinate: coordinate, context: context)
                },
                onCancel: { coordinator.reset() }
            )
        case .reveal:
            if let flower = coordinator.confirmedFlower {
                RevealView(flower: flower) { coordinator.reset() }
            }
        case .repeatFind:
            if let flower = coordinator.confirmedFlower {
                FlowerDetailView(flower: flower, isRepeatFind: true)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { coordinator.reset() }
                        }
                    }
            }
        case .idle:
            Color.clear
        }
    }

    private var presentingBinding: Binding<Bool> {
        Binding(
            get: { coordinator.isPresenting },
            set: { newValue in if !newValue { coordinator.reset() } }
        )
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { coordinator.errorMessage != nil },
            set: { newValue in if !newValue { coordinator.errorMessage = nil } }
        )
    }
}

struct PickerSource: Identifiable {
    let id = UUID()
    let type: UIImagePickerController.SourceType
}

//
//  PetalogueApp.swift
//  Petalogue
//
//  Created by 32 on 2026/6/11.
//

import SwiftUI

@main
struct PetalogueApp: App {
    private let persistence = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistence.viewContext)
        }
    }
}

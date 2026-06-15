//
//  ContentView.swift
//  Petalogue
//
//  Created by 32 on 2026/6/11.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            FloradexView()
                .tabItem { Label("Floradex", systemImage: "square.grid.2x2") }
            ScanView()
                .tabItem { Label("Scan", systemImage: "camera.viewfinder") }
            PersonalMapView()
                .tabItem { Label("Map", systemImage: "map") }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController(inMemory: true).viewContext)
    }
}

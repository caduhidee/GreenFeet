//
//  Sustainable_RoutesApp.swift
//  Sustainable Routes
//
//  Created by Caiden Hyde on 5/13/26.
//

import SwiftUI

@main
struct Sustainable_RoutesApp: App {
    @StateObject private var tripStore = LocationTripStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(tripStore)
        }
    }
}

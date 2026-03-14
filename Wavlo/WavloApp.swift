//
//  WavloApp.swift
//  Wavlo
//
//  Created by Vatsalya's Mac on 3/13/26.
//

import SwiftUI
import CoreData

@main
struct WavloApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

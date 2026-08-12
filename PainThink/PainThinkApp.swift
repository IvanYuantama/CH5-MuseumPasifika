//
//  PainThinkApp.swift
//  PainThink
//
//  Created by Ivan Yuantama Pradipta on 06/08/26.
//

import SwiftUI
import SwiftData

@main
struct PainThinkApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: PolaroidRecord.self)
    }
}

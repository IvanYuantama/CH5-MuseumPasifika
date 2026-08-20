//
//  PainThinkApp.swift
//  PainThink
//
//  Created by Ivan Yuantama Pradipta on 06/08/26.
//

import SwiftUI
import SwiftData
import TipKit

@main
struct PainThinkApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Wajib dipanggil sekali sebelum tip apa pun bisa muncul.
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .statusBarHidden(true)
        }
        .modelContainer(for: PolaroidRecord.self)
    }
}

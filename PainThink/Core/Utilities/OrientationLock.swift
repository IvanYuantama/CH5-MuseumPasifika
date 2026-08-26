//
//  OrientationLock.swift
//  PainThink
//
//  Created by Ivan Yuantama Pradipta on 06/08/26.
//

import UIKit

enum OrientationLock {
    static func enforcePortrait() {
        // Sinkronkan scene yang sudah aktif dengan lock portrait dari AppDelegate.
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            scene.windows.first?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)) { error in
                print("Gagal update orientasi: \(error)")
            }
        }
    }
}

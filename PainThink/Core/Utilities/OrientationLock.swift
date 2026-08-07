//
//  OrientationLock.swift
//  PainThink
//
//  Created by Ivan Yuantama Pradipta on 06/08/26.
//

import UIKit

final class OrientationLock {
    static var orientation: UIInterfaceOrientationMask = .all

    static func lock(to mask: UIInterfaceOrientationMask) {
        orientation = mask

        // Paksa update orientasi saat itu juga (bukan cuma nunggu user rotate manual)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            scene.windows.first?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask)) { error in
                print("Gagal update orientasi: \(error)")
            }
        }
    }

    static func unlock() {
        lock(to: .all)
    }
}

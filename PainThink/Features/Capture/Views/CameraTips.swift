//
//  CameraTips.swift
//  PainThink
//

import TipKit

// Cincin kuning di sekeliling shutter itu knob zoom (1x–5x), tapi gak ada
// afordansi visual yang bilang "aku bisa diputer". Tip ini yang ngasih tau,
// dan berhenti muncul begitu pengunjung beneran mutarnya.
struct ShutterZoomTip: Tip {

    // Di-set true pertama kali ring-nya diputar. Static supaya CameraView bisa
    // nandain tanpa perlu pegang instance tip-nya.
    @Parameter static var hasZoomed: Bool = false

    var title: Text {
        Text("Turn the ring to zoom")
    }

    var message: Text? {
        Text("Twist the yellow ring around the shutter — it zooms in up to 5×.")
    }

    var image: Image? {
        Image(systemName: "arrow.trianglehead.clockwise")
    }

    // Cuma tampil selama pengunjung belum pernah mutar ring-nya.
    var rules: [Rule] {
        #Rule(Self.$hasZoomed) { $0 == false }
    }
}

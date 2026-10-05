// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

// A little color makes source easier to read.
struct Swatch {
    let name: String
    let rgb: UInt32

    var hex: String {
        String(format: "#%06X", rgb)
    }
}

let palette = [
    Swatch(name: "Coral", rgb: 0xFF7B72),
    Swatch(name: "Gold", rgb: 0xFFD866),
    Swatch(name: "Mint", rgb: 0x7BDCB5),
    Swatch(name: "Periwinkle", rgb: 0xA5B4FC)
]

for color in palette {
    print("\(color.name): \(color.hex)")
}

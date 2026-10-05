// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

@objc protocol HighlighterProtocol {
    func highlight(_ source: String, language: String, withReply reply: @escaping @Sendable (String?) -> Void)
}

import CoreGraphics
import Foundation

enum RatioPreset: String, CaseIterable, Identifiable, Codable {
    case r16x9  = "16:9"
    case r16x10 = "16:10"
    case r4x3   = "4:3"
    case r1x1   = "1:1"
    case r3x4   = "3:4"
    case r9x16  = "9:16"

    var id: String { rawValue }

    var widthFactor: CGFloat {
        switch self {
        case .r16x9:  return 16
        case .r16x10: return 16
        case .r4x3:   return 4
        case .r1x1:   return 1
        case .r3x4:   return 3
        case .r9x16:  return 9
        }
    }

    var heightFactor: CGFloat {
        switch self {
        case .r16x9:  return 9
        case .r16x10: return 10
        case .r4x3:   return 3
        case .r1x1:   return 1
        case .r3x4:   return 4
        case .r9x16:  return 16
        }
    }

    var ratio: CGFloat { widthFactor / heightFactor }

    var label: String { rawValue }

    var defaultKeyIndex: Int {
        switch self {
        case .r16x9:  return 1
        case .r16x10: return 2
        case .r4x3:   return 3
        case .r1x1:   return 4
        case .r3x4:   return 5
        case .r9x16:  return 6
        }
    }

    func targetSize(currentWidth: CGFloat, currentHeight: CGFloat, screenFrame: CGRect) -> CGSize {
        var w = currentWidth
        var h = w / ratio

        if h > screenFrame.height {
            h = screenFrame.height
            w = h * ratio
        }
        if w > screenFrame.width {
            w = screenFrame.width
            h = w / ratio
        }

        return CGSize(width: round(w), height: round(h))
    }

    func maximizedSize(in screenFrame: CGRect) -> CGSize {
        let screenRatio = screenFrame.width / screenFrame.height
        var w: CGFloat
        var h: CGFloat

        if screenRatio > ratio {
            h = screenFrame.height
            w = h * ratio
        } else {
            w = screenFrame.width
            h = w / ratio
        }

        return CGSize(width: round(w), height: round(h))
    }

    static func scaledSize(currentWidth: CGFloat, currentHeight: CGFloat, factor: CGFloat, screenFrame: CGRect) -> CGSize {
        var w = currentWidth * factor
        var h = currentHeight * factor

        w = min(w, screenFrame.width)
        h = min(h, screenFrame.height)
        w = max(w, 200)
        h = max(h, 200)

        return CGSize(width: round(w), height: round(h))
    }
}

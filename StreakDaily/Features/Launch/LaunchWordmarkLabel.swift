import SwiftUI
import UIKit

/// Renders the two-line Streak Daily wordmark using UILabel and NSAttributedString.
struct LaunchWordmarkLabel: UIViewRepresentable {
    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.attributedText = Self.makeWordmark()
        label.isAccessibilityElement = true
        label.accessibilityLabel = "Streak Daily"
        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {}

    private static func makeWordmark() -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = 6

        let wordmark = NSMutableAttributedString(
            string: "Streak\n",
            attributes: attributes(fontSize: 54, paragraph: paragraph)
        )
        wordmark.append(NSAttributedString(
            string: "Daily",
            attributes: attributes(fontSize: 60, paragraph: paragraph)
        ))

        tint(wordmark, substring: "k", color: rouge)
        tint(wordmark, substring: "D", color: rouge)
        return wordmark
    }

    private static func attributes(
        fontSize: CGFloat,
        paragraph: NSParagraphStyle
    ) -> [NSAttributedString.Key: Any] {
        [
            .font: avenirNextBoldFont(size: fontSize),
            .foregroundColor: UIColor.label,
            .paragraphStyle: paragraph
        ]
    }

    private static func tint(
        _ string: NSMutableAttributedString,
        substring: String,
        color: UIColor
    ) {
        let range = (string.string as NSString).range(of: substring)
        guard range.location != NSNotFound else { return }
        string.addAttribute(.foregroundColor, value: color, range: range)
    }

    private static func avenirNextBoldFont(size: CGFloat) -> UIFont {
        UIFont(name: "AvenirNext-Bold", size: size) ?? .systemFont(ofSize: size, weight: .bold)
    }

    private static let rouge = UIColor(
        red: 228 / 255,
        green: 27 / 255,
        blue: 48 / 255,
        alpha: 1
    )
}

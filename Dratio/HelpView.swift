import SwiftUI

struct HelpView: View {

    @Environment(\.dismiss) private var dismiss

    private let numberWidth: CGFloat = 28
    private let stepSpacing: CGFloat = 14

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 18) {
                    stepRow(number: "1", text: String(localized: "help.step1"))
                    stepRow(number: "2", text: String(localized: "help.step2"))
                    stepRow(number: "3", text: String(localized: "help.step3"))
                }

                Divider()
                    .padding(.vertical, 16)

                VStack(alignment: .leading, spacing: 10) {
                    tipRow(icon: "plus.forwardslash.minus", text: String(localized: "help.tip.scale"))
                    tipRow(icon: "arrow.up.left.and.arrow.down.right", text: String(localized: "help.tip.maximize"))
                }

                Spacer(minLength: 16)

                HStack {
                    Spacer()
                    Button(String(localized: "help.close")) {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    Spacer()
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
        .frame(width: 400, height: 400)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "questionmark.circle.fill")
                .font(.title2)
                .foregroundStyle(Color.accentColor)
            Text("help.title")
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.bar)
    }

    private func stepRow(number: String, text: String) -> some View {
        HStack(alignment: .center, spacing: stepSpacing) {
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: numberWidth, height: numberWidth)
                Text(number)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: numberWidth)

            Text(text)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: stepSpacing) {
            Image(systemName: icon)
                .font(.caption)
                .frame(width: numberWidth)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

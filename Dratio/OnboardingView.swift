import SwiftUI

struct OnboardingView: View {

    let permissionHelper: PermissionHelper
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 32)

            Image(systemName: "aspectratio")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
                .padding(.bottom, 12)

            Text("onboarding.title")
                .font(.title.bold())
                .padding(.bottom, 4)

            Text("onboarding.subtitle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer(minLength: 24)

            VStack(alignment: .leading, spacing: 16) {
                featureRow(
                    icon: "rectangle.ratio.3.to.4",
                    title: String(localized: "onboarding.feature.ratio.title"),
                    detail: String(localized: "onboarding.feature.ratio.detail")
                )
                featureRow(
                    icon: "keyboard",
                    title: String(localized: "onboarding.feature.hotkey.title"),
                    detail: String(localized: "onboarding.feature.hotkey.detail")
                )
                featureRow(
                    icon: "arrow.up.left.and.arrow.down.right",
                    title: String(localized: "onboarding.feature.scale.title"),
                    detail: String(localized: "onboarding.feature.scale.detail")
                )
            }
            .padding(.horizontal, 36)

            Spacer(minLength: 24)

            permissionCard

            Spacer(minLength: 24)

            Button {
                dismiss()
            } label: {
                Text(permissionHelper.isAccessibilityGranted
                     ? "onboarding.done"
                     : "onboarding.skip")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 36)

            Spacer(minLength: 32)
        }
        .frame(width: 420, height: 560)
        .animation(.easeInOut(duration: 0.3), value: permissionHelper.isAccessibilityGranted)
    }

    // MARK: - Permission Card

    private var permissionCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: permissionHelper.isAccessibilityGranted
                      ? "checkmark.shield.fill" : "lock.shield")
                    .font(.title3)
                    .foregroundStyle(permissionHelper.isAccessibilityGranted ? .green : .orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("onboarding.permission.title")
                        .font(.subheadline.weight(.semibold))
                    Text(permissionHelper.isAccessibilityGranted
                         ? "onboarding.permission.granted"
                         : "onboarding.permission.needed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !permissionHelper.isAccessibilityGranted {
                    Button("onboarding.permission.grant") {
                        permissionHelper.requestAccessibility()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            if !permissionHelper.isAccessibilityGranted {
                Text("onboarding.permission.why")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(permissionHelper.isAccessibilityGranted
                      ? Color.green.opacity(0.06)
                      : Color.orange.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(permissionHelper.isAccessibilityGranted
                              ? Color.green.opacity(0.2)
                              : Color.orange.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 36)
    }

    // MARK: - Feature Row

    private func featureRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

import SwiftUI
import UIKit

// MARK: - Color Palette
extension Color {
    static let appBackground   = Color(hex: "#F7FDF9")
    static let softGreenBg     = Color(hex: "#ECFDF5")
    static let freshBg         = Color(hex: "#F0FDF4")
    static let cardBg          = Color.white
    static let dividerGreen    = Color(hex: "#D1FAE5")
    static let dividerMint     = Color(hex: "#A7F3D0")

    static let primaryGreen    = Color(hex: "#22C55E")
    static let activeGreen     = Color(hex: "#16A34A")
    static let lightGreen      = Color(hex: "#4ADE80")

    static let primaryBlue     = Color(hex: "#3B82F6")
    static let lightBlue       = Color(hex: "#60A5FA")
    static let accentCyan      = Color(hex: "#22D3EE")

    static let actionOrange    = Color(hex: "#F97316")
    static let lightOrange     = Color(hex: "#FB923C")
    static let paleOrange      = Color(hex: "#FDBA74")

    static let statusNormal    = Color(hex: "#22C55E")
    static let statusRisk      = Color(hex: "#FACC15")
    static let statusDanger    = Color(hex: "#EF4444")

    static let textPrimary     = Color(hex: "#064E3B")
    static let textSecondary   = Color(hex: "#065F46")
    static let textInactive    = Color(hex: "#6B7280")
    static let btnSecondaryBg  = Color(hex: "#E2E8F0")
    static let btnSecondaryText = Color(hex: "#1E293B")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a,r,g,b) = (255,(int>>8)*17,(int>>4 & 0xF)*17,(int & 0xF)*17)
        case 6:  (a,r,g,b) = (255,int>>16,int>>8 & 0xFF,int & 0xFF)
        case 8:  (a,r,g,b) = (int>>24,int>>16 & 0xFF,int>>8 & 0xFF,int & 0xFF)
        default: (a,r,g,b) = (255,0,0,0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Tab bar inset
//
// `.safeAreaInset` applied outside a NavigationView does not reach the
// ScrollView inside it, which left the last row of long lists stranded behind
// the tab bar. Instead the bar measures itself once and publishes its height
// down the environment, so every scrollable screen reserves exactly the right
// amount of room — and screens shown in a sheet, where the default is 0, add
// nothing.

struct TabBarHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct TabBarInsetKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var tabBarInset: CGFloat {
        get { self[TabBarInsetKey.self] }
        set { self[TabBarInsetKey.self] = newValue }
    }
}

private struct TabBarBottomPadding: ViewModifier {
    @Environment(\.tabBarInset) private var inset
    func body(content: Content) -> some View {
        content.padding(.bottom, inset)
    }
}

extension View {
    /// Reserves room under scrollable content for the custom tab bar.
    func tabBarBottomPadding() -> some View { modifier(TabBarBottomPadding()) }
}

// MARK: - Animations
extension Animation {
    static let appSpring  = Animation.spring(response: 0.4, dampingFraction: 0.7)
    static let softSpring = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let snappy     = Animation.spring(response: 0.3, dampingFraction: 0.7)
}

// MARK: - View Modifiers
struct AppCardModifier: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.cardBg)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 2)
    }
}

struct GreenGlowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.shadow(color: Color.primaryGreen.opacity(0.3), radius: 12, x: 0, y: 0)
    }
}

struct BlueGlowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.shadow(color: Color.primaryBlue.opacity(0.3), radius: 12, x: 0, y: 0)
    }
}

extension View {
    func appCard(padding: CGFloat = 16) -> some View { modifier(AppCardModifier(padding: padding)) }
    func greenGlow() -> some View { modifier(GreenGlowModifier()) }
    func blueGlow() -> some View { modifier(BlueGlowModifier()) }
    func appShadow() -> some View { shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2) }
}

// MARK: - Primary Button Style
struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = .primaryGreen
    var fullWidth: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .background(color)
            .cornerRadius(14)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.appSpring, value: configuration.isPressed)
            .greenGlow()
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.btnSecondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.btnSecondaryBg)
            .cornerRadius(14)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.appSpring, value: configuration.isPressed)
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.statusDanger)
            .cornerRadius(14)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.appSpring, value: configuration.isPressed)
    }
}

// MARK: - Reusable Components
struct StatusBadge: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(8)
    }
}

struct SectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "See All"
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if let action = action {
                Button(actionLabel, action: action)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primaryGreen)
            }
        }
    }
}

/// Section header whose trailing control pushes a destination, so "See All"
/// gets a real back button instead of a modal with no way out.
struct SectionHeaderLink<Destination: View>: View {
    let title: String
    var actionLabel: String = "See All"
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            NavigationLink(destination: destination()) {
                Text(actionLabel)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primaryGreen)
            }
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundColor(.primaryGreen.opacity(0.5))
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.textPrimary)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.textInactive)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}

struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    /// Number pads have no return key, so any non-default keyboard also gets a
    /// Done button in the accessory bar.
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 10) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.textInactive)
                    .frame(width: 20)
            }
            let field = TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .foregroundColor(.textPrimary)
                .keyboardType(keyboardType)

            if keyboardType == .default {
                field
            } else {
                field.modifier(KeyboardDoneToolbar())
            }
        }
        .padding(14)
        .background(Color.freshBg)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.dividerGreen, lineWidth: 1))
    }
}

/// Number pads have no return key, so numeric fields get an explicit Done button.
private struct KeyboardDoneToolbar: ViewModifier {
    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { KeyboardDismisser.dismiss() }
                    .foregroundColor(.primaryGreen)
            }
        }
    }
}

enum KeyboardDismisser {
    static func dismiss() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}

struct FormRow<Content: View>: View {
    let label: String
    let content: Content
    init(_ label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textSecondary)
            content
        }
        // Without this the row shrinks to its widest child, which left menu
        // pickers — and their labels — visually centred next to left-aligned
        // text fields.
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The same field treatment AppTextField uses, for controls that would
/// otherwise hug their content (menu pickers in particular).
private struct AppFieldBox: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color.freshBg)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.dividerGreen, lineWidth: 1))
    }
}

extension View {
    func appFieldBox() -> some View { modifier(AppFieldBox()) }
}

struct ProgressRing: View {
    let progress: Double
    let color: Color
    let size: CGFloat
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.softSpring, value: progress)
        }
        .frame(width: size, height: size)
    }
}

struct AppDivider: View {
    var body: some View {
        Divider().background(Color.dividerGreen)
    }
}

struct IconBadge: View {
    let icon: String
    let color: Color
    var size: CGFloat = 36
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.15))
                .frame(width: size, height: size)
            Image(systemName: icon)
                .font(.system(size: size * 0.44, weight: .semibold))
                .foregroundColor(color)
        }
    }
}

// MARK: - Gradient Presets
extension LinearGradient {
    static var farmGreen: LinearGradient {
        LinearGradient(colors: [Color(hex: "#064E3B"), Color(hex: "#16A34A"), Color(hex: "#4ADE80")],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var softGreen: LinearGradient {
        LinearGradient(colors: [Color(hex: "#F0FDF4"), Color(hex: "#DCFCE7")],
                       startPoint: .top, endPoint: .bottom)
    }
    static var appBg: LinearGradient {
        LinearGradient(colors: [Color(hex: "#F7FDF9"), Color(hex: "#ECFDF5")],
                       startPoint: .top, endPoint: .bottom)
    }
}

import SwiftUI

/// Bagel Fat One зарегистрирован в основном target через UIAppFonts.
private enum BagelFatOne {
    static func regular(_ size: CGFloat) -> Font { .custom("BagelFatOne-Regular", size: size) }
}

/// Сплошной текст с настраиваемым цветом.
private struct OutlinedTitle: View {
    let text: String
    let font: Font
    var uppercase: Bool = true
    var alignment: TextAlignment = .center
    var textColor: Color = .white

    private var frameAlignment: Alignment {
        switch alignment {
        case .leading:  return .leading
        case .trailing: return .trailing
        default:        return .center
        }
    }

    var body: some View {
        base
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity, alignment: frameAlignment)
    }

    private var base: some View {
        Text(text)
            .font(font)
            .textCase(uppercase ? .uppercase : nil)
            .multilineTextAlignment(alignment)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
    }

}

/// Кастомный pre-permission экран (только для режима WebView, п.4.1).
/// Адаптируется под портрет и альбом.
struct PrePermissionView: View {
    let onAccept: () -> Void
    let onSkip: () -> Void

    var body: some View {
        GeometryReader { geo in
            let landscape = geo.size.width > geo.size.height
            ZStack {
                background
                VStack(spacing: 32) {
                        Spacer()
                        VStack(spacing: 14) {
                            texts(.center)
                            buttons(landscape: landscape)
                    }
                   
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var background: some View {
        GeometryReader { geo in
            Image("bg")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
        .ignoresSafeArea()
    }

    private func texts(_ alignment: TextAlignment) -> some View {
        VStack(alignment: alignment == .leading ? .leading : .center, spacing: 8) {
            VStack(alignment: alignment == .leading ? .leading : .center) {
                OutlinedTitle(text: "Allow Notifications About Bonuses and Promos",
                              font: BagelFatOne.regular(24),
                              alignment: alignment,
                              textColor: .white
                )
            }
            OutlinedTitle(text: "Stay tuned with best offers from our casino",
                          font: BagelFatOne.regular(18),
                          uppercase: false,
                          alignment: alignment,
                          textColor: Color(hex: "BABABA"))
        }
    }

    private func buttons(landscape: Bool) -> some View {
        VStack(spacing: 8) {
            Button(action: onAccept) {
                Image(landscape ? "buttonLong" : "button")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
            }
            Button(action: onSkip) {
                Text("Skip")
                    .font(BagelFatOne.regular(16))
                    .textCase(.uppercase)
                    .foregroundStyle(Color(hex: "BABABA"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
            }
        }
        .padding(.horizontal, 12)
    }
}

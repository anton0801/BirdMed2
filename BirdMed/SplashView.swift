import SwiftUI

struct LaunchView: View {

    // Layer 2 – flying birds
    @State private var bird1X: CGFloat = -200
    @State private var bird2X: CGFloat = -300
    @State private var bird1Y: CGFloat = 0
    @State private var bird2Y: CGFloat = 0
    @State private var wingFlap = false
    // Layer 3 – logo entrance
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var subtitleOpacity: Double = 0
    var body: some View {
        ZStack {
            // ── Layer 1: supplied launch background ───────────────────────
            Image(.bg)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                .clipped()
                .blur(radius: 5)
                .opacity(0.15)
                .background(.black.opacity(0.5))
            // ── Layer 2: Flying birds ─────────────────────────────────────
            GeometryReader { geo in
                BirdShape(flap: wingFlap)
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 34, height: 18)
                    .offset(x: bird1X, y: geo.size.height * 0.22 + bird1Y)

                BirdShape(flap: !wingFlap)
                    .fill(Color.white.opacity(0.65))
                    .frame(width: 22, height: 12)
                    .offset(x: bird2X, y: geo.size.height * 0.32 + bird2Y)

                BirdShape(flap: wingFlap)
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 16, height: 9)
                    .offset(x: bird1X - 60, y: geo.size.height * 0.18 + bird2Y * 0.5)
            }

            // ── Layer 3: Logo + Title ─────────────────────────────────────
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 110, height: 110)
                        .blur(radius: 6)
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 90, height: 90)
                    Image(systemName: "syringe.fill")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 4)
                    // Orbit dot
                    Circle()
                        .fill(Color(hex: "#4ADE80"))
                        .frame(width: 12, height: 12)
                        .offset(x: 38, y: -38)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                .padding(.bottom, 20)

                Text("BirdMed")
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .offset(y: titleOffset)
                    .opacity(logoOpacity)
                    .shadow(color: .black.opacity(0.15), radius: 4)
            }
        }
        .onAppear { startAnimations() }
        .onDisappear { stopAnimations() }
    }

    private func startAnimations() {
        // Phase 1 (0–0.6s): background builds in
        withAnimation(Animation.linear(duration: 0.18).repeatForever(autoreverses: true)) {
            wingFlap = true
        }

        // Phase 2 (0.6–1.4s): birds fly across
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(Animation.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                bird1X = UIScreen.main.bounds.width + 100
            }
            withAnimation(Animation.linear(duration: 3.5).repeatForever(autoreverses: false).delay(0.3)) {
                bird2X = UIScreen.main.bounds.width + 150
            }
            withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                bird1Y = -20; bird2Y = -15
            }
        }

        // Phase 3 (1.4–2.2s): logo + title entrance
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
                logoScale = 1.0; logoOpacity = 1.0; titleOffset = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeIn(duration: 0.4)) { subtitleOpacity = 1.0 }
            }
        }

    }

    private func stopAnimations() {
        wingFlap      = false
        bird1X = -200; bird2X = -300
        bird1Y = 0;    bird2Y = 0
        logoScale = 0.3; logoOpacity = 0
        titleOffset = 30; subtitleOpacity = 0
    }
}

// MARK: - Bird Wing Shape
private struct BirdShape: Shape {
    var flap: Bool
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let midX = rect.midX, midY = rect.midY
        let wingY: CGFloat = flap ? -rect.height * 0.4 : rect.height * 0.2
        p.move(to: CGPoint(x: midX, y: midY))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: midY + 2),
                       control: CGPoint(x: rect.width * 0.25, y: wingY))
        p.move(to: CGPoint(x: midX, y: midY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: midY + 2),
                       control: CGPoint(x: rect.width * 0.75, y: wingY))
        return p
    }
    var animatableData: Bool { flap }
}

// MARK: - Field Grass
private struct FieldGrass: View {
    let delay: Double
    @State private var sway = false
    var body: some View {
        Capsule()
            .fill(Color(hex: "#166534").opacity(0.9))
            .frame(width: 6, height: CGFloat.random(in: 40...70))
            .rotationEffect(.degrees(sway ? 8 : -5))
            .animation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(delay),
                       value: sway)
            .onAppear { sway = true }
    }
}

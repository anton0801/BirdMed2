import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var currentPage = 0
    private let pages = 3

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                OnboardPage1().tag(0)
                OnboardPage2().tag(1)
                OnboardPage3().tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // Controls overlay
            VStack(spacing: 20) {
                // Dot indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? Color.primaryGreen : Color.white.opacity(0.4))
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.appSpring, value: currentPage)
                    }
                }

                HStack(spacing: 12) {
                    // Skip
                    Button("Skip") {
                        withAnimation { appVM.hasCompletedOnboarding = true }
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 80)

                    // Next / Get Started
                    Button(currentPage < pages - 1 ? "Next" : "Get Started") {
                        withAnimation(.appSpring) {
                            if currentPage < pages - 1 { currentPage += 1 }
                            else { appVM.hasCompletedOnboarding = true }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 48)
        }
    }
}

// MARK: - Page 1: Manage Bird Groups (tap to burst)
private struct OnboardPage1: View {
    @State private var burst = false
    @State private var particles: [ParticleData] = []

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#064E3B"), Color(hex: "#16A34A")],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Interactive icon
                ZStack {
                    // Particles
                    ForEach(particles) { p in
                        Circle()
                            .fill(p.color)
                            .frame(width: p.size, height: p.size)
                            .offset(x: p.x, y: p.y)
                            .opacity(p.opacity)
                    }

                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 140, height: 140)
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 110, height: 110)
                    VStack(spacing: 6) {
                        Text("🐔")
                            .font(.system(size: 52))
                            .scaleEffect(burst ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: burst)
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .onTapGesture { triggerBurst() }

                Text("Tap the flock!")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))

                VStack(spacing: 12) {
                    Text("Manage Bird Groups")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    Text("Keep every group organized.\nTrack type, count, age, and location.")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                Spacer()
                Spacer()
            }
        }
        .onDisappear { particles = [] }
    }

    private func triggerBurst() {
        burst = true
        particles = (0..<16).map { _ in
            ParticleData(
                x: CGFloat.random(in: -80...80),
                y: CGFloat.random(in: -80...80),
                color: [Color.primaryGreen, Color.lightGreen, Color.accentCyan,
                        Color.white, Color.paleOrange].randomElement()!,
                size: CGFloat.random(in: 6...14),
                opacity: 1.0
            )
        }
        withAnimation(.easeOut(duration: 0.8)) {
            particles = particles.map { p in
                var new = p
                new.x *= 2.5; new.y *= 2.5; new.opacity = 0
                return new
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            burst = false; particles = []
        }
    }
}

private struct ParticleData: Identifiable {
    let id = UUID()
    var x, y: CGFloat
    var color: Color
    var size: CGFloat
    var opacity: Double
}

// MARK: - Page 2: Track Daily Care (drag gesture)
private struct OnboardPage2: View {
    @State private var dragOffset = CGSize.zero
    @State private var checkmarks: [UUID] = []
    @State private var isAnimating = false

    // Generic labels on purpose — an onboarding illustration must not name a
    // vaccine or a supplement, or it reads as a suggestion.
    let taskItems = ["💉 Vaccination due", "🌿 Course ends today", "🧹 Coop cleaning", "💧 Water check"]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#1E3A5F"), Color(hex: "#1D4ED8"), Color(hex: "#3B82F6")],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                // Draggable calendar card
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 260, height: 200)
                        .blur(radius: 1)

                    VStack(spacing: 0) {
                        // Calendar header
                        HStack {
                            Text("This Week")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "calendar")
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                        ForEach(Array(taskItems.prefix(3).enumerated()), id: \.offset) { i, item in
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(checkmarks.count > i ? Color.primaryGreen : Color.white.opacity(0.3))
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                            .opacity(checkmarks.count > i ? 1 : 0)
                                    )
                                Text(item)
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.9))
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                        }
                    }
                }
                .offset(x: dragOffset.width * 0.4, y: dragOffset.height * 0.4)
                .rotationEffect(.degrees(Double(dragOffset.width) / 20))
                .gesture(
                    DragGesture()
                        .onChanged { v in
                            withAnimation(.interactiveSpring()) { dragOffset = v.translation }
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                dragOffset = .zero
                            }
                            withAnimation(.easeInOut(duration: 0.3).delay(Double(checkmarks.count) * 0.15)) {
                                checkmarks.append(UUID())
                                if checkmarks.count > 3 {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        checkmarks = []
                                    }
                                }
                            }
                        }
                )

                Text("Drag to interact!")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))

                VStack(spacing: 12) {
                    Text("Track Daily Care")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    Text("Record the dates your vet gave you\nand get a reminder before each one.")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                Spacer()
                Spacer()
            }
        }
        .onDisappear { dragOffset = .zero; checkmarks = [] }
    }
}

// MARK: - Page 3: See Useful Insights (scroll-driven)
private struct OnboardPage3: View {
    @State private var scrollOffset: CGFloat = 0
    @State private var animBars = false

    let bars: [(String, Double, Color)] = [
        ("Chickens", 0.85, .primaryGreen),
        ("Ducks",    0.60, .accentCyan),
        ("Turkeys",  0.40, .actionOrange),
    ]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#1C1917"), Color(hex: "#44403C"), Color(hex: "#78716C")],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                // Bar chart
                VStack(spacing: 0) {
                    HStack {
                        Text("Flock Overview")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        // Labelled as an illustration: these bars are decorative
                        // and must not read as real recorded figures.
                        Text("EXAMPLE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.white.opacity(0.18))
                            .cornerRadius(4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    VStack(spacing: 12) {
                        ForEach(bars, id: \.0) { name, value, color in
                            HStack(spacing: 10) {
                                Text(name)
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.8))
                                    .frame(width: 70, alignment: .leading)
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color.white.opacity(0.1))
                                        Capsule()
                                            .fill(color)
                                            .frame(width: animBars ? geo.size.width * value : 0)
                                            .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.2), value: animBars)
                                    }
                                }
                                .frame(height: 12)
                                Text("\(Int(value * 100))%")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(color)
                                    .frame(width: 34)
                            }
                        }
                    }
                    .padding(16)
                }
                .background(Color.white.opacity(0.1))
                .cornerRadius(20)
                .padding(.horizontal, 32)
                .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { animBars = true } }

                VStack(spacing: 12) {
                    Text("See Your Records Clearly")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    Text("Totals, dates and costs, summed from what you enter.\nBirdMed keeps the books — your vet makes the calls.")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                Spacer()
                Spacer()
            }
        }
        .onDisappear { animBars = false }
    }
}

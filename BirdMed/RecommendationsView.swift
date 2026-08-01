import SwiftUI

// Suggestions here are operational, never clinical: they are produced by
// DataStore.buildRecommendations() from the user's own records and never name a
// medicine, a dose or an interval. Where a clinical decision is involved they
// point at the veterinarian instead.
struct RecommendationsView: View {
    @EnvironmentObject var store: DataStore
    @State private var filterType: Recommendation.RecommendationType? = nil
    @State private var confirmAddedKey: String? = nil

    var displayed: [Recommendation] {
        guard let f = filterType else { return store.recommendations }
        return store.recommendations.filter { $0.type == f }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header card
                HStack(spacing: 16) {
                    IconBadge(icon: "checklist.checked", color: .primaryGreen, size: 52)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("From your records")
                            .font(.system(size: 18, weight: .bold)).foregroundColor(.textPrimary)
                        Text("Gaps and dates BirdMed spotted in what you entered")
                            .font(.system(size: 13)).foregroundColor(.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .appCard()
                .padding(.horizontal, 16)

                DisclaimerBanner()
                    .padding(.horizontal, 16)

                if store.recommendations.isEmpty {
                    EmptyStateView(icon: "checkmark.seal.fill",
                                   title: "Your records look complete",
                                   message: "Nothing is missing or overdue in what you entered. This is a check of your bookkeeping, not of your birds' health.")
                        .padding(.top, 12)
                } else {
                    // Type filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip3(label: "All", isSelected: filterType == nil, color: .primaryGreen) {
                                withAnimation(.appSpring) { filterType = nil }
                            }
                            ForEach(Recommendation.RecommendationType.allCases, id: \.rawValue) { t in
                                FilterChip3(label: t.rawValue, isSelected: filterType == t, color: t.color) {
                                    withAnimation(.appSpring) { filterType = filterType == t ? nil : t }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    if displayed.isEmpty {
                        Text("Nothing in this category right now.")
                            .font(.system(size: 14))
                            .foregroundColor(.textInactive)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                    } else {
                        ForEach(displayed) { rec in
                            RecCard(rec: rec, confirmAddedKey: $confirmAddedKey)
                                .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 16)
            .tabBarBottomPadding()
        }
        .background(LinearGradient.appBg.ignoresSafeArea())
        .navigationTitle("Recommendations")
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct FilterChip3: View {
    let label: String; let isSelected: Bool; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .textSecondary)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(isSelected ? color : Color.freshBg)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(isSelected ? color : Color.dividerGreen, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

private struct RecCard: View {
    @EnvironmentObject var store: DataStore
    let rec: Recommendation
    @Binding var confirmAddedKey: String?
    @State private var expanded = false

    private var isConfirmed: Bool { confirmAddedKey == rec.key }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                IconBadge(icon: rec.type.icon, color: rec.type.color, size: 42)
                VStack(alignment: .leading, spacing: 3) {
                    Text(rec.type.rawValue)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(rec.type.color)
                        .textCase(.uppercase)
                    Text(rec.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                if rec.isSaved {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 16)).foregroundColor(.primaryGreen)
                }
            }

            Text(rec.body)
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
                .lineLimit(expanded ? nil : 2)
                .fixedSize(horizontal: false, vertical: expanded)

            Button {
                withAnimation(.appSpring) { expanded.toggle() }
            } label: {
                Text(expanded ? "Show less" : "Read more")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primaryGreen)
            }
            .buttonStyle(.plain)

            HStack(spacing: 10) {
                Button {
                    guard !rec.isAddedToTasks else { return }
                    store.addRecToTasks(rec)
                    withAnimation(.appSpring) { confirmAddedKey = rec.key }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                        if confirmAddedKey == rec.key {
                            withAnimation(.appSpring) { confirmAddedKey = nil }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: rec.isAddedToTasks ? "checkmark.circle.fill" : "plus.circle")
                            .font(.system(size: 14))
                        Text(rec.isAddedToTasks ? "Added to Tasks" : "Add to Tasks")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(rec.isAddedToTasks ? .statusNormal : .white)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(rec.isAddedToTasks ? Color.statusNormal.opacity(0.1) : Color.primaryGreen)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .disabled(rec.isAddedToTasks)

                Button {
                    store.saveRec(rec)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: rec.isSaved ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 14))
                        Text(rec.isSaved ? "Saved" : "Save")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(rec.isSaved ? .primaryGreen : .btnSecondaryText)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(rec.isSaved ? Color.primaryGreen.opacity(0.1) : Color.btnSecondaryBg)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .background(Color.cardBg)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(rec.type.color.opacity(0.2), lineWidth: 1.5)
        )
        .appShadow()
        .overlay {
            if isConfirmed {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.cardBg.opacity(0.92))
                    .overlay(
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.statusNormal)
                            Text("Added to Tasks")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.statusNormal)
                        }
                    )
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
        }
    }
}

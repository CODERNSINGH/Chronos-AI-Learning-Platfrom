//
//  ContentView.swift
//  chronos
//
//  Root view: shows Onboarding on first launch, otherwise MainTabView.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var showOnboarding: Bool? = nil

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        Group {
            if let show = showOnboarding {
                if show {
                    OnboardingView(onComplete: completeOnboarding)
                } else {
                    MainTabView()
                }
            } else {
                ZStack {
                    ChronosTheme.backgroundGradient.ignoresSafeArea()
                    ProgressView().tint(ChronosTheme.amber)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: decideFlow)
    }

    private func decideFlow() {
        if let p = profile, p.hasCompletedOnboarding {
            if p.topics.isEmpty {
                _ = RoadmapService.shared.seedTopicsIfNeeded(profile: p)
                try? modelContext.save()
            }
            RoadmapService.shared.recomputeStatuses(profile: p)
            try? modelContext.save()
            showOnboarding = false
        } else if profiles.isEmpty {
            showOnboarding = true
        } else {
            showOnboarding = !(profile?.hasCompletedOnboarding ?? false)
        }
    }

    private func completeOnboarding() {
        guard let p = profile else { return }
        p.hasCompletedOnboarding = true
        try? modelContext.save()
        withAnimation {
            showOnboarding = false
        }
    }
}

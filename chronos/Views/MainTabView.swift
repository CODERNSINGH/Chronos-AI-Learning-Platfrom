import SwiftUI
import SwiftData

struct MainTabView: View {
    @Query private var profiles: [UserProfile]
    @State private var selection: Tab = .home

    enum Tab: Hashable { case home, roadmap, profile, settings }

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tag(Tab.home)
                .toolbar(.hidden, for: .tabBar)

            RoadmapView()
                .tag(Tab.roadmap)
                .toolbar(.hidden, for: .tabBar)

            ProfileView()
                .tag(Tab.profile)
                .toolbar(.hidden, for: .tabBar)

            SettingsView()
                .tag(Tab.settings)
                .toolbar(.hidden, for: .tabBar)
        }
        .tint(ChronosTheme.amber)
        .safeAreaInset(edge: .bottom) {
            customTabBar
        }
    }

    // MARK: - Custom tab bar

    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabButton(.home,     label: "Home",     icon: "house.fill")
            tabButton(.roadmap,  label: "Roadmap",  icon: "map.fill")
            tabButton(.profile,  label: "Profile",  icon: "person.crop.circle.fill")
            tabButton(.settings, label: "Settings", icon: "gearshape.fill")
        }
        .padding(.horizontal, 8)
        .padding(.top, 6)
        .padding(.bottom, 6)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(ChronosTheme.background)
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .opacity(0.55)
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(ChronosTheme.amber.opacity(0.22), lineWidth: 1)
            }
        )
        .shadow(color: .black.opacity(0.45), radius: 18, x: 0, y: 8)
        .padding(.horizontal, 12)
        .padding(.bottom, 2)
    }

    private func tabButton(_ tab: Tab, label: String, icon: String) -> some View {
        let active = selection == tab
        return         Button {
            Haptics.select()
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                selection = tab
            }
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    if active {
                        Circle()
                            .fill(ChronosTheme.amberGradient)
                            .frame(width: 38, height: 38)
                            .amberGlow(radius: 8, intensity: 0.55)
                            .matchedGeometryEffect(id: "activeTab", in: tabNamespace)
                    }
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(active ? .white : ChronosTheme.textTertiary)
                }
                Text(label)
                    .font(.system(size: 10,
                                  weight: active ? .heavy : .semibold,
                                  design: .rounded))
                    .foregroundStyle(active ? ChronosTheme.amber : ChronosTheme.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @Namespace private var tabNamespace
}

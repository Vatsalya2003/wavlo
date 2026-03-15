import SwiftUI
import SwiftData
import UIKit

// MARK: - Root (onboarding → auth → main app)

struct RootView: View {

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @EnvironmentObject private var playerVM: PlayerViewModel
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var authVM: AuthViewModel

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView()
            } else {
                switch authVM.authState {
                case .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(theme.colors.bgPrimary)
                case .unauthenticated:
                    NavigationStack {
                        WelcomeView()
                    }
                case .emailNotVerified:
                    NavigationStack {
                        EmailVerificationView()
                    }
                case .authenticated:
                    ContentView()
                }
            }
        }
        .preferredColorScheme(theme.isDarkMode ? .dark : .light)
    }
}

// MARK: - Main tab content

struct ContentView: View {

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var playerVM: PlayerViewModel
    @EnvironmentObject private var theme: ThemeManager
    @State private var selectedTab: Constants.Tab = .home

    private var colors: WavloColors { theme.colors }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(Constants.Tab.home)
                    .tabItem { Label(Constants.Tab.home.rawValue, systemImage: Constants.Tab.home.icon) }
                SearchView()
                    .tag(Constants.Tab.search)
                    .tabItem { Label(Constants.Tab.search.rawValue, systemImage: Constants.Tab.search.icon) }
                LibraryView()
                    .tag(Constants.Tab.library)
                    .tabItem { Label(Constants.Tab.library.rawValue, systemImage: Constants.Tab.library.icon) }
                AIDJView()
                    .tag(Constants.Tab.aidj)
                    .tabItem { Label(Constants.Tab.aidj.rawValue, systemImage: Constants.Tab.aidj.icon) }
            }
            .tabViewStyle(.automatic)
            .tint(theme.colors.primaryAccent)

            if playerVM.currentSong != nil {
                VStack(spacing: 0) {
                    MiniPlayerView()
                }
                .padding(.horizontal, 6)
                .padding(.bottom, 49)
            }
        }
        .onAppear {
            PlayerViewModel.shared.setModelContext(modelContext)
            configureTabBarAppearance()
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(theme.colors.bgCard)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    ContentView()
        .environmentObject(PlayerViewModel.shared)
        .environmentObject(ThemeManager())
}

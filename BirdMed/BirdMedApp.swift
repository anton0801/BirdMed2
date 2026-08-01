import SwiftUI

// MARK: - App ViewModel
//
// Only settings the app actually acts on live here. A stored preference that
// nothing reads is a promise the app doesn't keep, so there is no language or
// unit picker: BirdMed ships in English and records no weights or temperatures.
final class AppViewModel: ObservableObject {
    @AppStorage("hasCompletedOnboarding")       var hasCompletedOnboarding: Bool = false
    @AppStorage("hasAcceptedMedicalDisclaimer") var hasAcceptedMedicalDisclaimer: Bool = false
    @AppStorage("appTheme")                     var appTheme: String = "system"
    @AppStorage("dailyCareNotif")               var dailyCareNotif: Bool = true
    @AppStorage("healthCheckNotif")             var healthCheckNotif: Bool = true
    @AppStorage("lowStockNotif")                var lowStockNotif: Bool = false
    @AppStorage("notifHour")                    var notifHour: Int = 8
    @AppStorage("notifMinute")                  var notifMinute: Int = 0
    @AppStorage("farmName")                     var farmName: String = "My Farm"

    var colorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }
}

// MARK: - Entry Point
@main
struct BirdMedApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appVM = AppViewModel()
    @StateObject private var store = DataStore.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appVM)
                .environmentObject(store)
                .preferredColorScheme(appVM.colorScheme)
        }
    }
}

// MARK: - Root Router
struct AppRootView: View {
    @EnvironmentObject var appVM: AppViewModel

    var body: some View {
        ZStack {
            if !appVM.hasCompletedOnboarding {
                OnboardingView()
                    .transition(.opacity)
            } else if !appVM.hasAcceptedMedicalDisclaimer {
                // Nothing clinical is reachable until this has been accepted.
                MedicalDisclaimerGate()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: appVM.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.4), value: appVM.hasAcceptedMedicalDisclaimer)
    }
}

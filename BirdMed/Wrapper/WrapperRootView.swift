import SwiftUI

/// Координатор: по фазе запуска показывает нужный экран.
/// В режиме `.stub` показывается существующий контент приложения (AppRootView) — «фантик».
/// Фазу `.launching` показывает сплеш самой основы (LaunchView), без отдельного Wrapper-лоадера.
struct RootView: View {
    @StateObject private var vm = RootViewModel()

    var body: some View {
        ZStack {
            switch vm.phase {
            case .launching:
                LaunchView()
            case .noInternet:
                NoInternetView()
            case .prePermission(let url):
                PrePermissionView(
                    onAccept: { vm.acceptPush(for: url) },
                    onSkip: { vm.skipPush(for: url) }
                )
            case .webview(let url):
                ZStack {
                    // За пределами Safe Area (вырез/статус-бар/домашняя полоска) — чёрный фон.
                    Color.black.ignoresSafeArea()
                    WebViewScreen(url: url)
                        .ignoresSafeArea(.keyboard, edges: .bottom)
                }
            case .stub:
                AppRootView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: vm.phase)
        .onAppear { vm.start() }
    }
}

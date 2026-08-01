import Foundation
import SwiftUI
import Combine
import UserNotifications

/// Стейт-машина запуска: определяет и/или восстанавливает режим работы.
@MainActor
final class RootViewModel: ObservableObject {

    enum Phase: Equatable {
        case launching
        case noInternet
        case prePermission(URL)
        case webview(URL)
        case stub
    }

    @Published var phase: Phase = .launching

    private let store = WrapperStore.shared
    private var pushCancellable: AnyCancellable?
    private var networkCancellable: AnyCancellable?
    private var started = false

    func start() {
        guard !started else { return }
        started = true
        observePush()
        observeConnectivityLoss()
        Task { await run() }
    }

    // MARK: - Push handling (открыть ссылку из пуша, не сохраняя её)
    private func observePush() {
        pushCancellable = PushRouter.shared.$pendingURL
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] url in
                self?.phase = .webview(url)
            }
    }

    /// Событийная (не поллингом) реакция на обрыв сети прямо во время загрузки:
    /// `NetworkMonitor.isOnline` обновляется мгновенно через `pathUpdateHandler`, поэтому
    /// если связь пропадает, пока идёт AppsFlyer/Firebase/конфиг (это может занимать
    /// десятки секунд), пользователь не ждёт таймаута — экран «Нет интернета» показывается
    /// сразу. Срабатывает только пока мы ещё на загрузке — уже показанный WebView/фантик
    /// событием не трогаем.
    private func observeConnectivityLoss() {
        networkCancellable = NetworkMonitor.shared.$isOnline
            .receive(on: RunLoop.main)
            .sink { [weak self] online in
                guard let self, self.phase == .launching, !online else { return }
                self.phase = .noInternet
            }
    }

    /// Применяет новую фазу, только если мы всё ещё на загрузке — то есть за время
    /// awaiting'а сеть не пропала и `observeConnectivityLoss()` уже не увёл нас в
    /// `.noInternet`. Без этой защиты медленный AppsFlyer/конфиг-запрос мог бы
    /// перезаписать уже показанный «Нет интернета» устаревшим результатом.
    private func applyPhaseIfStillLaunching(_ newPhase: Phase) {
        guard phase == .launching else { return }
        phase = newPhase
    }

    /// AppsFlyer conversion data и Firebase push-токен живут только в памяти процесса,
    /// поэтому собираются заново на каждом холодном старте. Идут параллельно.
    ///
    /// ⚠️ Таймаут AppsFlyer немного больше лимита загрузки из раздела 6 ТЗ (≤10 c):
    /// если первый ответ атрибуции — Organic, AppsFlyerManager сам ждёт 5 c и перепроверяет
    /// ещё раз через лёгкий HTTP-пинг (не повторный `start()`), чтобы не потерять реальный
    /// Non-organic из-за задержки постбэка. Это удлиняет путь именно для organic/decoy-трафика
    /// (который увидит «фантик»), а не для целевого Non-organic-трафика (обычно отвечает сразу).
    private func gatherTrackingData() async {
        PushManager.shared.configureFirebaseIfPossible()
        async let conversion: Void = AppsFlyerManager.shared.startAndAwaitConversion(timeout: 12)
        async let token: String? = PushManager.shared.fetchToken(timeout: 3)
        _ = await (conversion, token)
    }

    // MARK: - Main flow
    private func run() async {
        // Холодный старт по тапу на пуш — открываем именно эту ссылку и не трогаем
        // обычный флоу (конфиг/фантик), иначе он гонкой перезапишет phase (п.4.3 ТЗ).
        if let pushURL = PushRouter.shared.pendingURL {
            phase = .webview(pushURL)
            return
        }

        switch store.mode {
        case .stub:
            // «Фантик»: интернет не требуется, конфиг не дёргаем.
            phase = .stub
        case .webview:
            await runWebViewMode()
        case .undecided:
            await runFirstLaunch()
        }
    }

    /// Первый запуск (п.1.1).
    private func runFirstLaunch() async {
        guard await NetworkMonitor.shared.currentStatus() else {
            applyPhaseIfStillLaunching(.noInternet)
            return
        }

        // 2–3. AppsFlyer + Firebase (параллельно, чтобы уложиться в лимит загрузки из раздела 6).
        await gatherTrackingData()

        // 4–5. Собрать тело и отправить POST.
        let result = await ConfigService.fetch()

        switch result {
        case .webview(let url, let expires):
            let decorated = url.appendingQueryItems(AppsFlyerManager.shared.deepLinkQueryItems)
            store.mode = .webview
            store.savedURL = decorated
            store.expires = expires
            await proceedToWebView(decorated)
        case .stub:
            // Сервер ответил отрицательно (ok:false / 404) → «фантик» навсегда,
            // конфиг больше не дёргаем (п.1.1).
            store.mode = .stub
            applyPhaseIfStillLaunching(.stub)
        case .networkError:
            // Не достучались до эндпоинта (таймаут/обрыв) — это НЕ отрицательный ответ.
            // Режим не фиксируем: показываем «Нет интернета» (п.2), решение отложено
            // до следующего запуска, иначе разовый сбой сети навсегда запрёт в «фантик».
            applyPhaseIfStillLaunching(.noInternet)
        }
    }

    /// Последующие запуски в режиме WebView (п.1.2 / 3.3).
    private func runWebViewMode() async {
        guard await NetworkMonitor.shared.currentStatus() else {
            applyPhaseIfStillLaunching(.noInternet)
            return
        }

        // Conversion data и push-токен живут только в памяти процесса — на каждом
        // холодном старте их нужно собрать заново, иначе тело конфиг-запроса будет неполным.
        await gatherTrackingData()

        // При каждом запуске обновляем ссылку (в т.ч. если expires истёк — запрос обязателен).
        let result = await ConfigService.fetch()

        switch result {
        case .webview(let url, let expires):
            let decorated = url.appendingQueryItems(AppsFlyerManager.shared.deepLinkQueryItems)
            store.savedURL = decorated
            store.expires = expires
            await proceedToWebView(decorated)
        case .networkError:
            // Запрос не дошёл. Раз интернет мог пропасть уже ПОСЛЕ первичной проверки
            // (пока шли AppsFlyer/Firebase/конфиг), перепроверяем сеть прямо сейчас:
            // реально офлайн → «Нет интернета» (п.1.2), а не молчаливая попытка
            // открыть WebView сохранённым url, которая просто зависнет без сети.
            if await NetworkMonitor.shared.currentStatus() {
                await fallBackToSavedURLOrStub()
            } else {
                applyPhaseIfStillLaunching(.noInternet)
            }
        case .stub:
            // Сервер явно ответил (пусть и отрицательно) — сеть точно есть,
            // используем сохранённый url, как и раньше.
            await fallBackToSavedURLOrStub()
        }
    }

    private func fallBackToSavedURLOrStub() async {
        if let saved = store.savedURL {
            await proceedToWebView(saved)
        } else {
            store.mode = .stub
            applyPhaseIfStillLaunching(.stub)
        }
    }

    // MARK: - WebView / pre-permission
    private func proceedToWebView(_ url: URL) async {
        if await shouldShowPrePermission() {
            applyPhaseIfStillLaunching(.prePermission(url))
        } else {
            applyPhaseIfStillLaunching(.webview(url))
        }
    }

    /// Показывать кастомный pre-permission экран (п.4.1):
    /// - только если системное разрешение ещё не запрашивалось (`notDetermined`);
    /// - 1-й Skip → показать снова, но не раньше чем через 3 дня;
    /// - 2-й Skip → больше не показывать никогда.
    private func shouldShowPrePermission() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return false }

        switch store.pushSkipCount {
        case 0:
            return true
        case 1:
            guard let declined = store.pushDeclinedAt else { return true }
            return Date().timeIntervalSince(declined) > 3 * 24 * 3600
        default:
            return false
        }
    }

    // MARK: - Actions from PrePermissionView
    func acceptPush(for url: URL) {
        // Показываем системный запрос и переходим в WebView ТОЛЬКО после ответа
        // пользователя (разрешил ИЛИ запретил) — не раньше.
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, _ in
            Task { @MainActor in
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                self?.phase = .webview(url)
            }
        }
    }

    func skipPush(for url: URL) {
        store.pushSkipCount += 1
        store.pushDeclinedAt = Date()
        phase = .webview(url)
    }
}

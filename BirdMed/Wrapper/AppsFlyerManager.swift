import Foundation
import AppsFlyerLib
import AppTrackingTransparency

/// Обёртка над AppsFlyer SDK: конверсионные данные, deep linking (UDL/OneLink), UID.
///
/// ВАЖНО (ТЗ): для нового приложения кабинет AppsFlyer настраивается с
/// Timezone = Moscow (UTC+3) и Currency = USD — это настройки кабинета, не SDK.
final class AppsFlyerManager: NSObject {
    static let shared = AppsFlyerManager()
    private override init() {}

    /// Конверсионные данные (как есть, без изменений — уходят в конфиг).
    private(set) var conversionData: [String: Any]?
    /// Данные deep linking (UDL).
    private(set) var deepLinkData: [String: Any]?
    /// true, если конверсионные данные пришли раньше deep-link — у них приоритет при слиянии.
    private(set) var conversionArrivedFirst = false

    // Ждём ОБА колбэка (conversion data И UDL) — оба вызываются AppsFlyer SDK всегда
    // после start() (UDL — со статусом .notFound, если диплинка нет), поэтому дожидаемся
    // обоих, а таймаут — лишь страховка на случай сетевых проблем/бага SDK.
    private var conversionSettled = false
    private var deepLinkSettled = false
    private var conversionAttempts = 0
    private var continuation: CheckedContinuation<Void, Never>?
    private var didResume = false

    func configure() {
        let af = AppsFlyerLib.shared()
        af.appsFlyerDevKey = Secrets.appsFlyerDevKey
        af.appleAppID = Secrets.appleAppID
        af.delegate = self
        af.deepLinkDelegate = self
        af.currencyCode = "USD"
        #if DEBUG
        af.isDebug = true
        #endif
    }

    var appsFlyerUID: String { AppsFlyerLib.shared().getAppsFlyerUID() }

    /// Conversion data + UDL deep link. Атрибуция (`af_status`, `af_sub*`, `campaign*`,
    /// `media_source` и т.д.) всегда берётся из `conversionData` — это авторитетный источник.
    /// От диплинка добавляются ТОЛЬКО его собственные поля (`deep_link_value`/`deep_link_sub*`),
    /// а не весь `clickEvent` словарь — иначе одноимённые (но иначе заполненные) поля диплинка
    /// затирают реальную атрибуцию конверсии значениями из другого контекста (полями клика
    /// по диплинку, не установки), что на практике превращало `af_sub1`, `campaign`,
    /// `media_source` и т.п. в пустые строки. При совпадении ключа среди `deep_link_*`
    /// побеждает пришедший первым (ТЗ разд. 3.1).
    var mergedTrackingData: [String: Any] {
        var merged = conversionData ?? [:]
        let deepLinkOwnFields = (deepLinkData ?? [:]).filter {
            $0.key == "deep_link_value" || $0.key.hasPrefix("deep_link_sub")
        }
        if conversionArrivedFirst {
            deepLinkOwnFields.forEach { if merged[$0.key] == nil { merged[$0.key] = $0.value } }
        } else {
            deepLinkOwnFields.forEach { merged[$0.key] = $0.value }
        }
        return merged
    }

    /// Параметры OneLink/UDL для проброса в URL вебвью: `deep_link_value` и `deep_link_sub*`.
    var deepLinkQueryItems: [URLQueryItem] {
        mergedTrackingData.compactMap { key, value in
            guard key == "deep_link_value" || key.hasPrefix("deep_link_sub") else { return nil }
            let str = "\(value)"
            guard !str.isEmpty, str.lowercased() != "null", str != "<null>" else { return nil }
            return URLQueryItem(name: key, value: str)
        }
    }

    /// Запрашивает ATT (для IDFA), стартует AppsFlyer (единственное место в приложении,
    /// откуда вызывается `start()` — см. AppDelegate) и ждёт И конверсионные данные,
    /// И разрешение UDL-диплинка. Если первый ответ конверсии — Organic, внутри делегата
    /// будет одна перепроверка через 5 c напрямую через install_data HTTP API AppsFlyer
    /// (быстрее, чем заново гонять весь `start()` — один запрос вместо всей цепочки SDK).
    func startAndAwaitConversion(timeout: TimeInterval = 12) async {
        await requestTrackingIfNeeded()
        AppsFlyerLib.shared().start(completionHandler: nil)

        if conversionSettled && deepLinkSettled { return }

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            self.continuation = cont
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
                self?.resume(force: true)
            }
        }
    }

    private func resume(force: Bool = false) {
        guard !didResume else { return }
        guard force || (conversionSettled && deepLinkSettled) else { return }
        didResume = true
        continuation?.resume()
        continuation = nil
    }

    private func requestTrackingIfNeeded() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        _ = await ATTrackingManager.requestTrackingAuthorization()
    }
}

// MARK: - Conversion data
extension AppsFlyerManager: AppsFlyerLibDelegate {
    func onConversionDataSuccess(_ conversionInfo: [AnyHashable: Any]) {
        conversionAttempts += 1
        let data = conversionInfo as? [String: Any] ?? [:]
        let isOrganic = (data["af_status"] as? String)?.caseInsensitiveCompare("organic") == .orderedSame

        conversionData = data

        // Первый ответ — Organic: атрибуция иногда доезжает с задержкой (SKAdNetwork/постбэк),
        // поэтому один раз перепроверяем через 5 c — но лёгким прямым HTTP-запросом к
        // install_data API, а не повторным start() (который заново гоняет всю цепочку SDK:
        // settings/SKAdNetwork rules/ATT — секунды впустую ради того же результата).
        if isOrganic && conversionAttempts == 1 {
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                await self?.recheckViaInstallDataAPI()
            }
            return
        }

        finalizeConversion()
    }

    func onConversionDataFail(_ error: Error) {
        finalizeConversion()
    }

    private func finalizeConversion() {
        conversionSettled = true
        if !deepLinkSettled { conversionArrivedFirst = true }
        resume()
    }

    /// Лёгкая перепроверка атрибуции напрямую через публичный install_data HTTP API
    /// AppsFlyer — один запрос вместо повторной инициализации всего SDK. При сетевой
    /// ошибке или некорректном ответе просто остаёмся с тем, что уже есть (Organic),
    /// не блокируя запуск дальше положенного таймаута.
    private func recheckViaInstallDataAPI() async {
        defer { finalizeConversion() }

        var comps = URLComponents(string: "https://gcdsdk.appsflyer.com/install_data/v4.0/\(Secrets.appleAppID)")
        comps?.queryItems = [
            URLQueryItem(name: "devkey", value: Secrets.appsFlyerDevKey),
            URLQueryItem(name: "device_id", value: appsFlyerUID),
        ]
        guard let url = comps?.url else { return }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        conversionData = json
    }
}

// MARK: - URL helper
extension URL {
    /// Дозаписывает query-параметры, не дублируя уже существующие ключи.
    func appendingQueryItems(_ newItems: [URLQueryItem]) -> URL {
        guard !newItems.isEmpty,
              var comps = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return self }
        var items = comps.queryItems ?? []
        let existing = Set(items.map { $0.name })
        items.append(contentsOf: newItems.filter { !existing.contains($0.name) })
        comps.queryItems = items
        return comps.url ?? self
    }
}

// MARK: - Deep linking (UDL / OneLink)
extension AppsFlyerManager: DeepLinkDelegate {
    func didResolveDeepLink(_ result: DeepLinkResult) {
        if result.status == .found, let deepLink = result.deepLink, deepLinkData == nil {
            deepLinkData = deepLink.clickEvent as? [String: Any] ?? [:]
        }
        deepLinkSettled = true
        resume()
    }
}

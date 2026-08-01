import Foundation

/// Результат обращения к конфиг-эндпоинту.
enum ConfigResult {
    case webview(url: URL, expires: Date?)
    case stub          // ok:false / 404 / некорректный ответ → «фантик»
    case networkError  // сеть/таймаут → на последующих запусках используем сохранённый url
}

/// Сборка тела запроса и обращение к конфигу (раздел 3 ТЗ).
enum ConfigService {

    static func fetch() async -> ConfigResult {
        let body = buildBody()

        var req = URLRequest(url: Secrets.configEndpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 8

        do {
            req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [.prettyPrinted, .sortedKeys])
        } catch {
            return .networkError
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse else { return .networkError }

            // 404 и прочие HTTP-ошибки трактуем как отрицательный ответ → «фантик».
            guard (200...299).contains(http.statusCode) else { return .stub }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return .stub
            }

            let ok = json["ok"] as? Bool ?? false
            guard ok, let urlStr = json["url"] as? String, let url = URL(string: urlStr) else {
                return .stub
            }

            var expires: Date?
            if let ts = json["expires"] as? TimeInterval {
                expires = Date(timeIntervalSince1970: ts)
            } else if let ts = json["expires"] as? Int {
                expires = Date(timeIntervalSince1970: TimeInterval(ts))
            }
            return .webview(url: url, expires: expires)
        } catch {
            return .networkError
        }
    }

    /// Тело = все поля conversion data + UDL (как есть, слитые по приоритету «кто пришёл
    /// первым» — п.3.1) + добавляемые приложением поля.
    private static func buildBody() -> [String: Any] {
        let af = AppsFlyerManager.shared
        var body = af.mergedTrackingData

        // Поля, добавляемые на стороне приложения.
        body["af_id"] = af.appsFlyerUID
        body["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        body["os"] = "iOS"
        body["store_id"] = Secrets.storeID
        body["locale"] = localeRFC3066()

        // Только если Firebase Messaging успешно инициализирован.
        if PushManager.shared.isFirebaseConfigured {
            if let token = PushManager.shared.fcmToken { body["push_token"] = token }
            if let pid = PushManager.shared.firebaseProjectID { body["firebase_project_id"] = pid }
        }

        return body
    }

    /// Локаль в формате RFC 3066: `en`, `ru`, `en_US`…
    private static func localeRFC3066() -> String {
        let loc = Locale.current
        if let lang = loc.language.languageCode?.identifier {
            if let region = loc.region?.identifier { return "\(lang)_\(region)" }
            return lang
        }
        return loc.identifier
    }
}

import Foundation
import Combine

/// Маршрутизатор ссылок из пуш-уведомлений.
/// При тапе по пушу с `data.url` публикует URL, который открывается в WebView.
/// Эта ссылка НЕ сохраняется (см. п.4.3 ТЗ).
final class PushRouter: ObservableObject {
    static let shared = PushRouter()
    private init() {}

    @Published var pendingURL: URL?

    /// FCM обычно кладёт поля из `data` в корень userInfo, но сервер может прислать `url`
    /// и во вложенном виде — проверяем несколько вариантов на случай другого формата пейлоада.
    func handle(userInfo: [AnyHashable: Any]) {
        guard let raw = extractURL(from: userInfo), let url = URL(string: raw) else { return }
        pendingURL = url
    }

    private func extractURL(from payload: [AnyHashable: Any]) -> String? {
        let root = payload as NSDictionary
        func nested(_ any: Any?) -> NSDictionary? { any as? NSDictionary }

        let raw = (root["url"] as? String)
            ?? (nested(root["data"])?["url"] as? String)
            ?? (nested(nested(root["aps"])?["data"])?["url"] as? String)
            ?? (nested(root["custom"])?["url"] as? String)

        guard let raw, !raw.isEmpty else { return nil }
        return raw
    }
}

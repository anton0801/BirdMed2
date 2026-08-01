import Foundation

/// Режим работы приложения, определяется один раз при первом запуске.
enum WrapperMode: String {
    case undecided   // решение ещё не принято
    case webview     // показываем сайт
    case stub        // показываем «фантик» (встроенный контент)
}

/// Тонкая обёртка над UserDefaults для состояния обёртки.
final class WrapperStore {
    static let shared = WrapperStore()
    private let d = UserDefaults.standard
    private init() {}

    private enum Key {
        static let mode = "wrapper_mode"
        static let url = "wrapper_saved_url"
        static let expires = "wrapper_expires"
        static let pushDeclinedAt = "push_last_declined_at"
        static let pushSkipCount = "push_skip_count"
    }

    var mode: WrapperMode {
        get { WrapperMode(rawValue: d.string(forKey: Key.mode) ?? "") ?? .undecided }
        set { d.set(newValue.rawValue, forKey: Key.mode) }
    }

    var savedURL: URL? {
        get { d.string(forKey: Key.url).flatMap { URL(string: $0) } }
        set { d.set(newValue?.absoluteString, forKey: Key.url) }
    }

    var expires: Date? {
        get {
            let t = d.double(forKey: Key.expires)
            return t > 0 ? Date(timeIntervalSince1970: t) : nil
        }
        set {
            if let nv = newValue { d.set(nv.timeIntervalSince1970, forKey: Key.expires) }
            else { d.removeObject(forKey: Key.expires) }
        }
    }

    /// true, если ссылка протухла (или срок не задан).
    var isExpired: Bool {
        guard let e = expires else { return true }
        return Date() >= e
    }

    /// Дата последнего Skip на КАСТОМНОМ pre-permission экране.
    var pushDeclinedAt: Date? {
        get {
            let t = d.double(forKey: Key.pushDeclinedAt)
            return t > 0 ? Date(timeIntervalSince1970: t) : nil
        }
        set {
            if let nv = newValue { d.set(nv.timeIntervalSince1970, forKey: Key.pushDeclinedAt) }
            else { d.removeObject(forKey: Key.pushDeclinedAt) }
        }
    }

    /// Сколько раз пользователь нажал Skip на кастомном экране.
    /// 0 — показываем; 1 — показываем снова через 3 дня; ≥2 — больше не показываем.
    var pushSkipCount: Int {
        get { d.integer(forKey: Key.pushSkipCount) }
        set { d.set(newValue, forKey: Key.pushSkipCount) }
    }
}

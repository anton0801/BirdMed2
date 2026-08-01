import Foundation
import FirebaseCore
import FirebaseMessaging

/// Обёртка над Firebase Messaging: инициализация, FCM-токен, project id.
final class PushManager: NSObject {
    static let shared = PushManager()
    private override init() {}

    private(set) var fcmToken: String?

    var isFirebaseConfigured: Bool { FirebaseApp.app() != nil }
    var firebaseProjectID: String? { FirebaseApp.app()?.options.projectID }

    /// Конфигурируем Firebase только при наличии GoogleService-Info.plist,
    /// иначе просто не используем push-поля (см. ТЗ п.1.1/3.1).
    func configureFirebaseIfPossible() {
        guard let plistURL = Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") else {
            return
        }
        if FirebaseApp.app() == nil {
            // Явный путь надёжнее автоматического поиска ресурса при выключенном
            // Firebase App Delegate proxy и в конфигурации симулятора.
            guard let options = FirebaseOptions(contentsOfFile: plistURL.path) else {
                return
            }
            FirebaseApp.configure(options: options)
        }
        Messaging.messaging().delegate = self
    }

    /// Пытается получить свежий FCM-токен (с таймаутом, чтобы не тормозить запуск).
    @discardableResult
    func fetchToken(timeout: TimeInterval = 5) async -> String? {
        guard isFirebaseConfigured else { return nil }
        if let t = fcmToken { return t }

        return await withCheckedContinuation { (cont: CheckedContinuation<String?, Never>) in
            var resumed = false
            Messaging.messaging().token { [weak self] token, _ in
                guard !resumed else { return }
                resumed = true
                self?.fcmToken = token
                cont.resume(returning: token)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
                guard !resumed else { return }
                resumed = true
                cont.resume(returning: self?.fcmToken)
            }
        }
    }
}

extension PushManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        self.fcmToken = fcmToken
    }
}

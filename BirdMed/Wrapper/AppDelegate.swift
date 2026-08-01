import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

/// UIApplicationDelegate: инициализация SDK и обработка пушей.
/// Method swizzling Firebase отключён (FirebaseAppDelegateProxyEnabled=NO в Info.plist),
/// поэтому APNs-токен и пуши прокидываем в Messaging вручную.
final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        PushManager.shared.configureFirebaseIfPossible()
        AppsFlyerManager.shared.configure()
        UNUserNotificationCenter.current().delegate = self

        // Холодный старт по тапу на пуш.
        if let userInfo = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            PushRouter.shared.handle(userInfo: userInfo)
        }
        return true
    }

    // Единственное место, откуда стартует AppsFlyer SDK — AppsFlyerManager.startAndAwaitConversion(),
    // вызываемое из RootViewModel на каждом запуске. Вызывать AppsFlyerLib.start() ещё и здесь
    // (на каждой активации) не нужно и вредно: конкурирующий/повторный start() создавал гонку,
    // из-за которой AppsFlyerManager.continuation мог быть создан уже ПОСЛЕ того, как SDK
    // отдал конверсию первому (этому) вызову — и onConversionDataSuccess у делегата не срабатывал.

    // MARK: - APNs
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Не удалось зарегистрироваться — push-поля просто не отправятся.
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        PushRouter.shared.handle(userInfo: response.notification.request.content.userInfo)
        completionHandler()
    }
}

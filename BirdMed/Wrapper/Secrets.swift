import Foundation

/// Значения, специфичные для конкретной установки/кабинета.
/// TODO помечены поля, которые нужно заполнить перед публикацией.
enum Secrets {
    /// Эндпоинт конфига (выдаёт менеджер). Формат: https://.../config.php
    static let configEndpoint = URL(string: "https://biirdmeed.com/config.php")!

    /// AppsFlyer dev key из кабинета AppsFlyer.
    static let appsFlyerDevKey = "3qmxcNHLp5omqHSGhDerpU"

    /// Apple ID приложения в формате idXXXXXXXXX (с префиксом "id" — этого формата
    /// ждёт и AppsFlyerLib.appleAppID, и store_id в конфиге).
    static let appleAppID = "id6778827213"

    /// store_id в формате idXXXXXXXX (с префиксом "id"), передаётся в конфиг.
    static let storeID = appleAppID
}

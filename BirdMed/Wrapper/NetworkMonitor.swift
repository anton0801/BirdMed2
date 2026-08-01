import Foundation
import Network
import Combine

/// Мониторинг доступности сети (Network framework). Событийный: `pathUpdateHandler`
/// обновляет `isOnline` мгновенно при любом изменении статуса сети, а не по опросу —
/// поэтому обрыв связи детектируется сразу, а не только когда кто-то решит проверить.
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.storagebuild.networkmonitor")

    @Published private(set) var isOnline: Bool = true

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let satisfied = path.status == .satisfied
            DispatchQueue.main.async {
                self?.isOnline = satisfied
            }
        }
        monitor.start(queue: queue)
    }

    /// Разовая проверка для явных guard'ов в асинхронном коде: если `pathUpdateHandler`
    /// ещё не успел сработать хотя бы раз при самом первом запуске — недолго ждём его.
    func currentStatus() async -> Bool {
        for _ in 0..<10 {
            if isOnline { return true }
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        }
        return isOnline
    }
}

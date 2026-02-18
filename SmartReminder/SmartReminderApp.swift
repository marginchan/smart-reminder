import SwiftUI
import UserNotifications
import SwiftData

#if canImport(UIKit)
import UIKit
#endif

@main
struct SmartReminderApp: App {
    #if canImport(UIKit)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            LaunchScreenView()
                .modelContainer(for: [Reminder.self, ReminderCategory.self, Note.self])
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                // 当 app 回到前台时，清除 badge 和已送达通知
                NotificationManager.shared.clearBadge()
                NotificationManager.shared.clearDeliveredNotifications()
            }
        }
    }
}

#if canImport(UIKit)
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("通知权限已获取")
            } else if let error = error {
                print("通知权限请求失败: \(error.localizedDescription)")
            }
        }
        return true
    }
    
    // 前台收到通知时也显示
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    // 用户点击通知时清除 badge
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        NotificationManager.shared.clearBadge()
        completionHandler()
    }
}
#endif

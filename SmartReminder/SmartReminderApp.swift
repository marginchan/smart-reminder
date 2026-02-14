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
    
    var body: some Scene {
        WindowGroup {
            LaunchScreenView()
                .modelContainer(for: [Reminder.self, ReminderCategory.self, Note.self])
        }
    }
}

#if canImport(UIKit)
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("通知权限已获取")
            } else if let error = error {
                print("通知权限请求失败: \(error.localizedDescription)")
            }
        }
        return true
    }
}
#endif

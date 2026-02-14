import Foundation

struct LunarFestivalInfo {
    let lunarText: String
    let festival: String?
    
    var displayText: String {
        festival ?? lunarText
    }
}

final class LunarFestivalService {
    static let shared = LunarFestivalService()
    
    private let lunarCalendar = Calendar(identifier: .chinese)
    private let gregorianCalendar = Calendar(identifier: .gregorian)
    
    private let lunarMonthNames = [
        "正月", "二月", "三月", "四月", "五月", "六月",
        "七月", "八月", "九月", "十月", "冬月", "腊月"
    ]
    
    private let lunarDayNames = [
        "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
        "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
        "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
    ]
    
    private let solarFestivals: [String: String] = [
        "1-1": "元旦",
        "2-14": "情人节",
        "3-8": "妇女节",
        "4-1": "愚人节",
        "5-1": "劳动节",
        "6-1": "儿童节",
        "10-1": "国庆",
        "12-25": "圣诞"
    ]
    
    private let lunarFestivals: [String: String] = [
        "1-1": "春节",
        "1-15": "元宵",
        "5-5": "端午",
        "7-7": "七夕",
        "8-15": "中秋",
        "9-9": "重阳",
        "12-8": "腊八",
        "12-23": "小年"
    ]
    
    private init() {}
    
    func info(for date: Date) -> LunarFestivalInfo {
        let lunarComponents = lunarCalendar.dateComponents([.month, .day, .isLeapMonth], from: date)
        let lunarMonth = lunarComponents.month ?? 1
        let lunarDay = lunarComponents.day ?? 1
        let isLeap = lunarComponents.isLeapMonth ?? false
        
        let lunarText = lunarDayText(month: lunarMonth, day: lunarDay, isLeap: isLeap)
        let festival = lunarFestivals["\(lunarMonth)-\(lunarDay)"] ?? solarFestivals[solarKey(for: date)]
        return LunarFestivalInfo(lunarText: lunarText, festival: festival)
    }
    
    private func solarKey(for date: Date) -> String {
        let month = gregorianCalendar.component(.month, from: date)
        let day = gregorianCalendar.component(.day, from: date)
        return "\(month)-\(day)"
    }
    
    private func lunarDayText(month: Int, day: Int, isLeap: Bool) -> String {
        let safeMonthIndex = max(1, min(month, lunarMonthNames.count)) - 1
        let safeDayIndex = max(1, min(day, lunarDayNames.count)) - 1
        let monthName = lunarMonthNames[safeMonthIndex]
        let dayName = lunarDayNames[safeDayIndex]
        
        if day == 1 {
            return (isLeap ? "闰" : "") + monthName
        }
        return dayName
    }
}

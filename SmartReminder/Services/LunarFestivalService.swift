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
        "3-12": "植树节",
        "4-1": "愚人节",
        "5-1": "劳动节",
        "5-4": "青年节",
        "5-12": "护士节",
        "6-1": "儿童节",
        "7-1": "建党节",
        "8-1": "建军节",
        "9-10": "教师节",
        "10-1": "国庆节",
        "10-31": "万圣夜",
        "11-1": "万圣节",
        "12-24": "平安夜",
        "12-25": "圣诞节"
    ]
    
    private let lunarFestivals: [String: String] = [
        "1-1": "春节",
        "1-15": "元宵节",
        "2-2": "龙抬头",
        "5-5": "端午节",
        "7-7": "七夕节",
        "7-15": "中元节",
        "8-15": "中秋节",
        "9-9": "重阳节",
        "10-1": "寒衣节",
        "12-8": "腊八节",
        "12-23": "小年"
    ]
    
    private init() {}
    
    func info(for date: Date) -> LunarFestivalInfo {
        let lunarComponents = lunarCalendar.dateComponents([.month, .day, .isLeapMonth], from: date)
        let lunarMonth = lunarComponents.month ?? 1
        let lunarDay = lunarComponents.day ?? 1
        let isLeap = lunarComponents.isLeapMonth ?? false
        
        let lunarText = lunarDayText(month: lunarMonth, day: lunarDay, isLeap: isLeap)
        let festival = resolveFestival(for: date, lunarMonth: lunarMonth, lunarDay: lunarDay)
        return LunarFestivalInfo(lunarText: lunarText, festival: festival)
    }
    
    private func solarKey(for date: Date) -> String {
        let month = gregorianCalendar.component(.month, from: date)
        let day = gregorianCalendar.component(.day, from: date)
        return "\(month)-\(day)"
    }
    
    private func resolveFestival(for date: Date, lunarMonth: Int, lunarDay: Int) -> String? {
        if isLunarNewYearEve(month: lunarMonth, day: lunarDay, date: date) {
            return "除夕"
        }
        
        let lunarFestival = lunarFestivals["\(lunarMonth)-\(lunarDay)"]
        if let lunarFestival { return lunarFestival }
        
        let solarFestival = solarFestivals[solarKey(for: date)]
        if let solarFestival { return solarFestival }
        
        return dynamicSolarFestival(for: date)
    }
    
    private func dynamicSolarFestival(for date: Date) -> String? {
        if isMotherDay(date) { return "母亲节" }
        if isFatherDay(date) { return "父亲节" }
        if isThanksgiving(date) { return "感恩节" }
        if isQingming(date) { return "清明节" }
        return nil
    }
    
    private func isMotherDay(_ date: Date) -> Bool {
        isNthWeekdayInMonth(date, weekday: 1, ordinal: 2, month: 5)
    }
    
    private func isFatherDay(_ date: Date) -> Bool {
        isNthWeekdayInMonth(date, weekday: 1, ordinal: 3, month: 6)
    }
    
    // 感恩节：11月的第4个星期四 (weekday = 5)
    private func isThanksgiving(_ date: Date) -> Bool {
        isNthWeekdayInMonth(date, weekday: 5, ordinal: 4, month: 11)
    }
    
    private func isNthWeekdayInMonth(_ date: Date, weekday: Int, ordinal: Int, month: Int) -> Bool {
        let components = gregorianCalendar.dateComponents([.year, .month, .weekday, .weekdayOrdinal], from: date)
        return components.month == month && components.weekday == weekday && components.weekdayOrdinal == ordinal
    }
    
    private func isQingming(_ date: Date) -> Bool {
        let year = gregorianCalendar.component(.year, from: date)
        let day = gregorianCalendar.component(.day, from: date)
        let month = gregorianCalendar.component(.month, from: date)
        if month != 4 { return false }
        let qingmingDay = qingmingDayInApril(for: year)
        return day == qingmingDay
    }
    
    private func qingmingDayInApril(for year: Int) -> Int {
        // 常用简化算法：20.8431 + 0.2422*(year-1900) - (year-1900)/4
        let y = year - 1900
        let day = Int(20.8431 + 0.2422 * Double(y) - Double(y / 4))
        return max(4, min(day, 5))
    }
    
    private func isLunarNewYearEve(month: Int, day: Int, date: Date) -> Bool {
        guard month == 12 else { return false }
        let lastDay = lunarLastDayOfMonth(for: date)
        return day == lastDay
    }
    
    private func lunarLastDayOfMonth(for date: Date) -> Int {
        let range = lunarCalendar.range(of: .day, in: .month, for: date)
        return range?.count ?? 30
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

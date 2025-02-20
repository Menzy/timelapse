import Foundation

struct Event: Identifiable, Codable {
    let id: UUID
    let title: String
    let targetDate: Date
    let creationDate: Date
    
    init(title: String, targetDate: Date, creationDate: Date = Date()) {
        self.id = UUID()
        self.title = title
        self.targetDate = targetDate
        self.creationDate = creationDate
    }
    
    init(id: UUID, title: String, targetDate: Date, creationDate: Date) {
        self.id = id
        self.title = title
        self.targetDate = targetDate
        self.creationDate = creationDate
    }
    
    func progressDetails() -> (daysLeft: Int, totalDays: Int) {
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.startOfDay(for: now)
        let targetDate = calendar.startOfDay(for: self.targetDate)
        
        // Get days between today and target date
        let daysLeft = max(0, (calendar.dateComponents([.day], from: startDate, to: targetDate).day ?? 0) - 1)  // FIXED
        
        // Calculate total days from the start of the year to the target date for the year tracker
        if title == String(calendar.component(.year, from: now)) {
            let startOfYear = calendar.date(from: DateComponents(year: calendar.component(.year, from: now), month: 1, day: 1))!
            let totalDays = calendar.dateComponents([.day], from: startOfYear, to: targetDate).day ?? 365
            return (daysLeft, totalDays)
        }
        
        // Calculate total days from creation date to target date for other events
        let totalDays = max(1, calendar.dateComponents([.day], from: calendar.startOfDay(for: creationDate), to: targetDate).day ?? 1)
        return (daysLeft, totalDays)
    }
    
    static func defaultYearTracker() -> Event {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let endOfYear = calendar.date(from: DateComponents(year: currentYear + 1, month: 1, day: 1))!
        return Event(title: "\(currentYear)", targetDate: endOfYear)
    }
}
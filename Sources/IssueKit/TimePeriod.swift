//
//  File.swift
//  
//
//  Created by Saultz, Ian on 9/28/22.
//

import Foundation

struct TimePeriod {
    static var calendar: Calendar { Calendar.current }

    private static func bySubstracting(component: DateComponents, from date: Date) -> Date {
        Self.calendar.date(byAdding: component, to: date)!
    }

    let description: String
    let start: (Date) -> Date

    static var oneWeek: TimePeriod {
        TimePeriod(description: "week") { today in
            bySubstracting(component: DateComponents(day: -7), from: today)
        }
    }

    static var oneMonth: TimePeriod {
        TimePeriod(description: "month") { today in
            bySubstracting(component: DateComponents(month: -1), from: today)
        }
    }

    static var threeMonths: TimePeriod {
        TimePeriod(description: "three months") { today in
            bySubstracting(component: DateComponents(month: -3), from: today)
        }
    }

    static var sixMonths: TimePeriod {
        TimePeriod(description: "six months") { today in
            bySubstracting(component: DateComponents(month: -6), from: today)
        }
    }

    static var oneYear: TimePeriod {
        TimePeriod(description: "year") { today in
            bySubstracting(component: DateComponents(year: -1), from: today)
        }
    }
}

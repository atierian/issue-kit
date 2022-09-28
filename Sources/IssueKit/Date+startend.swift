//
//  File.swift
//  
//
//  Created by Saultz, Ian on 9/28/22.
//

import Foundation

extension Date {
    static func endOf(month: Int, in year: Int) -> Date {
        let calendar = Calendar.current
        var components = DateComponents(calendar: calendar, year: year, month: month)
        components.setValue(month + 1, for: .month)
        components.setValue(1, for: .day)
        components.setValue(-1, for: .second)
        let date = calendar.date(from: components)
        return date!
    }

    static func startOf(month: Int, in year: Int) -> Date {
        let calendar = Calendar.current
        var components = DateComponents(calendar: calendar, year: year, month: month)
        components.setValue(month, for: .month)
        components.setValue(1, for: .day)
        let date = calendar.date(from: components)
        return date!
    }

    var readable: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: self)
    }
}

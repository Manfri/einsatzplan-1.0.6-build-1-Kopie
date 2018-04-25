//
//  ExtensionDate.swift
//  todoios
//
//  Created by Ilja Faerman on 15/08/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

import Foundation
import SystemConfiguration

extension  Date {
    func startOfWeek(_ weekday: Int?) -> Date? {
        
            var cal: Calendar = Calendar.current
        let comp: DateComponents = (cal as NSCalendar).components([.yearForWeekOfYear, .weekOfYear], from: self)
        
        cal.firstWeekday = weekday ?? 1
        return cal.date(from: comp)!
    }
    
    func endOfWeek(_ weekday: Int) -> Date? {
        
            let cal: Calendar = Calendar.current
            var comp: DateComponents = (cal as NSCalendar).components([.weekOfYear], from: self)
        comp.weekOfYear = 1
        comp.day = comp.day! - 1
        
        return (cal as NSCalendar).date(byAdding: comp, to: self.startOfWeek(weekday)!, options: [])!
    }
}

internal extension DateComponents {
    mutating func to12pm() {
        self.hour = 12
        self.minute = 0
        self.second = 0
    }
}

func getWeek(_ today:Date) -> Int {
    let myCalendar = Calendar(identifier: Calendar.Identifier.iso8601)
    let myComponents = (myCalendar as NSCalendar).components(.weekOfYear, from: today)
    let weekNumber = myComponents.weekOfYear
    return weekNumber!
}

func getYear(_ today:Date) -> Int {
    let myCalendar = Calendar(identifier: Calendar.Identifier.iso8601)
    let myComponents = (myCalendar as NSCalendar).components(.year, from: today)
    let yearNumber = myComponents.year
    return yearNumber!
}


func addDayToDate(_ startDate: Date, day:Int) -> Date{
    
    let newDate = (Calendar.current as NSCalendar)
        .date(
            byAdding: .day,
            value: day,
            to: startDate,
            options: []
    )
    return newDate!
}

func getFirstDateOfWeek(_ myWeek: Int) -> String {
    let myCalendar = Calendar(identifier: Calendar.Identifier.iso8601)
    var components = (myCalendar as NSCalendar).components([.year , .weekOfYear , .weekday], from: Date())
    
    (components as NSDateComponents).calendar = myCalendar
    
    components.weekday = 2 // 2 = Monday
    components.weekOfYear = myWeek
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd.MM"
    return String(dateFormatter.string(from: myCalendar.date(from: components)!))
}


func getLastDateOfWeek(_ myWeek: Int) -> String {
    let myCalendar = Calendar(identifier: Calendar.Identifier.iso8601)
    var components = (myCalendar as NSCalendar).components([.year , .weekOfYear , .weekday], from: Date())
    
    (components as NSDateComponents).calendar = myCalendar
    
    components.weekday = 2 // 2 = Monday
    components.weekOfYear = myWeek
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd.MM"
    return String(dateFormatter.string(from: addDayToDate(myCalendar.date(from: components)!,day:5)))
}


func isConnectedToNetwork() -> Bool {
    var zeroAddress = sockaddr_in()
    zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
    zeroAddress.sin_family = sa_family_t(AF_INET)
    
    let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
            SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
        }
    }
    /*
    let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
        SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
    }
    */
    var flags = SCNetworkReachabilityFlags()
    if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
        return false
    }
    let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
    let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
    return (isReachable && !needsConnection)
}



import Foundation

/// Records the actual process settings for isolated simulator comparisons.
/// It does not select a calendar, replace app state or change product controls.
enum CalendarParityFixture {
    static func record(){
        #if DEBUG
        let env=ProcessInfo.processInfo.environment
        guard env["PIYALI_OFFLINE_TESTS"]=="1",env["PIYALI_CALENDAR_PROBE"]=="1",let scope=env["PIYALI_TEST_IDENTITY_SCOPE"],UUID(uuidString:scope) != nil else{return}
        let now=Date(),calendar=Calendar.current,root=FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("Piyali/CalendarProbe",isDirectory:true)
        let fields:[String:Any]=["calendar":String(describing:calendar.identifier),"locale":Locale.current.identifier,"timeZone":calendar.timeZone.identifier,"systemYear":calendar.component(.year,from:now),"dayKey":CalendarDay.key(now),"queryYear":CalendarDay.year(now)]
        do{try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true);try JSONSerialization.data(withJSONObject:fields,options:.sortedKeys).write(to:root.appendingPathComponent(scope+"-"+String(describing:calendar.identifier)+".json"),options:.atomic)}catch{}
        #endif
    }
}

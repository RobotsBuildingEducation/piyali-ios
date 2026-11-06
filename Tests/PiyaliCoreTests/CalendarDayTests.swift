import XCTest
@testable import PiyaliCore

final class CalendarDayTests:XCTestCase {
    static let calendars:[Calendar.Identifier]=[.gregorian,.buddhist,.chinese,.coptic,.ethiopicAmeteMihret,.ethiopicAmeteAlem,.hebrew,.iso8601,.indian,.islamic,.islamicCivil,.japanese,.persian,.republicOfChina,.islamicTabular,.islamicUmmAlQura]
    private func calendar(_ id:Calendar.Identifier,_ zone:String)throws->Calendar{var c=Calendar(identifier:id);c.timeZone=try XCTUnwrap(TimeZone(identifier:zone));return c}
    func testSharedKeysYearAndShiftMatchOriginalSourceAcrossAllSystemCalendars()throws{
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/calendar-days.json"),fixtures=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:url));XCTAssertEqual(fixtures["cases"].array.count,144)
        for id in Self.calendars{
            for row in fixtures["cases"].array{let c=try calendar(id,row["zone"].string),date=try XCTUnwrap(WebProgressContract.date(row["iso"].string)),label="\(id): "+row.json;XCTAssertEqual(CalendarDay.key(date,calendar:c),row["day"].string,label);XCTAssertEqual(CalendarDay.year(date,calendar:c),Int(row["year"].number),label);XCTAssertEqual(CalendarDay.gregorian(c).timeZone,c.timeZone)
                for shift in row["shifts"].array{XCTAssertEqual(CalendarDay.shift(row["day"].string,by:Int(shift["amount"].number),calendar:c),shift["expected"].string,label)}
            }
            for row in fixtures["edge"].array{XCTAssertEqual(CalendarDay.shift(row["day"].string,by:Int(row["amount"].number),calendar:try calendar(id,row["zone"].string)),row["expected"].string,"\(id): "+row.json)}
        }
    }
    func testAwardRolloverStreakAndCalendarSelectionCannotChangeOperationDay()throws{
        let now=try XCTUnwrap(WebProgressContract.date("2026-10-28T12:00:00Z"))
        for id in Self.calendars{let c=try calendar(id,"America/Mexico_City");var state=LearnerState();state.dailyKey="2026-10-27";state.dailyXP=50;state.dailyGoal=50;state.streak=3;state.award(5,now:now,calendar:c);XCTAssertEqual(state.dailyKey,"2026-10-28");XCTAssertEqual(state.dailyXP,5);XCTAssertEqual(state.streak,3);XCTAssertEqual(state.pendingChanges?.last?.dayKey,"2026-10-28");state.rollDay(now:now.addingTimeInterval(86400),calendar:c);XCTAssertEqual(state.dailyKey,"2026-10-29");XCTAssertEqual(state.dailyXP,0);XCTAssertEqual(state.streak,0);XCTAssertEqual(state.totalXP,5)}
    }
    func testExistingHistoricalKeysAndReceiptIDsAreNotGuessedOrRewritten()throws{
        let historical=PracticeChange(dayKey:"2569-10-28",target:"es",level:"A1",amount:5,source:.practice),decoded=try JSONDecoder().decode(PracticeChange.self,from:JSONEncoder().encode(historical));XCTAssertEqual(decoded.id,historical.id);XCTAssertEqual(decoded.dayKey,"2569-10-28");XCTAssertEqual(decoded.date,historical.date);XCTAssertEqual(CalendarDay.normalize("2569-10-28"),"2569-10-28")
    }
}

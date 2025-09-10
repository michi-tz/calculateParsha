local p = {}
local getArgs = require('Module:Arguments').getArgs
local yesno = require('Module:Yesno')
local lang = mw.language.getContentLanguage()
local hebrewDate = require('Module:HebrewDate')
local holidayChecker = require('Module:HolidayChecker')

-- רשימת פרשיות השבוע בסדר
local parshiot = {
    "בראשית", "נח", "לך לך", "וירא", "חיי שרה", "תולדות", "ויצא", "וישלח", "וישב", "מקץ", "ויגש", "ויחי",
    "שמות", "וארא", "בא", "בשלח", "יתרו", "משפטים", "תרומה", "תצוה", "כי תשא", "ויקהל", "פקודי",
    "ויקרא", "צו", "שמיני", "תזריע", "מצורע", "אחרי מות", "קדושים", "אמור", "בהר", "בחקתי",
    "במדבר", "נשא", "בהעלתך", "שלח לך", "קרח", "חקת", "בלק", "פינחס", "מטות", "מסעי",
    "דברים", "ואתחנן", "עקב", "ראה", "שפטים", "כי תצא", "כי תבוא", "נצבים", "וילך", "האזינו", "וזאת הברכה"
}

-- פונקציה לחישוב פרשת השבוע (ללא חגים - בסיסי)
local function calculateRegularParsha(year, month, day)
    -- קבלת מידע מפורט על התאריך העברי
    local hebrewInfo = hebrewDate.getHebrewDateInfo(year, month, day)
    
    -- חישוב מספר השבוע מתחילת השנה העברית (תשרי)
    -- זהו חישוב בסיסי שצריך שיפור למדויק יותר
    
    local hebrewYear = hebrewInfo.hebrewYear
    local monthNumber = hebrewDate.getHebrewMonthNumber(hebrewInfo.hebrewMonth)
    local dayInMonth = hebrewInfo.hebrewDay
    
    -- חישוב קירוב לשבוע בשנה העברית
    -- התחלה מתשרי (חודש 1)
    local approximateWeek = 0
    
    -- הוספת שבועות מחודשים קודמים
    for month = 1, monthNumber - 1 do
        approximateWeek = approximateWeek + 4 -- ממוצע של 4 שבועות לחודש
    end
    
    -- הוספת שבועות מהחודש הנוכחי
    approximateWeek = approximateWeek + math.floor(dayInMonth / 7)
    
    -- התאמה למחזור הפרשיות (52 פרשיות)
    local parshaIndex = (approximateWeek % #parshiot) + 1
    
    if parshaIndex > #parshiot then
        parshaIndex = parshaIndex - #parshiot
    end
    
    return parshiot[parshaIndex] or "לא נמצא"
end

-- הפונקציה העיקרית לקבלת פרשת השבוע
function p.getParsha(frame)
    local args = getArgs(frame)
    
    -- קבלת התאריך הנוכחי או התאריך הנתון
    local currentTime = os.time()
    local year, month, day
    
    if args.date then
        year, month, day = args.date:match("(%d+)-(%d+)-(%d+)")
        if year and month and day then
            year, month, day = tonumber(year), tonumber(month), tonumber(day)
        else
            return "שגיאה: פורמט תאריך לא תקין. השתמש בפורמט: YYYY-MM-DD"
        end
    else
        local currentDate = os.date("*t", currentTime)
        year = currentDate.year
        month = currentDate.month  
        day = currentDate.day
    end
    
    -- אם התאריך הנתון אינו שבת, מצא את השבת הקרובה
    if not hebrewDate.isSaturday(year, month, day) then
        year, month, day = hebrewDate.getNextSaturday(year, month, day)
    end
    
    -- בדיקה אם יש חג בשבת הזו שמחליף את הפרשה
    local isHoliday, holidayName, holidayReading = holidayChecker.checkHolidayOnSaturday(year, month, day)
    
    if isHoliday then
        -- החזרת קריאת החג
        local result = "'''חג: " .. holidayName .. "'''\n\n"
        if holidayReading then
            result = result .. "'''קריאת התורה:''' " .. (holidayReading.torah or "") .. "\n\n"
            if holidayReading.maftir then
                result = result .. "'''מפטיר:''' " .. holidayReading.maftir .. "\n\n"
            end
            if holidayReading.haftarah then  
                result = result .. "'''הפטרה:''' " .. holidayReading.haftarah
            end
        end
        return result
    else
        -- חישוב פרשה רגילה
        local parsha = calculateRegularParsha(year, month, day)
        return "'''פרשת " .. parsha .. "'''"
    end
end

-- פונקציה עזר להחזרת רשימת כל הפרשיות
function p.listAllParshiot(frame)
    local result = {}
    for i, parsha in ipairs(parshiot) do
        table.insert(result, i .. ". פרשת " .. parsha)
    end
    return table.concat(result, "\n")
end

-- פונקציה לבדיקה האם תאריך נתון הוא חג
function p.checkIfHoliday(frame)
    local args = getArgs(frame)
    
    if not args.date then
        return "שגיאה: חסר פרמטר date"
    end
    
    local year, month, day = args.date:match("(%d+)-(%d+)-(%d+)")
    if not (year and month and day) then
        return "שגיאה: פורמט תאריך לא תקין"
    end
    
    year, month, day = tonumber(year), tonumber(month), tonumber(day)
    
    -- קבלת מידע מפורט על התאריך העברי
    local hebrewInfo = hebrewDate.getHebrewDateInfo(year, month, day)
    
    -- בדיקה אם זה חג
    local isHoliday, holidayName = holidayChecker.isHolidayThatReplacesTorah(
        hebrewInfo.hebrewYear, 
        hebrewInfo.hebrewMonth, 
        hebrewInfo.hebrewDay
    )
    
    if isHoliday then
        return string.format("כן - %s (%d ב%s %d)", 
            holidayName, 
            hebrewInfo.hebrewDay, 
            hebrewInfo.hebrewMonth, 
            hebrewInfo.hebrewYear
        )
    else
        return string.format("לא (%d ב%s %d)", 
            hebrewInfo.hebrewDay, 
            hebrewInfo.hebrewMonth, 
            hebrewInfo.hebrewYear
        )
    end
end

-- פונקציה חדשה: קבלת מידע מפורט על תאריך
function p.getDateInfo(frame)
    local args = getArgs(frame)
    
    if not args.date then
        return "שגיאה: חסר פרמטר date"
    end
    
    local year, month, day = args.date:match("(%d+)-(%d+)-(%d+)")
    if not (year and month and day) then
        return "שגיאה: פורמט תאריך לא תקין"
    end
    
    year, month, day = tonumber(year), tonumber(month), tonumber(day)
    
    -- קבלת מידע מפורט
    local hebrewInfo = hebrewDate.getHebrewDateInfo(year, month, day)
    
    local result = string.format(
        "'''תאריך גרגוריאני:''' %d-%02d-%02d\n" ..
        "'''תאריך עברי:''' %d ב%s %d\n" ..
        "'''יום בשבוע:''' %s\n" ..
        "'''שנה מעוברת:''' %s",
        year, month, day,
        hebrewInfo.hebrewDay, hebrewInfo.hebrewMonth, hebrewInfo.hebrewYear,
        hebrewInfo.dayName,
        hebrewInfo.isLeapYear and "כן" or "לא"
    )
    
    return result
end

return p

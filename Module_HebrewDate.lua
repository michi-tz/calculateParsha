local p = {}

-- פונקציות עזר לחישובי תאריכים עבריים
-- משתמש בספריות מדיה ויקי הקיימות

-- המרת תאריך גרגוריאני לתאריך עברי
function p.gregorianToHebrew(year, month, day)
    -- שימוש בפונקציית המרה של מדיה ויקי
    local lang = mw.language.new('he') -- עברית
    local timestamp = lang:formatDate('U', string.format('%04d-%02d-%02d', year, month, day))
    
    -- המרה לתאריך עברי באמצעות מדיה ויקי
    local hebrewDate = lang:formatDate('xij xin xiY', '@' .. timestamp)
    
    -- פירוק התאריך העברי
    local hebrewDay, hebrewMonthName, hebrewYear = hebrewDate:match('(%d+) (%S+) (%d+)')
    
    if hebrewDay and hebrewMonthName and hebrewYear then
        return tonumber(hebrewYear), hebrewMonthName, tonumber(hebrewDay)
    else
        -- fallback למקרה של שגיאה
        return p.gregorianToHebrewFallback(year, month, day)
    end
end

-- פונקציית fallback במקרה של כשל בפונקציית מדיה ויקי
function p.gregorianToHebrewFallback(year, month, day)
    -- חישוב בסיסי כפי שהיה קודם
    local hebrewYear = year + 3760
    local daysSinceEpoch = math.floor(os.time({year = year, month = month, day = day}) / 86400)
    
    local hebrewMonth, hebrewDay = p.calculateHebrewDate(hebrewYear, daysSinceEpoch)
    return hebrewYear, hebrewMonth, hebrewDay
end

-- חישוב החודש והיום העברי (פונקציה עזר)
function p.calculateHebrewDate(hebrewYear, daysSinceEpoch)
    -- רשימת חודשים עבריים
    local hebrewMonths = {
        "תשרי", "חשון", "כסלו", "טבת", "שבט", "אדר",
        "ניסן", "אייר", "סיון", "תמוז", "אב", "אלול"
    }
    
    -- בדיקה אם השנה מעוברת
    local isLeapYear = p.isHebrewLeapYear(hebrewYear)
    if isLeapYear then
        table.insert(hebrewMonths, 6, "אדר א'")
        hebrewMonths[7] = "אדר ב'"
    end
    
    -- חישוב קירוב לחודש ויום
    -- זהו חישוב מפושט - במדיה ויקי יש אלגוריתמים מדויקים יותר
    local approximateMonth = ((daysSinceEpoch % 354) / 29) + 1
    local monthIndex = math.floor(approximateMonth)
    local dayInMonth = (daysSinceEpoch % 29) + 1
    
    -- וידוא שהאינדקס תקין
    if monthIndex > #hebrewMonths then
        monthIndex = monthIndex % #hebrewMonths
    end
    if monthIndex < 1 then
        monthIndex = 1
    end
    
    return hebrewMonths[monthIndex], math.floor(dayInMonth)
end

-- בדיקה אם שנה עברית מעוברת
function p.isHebrewLeapYear(year)
    -- מחזור של 19 שנה, 7 מהן מעוברות
    local cycle = year % 19
    local leapYears = {3, 6, 8, 11, 14, 17, 0}
    
    for _, leapYear in ipairs(leapYears) do
        if cycle == leapYear then
            return true
        end
    end
    return false
end

-- בדיקה איזה יום בשבוע (0 = ראשון, 6 = שבת)
function p.getDayOfWeek(year, month, day)
    -- שימוש בפונקציות מדיה ויקי
    local lang = mw.language.new('he')
    local timestamp = lang:formatDate('U', string.format('%04d-%02d-%02d', year, month, day))
    local dayOfWeek = tonumber(lang:formatDate('w', '@' .. timestamp))
    
    -- המרה מפורמט מדיה ויקי (0=ראשון) למה שאנחנו צריכים
    return dayOfWeek
end

-- פונקציה מתקדמת לקבלת מידע מלא על תאריך עברי
function p.getHebrewDateInfo(year, month, day)
    local lang = mw.language.new('he')
    local timestamp = lang:formatDate('U', string.format('%04d-%02d-%02d', year, month, day))
    
    -- קבלת מידע מפורט
    local info = {
        hebrewDay = tonumber(lang:formatDate('xij', '@' .. timestamp)),
        hebrewMonth = lang:formatDate('xin', '@' .. timestamp),
        hebrewYear = tonumber(lang:formatDate('xiY', '@' .. timestamp)),
        dayOfWeek = tonumber(lang:formatDate('w', '@' .. timestamp)),
        dayName = lang:formatDate('l', '@' .. timestamp),
        isLeapYear = nil -- נחשב בנפרד
    }
    
    -- בדיקת שנה מעוברת עברית
    info.isLeapYear = p.isHebrewLeapYear(info.hebrewYear)
    
    return info
end

-- חישוב השבת הקרובה
function p.getNextSaturday(year, month, day)
    local currentDayOfWeek = p.getDayOfWeek(year, month, day)
    local daysUntilSaturday = (6 - currentDayOfWeek) % 7
    if daysUntilSaturday == 0 and currentDayOfWeek == 6 then
        -- אם זה כבר שבת, אז השבת הבאה
        daysUntilSaturday = 7
    end
    
    -- שימוש בפונקציות מדיה ויקי לחישוב התאריך
    local lang = mw.language.new('he')
    local timestamp = lang:formatDate('U', string.format('%04d-%02d-%02d', year, month, day))
    local saturdayTimestamp = timestamp + (daysUntilSaturday * 86400)
    
    local saturdayYear = tonumber(lang:formatDate('Y', '@' .. saturdayTimestamp))
    local saturdayMonth = tonumber(lang:formatDate('n', '@' .. saturdayTimestamp))
    local saturdayDay = tonumber(lang:formatDate('j', '@' .. saturdayTimestamp))
    
    return saturdayYear, saturdayMonth, saturdayDay
end

-- פונקציה לקבלת שם החודש העברי במספר
function p.getHebrewMonthNumber(monthName)
    local months = {
        ["תשרי"] = 1,
        ["חשון"] = 2, ["מרחשון"] = 2,
        ["כסלו"] = 3,
        ["טבת"] = 4,
        ["שבט"] = 5,
        ["אדר"] = 6,
        ["אדר א'"] = 6, ["אדר א"] = 6,
        ["אדר ב'"] = 7, ["אדר ב"] = 7,
        ["ניסן"] = 8,
        ["אייר"] = 9,
        ["סיון"] = 10,
        ["תמוז"] = 11,
        ["אב"] = 12,
        ["אלול"] = 13
    }
    
    return months[monthName] or 0
end

-- פונקציה לקבלת שם החודש העברי לפי מספר
function p.getHebrewMonthName(monthNumber, isLeapYear)
    local months = {
        "תשרי", "חשון", "כסלו", "טבת", "שבט", "אדר",
        "ניסן", "אייר", "סיון", "תמוז", "אב", "אלול"
    }
    
    if isLeapYear then
        months[6] = "אדר א'"
        table.insert(months, 7, "אדר ב'")
    end
    
    return months[monthNumber] or "לא ידוע"
end

-- בדיקה אם תאריך נתון הוא שבת
function p.isSaturday(year, month, day)
    return p.getDayOfWeek(year, month, day) == 6
end

-- חישוב יום בשנה (לצורך חישוב פרשה בסיסי)
function p.getDayOfYear(year, month, day)
    local daysInMonth = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
    
    -- בדיקת שנה מעוברת
    if (year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0) then
        daysInMonth[2] = 29
    end
    
    local dayOfYear = day
    for i = 1, month - 1 do
        dayOfYear = dayOfYear + daysInMonth[i]
    end
    
    return dayOfYear
end

return p

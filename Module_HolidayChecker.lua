-- Module:HolidayChecker
-- זיהוי חגים שבהם אין קריאת פרשת שבוע רגילה, עם הבחנה בין ארץ ישראל לחו"ל,
-- וטבלת קריאות (תורה / מפטיר / הפטרה).
-- מספור חודשים: ראו Module:HebrewDate (ניסן=1, סיון=3, תשרי=7).
local p = {}
local hebrewDate = require('Module:HebrewDate')

local TISHREI, NISAN, SIVAN = 7, 1, 3

-- טבלת קריאות
local READINGS = {
    rosh_hashana_1 = { name = "ראש השנה יום א", torah = "בראשית כא, א–לד", maftir = "במדבר כט, א–ו", haftarah = "שמואל א א, א – ב, י" },
    rosh_hashana_2 = { name = "ראש השנה יום ב", torah = "בראשית כב, א–כד", maftir = "במדבר כט, א–ו", haftarah = "ירמיהו לא, א–יט" },
    yom_kippur = { name = "יום כיפור", torah = "ויקרא טז, א–לד", maftir = "במדבר כט, ז–יא", haftarah = "ישעיהו נז, יד – נח, יד" },
    sukkot_1 = { name = "סוכות יום א", torah = "ויקרא כב, כו – כג, מד", maftir = "במדבר כט, יב–טז", haftarah = "זכריה יד, א–כא" },
    sukkot_2 = { name = "סוכות יום ב", torah = "ויקרא כב, כו – כג, מד", maftir = "במדבר כט, יב–טז", haftarah = "מלכים א ח, ב–כא" },
    sukkot_chol_hamoed = { name = "שבת חול המועד סוכות", torah = "שמות לג, יב – לד, כו", maftir = "קרבנות היום (במדבר כט)", haftarah = "יחזקאל לח, יח – לט, טז" },
    shemini_atzeret = { name = "שמיני עצרת", torah = "דברים יד, כב – טז, יז", maftir = "במדבר כט, לה – ל, א", haftarah = "מלכים א ח, נד–סו" },
    simchat_torah = { name = "שמחת תורה", torah = "דברים לג, א – לד, יב; בראשית א, א – ב, ג", maftir = "במדבר כט, לה – ל, א", haftarah = "יהושע א, א–יח" },
    pesach_1 = { name = "פסח יום א", torah = "שמות יב, כא–נא", maftir = "במדבר כח, טז–כה", haftarah = "יהושע ה, ב – ו, א" },
    pesach_2 = { name = "פסח יום ב", torah = "ויקרא כב, כו – כג, מד", maftir = "במדבר כח, טז–כה", haftarah = "מלכים ב כג, א–ט; כא–כה" },
    pesach_chol_hamoed = { name = "שבת חול המועד פסח", torah = "שמות לג, יב – לד, כו", maftir = "במדבר כח, יט–כה", haftarah = "יחזקאל לז, א–יד" },
    pesach_7 = { name = "שביעי של פסח", torah = "שמות יג, יז – טו, כו", maftir = "במדבר כח, יט–כה", haftarah = "שמואל ב כב, א–נא" },
    pesach_8 = { name = "אחרון של פסח", torah = "דברים יד, כב – טז, יז", maftir = "במדבר כח, יט–כה", haftarah = "ישעיהו י, לב – יב, ו" },
    shavuot_1 = { name = "שבועות יום א", torah = "שמות יט, א – כ, כג", maftir = "במדבר כח, כו–לא", haftarah = "יחזקאל א, א–כח; ג, יב" },
    shavuot_2 = { name = "שבועות יום ב", torah = "דברים יד, כב – טז, יז", maftir = "במדבר כח, כו–לא", haftarah = "חבקוק ב, כ – ג, יט" },
}

-- שמות ישנים / חלופיים -> מפתח
local NAME_TO_KEY = {
    ["ראש השנה"] = "rosh_hashana_1",
    ["סוכות"] = "sukkot_1",
    ["פסח"] = "pesach_1",
    ["שבועות"] = "shavuot_1",
    ["יום כיפור"] = "yom_kippur",
    ["יום כיפורים"] = "yom_kippur",
}
for key, r in pairs(READINGS) do NAME_TO_KEY[r.name] = key end

local function defaultIsrael(israel)
    if israel == nil then return true end
    return israel and true or false
end

-- getHoliday(hy, monthNum, day, israel) -> nil | {key, name, dayIndex}
-- dayIndex: היום בחג (1 = היום הראשון של החג)
function p.getHoliday(hy, m, d, israel)
    israel = defaultIsrael(israel)
    local key, dayIndex
    if m == TISHREI then
        if d == 1 or d == 2 then key, dayIndex = "rosh_hashana_" .. d, d
        elseif d == 10 then key, dayIndex = "yom_kippur", 1
        elseif d == 15 then key, dayIndex = "sukkot_1", 1
        elseif d == 16 then key, dayIndex = israel and "sukkot_chol_hamoed" or "sukkot_2", 2
        elseif d >= 17 and d <= 21 then key, dayIndex = "sukkot_chol_hamoed", d - 14
        elseif d == 22 then key, dayIndex = israel and "simchat_torah" or "shemini_atzeret", 8
        elseif d == 23 and not israel then key, dayIndex = "simchat_torah", 9
        end
    elseif m == NISAN then
        if d == 15 then key, dayIndex = "pesach_1", 1
        elseif d == 16 then key, dayIndex = israel and "pesach_chol_hamoed" or "pesach_2", 2
        elseif d >= 17 and d <= 20 then key, dayIndex = "pesach_chol_hamoed", d - 14
        elseif d == 21 then key, dayIndex = "pesach_7", 7
        elseif d == 22 and not israel then key, dayIndex = "pesach_8", 8
        end
    elseif m == SIVAN then
        if d == 6 then key, dayIndex = "shavuot_1", 1
        elseif d == 7 and not israel then key, dayIndex = "shavuot_2", 2
        end
    end
    if not key then return nil end
    return { key = key, name = READINGS[key].name, dayIndex = dayIndex }
end

-- תאימות לאחור: monthName הוא שם חודש עברי (או מספר במספור הפנימי)
function p.isHolidayThatReplacesTorah(hy, monthName, day, israel)
    local m = type(monthName) == "number" and monthName or hebrewDate.getHebrewMonthNumber(monthName)
    if not m then return false, nil end
    local h = p.getHoliday(hy, m, day, israel)
    if h then return true, h.name end
    return false, nil
end

-- קבלת קריאה לפי מפתח או שם
function p.getHolidayReading(nameOrKey)
    local r = READINGS[nameOrKey] or READINGS[NAME_TO_KEY[nameOrKey] or ""]
    if not r then return nil end
    return { torah = r.torah, maftir = r.maftir, haftarah = r.haftarah }
end

function p.checkHolidayAnyDay(gy, gm, gd, israel)
    local info = hebrewDate.getHebrewDateInfo(gy, gm, gd)
    local h = p.getHoliday(info.hebrewYear, info.hebrewMonthNum, info.hebrewDay, israel)
    if h then
        return true, h.name, p.getHolidayReading(h.key), info
    end
    return false, nil, nil, info
end

function p.checkHolidayOnSaturday(gy, gm, gd, israel)
    if not hebrewDate.isSaturday(gy, gm, gd) then
        return false, nil, nil
    end
    local isH, name, reading = p.checkHolidayAnyDay(gy, gm, gd, israel)
    if isH then return true, name, reading end
    return false, nil, nil
end

return p

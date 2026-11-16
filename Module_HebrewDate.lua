-- Module:HebrewDate
-- חישובי לוח עברי בלואה טהורה (ללא mw.* וללא os.*), לפי האלגוריתמים
-- הסטנדרטיים (Dershowitz–Reingold, "Calendrical Calculations").
--
-- מספר יום קבוע ("absolute" / Rata Die): 1 בינואר שנה 1 גרגוריאנית = 1.
-- abs % 7 == 0 הוא יום ראשון.
--
-- מספור חודשים פנימי: ניסן=1 ... אלול=6, תשרי=7, חשון=8, כסלו=9, טבת=10,
-- שבט=11, אדר (אדר א' בשנה מעוברת)=12, אדר ב'=13. השנה מתחילה בתשרי.
local p = {}

local floor = math.floor

local HEBREW_EPOCH = -1373427 -- abs של 1 בתשרי שנה 1 (7 באוקטובר 3761 לפנה"ס, יוליאני)

local MONTH_NAMES = {
    [1] = "ניסן", [2] = "אייר", [3] = "סיון", [4] = "תמוז", [5] = "אב", [6] = "אלול",
    [7] = "תשרי", [8] = "חשון", [9] = "כסלו", [10] = "טבת", [11] = "שבט", [12] = "אדר", [13] = "אדר ב'"
}

local DAY_NAMES = { [0] = "יום ראשון", "יום שני", "יום שלישי", "יום רביעי", "יום חמישי", "יום שישי", "שבת" }

---------------------------------------------------------------------------
-- לוח גרגוריאני
---------------------------------------------------------------------------
local function isGregorianLeap(y)
    return (y % 4 == 0 and y % 100 ~= 0) or y % 400 == 0
end

local GREG_DAYS = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

local function gregorianMonthLength(y, m)
    if m == 2 and isGregorianLeap(y) then return 29 end
    return GREG_DAYS[m]
end

function p.isValidGregorianDate(y, m, d)
    y, m, d = tonumber(y), tonumber(m), tonumber(d)
    if not (y and m and d) then return false end
    if y ~= floor(y) or m ~= floor(m) or d ~= floor(d) then return false end
    if y < 1 or m < 1 or m > 12 or d < 1 then return false end
    return d <= gregorianMonthLength(y, m)
end

function p.gregorianToAbsolute(y, m, d)
    local py = y - 1
    local days = 365 * py + floor(py / 4) - floor(py / 100) + floor(py / 400)
        + floor((367 * m - 362) / 12) + d
    if m > 2 then
        days = days - (isGregorianLeap(y) and 1 or 2)
    end
    return days
end

function p.absoluteToGregorian(abs)
    local d0 = abs - 1
    local n400 = floor(d0 / 146097); local d1 = d0 % 146097
    local n100 = floor(d1 / 36524); local d2 = d1 % 36524
    local n4 = floor(d2 / 1461); local d3 = d2 % 1461
    local n1 = floor(d3 / 365)
    local y = 400 * n400 + 100 * n100 + 4 * n4 + n1
    if not (n100 == 4 or n1 == 4) then y = y + 1 end
    local priorDays = abs - p.gregorianToAbsolute(y, 1, 1)
    local correction = 0
    if abs >= p.gregorianToAbsolute(y, 3, 1) then
        correction = isGregorianLeap(y) and 1 or 2
    end
    local m = floor((12 * (priorDays + correction) + 373) / 367)
    local d = abs - p.gregorianToAbsolute(y, m, 1) + 1
    return y, m, d
end

---------------------------------------------------------------------------
-- לוח עברי
---------------------------------------------------------------------------
function p.isHebrewLeapYear(hy)
    return (7 * hy + 1) % 19 < 7
end

function p.monthsInHebrewYear(hy)
    return p.isHebrewLeapYear(hy) and 13 or 12
end

-- מספר הימים מבריאת העולם עד ראש השנה hy (מולד + ארבע הדחיות)
local elapsedCache = {}
local function elapsedDays(hy)
    local c = elapsedCache[hy]
    if c then return c end
    local monthsElapsed = floor((235 * hy - 234) / 19)
    local partsElapsed = 12084 + 13753 * monthsElapsed
    local day = 29 * monthsElapsed + floor(partsElapsed / 25920)
    -- מולד זקן, לא אד"ו
    if (3 * (day + 1)) % 7 < 3 then day = day + 1 end
    elapsedCache[hy] = day
    return day
end

-- דחיות גט"ד ובט"ו תקפט (תיקון אורך שנה)
local function yearLengthCorrection(hy)
    local ny0 = elapsedDays(hy - 1)
    local ny1 = elapsedDays(hy)
    local ny2 = elapsedDays(hy + 1)
    if ny2 - ny1 == 356 then return 2 end
    if ny1 - ny0 == 382 then return 1 end
    return 0
end

local newYearCache = {}
local function newYear(hy)
    local c = newYearCache[hy]
    if c then return c end
    c = HEBREW_EPOCH + elapsedDays(hy) + yearLengthCorrection(hy)
    newYearCache[hy] = c
    return c
end

function p.daysInHebrewYear(hy)
    return newYear(hy + 1) - newYear(hy)
end

local function longCheshvan(hy) return p.daysInHebrewYear(hy) % 10 == 5 end
local function shortKislev(hy) return p.daysInHebrewYear(hy) % 10 == 3 end

function p.daysInHebrewMonth(hy, m)
    if m == 2 or m == 4 or m == 6 or m == 10 or m == 13 then return 29 end
    if m == 12 and not p.isHebrewLeapYear(hy) then return 29 end
    if m == 8 and not longCheshvan(hy) then return 29 end
    if m == 9 and shortKislev(hy) then return 29 end
    return 30
end

function p.hebrewToAbsolute(hy, m, d)
    local days = d
    local last = p.monthsInHebrewYear(hy)
    if m < 7 then
        for mm = 7, last do days = days + p.daysInHebrewMonth(hy, mm) end
        for mm = 1, m - 1 do days = days + p.daysInHebrewMonth(hy, mm) end
    else
        for mm = 7, m - 1 do days = days + p.daysInHebrewMonth(hy, mm) end
    end
    return newYear(hy) + days - 1
end

function p.absoluteToHebrew(abs)
    -- שנה משוערת ואז תיקון
    local hy = floor((abs - HEBREW_EPOCH) / 366)
    while newYear(hy + 1) <= abs do hy = hy + 1 end
    local m
    if abs < p.hebrewToAbsolute(hy, 1, 1) then m = 7 else m = 1 end
    while abs > p.hebrewToAbsolute(hy, m, p.daysInHebrewMonth(hy, m)) do m = m + 1 end
    local d = abs - p.hebrewToAbsolute(hy, m, 1) + 1
    return hy, m, d
end

---------------------------------------------------------------------------
-- שמות חודשים
---------------------------------------------------------------------------
-- num במספור הפנימי (ניסן=1, תשרי=7, אדר/אדר א'=12, אדר ב'=13)
function p.getHebrewMonthName(num, isLeap)
    if num == 12 and isLeap then return "אדר א'" end
    return MONTH_NAMES[num]
end

-- מחזיר מספר חודש במספור הפנימי
function p.getHebrewMonthNumber(name)
    if name == "אדר א'" or name == "אדר" then return 12 end
    for k, v in pairs(MONTH_NAMES) do
        if v == name then return k end
    end
    local aliases = { ["חשוון"] = 8, ["מרחשון"] = 8, ["סיוון"] = 3, ["אדר ב"] = 13, ["אדר א"] = 12 }
    return aliases[name]
end

---------------------------------------------------------------------------
-- המרות ונוחות
---------------------------------------------------------------------------
function p.gregorianToHebrew(y, m, d)
    local hy, hm, hd = p.absoluteToHebrew(p.gregorianToAbsolute(y, m, d))
    return hy, p.getHebrewMonthName(hm, p.isHebrewLeapYear(hy)), hd
end

function p.getDayOfWeek(y, m, d)
    return p.gregorianToAbsolute(y, m, d) % 7
end

function p.isSaturday(y, m, d)
    return p.getDayOfWeek(y, m, d) == 6
end

-- השבת הבאה (אם היום שבת – השבת שאחריה)
function p.getNextSaturday(y, m, d)
    local abs = p.gregorianToAbsolute(y, m, d)
    local delta = (6 - abs % 7) % 7
    if delta == 0 then delta = 7 end
    return p.absoluteToGregorian(abs + delta)
end

function p.getSaturdayOnOrAfter(y, m, d)
    local abs = p.gregorianToAbsolute(y, m, d)
    return p.absoluteToGregorian(abs + (6 - abs % 7) % 7)
end

function p.getHebrewDateInfo(y, m, d)
    local abs = p.gregorianToAbsolute(y, m, d)
    local hy, hm, hd = p.absoluteToHebrew(abs)
    local leap = p.isHebrewLeapYear(hy)
    local dow = abs % 7
    return {
        hebrewDay = hd,
        hebrewMonth = p.getHebrewMonthName(hm, leap),
        hebrewMonthNum = hm,
        hebrewYear = hy,
        dayOfWeek = dow,
        dayName = DAY_NAMES[dow],
        isLeapYear = leap,
        absolute = abs,
    }
end

---------------------------------------------------------------------------
-- גימטריה
---------------------------------------------------------------------------
local ONES = { "א", "ב", "ג", "ד", "ה", "ו", "ז", "ח", "ט" }
local TENS = { "י", "כ", "ל", "מ", "נ", "ס", "ע", "פ", "צ" }
local HUNDREDS = { "ק", "ר", "ש", "ת" }

local function utf8chars(s)
    local t = {}
    for ch in s:gmatch("[%z\1-\127\194-\244][\128-\191]*") do t[#t + 1] = ch end
    return t
end

-- ממיר מספר לאותיות. מספרים >= 1000 (שנים) נכתבים בלי האלפים (5786 -> תשפ"ו).
-- withThousands=true מוסיף "ה'" בתחילה.
function p.formatHebrewNumber(n, withThousands)
    n = floor(tonumber(n) or 0)
    if n <= 0 then return "" end
    local thousands = floor(n / 1000)
    n = n % 1000
    local parts = {}
    while n >= 400 do parts[#parts + 1] = "ת"; n = n - 400 end
    if n >= 100 then parts[#parts + 1] = HUNDREDS[floor(n / 100)]; n = n % 100 end
    if n == 15 then
        parts[#parts + 1] = "טו"; n = 0
    elseif n == 16 then
        parts[#parts + 1] = "טז"; n = 0
    end
    if n >= 10 then parts[#parts + 1] = TENS[floor(n / 10)]; n = n % 10 end
    if n > 0 then parts[#parts + 1] = ONES[n] end
    local chars = utf8chars(table.concat(parts))
    local s
    if #chars == 0 then
        s = ""
    elseif #chars == 1 then
        s = chars[1] .. "'"
    else
        s = table.concat(chars, "", 1, #chars - 1) .. '"' .. chars[#chars]
    end
    if withThousands and thousands > 0 then
        s = ONES[thousands] .. "'" .. s
    end
    return s
end

-- "י"א בתשרי ה'תשפ"ו"
function p.formatHebrewDate(hy, hm, hd)
    local name = p.getHebrewMonthName(hm, p.isHebrewLeapYear(hy))
    return p.formatHebrewNumber(hd) .. " ב" .. name .. " " .. p.formatHebrewNumber(hy, true)
end

return p

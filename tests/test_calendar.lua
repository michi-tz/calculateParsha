local H = require('Module:HebrewDate')

-- leap years (19-year cycle positions 3,6,8,11,14,17,19)
T.eq(H.isHebrewLeapYear(5784), true, 'leap 5784')
T.eq(H.isHebrewLeapYear(5785), false, 'leap 5785')
T.eq(H.isHebrewLeapYear(5787), true, 'leap 5787')
T.eq(H.monthsInHebrewYear(5784), 13, 'months 5784')
-- year lengths
T.eq(H.daysInHebrewYear(5784), 383, 'len 5784')
T.eq(H.daysInHebrewYear(5785), 355, 'len 5785')
T.eq(H.daysInHebrewYear(5786), 354, 'len 5786')
local valid = { [353] = 1, [354] = 1, [355] = 1, [383] = 1, [384] = 1, [385] = 1 }
for hy = 5600, 6000 do
    T.ok(valid[H.daysInHebrewYear(hy)], 'year length ' .. hy)
    local sum = 0
    for m = 1, H.monthsInHebrewYear(hy) do sum = sum + H.daysInHebrewMonth(hy, m) end
    T.eq(sum, H.daysInHebrewYear(hy), 'month sum ' .. hy)
    -- lo ADU Rosh
    local dow = H.hebrewToAbsolute(hy, 7, 1) % 7
    T.ok(dow ~= 0 and dow ~= 3 and dow ~= 5, 'RH weekday ' .. hy)
end
-- anchors
local y, m, d = H.absoluteToGregorian(H.hebrewToAbsolute(5786, 7, 1))
T.eq(string.format('%d-%02d-%02d', y, m, d), '2025-09-23', '1 Tishrei 5786')
T.eq(H.getDayOfWeek(2025, 9, 23), 2, 'RH 5786 is Tuesday')
local info = H.getHebrewDateInfo(2025, 10, 4)
T.eq(info.hebrewYear, 5786, 'hy'); T.eq(info.hebrewMonth, 'תשרי', 'month name')
T.eq(info.hebrewMonthNum, 7, 'month num'); T.eq(info.hebrewDay, 12, 'day')
T.eq(info.dayOfWeek, 6, 'dow'); T.eq(info.dayName, 'שבת', 'day name'); T.eq(info.isLeapYear, false, 'leap')
local hy, mn, hd = H.gregorianToHebrew(2024, 3, 22)
T.eq(hy .. ' ' .. mn .. ' ' .. hd, "5784 אדר ב' 12", 'Adar II name')
T.eq(select(2, H.gregorianToHebrew(2024, 2, 20)), "אדר א'", 'Adar I name')
T.eq(H.gregorianToAbsolute(1, 1, 1), 1, 'RD epoch')
T.eq(H.gregorianToAbsolute(1, 1, 7) % 7, 0, 'RD 7 is Sunday')
for abs = 700000, 760000, 37 do
    local a, b, c = H.absoluteToGregorian(abs)
    T.eq(H.gregorianToAbsolute(a, b, c), abs, 'greg round trip')
    local e, f, g = H.absoluteToHebrew(abs)
    T.eq(H.hebrewToAbsolute(e, f, g), abs, 'hebrew round trip')
end
-- saturdays
T.eq(H.isSaturday(2025, 10, 4), true, 'isSaturday')
T.eq(table.concat({ H.getNextSaturday(2025, 10, 4) }, '-'), '2025-10-11', 'next sat strict')
T.eq(table.concat({ H.getSaturdayOnOrAfter(2025, 10, 4) }, '-'), '2025-10-4', 'sat on/after')
T.eq(table.concat({ H.getSaturdayOnOrAfter(2025, 10, 1) }, '-'), '2025-10-4', 'sat on/after wed')
-- validity
T.eq(H.isValidGregorianDate(2024, 2, 29), true, '2024-02-29')
T.eq(H.isValidGregorianDate(2023, 2, 29), false, '2023-02-29')
T.eq(H.isValidGregorianDate(1900, 2, 29), false, '1900-02-29')
T.eq(H.isValidGregorianDate(2025, 13, 1), false, 'month 13')
T.eq(H.isValidGregorianDate(2025, 4, 31), false, 'Apr 31')
T.eq(H.isValidGregorianDate(2025, 1, 0), false, 'day 0')
-- month helpers (internal numbering)
T.eq(H.getHebrewMonthName(7, false), 'תשרי', 'name 7')
T.eq(H.getHebrewMonthName(12, true), "אדר א'", 'name 12 leap')
T.eq(H.getHebrewMonthNumber('ניסן'), 1, 'num ניסן')
T.eq(H.getHebrewMonthNumber("אדר ב'"), 13, 'num adar II')
-- gematria
T.eq(H.formatHebrewNumber(11), 'י"א', '11')
T.eq(H.formatHebrewNumber(15), 'ט"ו', '15')
T.eq(H.formatHebrewNumber(16), 'ט"ז', '16')
T.eq(H.formatHebrewNumber(1), "א'", '1')
T.eq(H.formatHebrewNumber(30), "ל'", '30')
T.eq(H.formatHebrewNumber(5786), 'תשפ"ו', '5786')
T.eq(H.formatHebrewNumber(5786, true), 'ה\'תשפ"ו', '5786 thousands')
T.eq(H.formatHebrewDate(5786, 7, 11), 'י"א בתשרי ה\'תשפ"ו', 'formatted date')

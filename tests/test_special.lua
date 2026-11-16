-- Expected dates verified against @hebcal/core 6.16.1 HebrewCalendar.calendar (SPECIAL_SHABBAT).
local P = require('Module:Parsha')
local expected = {
    ['2023-09-23'] = 'שבת שובה', ['2024-01-27'] = 'שבת שירה', ['2024-03-09'] = 'שבת שקלים',
    ['2024-03-23'] = 'שבת זכור', ['2024-03-30'] = 'שבת פרה', ['2024-04-06'] = 'שבת החודש',
    ['2024-04-20'] = 'שבת הגדול', ['2024-08-10'] = 'שבת חזון', ['2024-08-17'] = 'שבת נחמו',
    ['2024-10-05'] = 'שבת שובה', ['2025-02-08'] = 'שבת שירה', ['2025-03-01'] = 'שבת שקלים',
    ['2025-03-08'] = 'שבת זכור', ['2025-03-22'] = 'שבת פרה', ['2025-03-29'] = 'שבת החודש',
    ['2025-04-12'] = 'שבת הגדול', ['2025-08-02'] = 'שבת חזון', ['2025-08-09'] = 'שבת נחמו',
    ['2025-09-27'] = 'שבת שובה', ['2026-01-31'] = 'שבת שירה', ['2026-02-14'] = 'שבת שקלים',
    ['2026-02-28'] = 'שבת זכור', ['2026-03-07'] = 'שבת פרה', ['2026-03-14'] = 'שבת החודש',
    ['2026-03-28'] = 'שבת הגדול', ['2026-07-18'] = 'שבת חזון', ['2026-07-25'] = 'שבת נחמו',
}
local H = require('Module:HebrewDate')
-- every Saturday of 5784..5786: special list must be exactly the expected one
for hy = 5784, 5786 do
    for _, e in ipairs(P.getYearScheduleData(hy, true)) do
        local y, m, d = H.absoluteToGregorian(e.abs)
        local key = string.format('%04d-%02d-%02d', y, m, d)
        local got = table.concat(P.computeParsha(y, m, d, true).special, ',')
        T.eq(got, expected[key] or '', 'special ' .. key)
    end
end

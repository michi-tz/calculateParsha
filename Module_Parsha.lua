-- Module:Parsha
-- חישוב מדויק של פרשת השבוע (ארץ ישראל / חו"ל), כולל פרשיות מחוברות,
-- שבתות של חג וחול המועד, ושבתות מיוחדות.
--
-- המנוע מבוסס כללים (ולא טבלאות חיפוש): לכל שנה עברית בונים את רשימת כל
-- השבתות, מסמנים שבתות חג, ומחלקים את הפרשיות לפי הכללים ההלכתיים.
-- הפונקציות הטהורות (computeParsha, getYearScheduleData וכו') זמינות ללא MediaWiki.
local p = {}

local hebrewDate = require('Module:HebrewDate')
local holidayChecker = require('Module:HolidayChecker')

local floor = math.floor
local TISHREI, NISAN, SIVAN, AV = 7, 1, 3, 5

-- רשימת פרשיות השבוע בסדר
local parshiot = {
    "בראשית", "נח", "לך לך", "וירא", "חיי שרה", "תולדות", "ויצא", "וישלח", "וישב", "מקץ", "ויגש", "ויחי",
    "שמות", "וארא", "בא", "בשלח", "יתרו", "משפטים", "תרומה", "תצוה", "כי תשא", "ויקהל", "פקודי",
    "ויקרא", "צו", "שמיני", "תזריע", "מצורע", "אחרי מות", "קדושים", "אמור", "בהר", "בחקתי",
    "במדבר", "נשא", "בהעלתך", "שלח לך", "קרח", "חקת", "בלק", "פינחס", "מטות", "מסעי",
    "דברים", "ואתחנן", "עקב", "ראה", "שפטים", "כי תצא", "כי תבוא", "נצבים", "וילך", "האזינו", "וזאת הברכה"
}
p.parshiot = parshiot

local VAYAKHEL, PEKUDEI, TZAV, BESHALACH = 22, 23, 25, 16
local CHUKAT, BALAK = 39, 40
local NITZAVIM, VAYELECH, HAAZINU = 51, 52, 53

-- זוגות שניתנים לחיבור אחרי פסח, לפי סדר עדיפות
local PAIRS_REGULAR = { { 27, 28 }, { 29, 30 }, { 42, 43 }, { 32, 33 } }
local PAIRS_LEAP = { { 42, 43 } }

local H = hebrewDate

local function isHolidayShabbat(hy, hm, hd, israel)
    return holidayChecker.getHoliday(hy, hm, hd, israel) ~= nil
end

-- מספר השבתות הפנויות (לא חג) בתשרי לפני סוכות (אחרי ראש השנה)
local function availableBeforeSukkot(hy)
    local rh = H.hebrewToAbsolute(hy, TISHREI, 1)
    local sukkot = rh + 14
    local count = 0
    local s = rh + (6 - rh % 7) % 7
    while s < sukkot do
        local _, m, d = H.absoluteToHebrew(s)
        if not isHolidayShabbat(hy, m, d, true) then count = count + 1 end
        s = s + 7
    end
    return count
end

-- בחירת זוגות לחיבור: מחזירה set של האינדקס הראשון בכל זוג מחובר
local function choosePairs(needed, mandatory, priority)
    local joined = {}
    for _, first in ipairs(mandatory) do
        joined[first] = true
        needed = needed - 1
    end
    for _, pair in ipairs(priority) do
        if needed <= 0 then break end
        if not joined[pair[1]] then
            joined[pair[1]] = true
            needed = needed - 1
        end
    end
    return joined, needed
end

-- מחלק את הפרשיות from..to לשבתות slots לפי joined (set של התחלות זוג)
local function assignSequential(slots, from, to, joined)
    local idx = from
    for _, slot in ipairs(slots) do
        if idx > to then
            error("Parsha: too few parshiot for segment")
        end
        if joined[idx] then
            slot.parshiot = { idx, idx + 1 }
            idx = idx + 2
        else
            slot.parshiot = { idx }
            idx = idx + 1
        end
    end
    if idx ~= to + 1 then
        error("Parsha: parshiot left over in segment (" .. idx .. ".." .. to .. ")")
    end
end

local scheduleCache = {}

-- בונה את לוח השבתות לשנה עברית hy. כל רשומה:
-- { abs, hy, hm, hd, holiday = nil|{key,name,dayIndex}, parshiot = {...} }
function p.getYearScheduleData(hy, israel)
    if israel == nil then israel = true end
    israel = israel and true or false
    local cacheKey = hy .. (israel and "i" or "d")
    if scheduleCache[cacheKey] then return scheduleCache[cacheKey] end

    local leap = H.isHebrewLeapYear(hy)
    local rh = H.hebrewToAbsolute(hy, TISHREI, 1)
    local nextRh = H.hebrewToAbsolute(hy + 1, TISHREI, 1)
    local pesach = H.hebrewToAbsolute(hy, NISAN, 15)
    local simchatTorah = H.hebrewToAbsolute(hy, TISHREI, israel and 22 or 23)

    local all = {}
    local pre, mid, post = {}, {}, {}
    local s = rh + (6 - rh % 7) % 7
    while s < nextRh do
        local y, m, d = H.absoluteToHebrew(s)
        local entry = { abs = s, hy = y, hm = m, hd = d, parshiot = {} }
        entry.holiday = holidayChecker.getHoliday(y, m, d, israel)
        all[#all + 1] = entry
        if not entry.holiday then
            if s < simchatTorah then
                pre[#pre + 1] = entry
            elseif s < pesach then
                mid[#mid + 1] = entry
            else
                post[#post + 1] = entry
            end
        end
        s = s + 7
    end

    -- (א) לפני סוכות: וילך+האזינו או האזינו בלבד
    if #pre == 2 then
        pre[1].parshiot = { VAYELECH }
        pre[2].parshiot = { HAAZINU }
    elseif #pre == 1 then
        pre[1].parshiot = { HAAZINU }
    end

    -- (ב)+(ג) מבראשית ועד השבת שלפני פסח.
    -- בשנה פשוטה צו נקרא בשבת שלפני פסח: מחברים ויקהל-פקודי לפי הצורך.
    -- בשנה מעוברת אין חיבורים בקטע זה.
    local midEnd
    if leap then
        midEnd = #mid
        assignSequential(mid, 1, midEnd, {})
    else
        midEnd = TZAV
        local needed = TZAV - #mid
        local joined = {}
        if needed == 1 then joined[VAYAKHEL] = true
        elseif needed ~= 0 then error("Parsha: unexpected count before Pesach in " .. hy) end
        assignSequential(mid, 1, midEnd, joined)
    end

    -- (ד) אחרי פסח ועד סוף השנה: עד נצבים (ונצבים-וילך כשבשנה הבאה יש
    -- רק שבת פנויה אחת לפני סוכות).
    local lastIdx = (availableBeforeSukkot(hy + 1) == 1) and VAYELECH or NITZAVIM
    local remaining = lastIdx - midEnd
    local needed = remaining - #post
    local mandatory = {}
    if lastIdx == VAYELECH then mandatory[#mandatory + 1] = NITZAVIM end
    -- חוקת-בלק מחוברות בחו"ל כשיום ב' של שבועות (ז' סיון) חל בשבת
    if not israel then
        local sivan7 = H.hebrewToAbsolute(hy, SIVAN, 7)
        if sivan7 % 7 == 6 then mandatory[#mandatory + 1] = CHUKAT end
    end
    local joined, left = choosePairs(needed, mandatory, leap and PAIRS_LEAP or PAIRS_REGULAR)
    if left ~= 0 then error("Parsha: cannot fit post-Pesach segment in " .. hy) end
    assignSequential(post, midEnd + 1, lastIdx, joined)

    scheduleCache[cacheKey] = all
    return all
end

local function parshaName(list)
    local names = {}
    for i, idx in ipairs(list) do names[i] = parshiot[idx] end
    return table.concat(names, "-")
end
p.parshaName = parshaName

-- שבתות מיוחדות לשבת (abs) בשנה hy
local function specialShabbatot(entry)
    local hy, abs = entry.hy, entry.abs
    local leap = H.isHebrewLeapYear(hy)
    local adar = leap and 13 or 12
    local function satOnOrBefore(a) return a - ((a % 7) + 1) % 7 end
    local function satBefore(a) return satOnOrBefore(a - 1) end
    local list = {}
    local rh = H.hebrewToAbsolute(hy, TISHREI, 1)
    if abs > rh + 1 and abs < rh + 9 then list[#list + 1] = "שבת שובה" end
    for _, idx in ipairs(entry.parshiot) do
        if idx == BESHALACH then list[#list + 1] = "שבת שירה" end
    end
    local shekalim = satOnOrBefore(H.hebrewToAbsolute(hy, adar, 1))
    local zachor = satBefore(H.hebrewToAbsolute(hy, adar, 14))
    local hachodesh = satOnOrBefore(H.hebrewToAbsolute(hy, NISAN, 1))
    local parah = hachodesh - 7
    local hagadol = satBefore(H.hebrewToAbsolute(hy, NISAN, 15))
    local chazon = satOnOrBefore(H.hebrewToAbsolute(hy, AV, 9))
    if abs == shekalim then list[#list + 1] = "שבת שקלים" end
    if abs == zachor then list[#list + 1] = "שבת זכור" end
    if abs == parah then list[#list + 1] = "שבת פרה" end
    if abs == hachodesh then list[#list + 1] = "שבת החודש" end
    if abs == hagadol then list[#list + 1] = "שבת הגדול" end
    if abs == chazon then list[#list + 1] = "שבת חזון" end
    if abs == chazon + 7 then list[#list + 1] = "שבת נחמו" end
    return list
end

-- computeParsha(y, m, d, israel): תאריך גרגוריאני (אם אינו שבת – השבת הבאה/היום)
function p.computeParsha(y, m, d, israel)
    if israel == nil then israel = true end
    local sy, sm, sd = H.getSaturdayOnOrAfter(y, m, d)
    local abs = H.gregorianToAbsolute(sy, sm, sd)
    local hy = H.absoluteToHebrew(abs)
    local schedule = p.getYearScheduleData(hy, israel)
    local entry
    for _, e in ipairs(schedule) do
        if e.abs == abs then entry = e; break end
    end
    local result = {
        saturday = { year = sy, month = sm, day = sd },
        hebrew = H.getHebrewDateInfo(sy, sm, sd),
        parshiot = {},
        special = {},
    }
    if entry.holiday then
        result.holiday = { name = entry.holiday.name, key = entry.holiday.key,
            reading = holidayChecker.getHolidayReading(entry.holiday.key) }
        result.name = entry.holiday.name
    else
        for i, v in ipairs(entry.parshiot) do result.parshiot[i] = v end
        result.name = parshaName(entry.parshiot)
    end
    result.special = specialShabbatot(entry)
    return result
end

---------------------------------------------------------------------------
-- נקודות כניסה מוויקי (#invoke)
---------------------------------------------------------------------------
local ISRAEL_UTC_OFFSET = 2 * 3600 -- קירוב: שעון ישראל רגיל (UTC+2), ללא שעון קיץ

local function errorSpan(msg)
    return '<span class="error">' .. msg .. '</span>'
end

local function getArgsFrom(frame)
    return require('Module:Arguments').getArgs(frame)
end

local function today()
    local t = os.date('!*t', os.time() + ISRAEL_UTC_OFFSET)
    return t.year, t.month, t.day
end

-- מחזיר y, m, d או nil, הודעת שגיאה
local function parseDate(s)
    if s == nil or s == "" then return today() end
    local y, m, d = tostring(s):match("^%s*(%d+)-(%d+)-(%d+)%s*$")
    y, m, d = tonumber(y), tonumber(m), tonumber(d)
    if not (y and m and d) then
        return nil, "שגיאה: פורמט תאריך לא תקין. השתמש בפורמט: YYYY-MM-DD"
    end
    if not H.isValidGregorianDate(y, m, d) then
        return nil, "שגיאה: התאריך " .. s .. " אינו תאריך קיים"
    end
    return y, m, d
end

local function isIsrael(args)
    local yesno = require('Module:Yesno')
    if args.diaspora and yesno(args.diaspora, false) then return false end
    if args.israel ~= nil and args.israel ~= "" then return yesno(args.israel, true) ~= false end
    return true
end

local function flag(args, name)
    local v = args[name]
    if v == nil or v == "" then return false end
    return require('Module:Yesno')(v, false) == true
end

function p.getParsha(frame)
    local args = getArgsFrom(frame)
    local y, m, d = parseDate(args.date)
    if not y then return errorSpan(m) end
    local r = p.computeParsha(y, m, d, isIsrael(args))
    local suffix = ""
    if flag(args, "special") and #r.special > 0 then
        suffix = " (" .. table.concat(r.special, ", ") .. ")"
    end
    if flag(args, "plain") then
        return r.name .. suffix
    end
    if r.holiday then
        local reading = r.holiday.reading
        local result = "'''חג: " .. r.holiday.name .. "'''" .. suffix .. "\n\n"
        if reading then
            result = result .. "'''קריאת התורה:''' " .. (reading.torah or "") .. "\n\n"
            if reading.maftir then
                result = result .. "'''מפטיר:''' " .. reading.maftir .. "\n\n"
            end
            if reading.haftarah then
                result = result .. "'''הפטרה:''' " .. reading.haftarah
            end
        end
        return result
    end
    return "'''פרשת " .. r.name .. "'''" .. suffix
end

function p.getParshaName(frame)
    local args = getArgsFrom(frame)
    local copy = {}
    for k, v in pairs(args) do copy[k] = v end
    copy.plain = "yes"
    return p.getParsha(copy)
end

function p.getSpecialShabbat(frame)
    local args = getArgsFrom(frame)
    local y, m, d = parseDate(args.date)
    if not y then return errorSpan(m) end
    return table.concat(p.computeParsha(y, m, d, isIsrael(args)).special, ", ")
end

function p.listAllParshiot(frame)
    local result = {}
    for i, parsha in ipairs(parshiot) do
        table.insert(result, i .. ". פרשת " .. parsha)
    end
    return table.concat(result, "\n")
end

function p.checkIfHoliday(frame)
    local args = getArgsFrom(frame)
    if not args.date then
        return "שגיאה: חסר פרמטר date"
    end
    local y, m, d = parseDate(args.date)
    if not y then return errorSpan(m) end
    local isH, name, _, info = holidayChecker.checkHolidayAnyDay(y, m, d, isIsrael(args))
    if isH then
        return string.format("כן - %s (%d ב%s %d)", name, info.hebrewDay, info.hebrewMonth, info.hebrewYear)
    end
    return string.format("לא (%d ב%s %d)", info.hebrewDay, info.hebrewMonth, info.hebrewYear)
end

function p.getDateInfo(frame)
    local args = getArgsFrom(frame)
    if not args.date then
        return "שגיאה: חסר פרמטר date"
    end
    local y, m, d = parseDate(args.date)
    if not y then return errorSpan(m) end
    local info = H.getHebrewDateInfo(y, m, d)
    return string.format(
        "'''תאריך גרגוריאני:''' %d-%02d-%02d\n" ..
        "'''תאריך עברי:''' %d ב%s %d\n" ..
        "'''תאריך עברי (אותיות):''' %s\n" ..
        "'''יום בשבוע:''' %s\n" ..
        "'''שנה מעוברת:''' %s",
        y, m, d,
        info.hebrewDay, info.hebrewMonth, info.hebrewYear,
        H.formatHebrewDate(info.hebrewYear, info.hebrewMonthNum, info.hebrewDay),
        info.dayName,
        info.isLeapYear and "כן" or "לא"
    )
end

function p.getYearSchedule(frame)
    local args = getArgsFrom(frame)
    local hy = tonumber(args.year)
    if args.year and args.year ~= "" and not hy then
        return errorSpan("שגיאה: שנה עברית לא תקינה")
    end
    if not hy then
        local y, m, d = today()
        hy = H.absoluteToHebrew(H.gregorianToAbsolute(y, m, d))
    end
    if hy < 2 then return errorSpan("שגיאה: שנה עברית לא תקינה") end
    local israel = isIsrael(args)
    local rows = {
        '{| class="wikitable"',
        "|+ לוח פרשות השבוע לשנת " .. H.formatHebrewNumber(hy, true) .. (israel and " (ארץ ישראל)" or ' (חו"ל)'),
        "! תאריך לועזי !! תאריך עברי !! פרשה / חג !! שבת מיוחדת",
    }
    for _, e in ipairs(p.getYearScheduleData(hy, israel)) do
        local gy, gm, gd = H.absoluteToGregorian(e.abs)
        local r = p.computeParsha(gy, gm, gd, israel)
        local label = r.holiday and r.holiday.name or ("פרשת " .. r.name)
        rows[#rows + 1] = "|-"
        rows[#rows + 1] = string.format("| %04d-%02d-%02d || %s || %s || %s", gy, gm, gd,
            H.formatHebrewDate(e.hy, e.hm, e.hd), label, table.concat(r.special, ", "))
    end
    rows[#rows + 1] = "|}"
    return table.concat(rows, "\n")
end

return p

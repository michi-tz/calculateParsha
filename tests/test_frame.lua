local P = require('Module:Parsha')
local function frame(args) return { args = args } end

T.eq(P.getParsha(frame({ date = '2026-03-14' })), "'''פרשת ויקהל-פקודי'''", 'combined')
T.eq(P.getParsha(frame({ date = '2026-03-10' })), "'''פרשת ויקהל-פקודי'''", 'weekday -> next Saturday')
T.eq(P.getParsha(frame({ date = '2026-03-14', plain = 'yes' })), 'ויקהל-פקודי', 'plain')
T.eq(P.getParshaName(frame({ date = '2026-03-14' })), 'ויקהל-פקודי', 'getParshaName')
-- ארגומנטים כ-proxy עצל (כמו Module:Arguments): pairs לא מונה אותם
local lazy = setmetatable({}, { __index = { date = '2022-04-23', diaspora = 'yes' } })
T.eq(P.getParshaName(frame(lazy)), 'אחרון של פסח', 'getParshaName with lazy args proxy')
T.eq(P.getParsha(frame({ date = '2026-03-14', special = 'yes' })), "'''פרשת ויקהל-פקודי''' (שבת החודש)", 'special')
T.eq(P.getParsha(frame({ date = '2026-03-14', special = 'yes', plain = 'yes' })), 'ויקהל-פקודי (שבת החודש)', 'special plain')
T.eq(P.getSpecialShabbat(frame({ date = '2026-03-14' })), 'שבת החודש', 'getSpecialShabbat')
T.eq(P.getSpecialShabbat(frame({ date = '2026-03-21' })), '', 'no special')
T.eq(P.getParsha(frame({ date = '2022-04-23' })), "'''פרשת אחרי מות'''", 'Israel default')
local dia = P.getParsha(frame({ date = '2022-04-23', diaspora = 'yes' }))
T.ok(dia:find("'''חג: אחרון של פסח'''", 1, true) == 1, 'diaspora alias: ' .. dia)
T.ok(dia:find("'''קריאת התורה:''' דברים יד", 1, true) ~= nil, 'holiday torah line')
T.ok(dia:find("'''הפטרה:'''", 1, true) ~= nil, 'holiday haftarah line')
T.eq(P.getParsha(frame({ date = '2022-04-23', israel = 'no' })), dia, 'israel=no')
T.eq(P.getParsha(frame({ date = '2022-04-23', israel = 'no', plain = 'yes' })), 'אחרון של פסח', 'holiday plain')
local bad = P.getParsha(frame({ date = '2025-02-30' }))
T.ok(bad:find('<span class="error">', 1, true) == 1, 'invalid date error: ' .. bad)
T.ok(P.getParsha(frame({ date = 'garbage' })):find('<span class="error">', 1, true) == 1, 'bad format')
T.ok(P.getParsha(frame({})):find("'''", 1, true) ~= nil, 'today works')
T.eq(P.getParsha({ date = '2026-03-14', plain = 'yes' }), 'ויקהל-פקודי', 'plain table as frame')

local list = P.listAllParshiot(frame({}))
T.ok(list:find('1. פרשת בראשית', 1, true) == 1, 'list start')
T.ok(list:find('54. פרשת וזאת הברכה', 1, true) ~= nil, 'list end')
T.eq(P.checkIfHoliday(frame({ date = '2025-10-02' })), 'כן - יום כיפור (10 בתשרי 5786)', 'checkIfHoliday yes')
T.eq(P.checkIfHoliday(frame({ date = '2025-10-04' })), 'לא (12 בתשרי 5786)', 'checkIfHoliday no')
T.eq(P.checkIfHoliday(frame({})), 'שגיאה: חסר פרמטר date', 'checkIfHoliday missing')
local di = P.getDateInfo(frame({ date = '2025-10-03' }))
T.ok(di:find("'''תאריך עברי:''' 11 בתשרי 5786", 1, true) ~= nil, 'dateinfo hebrew')
T.ok(di:find("'''תאריך עברי (אותיות):''' י\"א בתשרי ה'תשפ\"ו", 1, true) ~= nil, 'dateinfo gematria')
T.ok(di:find("'''יום בשבוע:''' יום שישי", 1, true) ~= nil, 'dateinfo weekday')

local sched = P.getYearSchedule(frame({ year = '5786' }))
T.ok(sched:find('{| class="wikitable"', 1, true) == 1, 'schedule table')
T.ok(sched:find('| 2026-03-14 ||', 1, true) ~= nil, 'schedule row')
T.ok(sched:find('פרשת ויקהל-פקודי', 1, true) ~= nil, 'schedule parsha')
T.ok(sched:find('שבת חול המועד סוכות', 1, true) ~= nil, 'schedule holiday')
T.ok(sched:sub(-2) == '|}', 'schedule closed')
T.ok(P.getYearSchedule(frame({ year = 'abc' })):find('class="error"', 1, true) ~= nil, 'schedule bad year')
T.ok(P.getYearSchedule(frame({ year = '5782', diaspora = 'yes' })):find('אחרון של פסח', 1, true) ~= nil, 'schedule diaspora')

-- API ישיר למודולים אחרים: טבלת ארגומנטים רגילה, דגלים כ-boolean
T.eq(P._getParsha({ date = '2026-03-14' }), "'''פרשת ויקהל-פקודי'''", '_getParsha')
T.eq(P._getParsha({ date = '2026-03-14', plain = true, special = true }), 'ויקהל-פקודי (שבת החודש)', '_getParsha booleans')
T.eq(P._getParshaName({ date = '2022-04-23', diaspora = true }), 'אחרון של פסח', '_getParshaName diaspora=true')
T.eq(P._getParshaName({ date = '2022-04-23', israel = false }), 'אחרון של פסח', '_getParshaName israel=false')
T.eq(P._getParshaName({ date = '2022-04-23', israel = true }), 'אחרי מות', '_getParshaName israel=true')
T.eq(P._getSpecialShabbat({ date = '2026-03-14' }), 'שבת החודש', '_getSpecialShabbat')
T.eq(P._checkIfHoliday({ date = '2025-10-04' }), 'לא (12 בתשרי 5786)', '_checkIfHoliday')
T.ok(P._getDateInfo({ date = '2025-10-03' }):find('5786', 1, true) ~= nil, '_getDateInfo')
T.ok(P._getYearSchedule({ year = 5786 }):find('| 2026-03-14 ||', 1, true) ~= nil, '_getYearSchedule numeric year')
T.ok(P._getParsha():find("'''", 1, true) ~= nil, '_getParsha without args = today')
local src = { date = '2026-03-14' }
P._getParshaName(src)
T.eq(src.plain, nil, '_getParshaName does not mutate caller args')

-- modules load without MediaWiki globals
T.eq(mw, nil, 'no mw global needed')

-- today(): מחוץ לוויקי גיבוי os.date; בוויקי לפי השעון המקומי של האתר
local ty, tm, td = P.today()
T.ok(type(ty) == 'number' and tm >= 1 and tm <= 12 and td >= 1 and td <= 31, 'today fallback')
local seen
mw = { getContentLanguage = function()
    return { formatDate = function(_, fmt, ts, loc) seen = { fmt, ts, loc }; return '2026-3-14' end }
end }
local y2, m2, d2 = P.today()
T.eq(y2 .. '-' .. m2 .. '-' .. d2, '2026-3-14', 'today via mw')
T.eq(seen[3], true, 'today asks for wiki-local time')
T.eq(P._getParshaName({}), 'ויקהל-פקודי', 'default date uses mw today')
T.eq(P.getParshaName(frame({})), 'ויקהל-פקודי', 'frame default date uses mw today')
mw = { getContentLanguage = function() return { formatDate = function() return 'garbage' end } end }
T.ok(type((P.today())) == 'number', 'today falls back when mw output is unparsable')
mw = nil

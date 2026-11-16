# מודולי פרשת השבוע למדיה ויקי

מודולים ב-Scribunto (MediaWiki) המחשבים את פרשת השבוע (פרשת השבוע העברית) המדויקת לכל תאריך לועזי, כולל פרשיות מחוברות, התייחסות נפרדת לארץ ישראל ולחו"ל, שבתות של חג וחול המועד עם קריאות התורה, המפטיר וההפטרה, ושבתות מיוחדות. הקוד כתוב ב-Lua 5.1 טהורה ואינו תלוי ב-`mw.language`.

## התקנה

יש להעתיק כל קובץ `Module_X.lua` לדף הוויקי `Module:X`:

| קובץ במאגר | דף בוויקי |
|---|---|
| `Module_Parsha.lua` | `Module:Parsha` |
| `Module_HebrewDate.lua` | `Module:HebrewDate` |
| `Module_HolidayChecker.lua` | `Module:HolidayChecker` |

הדרישות בוויקי: `Module:Arguments` ו-`Module:Yesno` (מודולים סטנדרטיים בוויקי). `Module:Parsha` קורא להם, ו-`Module:HebrewDate` ו-`Module:HolidayChecker` מיובאים דרך `require` מתוך `Module:Parsha`.

## שימוש

הפונקציות הציבוריות נקראות דרך `#invoke:Parsha|<שם הפונקציה>`.

| פונקציה | פרמטרים | תיאור |
|---|---|---|
| `getParsha` | `date`, `israel`, `diaspora`, `plain`, `special` | שם הפרשה לשבת של התאריך (או השבת הבאה אם התאריך אינו שבת). בשבת חג מוצגות קריאות החג |
| `getParshaName` | `date`, `israel`, `diaspora`, `special` | כמו `getParsha` עם `plain=yes`: רק שם הפרשה, ללא עיצוב ובלי קריאות |
| `getSpecialShabbat` | `date`, `israel`, `diaspora` | רשימת השבתות המיוחדות של השבת, מופרדות בפסיקים |
| `listAllParshiot` | (ללא) | רשימה ממוספרת של 54 הפרשיות |
| `checkIfHoliday` | `date` (חובה), `israel`, `diaspora` | האם התאריך חג (בכל יום בשבוע), עם היום בחודש העברי |
| `getDateInfo` | `date` (חובה) | תאריך גרגוריאני, עברי, בגימטריה, יום בשבוע ושנה מעוברת |
| `getYearSchedule` | `year`, `israel`, `diaspora` | טבלת wikitable של כל השבתות בשנה עברית. ברירת מחדל: השנה העברית של היום |

משמעות הפרמטרים:

- `date` – בפורמט `YYYY-MM-DD`. ברירת המחדל: היום (ראו ההערה על אזור הזמן בסעיף ההגבלות).
- `israel` – `yes` (ברירת מחדל) לחישוב לארץ ישראל; `no` לחישוב לחו"ל.
- `diaspora` – `yes` מחשב לחו"ל ודורס את `israel`.
- `plain` – `yes` מחזיר רק את שם הפרשה, ללא כותרת "פרשת" ובלי קריאות חג (ב-`getParsha`).
- `special` – `yes` מוסיף לפלט את השבתות המיוחדות של השבת (ב-`getParsha`).
- `year` – שנה עברית מספרית, למשל `5786` (ב-`getYearSchedule`).

### דוגמאות

שם הפרשה לתאריך:
```
{{#invoke:Parsha|getParsha|date=2025-10-18}}
```
פלט: `'''פרשת בראשית'''`

שבוע שבו פרשת בחקתי מחוברת לבהר בחו"ל:
```
{{#invoke:Parsha|getParsha|date=2018-05-12}}
```
פלט: `'''פרשת בחקתי'''`

```
{{#invoke:Parsha|getParsha|date=2018-05-12|diaspora=yes}}
```
פלט: `'''פרשת בהר-בחקתי'''`

פרשה עם שבת מיוחדת:
```
{{#invoke:Parsha|getParsha|date=2026-03-28|special=yes}}
```
פלט: `'''פרשת צו''' (שבת הגדול)`

שם הפרשה בלבד:
```
{{#invoke:Parsha|getParshaName|date=2025-10-18}}
```

שבת של חג – מוצגים השם, קריאת התורה, המפטיר וההפטרה:
```
{{#invoke:Parsha|getParsha|date=2025-10-11}}
```
פלט (חלקי): `'''חג: שבת חול המועד סוכות'''`, ואחריו `'''קריאת התורה:'''`, `'''מפטיר:'''` ו-`'''הפטרה:'''`.

בדיקה האם תאריך הוא חג:
```
{{#invoke:Parsha|checkIfHoliday|date=2025-09-25}}
```

מידע על תאריך:
```
{{#invoke:Parsha|getDateInfo|date=2025-10-04}}
```

שבתות מיוחדות לשבת:
```
{{#invoke:Parsha|getSpecialShabbat|date=2026-03-28}}
```

רשימת כל הפרשיות:
```
{{#invoke:Parsha|listAllParshiot}}
```

לוח שנה עברית מלא לחו"ל:
```
{{#invoke:Parsha|getYearSchedule|year=5786|diaspora=yes}}
```

## אופן הפעולה

- **לוח עברי** (`Module:HebrewDate`): מספר יום קבוע (Rata Die, `abs`) שבו 1 בינואר שנה 1 הוא היום 1 ו-`abs % 7 == 0` הוא יום ראשון. חישוב ראש השנה נעשה לפי המולד ו"ארבע הדחיות" (`elapsedDays`, `yearLengthCorrection`), והמרות בין לוח גרגוריאני ועברי נעשות דרך מספר היום הקבוע. מספור החודשים הפנימי: ניסן=1, תשרי=7, אדר=12 (אדר א' בשנה מעוברת), אדר ב'=13.
- **לוח הפרשיות** (`Module:Parsha`): לוח השבתות של כל שנה עברית נבנה במנוע מבוסס כללים, ולא בטבלת חיפוש. השבתות שאינן חג מחולקות לשלושה קטעים, והפרשיות משובצות בהם לפי הכללים הבאים (כפי שמתועדים בהערות הקוד):
  - **(א) לפני סוכות**: "וילך+האזינו" או "האזינו בלבד", לפי מספר השבתות הפנויות בתשרי שלפני סוכות.
  - **(ב)+(ג) מבראשית ועד השבת שלפני פסח**: "בשנה פשוטה צו נקרא בשבת שלפני פסח: מחברים ויקהל-פקודי לפי הצורך. בשנה מעוברת אין חיבורים בקטע זה."
  - **(ד) אחרי פסח ועד סוף השנה**: עד נצבים (ונצבים-וילך כשבשנה הבאה יש רק שבת פנויה אחת לפני סוכות). בחו"ל, חוקת-בלק מחוברות כשז' סיון חל בשבת. החיבורים נבחרים לפי סדר עדיפות: בשנה פשוטה תזריע-מצורע, אחרי מות-קדושים, מטות-מסעי ובהר-בחקתי; בשנה מעוברת מטות-מסעי בלבד.
  - פרשה 54, וזאת הברכה, אינה משובצת בלוח השבתות; היא נקראת בשמחת תורה, שהוא חג.
- **שבתות מיוחדות** (`specialShabbatot`): שבת שובה (השבתות שבין ראש השנה לכיפור), שבת שירה (בשלח), שבת שקלים (השבת שלפני או ביום ראשון אדר, או אדר ב' בשנה מעוברת), שבת זכור (השבת שלפני פורים), שבת פרה (שבת החודש פחות שבוע), שבת החודש (השבת שלפני או ביום ראש חודש ניסן), שבת הגדול (השבת שלפני פסח), שבת חזון (השבת שלפני או ביום ט' באב), ושבת נחמו (השבת שאחרי שבת חזון).
- **חגים וקריאות** (`Module:HolidayChecker`): טבלת החגים, ההבחנה בין ארץ ישראל לחו"ל, וטבלת הקריאות (תורה, מפטיר והפטרה) לכל חג ולחול המועד. הפונקציה `getHoliday` מחזירה את החג לפי חודש ויום בחודש העברי.

## Lua API

### Module:Parsha

#### שימוש ממודול אחר

לכל פונקציית `#invoke` יש גרסה עם קו תחתון שמקבלת טבלת ארגומנטים רגילה, בלי `frame`: `p._getParsha`, `p._getParshaName`, `p._getSpecialShabbat`, `p._checkIfHoliday`, `p._getDateInfo`, `p._getYearSchedule`. הפרמטרים זהים לאלה של `#invoke`; הדגלים (`israel`, `diaspora`, `plain`, `special`) מקבלים גם boolean וגם `"yes"`/`"no"`, ו-`year` יכול להיות מספר. הפונקציות מחזירות את אותה מחרוזת שמחזיר `#invoke`.

```lua
local parsha = require('Module:Parsha')

parsha._getParshaName{ date = '2018-05-12', diaspora = true }  -- "בהר-בחקתי"
parsha._getParsha{ special = true }                             -- הפרשה של השבת הקרובה, בעיצוב ויקי

-- נתונים גולמיים במקום מחרוזת:
local r = parsha.computeParsha(2025, 10, 18, true)
-- r.name, r.parshiot, r.holiday, r.special, r.saturday, r.hebrew
local y, m, d = parsha.today()  -- התאריך הלועזי של היום לפי שעון הוויקי
```

פונקציות ה-`_` דורשות את `Module:Yesno`; `computeParsha`, `getYearScheduleData` ו-`today` אינן תלויות באף מודול חיצוני.

- `p.parshiot` – טבלת 54 שמות הפרשיות לפי הסדר.
- `p.parshaName(list)` – מחבר רשימת אינדקסים של פרשיות לשם מחובר (למשל `בהר-בחקתי`).
- `p.getYearScheduleData(hy, israel)` – לוח השבתות של שנה עברית; כל רשומה כוללת `abs`, תאריך עברי, `holiday` ו-`parshiot`. התוצאה נשמרת במטמון.
- `p.computeParsha(y, m, d, israel)` – מחשב את הפרשה, החג והשבתות המיוחדות לשבת של התאריך (או השבת הבאה).
- פונקציות `#invoke`: `getParsha`, `getParshaName`, `getSpecialShabbat`, `listAllParshiot`, `checkIfHoliday`, `getDateInfo`, `getYearSchedule`.

### Module:HebrewDate
- `p.isValidGregorianDate(y, m, d)` – בדיקת תקינות תאריך גרגוריאני.
- `p.gregorianToAbsolute(y, m, d)` / `p.absoluteToGregorian(abs)` – המרה למספר היום הקבוע ובחזרה.
- `p.hebrewToAbsolute(hy, m, d)` / `p.absoluteToHebrew(abs)` – המרה בין לוח עברי למספר היום הקבוע ובחזרה.
- `p.isHebrewLeapYear(hy)` – האם השנה מעוברת.
- `p.monthsInHebrewYear(hy)` – מספר החודשים בשנה (12 או 13).
- `p.daysInHebrewYear(hy)` / `p.daysInHebrewMonth(hy, m)` – אורך השנה ואורך חודש.
- `p.getHebrewMonthName(num, isLeap)` – שם חודש לפי המספור הפנימי.
- `p.getHebrewMonthNumber(name)` – מספר חודש פנימי לפי שם (תומך גם בכתיבים חלופיים כמו "חשוון").
- `p.gregorianToHebrew(y, m, d)` – מחזיר שנה, שם חודש ויום עברי.
- `p.getDayOfWeek(y, m, d)`, `p.isSaturday(y, m, d)` – יום בשבוע (0 = ראשון) ובדיקת שבת.
- `p.getNextSaturday(y, m, d)` / `p.getSaturdayOnOrAfter(y, m, d)` – השבת הבאה, או השבת הקרובה שביום או אחרי התאריך.
- `p.getHebrewDateInfo(y, m, d)` – טבלה עם היום, החודש, השנה, יום בשבוע, שנה מעוברת ומספר היום הקבוע.
- `p.formatHebrewNumber(n, withThousands)` – מספר בגימטריה (למשל תשפ"ו).
- `p.formatHebrewDate(hy, hm, hd)` – תאריך עברי מעוצב, למשל י"א בתשרי ה'תשפ"ו.

### Module:HolidayChecker
- `p.getHoliday(hy, m, d, israel)` – מחזיר `{key, name, dayIndex}` אם התאריך חג, או `nil`.
- `p.getHolidayReading(nameOrKey)` – מחזיר את קריאות התורה, המפטיר וההפטרה של חג לפי מפתח או שם.
- `p.checkHolidayAnyDay(gy, gm, gd, israel)` – בודק חג בכל יום בשבוע לפי תאריך גרגוריאני.
- `p.checkHolidayOnSaturday(gy, gm, gd, israel)` – כמו הקודמת, אך מחזירה חג רק אם התאריך שבת.
- `p.isHolidayThatReplacesTorah(hy, monthName, day, israel)` – פונקציית תאימות לאחור לבדיקת חג לפי שם חודש.

## בדיקות

הרצה מתיקיית השורש של המאגר:

```
lua5.1 tests/run.lua
```

הבדיקות כוללות 35891 טענות (assertions). טבלת ההשוואה `tests/fixtures/saturdays.tsv` כוללת 6054 שבתות של השנים העבריות 5745 עד 5860, והיא נוצרה על ידי `@hebcal/core` (גרסה 6.16.1). ה-`@hebcal/core` משמש רק ככלי פיתוח (oracle) ואינו נדרש להרצת הבדיקות או לשימוש בוויקי. לחידוש הטבלה:

```
cd tests/tools && npm install && node gen_fixture.mjs
```

ב-CI (`.github/workflows/test.yml`) מתבצעות בדיקת תחביר עם `luac5.1 -p` לכל `Module_*.lua`, והרצת `lua5.1 tests/run.lua`.

## הגבלות והערות

- **"היום"** נקבע בוויקי לפי אזור הזמן המקומי של האתר (`$wgLocaltimezone`, כולל שעון קיץ) דרך `mw.getContentLanguage():formatDate`. מחוץ לוויקי (בבדיקות) משמש קירוב קבוע של UTC+2. היום מתחלף בחצות ולא בשקיעה.
- **טווח אימות**: המנוע נבדק מול הטבלה לשנים העבריות 5745 עד 5860. אם הכללים אינם מצליחים לשבץ את הפרשיות בשנה מסוימת, המנוע זורק שגיאה במקום להחזיר לוח שגוי.
- **קריאות החג** (תורה, מפטיר והפטרה) נכתבו בטבלה `READINGS` ב-`Module_HolidayChecker.lua`. יש לבדוק אותן על ידי אדם בקיא בהלכה ובמנהגי הקריאה לפני שימוש ציבורי.
- **שינוי שובר תאימות**: הפונקציות העזר `getHebrewMonthName` ו-`getHebrewMonthNumber` משתמשות כעת במספור פנימי (ניסן=1 ... תשרי=7 ... אדר ב'=13), ולא במספור הקודם. פונקציות ה-fallback הישנות וכן `getDayOfYear` הוסרו.
- **לא מטופל עדיין**: שינויי הפטרה בחנוכה, בפורים ובראש חודש. חגים אלו אינם מחליפים את פרשת השבוע, אך משנים את ההפטרה, ולכן המודול אינו מציג אותם.

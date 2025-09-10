local p = {}
local hebrewDate = require('Module:HebrewDate')

-- בדיקה אם תאריך נתון הוא חג שמחליף את קריאת הפרשה
function p.isHolidayThatReplacesTorah(hebrewYear, hebrewMonth, hebrewDay)
    -- חגים שמחליפים את קריאת התורה הרגילה
    local holidays = {
        -- ראש השנה
        {month = "תשרי", days = {1, 2}, name = "ראש השנה"},
        
        -- יום כיפור
        {month = "תשרי", days = {10}, name = "יום כיפור"},
        
        -- יום ראשון של סוכות
        {month = "תשרי", days = {15}, name = "סוכות"},
        
        -- שמיני עצרת/שמחת תורה
        {month = "תשרי", days = {22}, name = "שמיני עצרת"},
        {month = "תשרי", days = {23}, name = "שמחת תורה"}, -- בחו"ל
        
        -- יום ראשון של פסח
        {month = "ניסן", days = {15}, name = "פסח"},
        
        -- שביעי של פסח
        {month = "ניסן", days = {21}, name = "שביעי של פסח"},
        
        -- שבועות
        {month = "סיון", days = {6}, name = "שבועות"}
    }
    
    for _, holiday in ipairs(holidays) do
        if holiday.month == hebrewMonth then
            for _, day in ipairs(holiday.days) do
                if day == hebrewDay then
                    return true, holiday.name
                end
            end
        end
    end
    
    return false, nil
end

-- קבלת קריאת התורה המיוחדת לחג
function p.getHolidayReading(holidayName)
    local readings = {
        ["ראש השנה"] = {
            torah = "וַיְדַבֵּר ה' אֶל־מֹשֶׁה לֵּאמֹר (במדבר כט, א-ו)",
            maftir = "עקדת יצחק (בראשית כב, א-כד)",
            haftarah = "הנערה עקרה לא ילדה (שמואל א ב, א-י)"
        },
        
        ["יום כיפור"] = {
            torah = "אַחֲרֵי מוֹת (ויקרא טז, א-לד)",
            maftir = "וּבְיוֹם הַכִּפֻּרִים (במדבר כט, ז-יא)",
            haftarah = "ספר יונה + מיכה ז, יח-כ"
        },
        
        ["סוכות"] = {
            torah = "וַיְדַבֵּר מֹשֶׁה אֶל־בְּנֵי יִשְׂרָאֵל אֶת־מוֹעֲדֵי ה' (ויקרא כג, לד-מד)",
            maftir = "וּבְיוֹם הָרִאשׁוֹן (במדבר כט, יב-טז)",
            haftarah = "הִנֵּה יָמִים בָּאִים (זכריה יד, א-כא)"
        },
        
        ["שמיני עצרת"] = {
            torah = "וְזֹאת הַבְּרָכָה (דברים לג, א-לד ושמ, א-ח)",
            maftir = "בַּיּוֹם הַשְּׁמִינִי (במדבר כט, לה-לט)",
            haftarah = "וַיְהִי כְּכַלּוֹת שְׁלֹמֹה (מלכים א ח, נד-סו)"
        },
        
        ["שמחת תורה"] = {
            torah = "וְזֹאת הַבְּרָכָה (דברים לג-לד) + בְּרֵאשִׁית (בראשית א, א-ה)",
            maftir = "בַּיּוֹם הַשְּׁמִינִי (במדבר כט, לה-לט)",
            haftarah = "וַיְהִי אַחֲרֵי מוֹת מֹשֶׁה (יהושע א, א-יח)"
        },
        
        ["פסח"] = {
            torah = "בֹּא אֶל־פַּרְעֹה (שמות יב, כא-נא)",
            maftir = "בַּחֹדֶשׁ הָרִאשׁוֹן (במדבר כח, טז-כה)",
            haftarah = "וַיְהִי בְּשַׁלַּח (יהושע ג, ה - ה, יב)"
        },
        
        ["שביעי של פסח"] = {
            torah = "וַיְהִי בְּשַׁלַּח פַּרְעֹה (שמות יג, יז - טו, כו)",
            maftir = "וּבַיּוֹם הַשְּׁבִיעִי (במדבר כח, יט-כה)",
            haftarah = "וַיְדַבֵּר דָּוִד (שמואל ב כב, א-נא)"
        },
        
        ["שבועות"] = {
            torah = "בַּחֹדֶשׁ הַשְּׁלִישִׁי (שמות יט, א - כ, כג)",
            maftir = "וּבְיוֹם הַבִּכּוּרִים (במדבר כח, כו-לא)",
            haftarah = "וַיְהִי דְבַר־ה' (יחזקאל א, א-כח + ג, יב)"
        }
    }
    
    return readings[holidayName]
end

-- בדיקה אם חג חל בשבת ומחליף את הפרשה
function p.checkHolidayOnSaturday(gregorianYear, gregorianMonth, gregorianDay)
    -- בדיקה אם התאריך הנתון הוא שבת
    if not hebrewDate.isSaturday(gregorianYear, gregorianMonth, gregorianDay) then
        return false, nil, nil
    end
    
    -- קבלת מידע מפורט על התאריך העברי
    local hebrewInfo = hebrewDate.getHebrewDateInfo(gregorianYear, gregorianMonth, gregorianDay)
    
    -- בדיקה אם זה חג שמחליף את הפרשה
    local isHoliday, holidayName = p.isHolidayThatReplacesTorah(
        hebrewInfo.hebrewYear, 
        hebrewInfo.hebrewMonth, 
        hebrewInfo.hebrewDay
    )
    
    if isHoliday then
        local reading = p.getHolidayReading(holidayName)
        return true, holidayName, reading
    end
    
    return false, nil, nil
end

-- פונקציה חדשה: בדיקת חגים לכל תאריך (לא רק שבת)
function p.checkHolidayAnyDay(gregorianYear, gregorianMonth, gregorianDay)
    local hebrewInfo = hebrewDate.getHebrewDateInfo(gregorianYear, gregorianMonth, gregorianDay)
    
    local isHoliday, holidayName = p.isHolidayThatReplacesTorah(
        hebrewInfo.hebrewYear, 
        hebrewInfo.hebrewMonth, 
        hebrewInfo.hebrewDay
    )
    
    if isHoliday then
        local reading = p.getHolidayReading(holidayName)
        return true, holidayName, reading, hebrewInfo
    end
    
    return false, nil, nil, hebrewInfo
end

return p

local P = require('Module:Parsha')
local H = require('Module:HebrewDate')
for _, israel in ipairs({ true, false }) do
    local tag = israel and 'IL' or 'DIA'
    for hy = 5745, 5860 do
        local sched = P.getYearScheduleData(hy, israel)
        local seen = {}
        local last
        for _, e in ipairs(sched) do
            for _, idx in ipairs(e.parshiot) do
                seen[idx] = (seen[idx] or 0) + 1
                if idx == 44 then
                    local av9 = H.hebrewToAbsolute(hy, 5, 9)
                    T.ok(e.abs <= av9 and av9 - e.abs < 7, tag .. ' Devarim before 9 Av ' .. hy)
                end
            end
            last = e
        end
        T.eq(last.parshiot[1], 51, tag .. ' Nitzavim on last Saturday ' .. hy)
        T.eq(seen[54], nil, tag .. ' Vezot Habracha never weekly ' .. hy)
        -- cycle: Vayelech/Haazinu of the Tishrei of hy+1 complete the cycle that starts at Bereshit hy
        local nxt = P.getYearScheduleData(hy + 1, israel)
        for _, e in ipairs(nxt) do
            if e.hm == 7 and e.hd < 15 then
                for _, idx in ipairs(e.parshiot) do seen[idx] = (seen[idx] or 0) + 1 end
            end
        end
        for _, e in ipairs(sched) do
            if e.hm == 7 and e.hd < 15 then
                for _, idx in ipairs(e.parshiot) do seen[idx] = seen[idx] - 1 end
            end
        end
        for i = 1, 53 do T.eq(seen[i], 1, tag .. ' parsha ' .. i .. ' once in cycle ' .. hy) end
    end
end

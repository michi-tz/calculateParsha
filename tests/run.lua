-- Plain-Lua (5.1) test runner. Usage from repo root: lua5.1 tests/run.lua
-- Maps require('Module:X') -> ./Module_X.lua and stubs Module:Arguments / Module:Yesno.

local stubs = {
    ['Module:Arguments'] = {
        getArgs = function(frame)
            if type(frame) == 'table' and type(frame.args) == 'table' then return frame.args end
            return frame or {}
        end,
    },
    ['Module:Yesno'] = function(val, default)
        if val == nil then return nil end
        if type(val) == 'boolean' then return val end
        local v = tostring(val):lower()
        if v == 'yes' or v == 'y' or v == 'true' or v == '1' or v == 'on' or v == 'כן' then return true end
        if v == 'no' or v == 'n' or v == 'false' or v == '0' or v == 'off' or v == 'לא' or v == '' then return false end
        return default
    end,
}

table.insert(package.loaders, 2, function(name)
    if stubs[name] ~= nil then
        return function() return stubs[name] end
    end
    local mod = name:match('^Module:(.+)$')
    if not mod then return nil end
    local path = './Module_' .. mod:gsub(' ', '_') .. '.lua'
    local f, err = loadfile(path)
    if not f then return '\n\tno file ' .. path .. ' (' .. tostring(err) .. ')' end
    return f
end)

-- assertion helpers
T = { passed = 0, failed = 0, current = '' }
function T.ok(cond, msg)
    if cond then
        T.passed = T.passed + 1
    else
        T.failed = T.failed + 1
        if T.failed <= 50 then print('FAIL [' .. T.current .. '] ' .. tostring(msg)) end
    end
    return cond
end
function T.eq(actual, expected, msg)
    return T.ok(actual == expected, (msg or '') .. ': expected ' .. tostring(expected) .. ', got ' .. tostring(actual))
end

local files = { 'test_calendar', 'test_holidays', 'test_fixture', 'test_special', 'test_invariants', 'test_frame' }
for _, name in ipairs(files) do
    T.current = name
    local f, err = loadfile('tests/' .. name .. '.lua')
    if not f then
        T.ok(false, 'cannot load ' .. name .. ': ' .. tostring(err))
    else
        local okRun, e = pcall(f)
        T.ok(okRun, 'error in ' .. name .. ': ' .. tostring(e))
    end
end

print(string.format('%d passed, %d failed', T.passed, T.failed))
os.exit(T.failed == 0 and 0 or 1)

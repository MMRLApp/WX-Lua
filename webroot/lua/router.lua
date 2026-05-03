imports "dev.mmrlx.webui.WebResourceResponse"

local App = {
    routes       = {},
    _initialized = false,
    mount        = "/myPath/",
}

local function normalize_mount(m)
    if not m then return "/" end
    if m:sub(1, 1) ~= "/" then m = "/" .. m end
    if m:sub(-1) ~= "/" then m = m .. "/" end
    return m
end

local function escape_magic(s)
    return (s:gsub("([%.%+%-%*%?%[%]%^%$%(%)%%])", "%%%1"))
end

local function compile_route(path)
    local param_names = {}
    local normalized = path ~= "/" and path:gsub("/$", "") or path

    if normalized == "/" then
        return "^/?$", param_names
    end

    local segments = {}
    for segment in normalized:gmatch("/([^/]*)") do
        segments[#segments + 1] = segment
    end

    local pattern = "^"
    local wildcard = false
    for _, segment in ipairs(segments) do
        if segment == "*" then
            pattern = pattern .. "/(.*)"
            wildcard = true
            break
        elseif segment:sub(1, 1) == ":" then
            param_names[#param_names + 1] = segment:sub(2)
            pattern = pattern .. "/([^/]+)"
        else
            pattern = pattern .. "/" .. escape_magic(segment)
        end
    end
    if not wildcard then
        pattern = pattern .. "/?$"
    end

    return pattern, param_names
end

local _compiled = {}

function App.get(path, callback)
    if path:sub(1, 1) ~= "/" then path = "/" .. path end

    if not path:find("[:*]") then
        App.routes[path] = callback
    end
    local pattern, param_names = compile_route(path)
    _compiled[#_compiled + 1] = {
        pattern     = pattern,
        param_names = param_names,
        callback    = callback,
        exact       = not path:find("[:*]"),
        path        = path,
    }
end

local function sort_routes()
    table.sort(_compiled, function(a, b)
        if a.exact ~= b.exact then return a.exact end
        local wa = select(2, a.path:gsub("[:*]", ""))
        local wb = select(2, b.path:gsub("[:*]", ""))
        return wa < wb
    end)
end

local function match_route(path)
    path = path ~= "/" and path:gsub("/$", "") or path

    if App.routes[path] then
        return App.routes[path], {}
    end

    for _, route in ipairs(_compiled) do
        local captures = { path:match(route.pattern) }
        if #captures > 0 or path:match(route.pattern) then
            local params = {}
            for i, name in ipairs(route.param_names) do
                params[name] = captures[i]
            end
            if #route.param_names == 0 and #captures > 0 then
                params.wildcard = captures[1]
            end
            return route.callback, params
        end
    end

    return nil, {}
end

local function master_handler(request)
    local res_headers = { ["Content-Type"] = "text/plain" }

    local mount = normalize_mount(App.mount)
    local path  = request.path

    if path:sub(1, 1) ~= "/" then path = "/" .. path end

    if mount ~= "/" then
        local prefix = mount:sub(1, -2)
        if path:sub(1, #prefix) == prefix then
            path = path:sub(#prefix + 1)
        end
    end

    if path == "" then path = "/" end

    local handler, params = match_route(path)

    if handler then
        request.params = params
        local status, body = handler(request, res_headers)
        return WebResourceResponse(
            res_headers["Content-Type"],
            "UTF-8",
            status or 200,
            "OK",
            res_headers,
            body
        )
    else
        return WebResourceResponse(
            "application/json",
            "UTF-8",
            404,
            "Not Found",
            res_headers,
            '{"error":"Path not found","path":"' .. request.path .. '"}'
        )
    end
end

if not App._initialized then
    sort_routes()
    registerPathHandler(normalize_mount(App.mount), master_handler)
    App._initialized = true
end

return App
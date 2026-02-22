require("wx:str")
local wv = require("wx:webview")

ApiPathHandler = {}
ApiPathHandler.__index = ApiPathHandler

function ApiPathHandler.new()
    return setmetatable({}, ApiPathHandler)
end

function ApiPathHandler:handle(request)
    local method = request:getMethod()
    local path   = request:getPath()
    
    print("[" .. method .. "] " .. path)
    
    if path == "root-result.txt" then
        return wv.textResponse("Hello World!")
    end
    
    if startsWith(path, "users/") then
        return wv.jsonResponse('{"lua":true,"user":' .. jsonString(path) .. '}')
    end
    
    return nil
end

return ApiPathHandler
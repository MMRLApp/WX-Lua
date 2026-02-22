-- FileInputStream.lua

require("wx:std")

local WebViewFeature  = java.import("androidx.webkit.WebViewFeature")
local WebMessageCompat = java.import("androidx.webkit.WebMessageCompat")
local Array = java.import("java.lang.reflect.Array")
local Byte = java.import("java.lang.Byte")
local ByteArrayOutputStream = java.import("java.io.ByteArrayOutputStream")
local BufferedInputStream = java.import("java.io.BufferedInputStream")

local DEFAULT_BUFFER_SIZE = 8 * 1024

FileInputStream = {}
FileInputStream.__index = FileInputStream

function SuFile(path)
    sufile_import = java.import("com.dergoogler.mmrl.platform.file.SuFile")
    return java.new(sufile_import, {path})
end

local function copyTo(input, output, bufferSize)
    bufferSize = bufferSize or DEFAULT_BUFFER_SIZE
    local bytesCopied = 0
    local chunk
    local buf = BufferedInputStream(input, bufferSize)
    -- read byte by byte as fallback
    local b = buf:read()
    while b ~= -1 do
        output:write(b)
        bytesCopied = bytesCopied + 1
        b = buf:read()
    end
    return bytesCopied
end

local function readBytes(input)
    local available = input:available()
    local size = math.max(DEFAULT_BUFFER_SIZE, available)
    local buffer = ByteArrayOutputStream(size)
    copyTo(input, buffer)
    return buffer:toByteArray()
end

function FileInputStream.new()
    return setmetatable({}, FileInputStream)
end

function FileInputStream:listen(event)
    local message = event:getMessage()
    local reply   = event:getReply()
    local data    = message:getData()

    if data == nil then
        reply:postMessage("Failed! Data was null.")
        return
    end

    local file = SuFile(data)

    if not file:exists() then
        reply:postMessage("Failed! File does not exist.")
        return
    end

    local msgType = message:getType()

    if msgType == WebMessageCompat.TYPE_STRING then
        if WebViewFeature:isFeatureSupported(WebViewFeature.WEB_MESSAGE_ARRAY_BUFFER) then
            local ok, err = pcall(function()
                local inputStream = file:newInputStream()
                local bytes = readBytes(inputStream)
                inputStream:close()
                reply:postMessage(bytes)
            end)
            if not ok then
                reply:postMessage("Failed! " .. tostring(err))
            end
        else
            reply:postMessage("Failed! WebMessageCompat.TYPE_ARRAY_BUFFER not supported.")
        end
    end
end

return FileInputStream
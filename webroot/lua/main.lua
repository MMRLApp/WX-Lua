local wv = require("wx:webview")

local ApiPathHandler = require("handlers.ApiPathHandler")
local ShellSpawn = require("events.FileInputStream")

-- Set a custom path handler. It is accessibile over https://mui.kernelsu.org/api/
wv.registerPathHandler("/api/", ApiPathHandler)

-- Define the path handler with a own host. It is accessibile over https://mui.mmrl.dev/api/
-- Don't forget to change the Content Security Policy as it will throw a error if not proper set up
-- wv.registerPathHandler("/api/", ApiPathHandler, "httrps://mui.mmrl.dev")

-- A custom FileInputStream event
wv.registerEventListener("FileInputStream", FileInputStream)

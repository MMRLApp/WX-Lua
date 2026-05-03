local package = require("package")
local router = require("router")

router.get("/package/list.json", function(req, headers)
    return 200, package.list()
end)

router.get("/package/icon/:id", function(req, headers)
    local packageName = req.params.id
    headers["Content-Type"] = "image/png"
    return 200, package.icon(packageName)
end)




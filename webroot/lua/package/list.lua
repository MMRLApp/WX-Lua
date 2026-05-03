imports "org.json.JSONArray"
imports "org.json.JSONObject"

return function()
    local pm = activity.getPackageManager()
    local jsonArray = JSONArray()
    local packages = pm.getInstalledPackages(0)
    
    for i = 1, #packages do
        local p = packages[i-1]
        if p then
            local appInfo = p.applicationInfo
            local packageObj = JSONObject()
            
            packageObj.put("appName", tostring(pm.getApplicationLabel(appInfo)))
            packageObj.put("packageName", p.packageName)
            packageObj.put("versionName", p.versionName)
            packageObj.put("versionCode", p.versionCode)
            
            packageObj.put("targetSdkVersion", appInfo.targetSdkVersion)
            packageObj.put("minSdkVersion", appInfo.minSdkVersion or "Unknown")
            packageObj.put("sourceDir", appInfo.sourceDir)
            packageObj.put("dataDir", appInfo.dataDir)
            packageObj.put("firstInstallTime", p.firstInstallTime)
            packageObj.put("lastUpdateTime", p.lastUpdateTime)
            packageObj.put("className", appInfo.className or "N/A")
            
            jsonArray.put(packageObj)
        end
    end

    return jsonArray.toString()
end
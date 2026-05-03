imports "android.graphics.Bitmap"
imports "android.graphics.Canvas"
imports "android.graphics.drawable.BitmapDrawable"
imports "java.io.ByteArrayOutputStream"
imports "java.io.ByteArrayInputStream"

return function(packageName)
    local pm = activity.getPackageManager()
    
    local status, appInfo = pcall(function() 
        return pm.getApplicationInfo(packageName, 0) 
    end)
    
    if not status or not appInfo then return nil end

    local drawable = appInfo.loadIcon(pm)
    local bitmap
    
    if tostring(drawable.getClass().getName()) == "android.graphics.drawable.BitmapDrawable" then
        bitmap = drawable.getBitmap()
    else
        local width = drawable.getIntrinsicWidth()
        local height = drawable.getIntrinsicHeight()
        
        if width <= 0 then width = 100 end
        if height <= 0 then height = 100 end

        bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        local canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.getWidth(), canvas.getHeight())
        drawable.draw(canvas)
    end
    
    -- Compress to PNG and return as InputStream
    local outputStream = ByteArrayOutputStream()
    bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
    
    return ByteArrayInputStream(outputStream.toByteArray())
end

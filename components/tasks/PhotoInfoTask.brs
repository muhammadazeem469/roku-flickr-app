' ******************************************************
' PhotoInfoTask.brs
' Task for loading photo information from Flickr API
' Runs on task thread to avoid blocking render thread
' ******************************************************

sub init()
    ' Task entry point
    m.top.functionName = "loadPhotoInfo"
end sub

' Load photo information from Flickr API
' This runs on a separate thread when the task is started
sub loadPhotoInfo()
    print "[PhotoInfoTask] Loading photo info for ID: "; m.top.photoId
    
    photoId = m.top.photoId
    
    if photoId = invalid or photoId = "" then
        print "[PhotoInfoTask] ERROR: Invalid photo ID"
        result = {}
        result.success = false
        result.error = "Invalid photo ID"
        result.data = invalid
        m.top.result = result
        return
    end if
    
    ' Build API URL
    apiKey = "452b3b7a5d806dcd110842e6649c604d"
    url = "https://api.flickr.com/services/rest/"
    url = url + "?method=flickr.photos.getInfo"
    url = url + "&api_key=" + apiKey
    url = url + "&photo_id=" + photoId
    url = url + "&format=json"
    url = url + "&nojsoncallback=1"
    
    print "[PhotoInfoTask] Request URL: "; url
    
    ' Create HTTP request (THIS IS OK ON TASK THREAD)
    request = CreateObject("roUrlTransfer")
    
    if request = invalid then
        print "[PhotoInfoTask] ERROR: Failed to create roUrlTransfer"
        result = {}
        result.success = false
        result.error = "Failed to create HTTP request"
        result.data = invalid
        m.top.result = result
        return
    end if
    
    request.SetUrl(url)
    request.EnablePeerVerification(false)
    request.EnableHostVerification(false)
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.InitClientCertificates()
    
    ' Make synchronous request (OK because we're on a task thread)
    response = request.GetToString()
    
    if response = invalid or response = "" then
        print "[PhotoInfoTask] ERROR: Empty response from API"
        result = {}
        result.success = false
        result.error = "Empty response from API"
        result.data = invalid
        m.top.result = result
        return
    end if
    
    print "[PhotoInfoTask] Response received, length: "; response.Len()
    
    ' Parse JSON response
    json = ParseJson(response)
    
    if json = invalid then
        print "[PhotoInfoTask] ERROR: Failed to parse JSON response"
        result = {}
        result.success = false
        result.error = "Invalid JSON response"
        result.data = invalid
        m.top.result = result
        return
    end if
    
    ' Check for API error
    if json.stat <> invalid and json.stat = "fail" then
        errorMsg = "API Error"
        if json.message <> invalid then
            errorMsg = json.message
        end if
        print "[PhotoInfoTask] API Error: "; errorMsg
        result = {}
        result.success = false
        result.error = errorMsg
        result.data = invalid
        m.top.result = result
        return
    end if
    
    ' Extract photo data
    if json.photo = invalid then
        print "[PhotoInfoTask] ERROR: No photo data in response"
        result = {}
        result.success = false
        result.error = "No photo data in response"
        result.data = invalid
        m.top.result = result
        return
    end if
    
    print "[PhotoInfoTask] Photo info loaded successfully"
    
    ' Return success result
    result = {}
    result.success = true
    result.error = ""
    result.data = json.photo
    m.top.result = result
end sub

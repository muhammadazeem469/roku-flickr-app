' ******************************************************
' FlickrService.brs
' Service layer for Flickr API interactions
' Handles HTTP requests and response parsing
' ******************************************************

' Fetch detailed photo information from Flickr API
' @param photoId - The Flickr photo ID
' @return Object with success flag and data/error
function FlickrService_GetPhotoInfo(photoId as String) as Object
    print "[FlickrService] Fetching photo info for ID: "; photoId
    
    ' Build URL using existing helper
    url = BuildPhotoInfoURL(photoId)
    print "[FlickrService] Request URL: "; url
    
    ' Create HTTP request
    request = CreateObject("roUrlTransfer")
    request.SetUrl(url)
    request.EnablePeerVerification(false)
    request.EnableHostVerification(false)
    
    ' Make synchronous request
    response = request.GetToString()
    
    if response = invalid or response = "" then
        print "[FlickrService] ERROR: Empty or invalid response"
        return {
            success: false
            error: "Failed to fetch photo information"
            data: invalid
        }
    end if
    
    ' Parse JSON response
    json = ParseJson(response)
    
    if json = invalid then
        print "[FlickrService] ERROR: Failed to parse JSON response"
        return {
            success: false
            error: "Invalid JSON response from server"
            data: invalid
        }
    end if
    
    ' Check for API errors
    if json.stat <> invalid and json.stat = "fail" then
        errorMsg = "Unknown API error"
        if json.message <> invalid then
            errorMsg = json.message
        end if
        print "[FlickrService] API Error: "; errorMsg
        return {
            success: false
            error: errorMsg
            data: invalid
        }
    end if
    
    ' Validate response structure
    if json.photo = invalid then
        print "[FlickrService] ERROR: Missing photo data in response"
        return {
            success: false
            error: "Invalid response structure"
            data: invalid
        }
    end if
    
    print "[FlickrService] Successfully fetched photo info"
    return {
        success: true
        error: ""
        data: json.photo
    }
end function


' Async version using roUrlEvent (for future use)
' @param photoId - The Flickr photo ID
' @param port - Message port for async callbacks
' @return roUrlTransfer object
function FlickrService_GetPhotoInfoAsync(photoId as String, port as Object) as Object
    print "[FlickrService] Starting async fetch for photo ID: "; photoId
    
    url = BuildPhotoInfoURL(photoId)
    
    request = CreateObject("roUrlTransfer")
    request.SetUrl(url)
    request.SetPort(port)
    request.EnablePeerVerification(false)
    request.EnableHostVerification(false)
    
    if request.AsyncGetToString() then
        print "[FlickrService] Async request initiated"
        return request
    else
        print "[FlickrService] ERROR: Failed to initiate async request"
        return invalid
    end if
end function
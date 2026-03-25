' ******************************************************
' FlickrService.brs
' Service layer for Flickr API interactions
' Handles HTTP requests and response parsing
' ******************************************************

' ============================================
' EXISTING METHOD - KEEP AS IS
' ============================================

' Fetch detailed photo information from Flickr API
' @param photoId - The Flickr photo ID
' @return Object with success flag and data/error
function FlickrService_GetPhotoInfo(photoId as String) as Object
    
    ' Build URL using existing helper
    url = BuildPhotoInfoURL(photoId)
    
    ' Create HTTP request
    request = CreateObject("roUrlTransfer")
    request.SetUrl(url)
    request.EnablePeerVerification(false)
    request.EnableHostVerification(false)
    
    ' Make synchronous request
    response = request.GetToString()
    
    if response = invalid or response = "" then
return {
            success: false
            error: "Failed to fetch photo information"
            data: invalid
        }
    end if
    
    ' Parse JSON response
    json = ParseJson(response)
    
    if json = invalid then
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
        return {
            success: false
            error: errorMsg
            data: invalid
        }
    end if
    
    ' Validate response structure
    if json.photo = invalid then
return {
            success: false
            error: "Invalid response structure"
            data: invalid
        }
    end if
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
    
    url = BuildPhotoInfoURL(photoId)
    
    request = CreateObject("roUrlTransfer")
    request.SetUrl(url)
    request.SetPort(port)
    request.EnablePeerVerification(false)
    request.EnableHostVerification(false)
    
    if request.AsyncGetToString() then
return request
    else
return invalid
    end if
end function


' ============================================
' NEW METHODS FOR FG-011
' ============================================

' Constructor - NEW
function CreateFlickrService() as Object
    return {
        ' New methods
        getInterestingImages: FlickrService_getInterestingImages
        searchImagesByTag: FlickrService_searchImagesByTag
        getRecentImages: FlickrService_getRecentImages
        getImageInfo: FlickrService_getImageInfo
        
        ' Legacy method (keep for backward compatibility)
        GetPhotoInfo: FlickrService_GetPhotoInfo
        GetPhotoInfoAsync: FlickrService_GetPhotoInfoAsync
        
        ' Helper modules
        apiMethods: FlickrService_ApiMethods()
        responseParser: FlickrService_ResponseParser()
    }
end function


' Wrapper for new API - calls existing method
function FlickrService_getImageInfo(photoId as String) as Object
    return FlickrService_GetPhotoInfo(photoId)
end function


' Get interesting images - delegates to ApiMethods
function FlickrService_getInterestingImages(page as Integer, perPage as Integer) as Object
    return m.apiMethods.getInterestingImages(page, perPage)
end function


' Search by tags - delegates to ApiMethods
function FlickrService_searchImagesByTag(tags as String, page as Integer, perPage as Integer) as Object
    return m.apiMethods.searchImagesByTag(tags, page, perPage)
end function


' Get recent images - delegates to ApiMethods
function FlickrService_getRecentImages(page as Integer, perPage as Integer) as Object
    return m.apiMethods.getRecentImages(page, perPage)
end function


' Create error response helper
function FlickrService_createErrorResponse(errorMessage as String) as Object
    return {
        success: false
        data: []
        error: errorMessage
        page: 0
        pages: 0
        total: 0
    }
end function
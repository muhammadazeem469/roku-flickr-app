' ******************************************************
' HttpClient.brs
' Core HTTP client for making requests
' Handles request creation, execution, and basic response handling
' ******************************************************

' Make HTTP GET request
' @param url - Full URL to request
' @param timeout - Timeout in milliseconds
' @return Object with { success, data, error, statusCode, errorCategory }
function HttpClient_makeRequest(url as String, timeout as Integer) as Object
    ' Validate URL
    if url = "" or url = invalid then
        return HttpClient_createErrorResponse("INVALID_URL", "URL is empty or invalid", 0)
    end if

    ' Create request object
    request = HttpClient_createRequestObject(url)
    if request = invalid then
        return HttpClient_createErrorResponse("REQUEST_CREATION_FAILED", "Could not create HTTP request object", 0)
    end if

    ' Execute request
    ' Note: GetResponseCode() is only available on roUrlEvent (async interface).
    ' Flickr always returns HTTP 200 even for API errors; failures are detected
    ' via stat:"fail" in the JSON body by FlickrService_ResponseParser.
    response = request.GetToString()

    ' Validate response body
    if response = invalid or response = "" then
        return HttpClient_createErrorResponse("EMPTY_RESPONSE", "Server returned empty response", 0)
    end if

    return {
        success: true
        data: response
        error: ""
        statusCode: 200
        errorCategory: ""
    }
end function


' Create and configure roUrlTransfer object
' @param url - URL to request
' @return roUrlTransfer object or invalid
function HttpClient_createRequestObject(url as String) as Object
    request = CreateObject("roUrlTransfer")
    
    if request = invalid then
return invalid
    end if
    
    ' Configure request
    request.SetUrl(url)
    request.EnablePeerVerification(true)
    request.EnableHostVerification(true)

    ' Set headers
    request.AddHeader("Accept", "application/json")
    request.AddHeader("User-Agent", "FlickrGallery/1.0")
    
    return request
end function


' Create standardized error response
' @param category - Error category
' @param message - Error message  
' @param statusCode - HTTP status code
' @return Error response object
function HttpClient_createErrorResponse(category as String, message as String, statusCode as Integer) as Object
    return {
        success: false
        data: invalid
        error: message
        statusCode: statusCode
        errorCategory: category
    }
end function



' ******************************************************
' HttpClient.brs
' Core HTTP client for making requests
' Handles request creation, execution, and basic response handling
' ******************************************************

' Make HTTP GET request
' @param url - Full URL to request
' @param timeout - Timeout in milliseconds
' @return Object with { success, data, error, statusCode, errorCategory }
' Make HTTP GET request (simplified - no status code checking)
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
    response = request.GetToString()
    
    ' Validate response
    if response = invalid or response = "" then
return HttpClient_createErrorResponse("EMPTY_RESPONSE", "Server returned empty response", 0)
    end if
    
    ' Success - we got data
return {
        success: true
        data: response
        error: ""
        statusCode: 200
        errorCategory: ""
    }
end function

' Get HTTP status code safely
' @param request - roUrlTransfer object
' @return Integer - Status code (200 if successful but unknown, 0 if error)
function HttpClient_getStatusCode(request as Object) as Integer
    if request = invalid then
        return 0
    end if
    
    statusCode = 200  ' Default to success
    
    ' Try to get response headers first (more reliable)
    headers = request.GetResponseHeaders()
    
    if headers <> invalid and headers.Count() > 0 then
        ' Response headers exist, so request was successful
        ' Try to parse status from headers
        if headers["Status"] <> invalid then
            statusStr = headers["Status"]
            ' Status header format: "200 OK" or just "200"
            statusCode = statusStr.ToInt()
        end if
        return statusCode
    end if
    
    ' If no headers, assume success if we got this far
return 200
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
    request.EnablePeerVerification(false)
    request.EnableHostVerification(false)
    
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


' Make async HTTP request (for future use)
' @param url - URL to request
' @param port - Message port for callbacks
' @return roUrlTransfer object or invalid
function HttpClient_makeAsyncRequest(url as String, port as Object) as Object
    
    request = HttpClient_createRequestObject(url)
    if request = invalid then
        return invalid
    end if
    
    request.SetPort(port)
    
    if request.AsyncGetToString() then
return request
    else
return invalid
    end if
end function
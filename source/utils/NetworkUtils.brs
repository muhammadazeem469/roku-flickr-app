' ******************************************************
' NetworkUtils.brs
' Facade/wrapper for network operations
' Provides simplified API for common network tasks
' ******************************************************

' Make HTTP request with automatic retry
' @param url - URL to request
' @param options - Optional settings { maxRetries, timeout }
' @return Object - Response with parsed JSON
function NetworkUtils_request(url as String, options as Object) as Object
    ' Set defaults
    maxRetries = 3
    timeout = 10000
    
    if options <> invalid then
        if options.maxRetries <> invalid then
            maxRetries = options.maxRetries
        end if
        if options.timeout <> invalid then
            timeout = options.timeout
        end if
    end if
    
    ' Check network first
    if not NetworkValidator_isAvailable() then
        return HttpClient_createErrorResponse("NETWORK_UNAVAILABLE", "No network connection", 0)
    end if
    
    ' Make request with retry
    response = RetryManager_retryRequest(url, maxRetries)
    
    ' Parse JSON if successful
    if response.success then
        return JsonParser_parse(response)
    end if
    
    return response
end function

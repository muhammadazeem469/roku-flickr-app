' ******************************************************
' RetryManager.brs
' Manages retry logic with exponential backoff
' Handles retry attempts, delays, and retry decision making
' ******************************************************

' Retry request with exponential backoff
' @param url - URL to request
' @param maxRetries - Maximum retry attempts
' @return Object - Request response
function RetryManager_retryRequest(url as String, maxRetries as Integer) as Object
    
    ' Get config
    config = GetNetworkConfig()
    
    if maxRetries <= 0 then
        maxRetries = config.MAX_RETRIES
    end if
    
    attempt = 0
    
    while attempt <= maxRetries
        
        ' Make request
        response = HttpClient_makeRequest(url, config.DEFAULT_TIMEOUT)
        
        ' Success - return immediately
        if response.success then
            return response
        end if
        
        ' Check if should retry
        if not RetryManager_shouldRetry(response, attempt, maxRetries) then
return response
        end if
        
        ' Calculate and apply backoff
        RetryManager_applyBackoff(attempt)
        
        attempt = attempt + 1
    end while
return response
end function


' Determine if request should be retried
' @param response - Response from previous attempt
' @param currentAttempt - Current attempt number
' @param maxRetries - Maximum allowed retries
' @return Boolean - true if should retry
function RetryManager_shouldRetry(response as Object, currentAttempt as Integer, maxRetries as Integer) as Boolean
    ' Don't retry if this was the last attempt
    if currentAttempt >= maxRetries then
        return false
    end if
    
    ' Check if error is retryable
    errorInfo = ErrorHandler_handle(response)
    
    if not errorInfo.isRetryable then
        return false
    end if
    
    return true
end function


' Apply exponential backoff delay
' @param attemptNumber - Current attempt number (0-indexed)
function RetryManager_applyBackoff(attemptNumber as Integer) as Void
    config = GetNetworkConfig()
    
    ' Calculate backoff: 1s, 2s, 4s, 8s (capped at MAX_BACKOFF_SECONDS)
    backoffSeconds = config.BASE_BACKOFF_SECONDS * (2 ^ attemptNumber)
    
    if backoffSeconds > config.MAX_BACKOFF_SECONDS then
        backoffSeconds = config.MAX_BACKOFF_SECONDS
    end if
Sleep(backoffSeconds * 1000)
end function



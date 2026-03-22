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
    print "[RetryManager] Starting retry logic for: "; url
    print "[RetryManager] Max retries: "; maxRetries
    
    ' Get config
    config = GetNetworkConfig()
    
    if maxRetries <= 0 then
        maxRetries = config.MAX_RETRIES
    end if
    
    attempt = 0
    
    while attempt <= maxRetries
        print "[RetryManager] Attempt "; attempt + 1; " of "; maxRetries + 1
        
        ' Make request
        response = HttpClient_makeRequest(url, config.DEFAULT_TIMEOUT)
        
        ' Success - return immediately
        if response.success then
            print "[RetryManager] Success on attempt "; attempt + 1
            return response
        end if
        
        ' Check if should retry
        if not RetryManager_shouldRetry(response, attempt, maxRetries) then
            print "[RetryManager] Not retrying - final attempt or non-retryable error"
            return response
        end if
        
        ' Calculate and apply backoff
        RetryManager_applyBackoff(attempt)
        
        attempt = attempt + 1
    end while
    
    print "[RetryManager] All retries exhausted"
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
        print "[RetryManager] Error not retryable: "; errorInfo.category
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
    
    print "[RetryManager] Waiting "; backoffSeconds; " seconds before retry..."
    Sleep(backoffSeconds * 1000)
end function


' Retry with custom backoff strategy
' @param url - URL to request
' @param maxRetries - Maximum retries
' @param backoffStrategy - "exponential", "linear", or "fixed"
' @param baseDelay - Base delay in seconds
' @return Object - Request response
function RetryManager_retryWithStrategy(url as String, maxRetries as Integer, backoffStrategy as String, baseDelay as Integer) as Object
    print "[RetryManager] Retry with strategy: "; backoffStrategy
    
    attempt = 0
    config = GetNetworkConfig()
    
    while attempt <= maxRetries
        print "[RetryManager] Attempt "; attempt + 1
        
        response = HttpClient_makeRequest(url, config.DEFAULT_TIMEOUT)
        
        if response.success then
            return response
        end if
        
        if not RetryManager_shouldRetry(response, attempt, maxRetries) then
            return response
        end if
        
        ' Apply strategy-based backoff
        delay = RetryManager_calculateDelay(attempt, backoffStrategy, baseDelay)
        print "[RetryManager] Waiting "; delay; " seconds..."
        Sleep(delay * 1000)
        
        attempt = attempt + 1
    end while
    
    return response
end function


' Calculate delay based on strategy
' @param attemptNumber - Current attempt
' @param strategy - Backoff strategy
' @param baseDelay - Base delay in seconds
' @return Integer - Delay in seconds
function RetryManager_calculateDelay(attemptNumber as Integer, strategy as String, baseDelay as Integer) as Integer
    if strategy = "exponential" then
        return baseDelay * (2 ^ attemptNumber)
    else if strategy = "linear" then
        return baseDelay * (attemptNumber + 1)
    else if strategy = "fixed" then
        return baseDelay
    end if
    
    ' Default to exponential
    return baseDelay * (2 ^ attemptNumber)
end function
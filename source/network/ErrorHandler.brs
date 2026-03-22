' ******************************************************
' ErrorHandler.brs
' Network error categorization and handling
' Determines error types, retry eligibility, and error details
' ******************************************************

' Handle network error and provide detailed information
' @param response - Response object from HttpClient
' @return Object with error details
function ErrorHandler_handle(response as Object) as Object
    print "[ErrorHandler] Handling error..."
    
    if response = invalid then
        return ErrorHandler_createErrorInfo("UNKNOWN", "Invalid response object", false, 0)
    end if
    
    errorCategory = response.errorCategory
    errorMessage = response.error
    statusCode = response.statusCode
    
    ' Determine if retryable
    isRetryable = ErrorHandler_isRetryable(errorCategory, statusCode)
    
    print "[ErrorHandler] Category: "; errorCategory
    print "[ErrorHandler] Retryable: "; isRetryable
    
    return ErrorHandler_createErrorInfo(errorCategory, errorMessage, isRetryable, statusCode)
end function


' Categorize HTTP status code into error type
' @param statusCode - HTTP status code
' @return String - Error category
function ErrorHandler_categorizeHttpStatus(statusCode as Integer) as String
    ' 4xx Client Errors
    if statusCode >= 400 and statusCode < 500 then
        if statusCode = 400 then return "BAD_REQUEST"
        if statusCode = 401 then return "UNAUTHORIZED"
        if statusCode = 403 then return "FORBIDDEN"
        if statusCode = 404 then return "NOT_FOUND"
        if statusCode = 429 then return "RATE_LIMITED"
        return "CLIENT_ERROR"
    end if
    
    ' 5xx Server Errors
    if statusCode >= 500 and statusCode < 600 then
        if statusCode = 500 then return "SERVER_ERROR"
        if statusCode = 502 then return "BAD_GATEWAY"
        if statusCode = 503 then return "SERVICE_UNAVAILABLE"
        if statusCode = 504 then return "GATEWAY_TIMEOUT"
        return "SERVER_ERROR"
    end if
    
    ' No response
    if statusCode = 0 then
        return "NO_RESPONSE"
    end if
    
    return "UNKNOWN_ERROR"
end function


' Determine if error should be retried
' @param errorCategory - Error category string
' @param statusCode - HTTP status code
' @return Boolean - true if retryable
function ErrorHandler_isRetryable(errorCategory as String, statusCode as Integer) as Boolean
    ' Network-related errors (retryable)
    retryableCategories = [
        "NETWORK_UNAVAILABLE",
        "EMPTY_RESPONSE",
        "NO_RESPONSE",
        "GATEWAY_TIMEOUT",
        "SERVICE_UNAVAILABLE",
        "BAD_GATEWAY"
    ]
    
    for each category in retryableCategories
        if errorCategory = category then
            return true
        end if
    end for
    
    ' Server errors (retryable)
    if statusCode >= 500 and statusCode < 600 then
        return true
    end if
    
    ' Rate limiting (retryable with caution)
    if statusCode = 429 then
        return true
    end if
    
    ' Client errors (NOT retryable)
    if statusCode >= 400 and statusCode < 500 then
        return false
    end if
    
    ' Default: not retryable
    return false
end function


' Create error info object
' @param category - Error category
' @param message - Error message
' @param isRetryable - Whether error is retryable
' @param statusCode - HTTP status code
' @return Error info object
function ErrorHandler_createErrorInfo(category as String, message as String, isRetryable as Boolean, statusCode as Integer) as Object
    return {
        category: category
        message: message
        isRetryable: isRetryable
        statusCode: statusCode
    }
end function


' Get user-friendly error message
' @param errorCategory - Error category
' @return String - User-friendly message
function ErrorHandler_getUserMessage(errorCategory as String) as String
    messages = {
        "NETWORK_UNAVAILABLE": "No network connection available"
        "TIMEOUT": "Request timed out"
        "NOT_FOUND": "Resource not found"
        "UNAUTHORIZED": "Authentication required"
        "FORBIDDEN": "Access denied"
        "RATE_LIMITED": "Too many requests, please try again later"
        "SERVER_ERROR": "Server error occurred"
        "SERVICE_UNAVAILABLE": "Service temporarily unavailable"
        "INVALID_JSON": "Invalid response format"
        "EMPTY_RESPONSE": "No response from server"
    }
    
    if messages[errorCategory] <> invalid then
        return messages[errorCategory]
    end if
    
    return "An error occurred"
end function
' ******************************************************
' NetworkConfig.brs
' Configuration constants for network operations
' ******************************************************

function GetNetworkConfig() as Object
    return {
        ' Timeout settings (milliseconds)
        DEFAULT_TIMEOUT: 10000          ' 10 seconds
        LONG_TIMEOUT: 30000             ' 30 seconds for large requests
        SHORT_TIMEOUT: 5000             ' 5 seconds for quick checks
        
        ' Retry settings
        MAX_RETRIES: 3                  ' Maximum retry attempts
        BASE_BACKOFF_SECONDS: 1         ' Base backoff time
        MAX_BACKOFF_SECONDS: 8          ' Maximum backoff time
        
        ' HTTP status codes
        HTTP_OK: 200
        HTTP_BAD_REQUEST: 400
        HTTP_UNAUTHORIZED: 401
        HTTP_FORBIDDEN: 403
        HTTP_NOT_FOUND: 404
        HTTP_RATE_LIMITED: 429
        HTTP_SERVER_ERROR: 500
        HTTP_BAD_GATEWAY: 502
        HTTP_SERVICE_UNAVAILABLE: 503
        HTTP_GATEWAY_TIMEOUT: 504
        
        ' Error categories
        ERROR_NETWORK_UNAVAILABLE: "NETWORK_UNAVAILABLE"
        ERROR_TIMEOUT: "TIMEOUT"
        ERROR_INVALID_JSON: "INVALID_JSON"
        ERROR_API_ERROR: "API_ERROR"
        ERROR_EMPTY_RESPONSE: "EMPTY_RESPONSE"
        ERROR_CLIENT_ERROR: "CLIENT_ERROR"
        ERROR_SERVER_ERROR: "SERVER_ERROR"
        ERROR_UNKNOWN: "UNKNOWN_ERROR"
    }
end function
' ******************************************************
' ResponseBuilder.brs
' Standardised { success, data, error, errorType } factory
' Used by task nodes and service layers to return results
' with a consistent shape instead of inline object literals.
' ******************************************************

' Build a success response.
' @param data - payload to return (array, assocarray, or invalid)
' @return Object { success: true, data: data, error: "", errorType: "" }
function ResponseBuilder_success(data as Dynamic) as Object
    return {
        success:   true
        data:      data
        error:     ""
        errorType: ""
    }
end function

' Build an error response.
' @param message   - human-readable error string
' @param errorType - optional category tag (e.g. "NETWORK", "API_ERROR", "EMPTY")
' @return Object { success: false, data: invalid, error: message, errorType: errorType }
function ResponseBuilder_error(message as String, errorType = "" as String) as Object
    return {
        success:   false
        data:      invalid
        error:     message
        errorType: errorType
    }
end function

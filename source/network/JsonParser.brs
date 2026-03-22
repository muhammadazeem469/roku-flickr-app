' ******************************************************
' JsonParser.brs
' JSON parsing with error handling and validation
' Handles parsing, API-level error detection, and data extraction
' ******************************************************

' Parse JSON response with comprehensive error handling
' @param response - Response object from HttpClient
' @return Object with { success, data, error }
function JsonParser_parse(response as Object) as Object
    print "[JsonParser] Parsing JSON response..."
    
    ' Validate input
    if not JsonParser_validateInput(response) then
        return JsonParser_createErrorResponse("Invalid input to parser")
    end if
    
    ' Check if HTTP request was successful
    if not response.success then
        print "[JsonParser] ERROR: Cannot parse failed request"
        return JsonParser_createErrorResponse(response.error)
    end if
    
    ' Get response data
    responseData = response.data
    if responseData = invalid or responseData = "" then
        print "[JsonParser] ERROR: No data to parse"
        return JsonParser_createErrorResponse("No data in response")
    end if
    
    ' Attempt to parse JSON
    json = ParseJson(responseData)
    
    if json = invalid then
        print "[JsonParser] ERROR: Failed to parse JSON"
        print "[JsonParser] Response preview: "; Left(responseData, 100)
        return JsonParser_createErrorResponse("Invalid JSON format")
    end if
    
    ' Check for API-level errors
    apiError = JsonParser_checkApiError(json)
    if apiError <> "" then
        print "[JsonParser] API Error: "; apiError
        return {
            success: false
            data: json
            error: apiError
        }
    end if
    
    print "[JsonParser] JSON parsed successfully"
    return {
        success: true
        data: json
        error: ""
    }
end function


' Validate parser input
' @param response - Response object to validate
' @return Boolean - true if valid
function JsonParser_validateInput(response as Object) as Boolean
    if response = invalid then
        print "[JsonParser] ERROR: Response is invalid"
        return false
    end if
    
    if response.data = invalid then
        print "[JsonParser] ERROR: Response has no data field"
        return false
    end if
    
    return true
end function


' Check for API-level errors in parsed JSON
' @param json - Parsed JSON object
' @return String - Error message or empty string
function JsonParser_checkApiError(json as Object) as String
    ' Flickr API error format
    if json.stat <> invalid and json.stat = "fail" then
        if json.message <> invalid then
            return json.message
        end if
        return "Unknown API error"
    end if
    
    ' Generic error format
    if json.error <> invalid then
        if Type(json.error) = "roString" or Type(json.error) = "String" then
            return json.error
        end if
        if json.error.message <> invalid then
            return json.error.message
        end if
    end if
    
    return ""
end function


' Create error response
' @param errorMsg - Error message
' @return Error response object
function JsonParser_createErrorResponse(errorMsg as String) as Object
    return {
        success: false
        data: invalid
        error: errorMsg
    }
end function


' Safe JSON field extraction with default value
' @param json - JSON object
' @param fieldPath - Dot-separated field path (e.g., "photo.title._content")
' @param defaultValue - Default value if field not found
' @return Field value or default
function JsonParser_extractField(json as Object, fieldPath as String, defaultValue as Dynamic) as Dynamic
    if json = invalid or fieldPath = "" then
        return defaultValue
    end if
    
    ' Split path by dots
    fields = fieldPath.Split(".")
    current = json
    
    for each field in fields
        if current = invalid then
            return defaultValue
        end if
        
        if current[field] = invalid then
            return defaultValue
        end if
        
        current = current[field]
    end for
    
    return current
end function
' ******************************************************
' NetworkValidator.brs
' Network and response validation utilities
' Checks network availability and validates responses
' ******************************************************

' Check if network is available
' @return Boolean - true if connected
function NetworkValidator_isAvailable() as Boolean
    device = CreateObject("roDeviceInfo")
    
    if device = invalid then
return true  ' Assume available
    end if
    
    connectionType = device.GetConnectionType()
    
    if connectionType = "WiredConnection" or connectionType = "WiFiConnection" then
        return true
    end if
    return false
end function


' Validate HTTP response
' @param request - roUrlTransfer object
' @return Boolean - true if valid
function NetworkValidator_validateResponse(request as Object) as Boolean
    if request = invalid then
        return false
    end if
    
    statusCode = request.GetResponseCode()
    
    ' Success codes (2xx)
    if statusCode >= 200 and statusCode < 300 then
        return true
    end if
    return false
end function


' Validate URL format
' @param url - URL string to validate
' @return Boolean - true if valid
function NetworkValidator_validateUrl(url as String) as Boolean
    if url = invalid or url = "" then
        return false
    end if
    
    ' Check for http/https
    if url.Instr("http://") <> 0 and url.Instr("https://") <> 0 then
return false
    end if
    
    ' Basic length check
    if url.Len() < 10 then
return false
    end if
    
    return true
end function


' Check if response has expected content
' @param response - Response object
' @param expectedField - Field that should exist in JSON
' @return Boolean - true if contains expected content
function NetworkValidator_hasExpectedContent(response as Object, expectedField as String) as Boolean
    if response = invalid or not response.success then
        return false
    end if
    
    if response.data = invalid then
        return false
    end if
    
    ' If no specific field required, just check data exists
    if expectedField = "" then
        return true
    end if
    
    ' Check for specific field
    if response.data[expectedField] <> invalid then
        return true
    end if
    
    return false
end function
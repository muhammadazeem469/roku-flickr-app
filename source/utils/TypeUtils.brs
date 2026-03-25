' ******************************************************
' TypeUtils.brs
' Safe type conversion helpers
' Eliminates repeated Type() guard boilerplate across the codebase
' ******************************************************

' Convert a string-or-integer field to Integer safely.
' Flickr API returns numbers as strings in some responses.
' @param value - roString, String, or numeric value (or invalid)
' @return Integer - parsed value, or 0 if invalid/unconvertible
function SafeToInt(value as Dynamic) as Integer
    if value = invalid then return 0
    if Type(value) = "roString" or Type(value) = "String" then
        return value.ToInt()
    end if
    return value
end function

' Convert a value to String safely.
' @param value - any value (or invalid)
' @return String - string representation, or "" if invalid
function SafeToStr(value as Dynamic) as String
    if value = invalid then return ""
    if Type(value) = "roString" or Type(value) = "String" then
        return value
    end if
    return value.ToStr()
end function

' Return obj[key] if it exists and is non-invalid, otherwise return defaultValue.
' Eliminates the "if json.field <> invalid then model.field = json.field" pattern.
' @param obj          - associative array to read from
' @param key          - field name
' @param defaultValue - value to return when field is missing or invalid
function GetField(obj as Object, key as String, defaultValue as Dynamic) as Dynamic
    if obj = invalid then return defaultValue
    value = obj[key]
    if value = invalid then return defaultValue
    return value
end function

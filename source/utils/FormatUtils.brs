' ******************************************************
' FormatUtils.brs
' General-purpose display formatting helpers
' Centralises FormatNumber and FormatUnixTimestamp so
' components do not each need their own copy.
' ******************************************************

' Format an integer with thousands-separator commas.
' Example: 1234567 → "1,234,567"
' @param num - integer to format
' @return formatted string
function FormatNumber(num as Integer) as String
    numStr = num.ToStr()
    result = ""
    count  = 0

    for i = numStr.Len() - 1 to 0 step -1
        if count = 3 then
            result = "," + result
            count  = 0
        end if
        result = numStr.Mid(i, 1) + result
        count  = count + 1
    end for

    return result
end function

' Format a Unix timestamp (seconds since epoch) as a readable date.
' Example: 1704067200 → "January 1, 2024"
' @param timestamp - Unix timestamp integer
' @return formatted date string
function FormatUnixTimestamp(timestamp as Integer) as String
    dateObj = CreateObject("roDateTime")
    dateObj.FromSeconds(timestamp)

    months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

    month = months[dateObj.GetMonth() - 1]
    day   = dateObj.GetDayOfMonth()
    year  = dateObj.GetYear()

    return month + " " + day.ToStr() + ", " + year.ToStr()
end function

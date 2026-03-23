' ******************************************************
' ImageUrlBuilder_Extended.brs
' Advanced features: fallback, multiple URLs, extraction
' Ticket: FG-012
' ******************************************************

' ******************************************************
' Build with fallback size
' @param photoObj - Photo object
' @param preferredSize - First choice size
' @param fallbackSize - Use this if preferred fails
' @return String - Image URL
' ******************************************************
function ImageUrlBuilder_buildWithFallback(photoObj as Object, preferredSize as String, fallbackSize as String) as String
    ' Try preferred size first
    url = m.build(photoObj, preferredSize)
    
    ' If failed and fallback provided, try fallback
    if url = "" and fallbackSize <> invalid and fallbackSize <> "" then
        url = m.build(photoObj, fallbackSize)
    end if
    
    return url
end function


' ******************************************************
' Build multiple URLs at once
' @param photoObj - Photo object
' @param sizes - Array of size suffixes ["q", "z", "b"]
' @return Object - AA with size as key, URL as value
' ******************************************************
function ImageUrlBuilder_buildMultiple(photoObj as Object, sizes as Object) as Object
    urls = {}
    
    if sizes = invalid or sizes.Count() = 0 then
        return urls
    end if
    
    for each size in sizes
        url = m.build(photoObj, size)
        if url <> "" then
            urls[size] = url
        end if
    end for
    
    return urls
end function


' ******************************************************
' Extract size suffix from URL
' @param url - Flickr image URL
' @return String - Size suffix (e.g., "z") or empty
' ******************************************************
function ImageUrlBuilder_extractSize(url as String) as String
    if url = invalid or url = "" then
        return ""
    end if
    
    ' Get filename from URL
    parts = url.Split("/")
    if parts.Count() = 0 then
        return ""
    end if
    
    filename = parts[parts.Count() - 1]
    
    ' Remove .jpg extension
    if filename.Right(4) = ".jpg" then
        filename = filename.Left(filename.Len() - 4)
    end if
    
    ' Split by underscore: id_secret_size
    filenameParts = filename.Split("_")
    
    ' If 3 parts, last part is size
    if filenameParts.Count() = 3 then
        return filenameParts[2]
    end if
    
    ' No size suffix
    return ""
end function


' ******************************************************
' Get expected dimensions for size
' @param size - Size suffix
' @return Object - AA with width, height, longestSide
' ******************************************************
function ImageUrlBuilder_getDimensions(size as String) as Object
    dimensions = {
        width: 0
        height: 0
        longestSide: 0
    }
    
    normalizedSize = ImageUrlBuilder_normalizeSize(size, m.config)
    
    ' Based on Flickr documentation
    if normalizedSize = "q" then
        dimensions.width = 150
        dimensions.height = 150
    else if normalizedSize = "n" then
        dimensions.longestSide = 320
    else if normalizedSize = "z" then
        dimensions.longestSide = 640
    else if normalizedSize = "b" then
        dimensions.longestSide = 1024
    else if normalizedSize = "h" then
        dimensions.longestSide = 1600
    end if
    
    return dimensions
end function
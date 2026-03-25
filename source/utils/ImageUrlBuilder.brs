' ******************************************************
' ImageUrlBuilder.brs
' Core URL building and validation
' Ticket: FG-012
' ******************************************************

function ImageUrlBuilder() as Object
    config = GetImageConfig()
    
    return {
        BASE_URL: "https://live.staticflickr.com/"
        config: config
        
        ' Core methods
        build: ImageUrlBuilder_build
        validate: ImageUrlBuilder_validate
        
        ' Extended methods (from ImageUrlBuilder_Extended.brs)
        buildWithFallback: ImageUrlBuilder_buildWithFallback
        buildMultiple: ImageUrlBuilder_buildMultiple
        extractSize: ImageUrlBuilder_extractSize
        getDimensions: ImageUrlBuilder_getDimensions
    }
end function


' ******************************************************
' Build Flickr image URL
' Format: https://live.staticflickr.com/{server}/{id}_{secret}_{size}.jpg
' @param photoObj - Photo object from Flickr API
' @param size - Size suffix (q=thumbnail, n=small, z=medium, b=large)
' @return String - Image URL or empty string if invalid
' ******************************************************
function ImageUrlBuilder_build(photoObj as Object, size as String) as String
    if not m.validate(photoObj) then
        return ""
    end if
    
    ' Normalize and validate size
    normalizedSize = ImageUrlBuilder_normalizeSize(size, m.config)
    if normalizedSize = "" then
normalizedSize = m.config.DEFAULTS.GRID_VIEW
    end if
    
    server = photoObj.server
    id = photoObj.id
    secret = photoObj.secret
    
    ' Construct URL
    url = m.BASE_URL + server + "/" + id + "_" + secret + "_" + normalizedSize + ".jpg"
    
    return url
end function


' ******************************************************
' Validate photo object has required fields
' @param photoObj - Photo object to validate
' @return Boolean - True if valid
' ******************************************************
function ImageUrlBuilder_validate(photoObj as Object) as Boolean
    if photoObj = invalid then
return false
    end if
    
    if photoObj.server = invalid or photoObj.server = "" then
return false
    end if
    
    if photoObj.id = invalid or photoObj.id = "" then
return false
    end if
    
    if photoObj.secret = invalid or photoObj.secret = "" then
return false
    end if
    
    return true
end function


' ******************************************************
' HELPER: Normalize and validate size parameter
' ******************************************************
function ImageUrlBuilder_normalizeSize(size as String, config as Object) as String
    if size = invalid then
        return config.DEFAULTS.GRID_VIEW
    end if
    
    ' Trim and lowercase
    normalized = LCase(size.Trim())
    
    ' Valid sizes from ImageConfig
    validSizes = [
        config.SIZES.THUMBNAIL,
        config.SIZES.SMALL,
        config.SIZES.MEDIUM,
        config.SIZES.LARGE,
        config.SIZES.EXTRA_LARGE,
        config.SIZES.ORIGINAL
    ]
    
    ' Check if valid
    for each validSize in validSizes
        if normalized = validSize then
            return normalized
        end if
    end for
    
    ' Invalid size - return empty
    return ""
end function
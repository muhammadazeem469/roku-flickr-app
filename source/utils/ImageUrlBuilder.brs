' ImageUrlBuilder.brs
' Constructs Flickr static image URLs

function ImageUrlBuilder() as Object
    return {
        BASE_URL: "https://live.staticflickr.com/"
        build: ImageUrlBuilder_build
        validate: ImageUrlBuilder_validate
    }
end function


' Build Flickr image URL
' Format: https://live.staticflickr.com/{server}/{id}_{secret}_{size}.jpg
' @param photoObj - Photo object from Flickr API
' @param size - Size suffix (q=thumbnail, n=small, z=medium, b=large)
function ImageUrlBuilder_build(photoObj as Object, size as String) as String
    if not m.validate(photoObj) then
        return ""
    end if
    
    server = photoObj.server
    id = photoObj.id
    secret = photoObj.secret
    
    ' Construct URL
    url = m.BASE_URL + server + "/" + id + "_" + secret + "_" + size + ".jpg"
    
    return url
end function


' Validate photo object has required fields
function ImageUrlBuilder_validate(photoObj as Object) as Boolean
    if photoObj = invalid then
        print "[ImageUrlBuilder] Photo object is invalid"
        return false
    end if
    
    if photoObj.server = invalid or photoObj.server = "" then
        print "[ImageUrlBuilder] Missing server field"
        return false
    end if
    
    if photoObj.id = invalid or photoObj.id = "" then
        print "[ImageUrlBuilder] Missing id field"
        return false
    end if
    
    if photoObj.secret = invalid or photoObj.secret = "" then
        print "[ImageUrlBuilder] Missing secret field"
        return false
    end if
    
    return true
end function
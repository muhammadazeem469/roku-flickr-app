' ******************************************************
' ImageConfig.brs
' Image size and quality configuration
' ******************************************************

function GetImageConfig() as Object
    return {
        ' Flickr Image Size Suffixes
        ' Reference: https://www.flickr.com/services/api/misc.urls.html
        SIZES: {
            THUMBNAIL: "q"      ' 150x150 square
            SMALL: "n"          ' 320px on longest side
            MEDIUM: "z"         ' 640px on longest side
            LARGE: "b"          ' 1024px on longest side
            EXTRA_LARGE: "h"    ' 1600px on longest side
            ORIGINAL: "o"       ' Original image
        }
        
        ' Default sizes for different views
        DEFAULTS: {
            GRID_VIEW: "q"      ' Use thumbnail in grid
            DETAIL_VIEW: "b"    ' Use large in detail screen
        }
    }
end function

' Build image URL from photo object
function BuildImageURL(photo as Object, size as String) as String
    ' Flickr image URL format:
    ' https://live.staticflickr.com/{server-id}/{id}_{secret}_{size}.jpg
    
    if photo = invalid then return ""
    
    url = "https://live.staticflickr.com/"
    url = url + photo.server + "/"
    url = url + photo.id + "_"
    url = url + photo.secret + "_"
    url = url + size + ".jpg"
    
    return url
end function
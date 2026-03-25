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


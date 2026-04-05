

' Build complete Flickr API URL with parameters
function BuildFlickrURL(method as String, additionalParams as Object) as String
    config = GetApiConfig()
    
    ' Start with base URL
    url = config.BASE_URL + "?"
    
    ' Add required parameters
    url = url + "method=" + method
    url = url + "&api_key=" + config.API_KEY
    url = url + "&format=" + config.FORMAT
    url = url + "&nojsoncallback=" + config.NO_JSON_CALLBACK
    
    ' Add additional parameters if provided (skip empty or invalid values)
    if additionalParams <> invalid then
        for each key in additionalParams
            value = additionalParams[key]
            if value <> invalid then
                strValue = Box(value).ToStr()
                if strValue <> "" then
                    url = url + "&" + key + "=" + strValue
                end if
            end if
        end for
    end if
    
    return url
end function

' Build URL for fetching photos by category
function BuildCategoryURL(category as Object, page as Integer, perPage as Integer) as String
    params = {
        page: page.ToStr()
        per_page: perPage.ToStr()
    }
    
    ' Add tags if category uses search method
    if category.method = "flickr.photos.search" and category.tags <> "" then
        params.tags = category.tags
        params.tag_mode = "any"
    end if
    
    return BuildFlickrURL(category.method, params)
end function

' Build URL for photo details
function BuildPhotoInfoURL(photoId as String) as String
    params = {
        photo_id: photoId
    }
    
    return BuildFlickrURL("flickr.photos.getInfo", params)
end function
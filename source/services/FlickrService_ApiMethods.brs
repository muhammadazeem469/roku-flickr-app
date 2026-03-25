' ******************************************************
' FlickrService_ApiMethods.brs
' Implements Flickr API method calls
' Uses existing ApiHelper for URL building
' ******************************************************

function FlickrService_ApiMethods() as Object
    return {
        getInterestingImages: FlickrService_ApiMethods_getInterestingImages
        searchImagesByTag: FlickrService_ApiMethods_searchImagesByTag
        getRecentImages: FlickrService_ApiMethods_getRecentImages
        getImageInfo: FlickrService_ApiMethods_getImageInfo
        makePhotosRequest: FlickrService_ApiMethods_makePhotosRequest
        getExtrasString: FlickrService_ApiMethods_getExtrasString
    }
end function


' Get interesting images
function FlickrService_ApiMethods_getInterestingImages(page as Integer, perPage as Integer) as Object
    
    ' Set defaults
    if page <= 0 then page = 1
    if perPage <= 0 then perPage = 20
    
    ' Build URL using existing ApiHelper
    params = {
        page: page.ToStr()
        per_page: perPage.ToStr()
        extras: m.getExtrasString()
    }
    
    url = BuildFlickrURL("flickr.interestingness.getList", params)
    
    return m.makePhotosRequest(url)
end function


' Search images by tags
function FlickrService_ApiMethods_searchImagesByTag(tags as String, page as Integer, perPage as Integer) as Object
    
    ' Validate tags
    if tags = "" or tags = invalid then
return FlickrService_createErrorResponse("Tags required for search")
    end if
    
    ' Set defaults
    if page <= 0 then page = 1
    if perPage <= 0 then perPage = 20
    
    ' Build URL using existing ApiHelper
    params = {
        tags: tags
        tag_mode: "any"
        page: page.ToStr()
        per_page: perPage.ToStr()
        extras: m.getExtrasString()
    }
    
    url = BuildFlickrURL("flickr.photos.search", params)
    
    return m.makePhotosRequest(url)
end function


' Get recent images
function FlickrService_ApiMethods_getRecentImages(page as Integer, perPage as Integer) as Object
    
    ' Set defaults
    if page <= 0 then page = 1
    if perPage <= 0 then perPage = 20
    
    ' Build URL using existing ApiHelper
    params = {
        page: page.ToStr()
        per_page: perPage.ToStr()
        extras: m.getExtrasString()
    }
    
    url = BuildFlickrURL("flickr.photos.getRecent", params)
    
    return m.makePhotosRequest(url)
end function


' Get detailed photo information
function FlickrService_ApiMethods_getImageInfo(photoId as String) as Object
    
    ' Validate photoId
    if photoId = "" or photoId = invalid then
return {
            success: false
            error: "Photo ID is required"
            data: invalid
        }
    end if
    
    ' Build URL using existing ApiHelper
    url = BuildPhotoInfoURL(photoId)
    
    ' Make HTTP request using existing network layer
    config = GetNetworkConfig()
    response = HttpClient_makeRequest(url, config.DEFAULT_TIMEOUT)
    
    if not response.success then
        return {
            success: false
            error: response.error
            data: invalid
        }
    end if
    
    ' Parse JSON using existing JsonParser
    parsedResponse = JsonParser_parse(response)
    
    if not parsedResponse.success then
        return {
            success: false
            error: parsedResponse.error
            data: invalid
        }
    end if
    
    ' Extract photo data
    json = parsedResponse.data
    if json.photo = invalid then
return {
            success: false
            error: "Invalid response structure"
            data: invalid
        }
    end if
return {
        success: true
        error: ""
        data: json.photo
    }
end function


' Make API request for photos (common logic)
function FlickrService_ApiMethods_makePhotosRequest(url as String) as Object
' Make HTTP request using existing network layer
    config = GetNetworkConfig()
    response = HttpClient_makeRequest(url, config.DEFAULT_TIMEOUT)
    
    if not response.success then
        return FlickrService_createErrorResponse(response.error)
    end if
    
    ' Parse JSON using existing JsonParser
    parsedResponse = JsonParser_parse(response)
    
    if not parsedResponse.success then
        return FlickrService_createErrorResponse(parsedResponse.error)
    end if
    
    ' Parse photos from response using ResponseParser
    responseParser = FlickrService_ResponseParser()
    return responseParser.parsePhotosResponse(parsedResponse.data)
end function


' Get extras parameter string
function FlickrService_ApiMethods_getExtrasString() as String
    return "url_q,url_n,url_z,url_b,description,owner_name,tags,views,date_upload"
end function
' ******************************************************
' FlickrService_ApiMethods.brs
' Implements Flickr API method calls
' Uses existing ApiHelper for URL building
' ******************************************************

function FlickrService_ApiMethods() as Object
    apiCfg = GetApiConfig()
    return {
        DEFAULT_PAGE:     apiCfg.DEFAULT_PAGE
        DEFAULT_PER_PAGE: apiCfg.DEFAULT_PER_PAGE

        getInterestingImages: FlickrService_ApiMethods_getInterestingImages
        searchImagesByTag:    FlickrService_ApiMethods_searchImagesByTag
        getRecentImages:      FlickrService_ApiMethods_getRecentImages
        getPopularImages:     FlickrService_ApiMethods_getPopularImages
        getImageInfo:         FlickrService_ApiMethods_getImageInfo
        makePhotosRequest:    FlickrService_ApiMethods_makePhotosRequest
        getExtrasString:      FlickrService_ApiMethods_getExtrasString
    }
end function


' Get interesting images
function FlickrService_ApiMethods_getInterestingImages(page as Integer, perPage as Integer) as Object
    if page <= 0 then page = m.DEFAULT_PAGE
    if perPage <= 0 then perPage = m.DEFAULT_PER_PAGE

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
    
    if tags = "" or tags = invalid then
        return FlickrService_createErrorResponse("Tags required for search")
    end if

    if page <= 0 then page = m.DEFAULT_PAGE
    if perPage <= 0 then perPage = m.DEFAULT_PER_PAGE

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
    if page <= 0 then page = m.DEFAULT_PAGE
    if perPage <= 0 then perPage = m.DEFAULT_PER_PAGE

    params = {
        page: page.ToStr()
        per_page: perPage.ToStr()
        extras: m.getExtrasString()
    }
    
    url = BuildFlickrURL("flickr.photos.getRecent", params)
    
    return m.makePhotosRequest(url)
end function


' Get popular images
function FlickrService_ApiMethods_getPopularImages(page as Integer, perPage as Integer) as Object
    if page <= 0 then page = m.DEFAULT_PAGE
    if perPage <= 0 then perPage = m.DEFAULT_PER_PAGE

    params = {
        page: page.ToStr()
        per_page: perPage.ToStr()
        extras: m.getExtrasString()
    }

    url = BuildFlickrURL("flickr.photos.getPopular", params)

    return m.makePhotosRequest(url)
end function


' Get detailed photo information
function FlickrService_ApiMethods_getImageInfo(photoId as String) as Object

    if photoId = "" or photoId = invalid then
        return ResponseBuilder_error("Photo ID is required")
    end if

    url = BuildPhotoInfoURL(photoId)

    config = GetNetworkConfig()
    response = HttpClient_makeRequest(url, config.DEFAULT_TIMEOUT)

    if not response.success then
        return ResponseBuilder_error(response.error)
    end if

    parsedResponse = JsonParser_parse(response)

    if not parsedResponse.success then
        return ResponseBuilder_error(parsedResponse.error)
    end if

    json = parsedResponse.data
    if json.photo = invalid then
        return ResponseBuilder_error("Invalid response structure")
    end if

    return ResponseBuilder_success(json.photo)
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


' Get extras parameter string — size suffixes from ImageConfig
function FlickrService_ApiMethods_getExtrasString() as String
    s = GetImageConfig().SIZES
    return "url_" + s.THUMBNAIL + ",url_" + s.SMALL + ",url_" + s.MEDIUM + ",url_" + s.LARGE + ",description,owner_name,tags,views,date_upload"
end function
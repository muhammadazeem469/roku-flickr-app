' ******************************************************
' FlickrService_ResponseParser.brs
' Parses Flickr API responses
' Uses existing ImageMapper for conversion
' ******************************************************

function FlickrService_ResponseParser() as Object
    return {
        parsePhotosResponse:    FlickrService_ResponseParser_parsePhotosResponse
        extractPaginationInfo:  FlickrService_ResponseParser_extractPaginationInfo
    }
end function


' Parse photos response and convert to ImageModel array
function FlickrService_ResponseParser_parsePhotosResponse(json as Object) as Object
    if json = invalid then
        return FlickrService_createErrorResponse("Invalid JSON response")
    end if

    ' -------------------------------------------------------
    ' FG-022: Flickr always returns HTTP 200, even for errors
    ' like an invalid API key or rate limiting. The only way
    ' to detect these is to check stat="fail" in the body.
    '
    ' Example failure body:
    '   { "stat": "fail", "code": 100, "message": "Invalid API Key" }
    '
    ' Flickr error codes of interest:
    '   100 - Invalid API Key        → errorType: API_ERROR
    '   105 - Service unavailable    → errorType: API_ERROR
    '   106 - Write operation failed → errorType: API_ERROR
    '   116 - Bad URL found          → errorType: API_ERROR
    ' -------------------------------------------------------
    if json.stat <> invalid and json.stat = "fail" then
        errorMsg   = GetErrorMessages().API
        flickrCode = 0

        if json.message <> invalid and json.message <> "" then
            errorMsg = json.message
        end if

        if json.code <> invalid then flickrCode = json.code

        result = FlickrService_createErrorResponse(errorMsg)
        result.errorType  = "API_ERROR"
        result.flickrCode = flickrCode
        return result
    end if

    if json.photos = invalid then
        return FlickrService_createErrorResponse("Invalid response structure")
    end if

    paginationInfo = m.extractPaginationInfo(json.photos)

    if json.photos.photo = invalid then
        return {
            success:   true
            data:      []
            error:     ""
            errorType: ""
            page:      paginationInfo.page
            pages:     paginationInfo.pages
            total:     paginationInfo.total
        }
    end if

    ' Convert each photo to ImageModel using existing ImageMapper
    imageModels = []
    mapper = ImageMapper()

    for each photoJson in json.photos.photo
        imageModel = mapper.fromFlickrJSON(photoJson)
        if imageModel <> invalid then
            imageModels.Push(imageModel)
        end if
    end for

    return {
        success:   true
        data:      imageModels
        error:     ""
        errorType: ""
        page:      paginationInfo.page
        pages:     paginationInfo.pages
        total:     paginationInfo.total
    }
end function


' Extract pagination information
function FlickrService_ResponseParser_extractPaginationInfo(photosObj as Object) as Object
    page  = 1
    pages = 1
    total = 0

    if photosObj = invalid then
        return { page: page, pages: pages, total: total }
    end if

    if photosObj.page  <> invalid then page  = SafeToInt(photosObj.page)
    if photosObj.pages <> invalid then pages = SafeToInt(photosObj.pages)
    if photosObj.total <> invalid then total = SafeToInt(photosObj.total)

    return { page: page, pages: pages, total: total }
end function

' ******************************************************
' FlickrService_ResponseParser.brs
' Parses Flickr API responses
' Uses existing ImageMapper for conversion
' ******************************************************

function FlickrService_ResponseParser() as Object
    return {
        parsePhotosResponse: FlickrService_ResponseParser_parsePhotosResponse
        extractPaginationInfo: FlickrService_ResponseParser_extractPaginationInfo
    }
end function


' Parse photos response and convert to ImageModel array
function FlickrService_ResponseParser_parsePhotosResponse(json as Object) as Object
' Validate response structure
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
        errorMsg = "Couldn't load images. Please try again later."
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

    if json.photos.photo = invalid then
paginationInfo = m.extractPaginationInfo(json.photos)
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

    ' Extract pagination info
    paginationInfo = m.extractPaginationInfo(json.photos)

    ' Convert each photo to ImageModel using existing ImageMapper
    imageModels = []
    mapper = ImageMapper()

    for each photoJson in json.photos.photo
        imageModel = mapper.fromFlickrJSON(photoJson)
        imageModels.Push(imageModel)
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

    ' Extract page number
    if photosObj.page <> invalid then
        if Type(photosObj.page) = "roString" or Type(photosObj.page) = "String" then
            page = photosObj.page.ToInt()
        else
            page = photosObj.page
        end if
    end if

    ' Extract total pages
    if photosObj.pages <> invalid then
        if Type(photosObj.pages) = "roString" or Type(photosObj.pages) = "String" then
            pages = photosObj.pages.ToInt()
        else
            pages = photosObj.pages
        end if
    end if

    ' Extract total count
    if photosObj.total <> invalid then
        if Type(photosObj.total) = "roString" or Type(photosObj.total) = "String" then
            total = photosObj.total.ToInt()
        else
            total = photosObj.total
        end if
    end if

    return {
        page:  page
        pages: pages
        total: total
    }
end function

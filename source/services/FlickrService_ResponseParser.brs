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
    print "[FlickrService] Parsing photos response..."
    
    ' Validate response structure
    if json = invalid then
        print "[FlickrService] ERROR: Invalid JSON"
        return FlickrService_createErrorResponse("Invalid JSON response")
    end if
    
    if json.photos = invalid then
        print "[FlickrService] ERROR: No photos object in response"
        return FlickrService_createErrorResponse("Invalid response structure")
    end if
    
    if json.photos.photo = invalid then
        print "[FlickrService] WARNING: No photos array in response"
        paginationInfo = m.extractPaginationInfo(json.photos)
        return {
            success: true
            data: []
            error: ""
            page: paginationInfo.page
            pages: paginationInfo.pages
            total: paginationInfo.total
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
    
    print "[FlickrService] Parsed "; imageModels.Count(); " images"
    print "[FlickrService] Page "; paginationInfo.page; " of "; paginationInfo.pages; " (Total: "; paginationInfo.total; ")"
    
    return {
        success: true
        data: imageModels
        error: ""
        page: paginationInfo.page
        pages: paginationInfo.pages
        total: paginationInfo.total
    }
end function


' Extract pagination information
function FlickrService_ResponseParser_extractPaginationInfo(photosObj as Object) as Object
    page = 1
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
        page: page
        pages: pages
        total: total
    }
end function
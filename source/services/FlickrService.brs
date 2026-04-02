' ******************************************************
' FlickrService.brs
' Service layer for Flickr API interactions
' Handles HTTP requests and response parsing
' ******************************************************

' Constructor
function CreateFlickrService() as Object
    return {
        getInterestingImages: FlickrService_getInterestingImages
        searchImagesByTag:    FlickrService_searchImagesByTag
        getRecentImages:      FlickrService_getRecentImages
        getPopularImages:     FlickrService_getPopularImages
        getImageInfo:         FlickrService_getImageInfo

        ' Helper modules
        apiMethods:     FlickrService_ApiMethods()
        responseParser: FlickrService_ResponseParser()
    }
end function


' Get detailed photo info - delegates to ApiMethods
function FlickrService_getImageInfo(photoId as String) as Object
    return m.apiMethods.getImageInfo(photoId)
end function


' Get interesting images - delegates to ApiMethods
function FlickrService_getInterestingImages(page as Integer, perPage as Integer) as Object
    return m.apiMethods.getInterestingImages(page, perPage)
end function


' Search by tags - delegates to ApiMethods
function FlickrService_searchImagesByTag(tags as String, page as Integer, perPage as Integer) as Object
    return m.apiMethods.searchImagesByTag(tags, page, perPage)
end function


' Get recent images - delegates to ApiMethods
function FlickrService_getRecentImages(page as Integer, perPage as Integer) as Object
    return m.apiMethods.getRecentImages(page, perPage)
end function


' Get popular images - delegates to ApiMethods
function FlickrService_getPopularImages(page as Integer, perPage as Integer) as Object
    return m.apiMethods.getPopularImages(page, perPage)
end function


' Create error response helper
function FlickrService_createErrorResponse(errorMessage as String) as Object
    return {
        success: false
        data: []
        error: errorMessage
        page: 0
        pages: 0
        total: 0
    }
end function
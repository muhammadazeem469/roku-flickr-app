' ******************************************************
' CategoryLoadTask.brs
' Task node for loading category data from Flickr API
' CRITICAL: HTTP requests MUST run on Task thread, not render thread
' ******************************************************

sub init()
    m.top.functionName = "loadCategoryData"
end sub

' Load category data from Flickr API
' This runs on TASK thread where HTTP is allowed
sub loadCategoryData()
    categoryMethod = m.top.categoryMethod
    categoryTags   = m.top.categoryTags
    page           = m.top.page
    perPage        = m.top.perPage

    msgs = GetErrorMessages()

    if not NetworkValidator_isAvailable() then
        m.top.result = ResponseBuilder_error(msgs.NETWORK, "NETWORK")
        return
    end if

    flickrService = CreateFlickrService()

    if categoryMethod = "flickr.interestingness.getList" then
        m.top.result = flickrService.getInterestingImages(page, perPage)

    else if categoryMethod = "flickr.photos.search" then
        if categoryTags <> invalid and categoryTags <> "" then
            m.top.result = flickrService.searchImagesByTag(categoryTags, page, perPage)
        else
            m.top.result = ResponseBuilder_error(msgs.API, "API_ERROR")
        end if

    else if categoryMethod = "flickr.photos.getRecent" then
        m.top.result = flickrService.getRecentImages(page, perPage)

    else
        m.top.result = ResponseBuilder_error(msgs.API, "API_ERROR")
    end if
end sub

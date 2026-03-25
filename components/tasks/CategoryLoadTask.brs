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
' Get parameters
    categoryMethod = m.top.categoryMethod
    categoryTags   = m.top.categoryTags
    page           = m.top.page
    perPage        = m.top.perPage

    ' -------------------------------------------------------
    ' FG-022 DEBUG: Check debug flags from AppConfig.
    ' These let you simulate every error scenario on a real
    ' device without touching the network or the API key.
    ' -------------------------------------------------------
    config = GetApiConfig()

    if config.DEBUG_NETWORK_ERROR = true then
m.top.result = {
            success:   false
            error:     "Unable to connect. Check your internet connection."
            errorType: "NETWORK"
            data:      []
            pages:     0
        }
        return
    end if

    if config.DEBUG_EMPTY_RESULTS = true then
m.top.result = {
            success:   false
            error:     "No images found in this category."
            errorType: "EMPTY"
            data:      []
            pages:     0
        }
        return
    end if

    ' -------------------------------------------------------
    ' Real path: check actual network availability first
    ' -------------------------------------------------------
    if not NetworkValidator_isAvailable() then
m.top.result = {
            success:   false
            error:     "Unable to connect. Check your internet connection."
            errorType: "NETWORK"
            data:      []
            pages:     0
        }
        return
    end if

    ' Create FlickrService instance
    flickrService = CreateFlickrService()

    ' Call appropriate API method
    result = invalid

    if categoryMethod = "flickr.interestingness.getList" then
result = flickrService.getInterestingImages(page, perPage)

    else if categoryMethod = "flickr.photos.search" then
        if categoryTags <> invalid and categoryTags <> "" then
result = flickrService.searchImagesByTag(categoryTags, page, perPage)
        else
result = {
                success:   false
                error:     "Couldn't load images. Please try again later."
                errorType: "API_ERROR"
                data:      []
                pages:     0
            }
        end if

    else if categoryMethod = "flickr.photos.getRecent" then
result = flickrService.getRecentImages(page, perPage)

    else
result = {
            success:   false
            error:     "Couldn't load images. Please try again later."
            errorType: "API_ERROR"
            data:      []
            pages:     0
        }
    end if

    ' -------------------------------------------------------
    ' FG-022: Annotate result with errorType so the UI layer
    ' shows the correct user-facing message.
    '   NETWORK   → network unavailable (handled above)
    '   EMPTY     → API succeeded but returned 0 photos
    '   API_ERROR → HTTP / parse / key / rate-limit failure
    ' -------------------------------------------------------
    if result <> invalid then
        if result.success then
            if result.data = invalid or result.data.Count() = 0 then
result.success   = false
                result.error     = "No images found in this category."
                result.errorType = "EMPTY"
            else
                result.errorType = ""
            end if
        else
            if result.errorType = invalid or result.errorType = "" then
                result.errorType = "API_ERROR"
                result.error     = "Couldn't load images. Please try again later."
            end if
        end if
    end if
    m.top.result = result
end sub

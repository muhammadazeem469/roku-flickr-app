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
    print "[CategoryLoadTask] Starting on TASK thread..."
    
    ' Get parameters
    categoryMethod = m.top.categoryMethod
    categoryTags = m.top.categoryTags
    page = m.top.page
    perPage = m.top.perPage
    
    print "[CategoryLoadTask] Method: "; categoryMethod
    print "[CategoryLoadTask] Tags: "; categoryTags
    
    ' Create FlickrService instance
    flickrService = CreateFlickrService()
    
    ' Call appropriate API method
    result = invalid
    
    if categoryMethod = "flickr.interestingness.getList" then
        print "[CategoryLoadTask] Calling getInterestingImages..."
        result = flickrService.getInterestingImages(page, perPage)
        
    else if categoryMethod = "flickr.photos.search" then
        if categoryTags <> invalid and categoryTags <> "" then
            print "[CategoryLoadTask] Calling searchImagesByTag..."
            result = flickrService.searchImagesByTag(categoryTags, page, perPage)
        else
            print "[CategoryLoadTask] ERROR: Search requires tags"
            result = {
                success: false
                error: "Tags required for search"
                data: []
                pages: 0
            }
        end if
        
    else if categoryMethod = "flickr.photos.getRecent" then
        print "[CategoryLoadTask] Calling getRecentImages..."
        result = flickrService.getRecentImages(page, perPage)
        
    else
        print "[CategoryLoadTask] ERROR: Unknown method"
        result = {
            success: false
            error: "Unknown API method"
            data: []
            pages: 0
        }
    end if
    
    ' Return result
    print "[CategoryLoadTask] Task complete, returning result"
    m.top.result = result
end sub

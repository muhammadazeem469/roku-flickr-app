' ******************************************************
' TestFlickrService.brs
' Unit tests for FlickrService
' ******************************************************

function TestFlickrServiceSuite() as Boolean
    print ""
    print "================================================"
    print "TESTING FLICKR SERVICE SUITE"
    print "================================================"
    
    TestFlickrService_GetInterestingImages()
    TestFlickrService_SearchImagesByTag()
    TestFlickrService_GetRecentImages()
    TestFlickrService_GetImageInfo()
    TestFlickrService_ErrorHandling()
    TestFlickrService_Pagination()
    TestFlickrService_ResponseParsing()
    
    print "================================================"
    print "FLICKR SERVICE TESTS COMPLETE"
    print "================================================"
    print ""
    
    return true
end function


function TestFlickrService_GetInterestingImages() as Boolean
    print ""
    print "--- Testing getInterestingImages ---"
    print "NOTE: Makes real API call"
    
    service = CreateFlickrService()
    result = service.getInterestingImages(1, 5)
    
    print "Success: "; result.success
    print "Error: "; result.error
    print "Images returned: "; result.data.Count()
    print "Page: "; result.page
    print "Total pages: "; result.pages
    print "Total images: "; result.total
    
    if result.success and result.data.Count() > 0 then
        print ""
        print "First image:"
        img = result.data[0]
        print "  ID: "; img.id
        print "  Title: "; img.title
        print "  Owner: "; img.owner
        print "  Has thumbnail: "; (img.url_thumbnail <> "")
        print "  Has medium: "; (img.url_medium <> "")
    end if
    
    print ""
    return true
end function


function TestFlickrService_SearchImagesByTag() as Boolean
    print ""
    print "--- Testing searchImagesByTag ---"
    print "NOTE: Makes real API call"
    
    service = CreateFlickrService()
    
    print "Searching for 'sunset'..."
    result = service.searchImagesByTag("sunset", 1, 5)
    
    print "Success: "; result.success
    print "Images found: "; result.data.Count()
    
    print ""
    print "Searching for 'nature,landscape'..."
    result2 = service.searchImagesByTag("nature,landscape", 1, 3)
    print "Success: "; result2.success
    print "Images found: "; result2.data.Count()
    
    print ""
    print "Testing empty tags (should fail)..."
    result3 = service.searchImagesByTag("", 1, 5)
    print "Success (should be false): "; result3.success
    print "Error: "; result3.error
    
    print ""
    return true
end function


function TestFlickrService_GetRecentImages() as Boolean
    print ""
    print "--- Testing getRecentImages ---"
    print "NOTE: Makes real API call"
    
    service = CreateFlickrService()
    result = service.getRecentImages(1, 5)
    
    print "Success: "; result.success
    print "Images returned: "; result.data.Count()
    print "Page: "; result.page
    
    if result.success and result.data.Count() > 0 then
        print ""
        print "Recent image:"
        img = result.data[0]
        print "  Title: "; img.title
        print "  Date posted: "; img.datePosted
    end if
    
    print ""
    return true
end function


function TestFlickrService_GetImageInfo() as Boolean
    print ""
    print "--- Testing getImageInfo ---"
    print "NOTE: Makes real API call"
    
    service = CreateFlickrService()
    
    ' Get a photo ID first
    interestingResult = service.getInterestingImages(1, 1)
    
    if interestingResult.success and interestingResult.data.Count() > 0 then
        photoId = interestingResult.data[0].id
        print "Testing with photo ID: "; photoId
        
        result = service.getImageInfo(photoId)
        
        print "Success: "; result.success
        print "Has data: "; (result.data <> invalid)
        
        if result.success and result.data <> invalid then
            print ""
            print "Photo info:"
            print "  ID: "; result.data.id
            if result.data.title <> invalid and result.data.title._content <> invalid then
                print "  Title: "; result.data.title._content
            end if
            if result.data.views <> invalid then
                print "  Views: "; result.data.views
            end if
        end if
    else
        print "Could not get sample photo ID"
    end if
    
    print ""
    print "Testing invalid ID..."
    errorResult = service.getImageInfo("")
    print "Success (should be false): "; errorResult.success
    print "Error: "; errorResult.error
    
    print ""
    return true
end function


function TestFlickrService_ErrorHandling() as Boolean
    print ""
    print "--- Testing Error Handling ---"
    
    service = CreateFlickrService()
    
    print "Test 1: Empty tags"
    result1 = service.searchImagesByTag("", 1, 5)
    print "  Failed as expected: "; (not result1.success)
    print "  Error: "; result1.error
    
    print ""
    print "Test 2: Empty photo ID"
    result2 = service.getImageInfo("")
    print "  Failed as expected: "; (not result2.success)
    print "  Error: "; result2.error
    
    print ""
    print "Test 3: Invalid page (auto-corrects)"
    result3 = service.getInterestingImages(0, 5)
    print "  Auto-corrected to page 1: "; (result3.page = 1)
    
    print ""
    return true
end function


function TestFlickrService_Pagination() as Boolean
    print ""
    print "--- Testing Pagination ---"
    print "NOTE: Makes real API calls"
    
    service = CreateFlickrService()
    
    print "Fetching page 1..."
    page1 = service.getInterestingImages(1, 5)
    print "  Success: "; page1.success
    print "  Page: "; page1.page
    print "  Total pages: "; page1.pages
    print "  Images: "; page1.data.Count()
    
    print ""
    print "Fetching page 2..."
    page2 = service.getInterestingImages(2, 5)
    print "  Success: "; page2.success
    print "  Page: "; page2.page
    print "  Images: "; page2.data.Count()
    
    if page1.success and page2.success then
        if page1.data.Count() > 0 and page2.data.Count() > 0 then
            different = (page1.data[0].id <> page2.data[0].id)
            print ""
            print "Pages have different content: "; different
        end if
    end if
    
    print ""
    return true
end function


function TestFlickrService_ResponseParsing() as Boolean
    print ""
    print "--- Testing Response Parsing ---"
    
    ' Test pagination extraction
    parser = FlickrService_ResponseParser()
    
    mockPhotosObj = {
        page: "2"
        pages: "100"
        total: "5000"
    }
    
    paginationInfo = parser.extractPaginationInfo(mockPhotosObj)
    
    print "Pagination parsing:"
    print "  Page: "; paginationInfo.page
    print "  Pages: "; paginationInfo.pages
    print "  Total: "; paginationInfo.total
    
    print ""
    return true
end function

' ******************************************************
' TestFlickrService.brs
' Unit tests for FlickrService
' ******************************************************

function TestFlickrServiceSuite() as Boolean
TestFlickrService_GetInterestingImages()
    TestFlickrService_SearchImagesByTag()
    TestFlickrService_GetRecentImages()
    TestFlickrService_GetImageInfo()
    TestFlickrService_ErrorHandling()
    TestFlickrService_Pagination()
    TestFlickrService_ResponseParsing()
return true
end function


function TestFlickrService_GetInterestingImages() as Boolean
service = CreateFlickrService()
    result = service.getInterestingImages(1, 5)
    
    if result.success and result.data.Count() > 0 then
        img = result.data[0]

    end if
return true
end function


function TestFlickrService_SearchImagesByTag() as Boolean
service = CreateFlickrService()
result = service.searchImagesByTag("sunset", 1, 5)
result2 = service.searchImagesByTag("nature,landscape", 1, 3)
result3 = service.searchImagesByTag("", 1, 5)
return true
end function


function TestFlickrService_GetRecentImages() as Boolean
service = CreateFlickrService()
    result = service.getRecentImages(1, 5)
    
    if result.success and result.data.Count() > 0 then
img = result.data[0]
    end if
return true
end function


function TestFlickrService_GetImageInfo() as Boolean
service = CreateFlickrService()
    
    ' Get a photo ID first
    interestingResult = service.getInterestingImages(1, 1)
    
    if interestingResult.success and interestingResult.data.Count() > 0 then
        photoId = interestingResult.data[0].id
        
        result = service.getImageInfo(photoId)
        
        if result.success and result.data <> invalid then
            if result.data.title <> invalid and result.data.title._content <> invalid then
            end if
            if result.data.views <> invalid then
            end if
        end if
    else
end if
errorResult = service.getImageInfo("")
return true
end function


function TestFlickrService_ErrorHandling() as Boolean
service = CreateFlickrService()
result1 = service.searchImagesByTag("", 1, 5)
result2 = service.getImageInfo("")
result3 = service.getInterestingImages(0, 5)
return true
end function


function TestFlickrService_Pagination() as Boolean
service = CreateFlickrService()
page1 = service.getInterestingImages(1, 5)
page2 = service.getInterestingImages(2, 5)
    
    if page1.success and page2.success then
        if page1.data.Count() > 0 and page2.data.Count() > 0 then
            different = (page1.data[0].id <> page2.data[0].id)
        end if
    end if
return true
end function


function TestFlickrService_ResponseParsing() as Boolean
' Test pagination extraction
    parser = FlickrService_ResponseParser()
    
    mockPhotosObj = {
        page: "2"
        pages: "100"
        total: "5000"
    }
    
    paginationInfo = parser.extractPaginationInfo(mockPhotosObj)
return true
end function

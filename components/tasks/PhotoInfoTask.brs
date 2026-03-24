' ******************************************************
' PhotoInfoTask.brs
' Task for loading photo information from Flickr API
' MODIFIED FOR EASY TESTING - Change USE_MOCK_DATA to test
' ******************************************************

sub init()
    ' Task entry point
    m.top.functionName = "loadPhotoInfo"
end sub

' Load photo information from Flickr API
sub loadPhotoInfo()
    print "[PhotoInfoTask] Loading photo info for ID: "; m.top.photoId
    
    photoId = m.top.photoId
    
    if photoId = invalid or photoId = "" then
        print "[PhotoInfoTask] ERROR: Invalid photo ID"
        result = {}
        result.success = false
        result.error = "Invalid photo ID"
        result.data = invalid
        m.top.result = result
        return
    end if
    
    ' =====================================================
    ' TESTING MODE - Change this to test different scenarios
    ' =====================================================
    USE_MOCK_DATA = false  ' ← SET TO true FOR TESTING, false FOR REAL API
    
    if USE_MOCK_DATA then
        print "[PhotoInfoTask] *** MOCK MODE ENABLED ***"
        print "[PhotoInfoTask] Using mock data instead of real API"
        
        ' Get mock response based on photo ID
        mockResult = getMockResponse(photoId)
        m.top.result = mockResult
        return
    end if
    ' =====================================================
    
    ' Real API call (only runs if USE_MOCK_DATA = false)
    apiKey = "452b3b7a5d806dcd110842e6649c604d"
    url = "https://api.flickr.com/services/rest/"
    url = url + "?method=flickr.photos.getInfo"
    url = url + "&api_key=" + apiKey
    url = url + "&photo_id=" + photoId
    url = url + "&format=json"
    url = url + "&nojsoncallback=1"
    
    print "[PhotoInfoTask] Request URL: "; url
    
    request = CreateObject("roUrlTransfer")
    
    if request = invalid then
        print "[PhotoInfoTask] ERROR: Failed to create roUrlTransfer"
        result = {}
        result.success = false
        result.error = "Failed to create HTTP request"
        result.data = invalid
        m.top.result = result
        return
    end if
    
    request.SetUrl(url)
    request.EnablePeerVerification(false)
    request.EnableHostVerification(false)
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.InitClientCertificates()
    
    response = request.GetToString()
    
    if response = invalid or response = "" then
        print "[PhotoInfoTask] ERROR: Empty response from API"
        result = {}
        result.success = false
        result.error = "Empty response from API"
        result.data = invalid
        m.top.result = result
        return
    end if
    
    print "[PhotoInfoTask] Response received, length: "; response.Len()
    
    json = ParseJson(response)
    
    if json = invalid then
        print "[PhotoInfoTask] ERROR: Failed to parse JSON response"
        result = {}
        result.success = false
        result.error = "Invalid JSON response"
        result.data = invalid
        m.top.result = result
        return
    end if
    
    if json.stat <> invalid and json.stat = "fail" then
        errorMsg = "API Error"
        if json.message <> invalid then
            errorMsg = json.message
        end if
        print "[PhotoInfoTask] API Error: "; errorMsg
        result = {}
        result.success = false
        result.error = errorMsg
        result.data = invalid
        m.top.result = result
        return
    end if
    
    if json.photo = invalid then
        print "[PhotoInfoTask] ERROR: No photo data in response"
        result = {}
        result.success = false
        result.error = "No photo data in response"
        result.data = invalid
        m.top.result = result
        return
    end if
    
    print "[PhotoInfoTask] Photo info loaded successfully"
    
    result = {}
    result.success = true
    result.error = ""
    result.data = json.photo
    m.top.result = result
end sub


' ******************************************************
' MOCK DATA FOR TESTING
' ******************************************************
function getMockResponse(photoId as String) as Object
    print "[PhotoInfoTask] Getting mock response for ID: "; photoId
    
    ' TEST: Success with all fields
    if photoId = "test_success" or photoId = "mock_success" or photoId.Left(5) = "mock_" then
        print "[PhotoInfoTask] Mock Scenario: SUCCESS with all fields"
        
        result = {}
        result.success = true
        result.error = ""
        result.data = {
            id: photoId
            title: { _content: "Beautiful Sunset Over Mountains" }
            description: { _content: "This stunning photograph captures the golden hour as the sun sets behind snow-capped mountain peaks." }
            owner: {
                nsid: "12345678@N00"
                username: "NaturePhotographer"
                realname: "John Smith"
            }
            dates: {
                posted: "1704067200"
                taken: "2024-01-15 14:30:00"
            }
            views: "15234"
            comments: { _content: "42" }
        }
        return result
    end if
    
    ' TEST: Missing optional fields
    if photoId = "test_minimal" or photoId = "mock_minimal" then
        print "[PhotoInfoTask] Mock Scenario: SUCCESS with missing fields"
        
        result = {}
        result.success = true
        result.error = ""
        result.data = {
            id: photoId
            title: { _content: "Untitled Photo" }
            description: { _content: "" }
            owner: {
                nsid: "12345678@N00"
                username: "Anonymous"
            }
            dates: {
                posted: "1704067200"
            }
        }
        return result
    end if
    
    ' TEST: Photo not found error
    if photoId = "test_notfound" or photoId = "mock_error" then
        print "[PhotoInfoTask] Mock Scenario: API ERROR - Photo not found"
        
        result = {}
        result.success = false
        result.error = "Photo not found"
        result.data = invalid
        return result
    end if
    
    ' TEST: Network error
    if photoId = "test_network_error" then
        print "[PhotoInfoTask] Mock Scenario: NETWORK ERROR"
        
        result = {}
        result.success = false
        result.error = "Network timeout - Unable to connect to server"
        result.data = invalid
        return result
    end if
    
    ' TEST: Extreme values
    if photoId = "test_extreme" then
        print "[PhotoInfoTask] Mock Scenario: SUCCESS with extreme values"
        
        result = {}
        result.success = true
        result.error = ""
        result.data = {
            id: photoId
            title: { _content: "A very long title that goes on and on and might break the UI if not handled properly" }
            description: { _content: "Very long description with special characters: é, ñ, 中文, emoji 🌄🏔️" }
            owner: {
                nsid: "12345678@N00"
                username: "VeryLongUsernameToTest123456789"
                realname: "Firstname Middlename Lastname Jr."
            }
            dates: {
                posted: "1704067200"
                taken: "2024-01-15 14:30:00"
            }
            views: "999999999"
            comments: { _content: "12345" }
        }
        return result
    end if
    
    ' DEFAULT: Normal success
    print "[PhotoInfoTask] Mock Scenario: DEFAULT success"
    
    result = {}
    result.success = true
    result.error = ""
    result.data = {
        id: photoId
        title: { _content: "Sample Photo" }
        description: { _content: "Sample description for testing" }
        owner: {
            nsid: "12345678@N00"
            username: "TestUser"
            realname: "Test User"
        }
        dates: {
            posted: "1704067200"
            taken: "2024-01-15 12:00:00"
        }
        views: "1234"
        comments: { _content: "5" }
    }
    return result
end function
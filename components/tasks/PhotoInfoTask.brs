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

    photoId = m.top.photoId

    if photoId = invalid or photoId = "" then
        m.top.result = ResponseBuilder_error("Invalid photo ID")
        return
    end if

    ' =====================================================
    ' TESTING MODE - Change this to test different scenarios
    ' =====================================================
    USE_MOCK_DATA = false  ' ← SET TO true FOR TESTING, false FOR REAL API

    if USE_MOCK_DATA then
        m.top.result = getMockResponse(photoId)
        return
    end if
    ' =====================================================

    ' Real API call (only runs if USE_MOCK_DATA = false)
    apiKey = GetApiConfig().API_KEY
    url = GetApiConfig().BASE_URL
    url = url + "?method=flickr.photos.getInfo"
    url = url + "&api_key=" + apiKey
    url = url + "&photo_id=" + photoId
    url = url + "&format=json"
    url = url + "&nojsoncallback=1"

    request = CreateObject("roUrlTransfer")

    if request = invalid then
        m.top.result = ResponseBuilder_error("Failed to create HTTP request")
        return
    end if

    request.SetUrl(url)
    request.EnablePeerVerification(false)
    request.EnableHostVerification(false)
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.InitClientCertificates()

    response = request.GetToString()

    if response = invalid or response = "" then
        m.top.result = ResponseBuilder_error("Empty response from API")
        return
    end if

    json = ParseJson(response)

    if json = invalid then
        m.top.result = ResponseBuilder_error("Invalid JSON response")
        return
    end if

    if json.stat <> invalid and json.stat = "fail" then
        errorMsg = "API Error"
        if json.message <> invalid then errorMsg = json.message
        m.top.result = ResponseBuilder_error(errorMsg, "API_ERROR")
        return
    end if

    if json.photo = invalid then
        m.top.result = ResponseBuilder_error("No photo data in response")
        return
    end if

    m.top.result = ResponseBuilder_success(json.photo)
end sub


' ******************************************************
' MOCK DATA FOR TESTING
' ******************************************************
function getMockResponse(photoId as String) as Object

    ' TEST: Success with all fields
    if photoId = "test_success" or photoId = "mock_success" or photoId.Left(5) = "mock_" then
        return ResponseBuilder_success({
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
        })
    end if

    ' TEST: Missing optional fields
    if photoId = "test_minimal" or photoId = "mock_minimal" then
        return ResponseBuilder_success({
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
        })
    end if

    ' TEST: Photo not found error
    if photoId = "test_notfound" or photoId = "mock_error" then
        return ResponseBuilder_error("Photo not found")
    end if

    ' TEST: Network error
    if photoId = "test_network_error" then
        return ResponseBuilder_error("Network timeout - Unable to connect to server", "NETWORK")
    end if

    ' TEST: Extreme values
    if photoId = "test_extreme" then
        return ResponseBuilder_success({
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
        })
    end if

    ' DEFAULT: Normal success
    return ResponseBuilder_success({
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
    })
end function

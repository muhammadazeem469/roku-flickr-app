' ******************************************************
' PhotoInfoTask.brs
' Task for loading photo information from Flickr API
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

    url = BuildPhotoInfoURL(photoId)

    config = GetNetworkConfig()
    response = HttpClient_makeRequest(url, config.DEFAULT_TIMEOUT)

    if not response.success then
        m.top.result = ResponseBuilder_error(response.error)
        return
    end if

    parsedResponse = JsonParser_parse(response)

    if not parsedResponse.success then
        m.top.result = ResponseBuilder_error(parsedResponse.error)
        return
    end if

    json = parsedResponse.data

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

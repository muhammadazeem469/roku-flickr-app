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

    ' Real API call
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

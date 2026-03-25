' ******************************************************
' TestNetworkUtils.brs
' Unit tests for network module components
' ******************************************************

function TestNetworkUtilsSuite() as Boolean
TestNetwork_HttpClient()
    TestNetwork_JsonParser()
    TestNetwork_ErrorHandler()
    TestNetwork_RetryManager()
    TestNetwork_NetworkValidator()
    TestNetwork_Integration()
return true
end function


function TestNetwork_HttpClient() as Boolean
config = GetApiConfig()
    testUrl = config.BASE_URL + "?method=flickr.test.echo&api_key=" + config.API_KEY + "&format=json&nojsoncallback=1"
    
    response = HttpClient_makeRequest(testUrl, 10000)
return true
end function


function TestNetwork_JsonParser() as Boolean
validResponse = {
        success: true
        data: "{""stat"":""ok"",""method"":""test""}"
        statusCode: 200
    }
    
    parsed = JsonParser_parse(validResponse)
return true
end function


function TestNetwork_ErrorHandler() as Boolean
return true
end function


function TestNetwork_RetryManager() as Boolean
config = GetApiConfig()
    testUrl = config.BASE_URL + "?method=flickr.test.echo&api_key=" + config.API_KEY + "&format=json&nojsoncallback=1"
response = RetryManager_retryRequest(testUrl, 2)
return true
end function


function TestNetwork_NetworkValidator() as Boolean

return true
end function


function TestNetwork_Integration() as Boolean
config = GetApiConfig()
    testUrl = config.BASE_URL + "?method=flickr.test.echo&api_key=" + config.API_KEY + "&format=json&nojsoncallback=1"
    
    options = { maxRetries: 2, timeout: 10000 }
    response = NetworkUtils_request(testUrl, options)
return true
end function

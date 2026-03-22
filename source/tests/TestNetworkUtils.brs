' ******************************************************
' TestNetworkUtils.brs
' Unit tests for network module components
' ******************************************************

function TestNetworkUtilsSuite() as Boolean
    print ""
    print "================================================"
    print "TESTING NETWORK UTILS SUITE"
    print "================================================"
    
    TestNetwork_HttpClient()
    TestNetwork_JsonParser()
    TestNetwork_ErrorHandler()
    TestNetwork_RetryManager()
    TestNetwork_NetworkValidator()
    TestNetwork_Integration()
    
    print "================================================"
    print "NETWORK UTILS TESTS COMPLETE"
    print "================================================"
    print ""
    
    return true
end function


function TestNetwork_HttpClient() as Boolean
    print ""
    print "--- Testing HttpClient ---"
    
    config = GetApiConfig()
    testUrl = config.BASE_URL + "?method=flickr.test.echo&api_key=" + config.API_KEY + "&format=json&nojsoncallback=1"
    
    response = HttpClient_makeRequest(testUrl, 10000)
    
    print "Success: "; response.success
    print "Status Code: "; response.statusCode
    print "Has Data: "; (response.data <> invalid)
    
    print ""
    return true
end function


function TestNetwork_JsonParser() as Boolean
    print ""
    print "--- Testing JsonParser ---"
    
    validResponse = {
        success: true
        data: "{""stat"":""ok"",""method"":""test""}"
        statusCode: 200
    }
    
    parsed = JsonParser_parse(validResponse)
    print "Parse Success: "; parsed.success
    print "Data Valid: "; (parsed.data <> invalid)
    
    print ""
    return true
end function


function TestNetwork_ErrorHandler() as Boolean
    print ""
    print "--- Testing ErrorHandler ---"
    
    print "Testing error categorization..."
    print "404:", ErrorHandler_categorizeHttpStatus(404)
    print "500:", ErrorHandler_categorizeHttpStatus(500)
    print "503:", ErrorHandler_categorizeHttpStatus(503)
    
    print ""
    print "Testing retry logic..."
    print "500 retryable:", ErrorHandler_isRetryable("SERVER_ERROR", 500)
    print "404 retryable:", ErrorHandler_isRetryable("NOT_FOUND", 404)
    
    print ""
    return true
end function


function TestNetwork_RetryManager() as Boolean
    print ""
    print "--- Testing RetryManager ---"
    
    config = GetApiConfig()
    testUrl = config.BASE_URL + "?method=flickr.test.echo&api_key=" + config.API_KEY + "&format=json&nojsoncallback=1"
    
    print "Testing retry with valid endpoint..."
    response = RetryManager_retryRequest(testUrl, 2)
    print "Success: "; response.success
    
    print ""
    return true
end function


function TestNetwork_NetworkValidator() as Boolean
    print ""
    print "--- Testing NetworkValidator ---"
    
    print "Network Available: "; NetworkValidator_isAvailable()
    print "Valid URL (https://test.com): "; NetworkValidator_validateUrl("https://test.com")
    print "Invalid URL (empty): "; NetworkValidator_validateUrl("")
    
    print ""
    return true
end function


function TestNetwork_Integration() as Boolean
    print ""
    print "--- Testing Integration (NetworkUtils facade) ---"
    
    config = GetApiConfig()
    testUrl = config.BASE_URL + "?method=flickr.test.echo&api_key=" + config.API_KEY + "&format=json&nojsoncallback=1"
    
    options = { maxRetries: 2, timeout: 10000 }
    response = NetworkUtils_request(testUrl, options)
    
    print "Request Success: "; response.success
    print "Has Parsed Data: "; (response.data <> invalid)
    
    print ""
    return true
end function

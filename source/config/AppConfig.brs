function GetApiConfig() as Object
    ' -------------------------------------------------------
    ' FG-022 DEBUG FLAGS
    ' Flip one at a time to test each error scenario.
    ' Set ALL back to false before shipping.
    '
    '   DEBUG_BAD_API_KEY  = true  → Flickr returns stat:"fail"
    '                                Exercises API_ERROR path.
    '                                On screen: "Couldn't load images. Please try again later."
    '
    '   DEBUG_NETWORK_ERROR = true → Skips HTTP entirely, fakes
    '                                a network-down response.
    '                                Exercises NETWORK path.
    '                                On screen: "Unable to connect. Check your internet connection."
    '
    '   DEBUG_EMPTY_RESULTS = true → Returns success but 0 photos.
    '                                Exercises EMPTY path.
    '                                On screen: "No images found in this category."
    ' -------------------------------------------------------
    DEBUG_BAD_API_KEY   = false
    DEBUG_NETWORK_ERROR = false
    DEBUG_EMPTY_RESULTS = false

    apiKey = "452b3b7a5d806dcd110842e6649c604d"
    if DEBUG_BAD_API_KEY then
        apiKey = "INVALID_KEY_XXXX"
    end if

    return {
        BASE_URL: "https://api.flickr.com/services/rest/"
        API_KEY: apiKey
        FORMAT: "json"
        NO_JSON_CALLBACK: "1"

        ' App Metadata
        APP_NAME: "Flickr Gallery"
        APP_VERSION: "1.0.0"

        ' Debug flags — read by CategoryLoadTask
        DEBUG_BAD_API_KEY:   DEBUG_BAD_API_KEY
        DEBUG_NETWORK_ERROR: DEBUG_NETWORK_ERROR
        DEBUG_EMPTY_RESULTS: DEBUG_EMPTY_RESULTS
    }
end function

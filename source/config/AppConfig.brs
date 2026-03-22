function GetApiConfig() as Object
    return {
        BASE_URL: "https://api.flickr.com/services/rest/"
        API_KEY: "452b3b7a5d806dcd110842e6649c604d"
        FORMAT: "json"
        NO_JSON_CALLBACK: "1"
        
        ' App Metadata
        APP_NAME: "Flickr Gallery"
        APP_VERSION: "1.0.0"
    }
end function
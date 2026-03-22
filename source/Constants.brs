function GetConstants() as Object
    return {
        ' API Configuration
        FLICKR_API_KEY: ""  ' To be configured
        FLICKR_API_URL: "https://api.flickr.com/services/rest/"
        
        ' App Configuration
        APP_NAME: "Flickr Gallery"
        APP_VERSION: "1.0.0"
        
        ' UI Configuration
        GRID_COLUMNS: 4
        GRID_ROWS: 3
        
        ' Image Quality
        IMAGE_SIZE: "medium"
    }
end function
' ******************************************************
' DetailViewModel.brs
' ViewModel for the image detail screen
' Manages business logic for displaying detailed image information
' ******************************************************

' Constructor - Creates DetailViewModel instance
' @param imageModel - ImageModel object from selected image
' @return DetailViewModel object
function CreateDetailViewModel(imageModel as Object) as Object
    print "[DetailViewModel] Creating DetailViewModel for image: "; imageModel.id
    
    viewModel = {
        ' Data
        image: imageModel
        imageInfo: invalid
        
        ' State
        isLoading: false
        hasError: false
        errorMessage: ""
        
        ' Extended metadata (populated after loadExtendedInfo)
        dimensions: ""          ' e.g., "1024 x 768"
        fileSize: ""            ' e.g., "2.5 MB"
        uploadDate: ""          ' Formatted date
        viewCount: 0
        commentCount: 0
        fullDescription: ""
        
        ' Helper modules
        infoLoader: DetailViewModel_InfoLoader()
        infoParser: DetailViewModel_InfoParser()
        stateManager: DetailViewModel_StateManager()
        
        ' Methods
        init: DetailViewModel_init
        loadExtendedInfo: DetailViewModel_loadExtendedInfo
        parseImageInfo: DetailViewModel_parseImageInfo
        handleError: DetailViewModel_handleError
        cleanup: DetailViewModel_cleanup
    }
    
    return viewModel
end function


' Initialize ViewModel
function DetailViewModel_init() as Void
    print "[DetailViewModel] Initializing..."
    
    if m.image = invalid then
        print "[DetailViewModel] ERROR: No image model provided"
        m.stateManager.setError(m, "No image data available")
        return
    end if
    
    ' Validate required fields
    if m.image.id = "" or m.image.id = invalid then
        print "[DetailViewModel] ERROR: Invalid image ID"
        m.stateManager.setError(m, "Invalid image data")
        return
    end if
    
    ' Initialize basic metadata from image model
    m.infoParser.initializeBasicMetadata(m)
    
    print "[DetailViewModel] Initialization complete for: "; m.image.title
end function


' Load extended information from Flickr API
function DetailViewModel_loadExtendedInfo() as Void
    print "[DetailViewModel] Loading extended info for photo: "; m.image.id
    
    m.infoLoader.loadPhotoInfo(m, m.image.id)
end function


' Parse and populate extended metadata from API response
' @param photoData - Parsed JSON response from flickr.photos.getInfo
function DetailViewModel_parseImageInfo(photoData as Object) as Void
    print "[DetailViewModel] Parsing image info..."
    
    if photoData = invalid then
        print "[DetailViewModel] ERROR: Invalid photo data"
        return
    end if
    
    ' Store raw data
    m.imageInfo = photoData
    
    ' Delegate parsing to InfoParser module
    m.infoParser.parseExtendedMetadata(m, photoData)
    
    print "[DetailViewModel] Image info parsing complete"
end function


' Handle error during info loading
' @param errorMsg - Error message
function DetailViewModel_handleError(errorMsg as String) as Void
    m.stateManager.setError(m, errorMsg)
end function


' Cleanup resources
function DetailViewModel_cleanup() as Void
    print "[DetailViewModel] Cleaning up..."
    
    m.image = invalid
    m.imageInfo = invalid
    
    print "[DetailViewModel] Cleanup complete"
end function
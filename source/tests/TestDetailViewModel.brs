' ******************************************************
' TestDetailViewModel.brs
' Unit tests for DetailViewModel and related components
' ******************************************************

function TestDetailViewModelSuite() as Boolean
    print ""
    print "================================================"
    print "TESTING DETAIL VIEW MODEL SUITE"
    print "================================================"
    
    TestDetailViewModel_Creation()
    TestDetailViewModel_InitWithValidImage()
    TestDetailViewModel_InitWithInvalidImage()
    TestDetailViewModel_ParseImageInfo()
    TestDetailViewModel_ParseImageInfoMissingData()
    TestDetailViewModel_ErrorHandling()
    TestDetailViewModel_StateManager()
    TestDetailViewModel_Cleanup()
    
    print "================================================"
    print "DETAIL VIEW MODEL TESTS COMPLETE"
    print "================================================"
    print ""
    
    return true
end function


function TestDetailViewModel_Creation() as Boolean
    print ""
    print "--- Testing DetailViewModel Creation ---"
    
    ' Create mock image model
    mockImage = CreateImageModel()
    mockImage.id = "12345"
    mockImage.title = "Test Image"
    mockImage.width = 1024
    mockImage.height = 768
    
    ' Create ViewModel
    viewModel = CreateDetailViewModel(mockImage)
    
    ' Verify structure
    print "Image ID: "; viewModel.image.id
    print "Image Title: "; viewModel.image.title
    print "Is Loading: "; viewModel.isLoading
    print "Has Error: "; viewModel.hasError
    print "Has init method: "; (viewModel.init <> invalid)
    print "Has loadExtendedInfo method: "; (viewModel.loadExtendedInfo <> invalid)
    print "Has parseImageInfo method: "; (viewModel.parseImageInfo <> invalid)
    print "Has infoLoader module: "; (viewModel.infoLoader <> invalid)
    print "Has stateManager module: "; (viewModel.stateManager <> invalid)
    print ""
    
    return true
end function


function TestDetailViewModel_InitWithValidImage() as Boolean
    print "--- Testing Init with Valid Image ---"
    
    ' Create mock image
    mockImage = CreateImageModel()
    mockImage.id = "67890"
    mockImage.title = "Sunset Photo"
    mockImage.width = 1920
    mockImage.height = 1080
    mockImage.views = 1500
    mockImage.description = "Beautiful sunset"
    
    ' Create and init ViewModel
    viewModel = CreateDetailViewModel(mockImage)
    viewModel.init()
    
    ' Verify initialization
    print "Has Error: "; viewModel.hasError
    print "Dimensions: "; viewModel.dimensions
    print "View Count: "; viewModel.viewCount
    print "Full Description: "; viewModel.fullDescription
    print ""
    
    return true
end function


function TestDetailViewModel_InitWithInvalidImage() as Boolean
    print "--- Testing Init with Invalid Image ---"
    
    ' Create mock image with missing ID
    mockImage = CreateImageModel()
    mockImage.id = ""
    mockImage.title = "Invalid Image"
    
    ' Create and init ViewModel
    viewModel = CreateDetailViewModel(mockImage)
    viewModel.init()
    
    ' Verify error state
    print "Has Error: "; viewModel.hasError
    print "Error Message: "; viewModel.errorMessage
    print ""
    
    return true
end function


function TestDetailViewModel_ParseImageInfo() as Boolean
    print "--- Testing ParseImageInfo with Complete Data ---"
    
    ' Create mock image
    mockImage = CreateImageModel()
    mockImage.id = "11111"
    mockImage.title = "Test"
    
    viewModel = CreateDetailViewModel(mockImage)
    viewModel.init()
    
    ' Create mock API response
    mockPhotoData = {
        id: "11111"
        title: { _content: "Updated Title" }
        description: { _content: "Full description from API" }
        originalwidth: "2048"
        originalheight: "1536"
        views: "5000"
        dates: { posted: "1640995200" }
        comments: { _content: "25" }
        tags: {
            tag: [
                { _content: "nature" }
                { _content: "landscape" }
            ]
        }
    }
    
    ' Parse the data
    viewModel.parseImageInfo(mockPhotoData)
    
    ' Verify parsing
    print "Dimensions: "; viewModel.dimensions
    print "View Count: "; viewModel.viewCount
    print "Comment Count: "; viewModel.commentCount
    print "Full Description: "; viewModel.fullDescription
    print "Updated Title: "; viewModel.image.title
    print "Tag Count: "; viewModel.image.tags.Count()
    print ""
    
    return true
end function


function TestDetailViewModel_ParseImageInfoMissingData() as Boolean
    print "--- Testing ParseImageInfo with Missing Data ---"
    
    mockImage = CreateImageModel()
    mockImage.id = "22222"
    mockImage.description = "Fallback description"
    
    viewModel = CreateDetailViewModel(mockImage)
    viewModel.init()
    
    ' Create minimal mock data
    mockPhotoData = {
        id: "22222"
    }
    
    ' Parse the data (should handle missing fields gracefully)
    viewModel.parseImageInfo(mockPhotoData)
    
    ' Verify fallback values
    print "Full Description (fallback): "; viewModel.fullDescription
    print "View Count (default): "; viewModel.viewCount
    print "Comment Count (default): "; viewModel.commentCount
    print ""
    
    return true
end function


function TestDetailViewModel_ErrorHandling() as Boolean
    print "--- Testing Error Handling ---"
    
    mockImage = CreateImageModel()
    mockImage.id = "33333"
    
    viewModel = CreateDetailViewModel(mockImage)
    viewModel.init()
    
    ' Trigger error
    errorMsg = "Network error occurred"
    viewModel.handleError(errorMsg)
    
    ' Verify error state
    print "Has Error: "; viewModel.hasError
    print "Error Message: "; viewModel.errorMessage
    print "Is Loading: "; viewModel.isLoading
    print ""
    
    return true
end function


function TestDetailViewModel_StateManager() as Boolean
    print "--- Testing DetailViewModel_StateManager ---"
    
    mockImage = CreateImageModel()
    mockImage.id = "44444"
    
    viewModel = CreateDetailViewModel(mockImage)
    viewModel.init()
    
    ' Test setLoading
    viewModel.stateManager.setLoading(viewModel, true)
    print "Is Loading (set to true): "; viewModel.isLoading
    print "Has Error (should be false): "; viewModel.hasError
    
    viewModel.stateManager.setLoading(viewModel, false)
    print "Is Loading (set to false): "; viewModel.isLoading
    
    ' Test setError
    viewModel.stateManager.setError(viewModel, "Test error")
    print "Has Error: "; viewModel.hasError
    print "Error Message: "; viewModel.errorMessage
    print "Is Loading (should be false): "; viewModel.isLoading
    
    ' Test clearError
    viewModel.stateManager.clearError(viewModel)
    print "Error Cleared: "; not viewModel.hasError
    print ""
    
    return true
end function


function TestDetailViewModel_Cleanup() as Boolean
    print "--- Testing Cleanup ---"
    
    mockImage = CreateImageModel()
    mockImage.id = "55555"
    mockImage.title = "Cleanup Test"
    
    viewModel = CreateDetailViewModel(mockImage)
    viewModel.init()
    
    print "Before cleanup - Image ID: "; viewModel.image.id
    
    ' Cleanup
    viewModel.cleanup()
    
    ' Verify cleanup
    print "After cleanup - Image is invalid: "; (viewModel.image = invalid)
    print "After cleanup - ImageInfo is invalid: "; (viewModel.imageInfo = invalid)
    print ""
    
    return true
end function
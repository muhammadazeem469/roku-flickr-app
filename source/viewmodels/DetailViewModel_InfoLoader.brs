' ******************************************************
' DetailViewModel_InfoLoader.brs
' Handles loading extended photo information from Flickr API
' Separated concern for API interaction and response handling
' ******************************************************

function DetailViewModel_InfoLoader() as Object
    return {
        loadPhotoInfo: DetailViewModel_InfoLoader_loadPhotoInfo
    }
end function


' Load photo information from Flickr API
' @param viewModel - Reference to parent DetailViewModel
' @param photoId - Flickr photo ID to fetch
function DetailViewModel_InfoLoader_loadPhotoInfo(viewModel as Object, photoId as String) as Void
    print "[InfoLoader] Loading photo info for ID: "; photoId
    
    ' Set loading state
    viewModel.stateManager.setLoading(viewModel, true)
    
    ' Call FlickrService to fetch data
    result = FlickrService_GetPhotoInfo(photoId)
    
    ' Handle response
    if result.success then
        print "[InfoLoader] Photo info loaded successfully"
        
        ' Parse the photo data
        viewModel.parseImageInfo(result.data)
        
        ' Clear loading state
        viewModel.stateManager.setLoading(viewModel, false)
    else
        print "[InfoLoader] Failed to load photo info: "; result.error
        
        ' Set error state
        viewModel.handleError(result.error)
        viewModel.stateManager.setLoading(viewModel, false)
    end if
end function
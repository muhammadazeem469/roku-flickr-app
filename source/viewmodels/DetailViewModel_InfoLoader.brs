' ******************************************************
' DetailViewModel_InfoLoader.brs
' Creates and configures the PhotoInfoTask for extended
' photo metadata loading, and interprets its result.
'
' MVVM role — ViewModel sub-module.
'
'   createTask   — called by DetailViewModel.loadExtendedInfo().
'                  Returns a configured PhotoInfoTask ready to run,
'                  or invalid for mock IDs / creation failure.
'                  The VIEW is responsible only for:
'                    1. observing task.result
'                    2. calling task.control = "RUN"
'                    3. forwarding the result back via
'                       viewModel.handlePhotoInfoResult()
'
'   handleResult — called by DetailViewModel.handlePhotoInfoResult().
'                  All success/failure logic lives here, not in the View.
' ******************************************************

function DetailViewModel_InfoLoader() as Object
    return {
        createTask:   DetailViewModel_InfoLoader_createTask
        handleResult: DetailViewModel_InfoLoader_handleResult
    }
end function


' Create and configure a PhotoInfoTask for the viewModel's image.
'
' Returns the task node (caller must observe "result" then set
' control = "RUN"), or invalid when:
'   - photo ID starts with "mock_"  → test data, no real task needed
'   - CreateObject fails            → viewModel error state is set
'
' @param viewModel - DetailViewModel reference
' @return roSGNode PhotoInfoTask, or invalid
function DetailViewModel_InfoLoader_createTask(viewModel as Object) as Object
    photoId = viewModel.image.id

    ' Skip real API call for mock/test photo IDs.
    ' The caller will display placeholder "Not available" values.
    if photoId.Left(5) = "mock_" then
        return invalid
    end if

    task = CreateObject("roSGNode", "PhotoInfoTask")
    if task = invalid then
        viewModel.stateManager.setError(viewModel, "Failed to create API task")
        return invalid
    end if

    task.photoId = photoId
    return task
end function


' Process a completed PhotoInfoTask result.
' On success: delegates to viewModel.parseImageInfo() which updates
'             all extended metadata fields (dimensions, date, etc.).
' On failure: delegates to viewModel.handleError() which sets
'             viewModel.hasError / viewModel.errorMessage.
'
' @param viewModel - DetailViewModel reference
' @param result    - assocarray from task.result  { success, data, error }
function DetailViewModel_InfoLoader_handleResult(viewModel as Object, result as Object) as Void
    if result = invalid then
        viewModel.stateManager.setError(viewModel, "Invalid API response")
        return
    end if

    if result.success then
        viewModel.parseImageInfo(result.data)
    else
        viewModel.handleError(result.error)
    end if
end function

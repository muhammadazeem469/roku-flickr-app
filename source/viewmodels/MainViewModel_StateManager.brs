' ******************************************************
' MainViewModel_StateManager.brs
' State management helpers for MainViewModel
' ******************************************************

function MainViewModel_StateManager() as Object
    return {
        setGlobalError: MainViewModel_StateManager_setGlobalError
        clearGlobalError: MainViewModel_StateManager_clearGlobalError
        getCategoryState: MainViewModel_StateManager_getCategoryState
    }
end function


' Set global error state
function MainViewModel_StateManager_setGlobalError(viewModel as Object, errorMessage as String) as Void
    
    viewModel.hasError = true
    viewModel.errorMessage = errorMessage
    viewModel.isInitializing = false
    
    ' Trigger view update
    viewModel.categoryDataChanged = not viewModel.categoryDataChanged
end function


' Clear global error state
function MainViewModel_StateManager_clearGlobalError(viewModel as Object) as Void
viewModel.hasError = false
    viewModel.errorMessage = ""
end function


' Get summary of category states
function MainViewModel_StateManager_getCategoryState(viewModel as Object) as Object
    loadingCount = 0
    errorCount = 0
    loadedCount = 0
    
    for each category in viewModel.categories
        if category.isLoading then
            loadingCount = loadingCount + 1
        else if category.hasError then
            errorCount = errorCount + 1
        else if category.images.Count() > 0 then
            loadedCount = loadedCount + 1
        end if
    end for
    
    return {
        total: viewModel.categories.Count()
        loading: loadingCount
        error: errorCount
        loaded: loadedCount
    }
end function
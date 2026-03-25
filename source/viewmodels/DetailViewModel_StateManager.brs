' ******************************************************
' DetailViewModel_StateManager.brs
' State management helpers for DetailViewModel
' Handles loading, error, and data state transitions
' ******************************************************

function DetailViewModel_StateManager() as Object
    return {
        setLoading: DetailViewModel_StateManager_setLoading
        setError: DetailViewModel_StateManager_setError
        clearError: DetailViewModel_StateManager_clearError
    }
end function


' Set loading state
' @param viewModel - Reference to DetailViewModel
' @param state - Boolean loading state
function DetailViewModel_StateManager_setLoading(viewModel as Object, state as Boolean) as Void
    
    viewModel.isLoading = state
    
    ' Clear error when starting to load
    if state = true then
        viewModel.hasError = false
        viewModel.errorMessage = ""
    end if
end function


' Set error state with message
' @param viewModel - Reference to DetailViewModel
' @param errorMessage - Error message to display
function DetailViewModel_StateManager_setError(viewModel as Object, errorMessage as String) as Void
    
    viewModel.hasError = true
    viewModel.errorMessage = errorMessage
    viewModel.isLoading = false
end function


' Clear error state
' @param viewModel - Reference to DetailViewModel
function DetailViewModel_StateManager_clearError(viewModel as Object) as Void
viewModel.hasError = false
    viewModel.errorMessage = ""
end function
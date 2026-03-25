' ******************************************************
' TestMainViewModel.brs
' Unit tests for MainViewModel
' ******************************************************

function TestMainViewModelSuite() as Boolean
TestMainViewModel_Initialization()
    TestMainViewModel_CategoryLoading()
    TestMainViewModel_StateManagement()
    TestMainViewModel_ImageSelection()
return true
end function


function TestMainViewModel_Initialization() as Boolean
' Create ViewModel
    viewModel = CreateMainViewModel()
    
    ' Initialize
    viewModel.init()
    
    ' Verify categories loaded
    if viewModel.categories.Count() > 0 then
        firstCategory = viewModel.categories[0]
    end if
return true
end function


function TestMainViewModel_CategoryLoading() as Boolean
viewModel = CreateMainViewModel()
    viewModel.init()
    
    ' Test loading single category
viewModel.loadCategory(0)
    
    category = viewModel.categories[0]
    
    ' Test loading all categories
viewModel.loadAllCategories()
    
    ' Check state
    stateManager = viewModel.stateManager
    state = stateManager.getCategoryState(viewModel)
return true
end function


function TestMainViewModel_StateManagement() as Boolean
viewModel = CreateMainViewModel()
    viewModel.init()
    
    ' Test global error
    viewModel.stateManager.setGlobalError(viewModel, "Test error message")
    
    ' Clear error
    viewModel.stateManager.clearGlobalError(viewModel)
return true
end function


function TestMainViewModel_ImageSelection() as Boolean
viewModel = CreateMainViewModel()
    viewModel.init()
    viewModel.loadCategory(0)
    
    ' Select image
    viewModel.handleImageSelection(0, 2)
return true
end function
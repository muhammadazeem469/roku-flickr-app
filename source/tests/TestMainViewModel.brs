' ******************************************************
' TestMainViewModel.brs
' Unit tests for MainViewModel
' ******************************************************

function TestMainViewModelSuite() as Boolean
    print ""
    print "================================================"
    print "TESTING MAIN VIEWMODEL SUITE"
    print "================================================"
    
    TestMainViewModel_Initialization()
    TestMainViewModel_CategoryLoading()
    TestMainViewModel_StateManagement()
    TestMainViewModel_ImageSelection()
    
    print "================================================"
    print "MAIN VIEWMODEL TESTS COMPLETE"
    print "================================================"
    print ""
    
    return true
end function


function TestMainViewModel_Initialization() as Boolean
    print ""
    print "--- Testing MainViewModel Initialization ---"
    
    ' Create ViewModel
    viewModel = CreateMainViewModel()
    
    print "ViewModel created: "; (viewModel <> invalid)
    print "Is Initializing: "; viewModel.isInitializing
    
    ' Initialize
    viewModel.init()
    
    print "After init - Is Initializing: "; viewModel.isInitializing
    print "Categories count: "; viewModel.categories.Count()
    print "Has Error: "; viewModel.hasError
    
    ' Verify categories loaded
    if viewModel.categories.Count() > 0 then
        firstCategory = viewModel.categories[0]
        print "First category name: "; firstCategory.name
        print "First category display: "; firstCategory.display_name
    end if
    
    print ""
    return true
end function


function TestMainViewModel_CategoryLoading() as Boolean
    print "--- Testing Category Loading ---"
    
    viewModel = CreateMainViewModel()
    viewModel.init()
    
    ' Test loading single category
    print "Loading category 0..."
    viewModel.loadCategory(0)
    
    category = viewModel.categories[0]
    print "Category loaded: "; category.name
    print "Images loaded: "; category.images.Count()
    print "Is Loading: "; category.isLoading
    print "Total Pages: "; category.totalPages
    
    ' Test loading all categories
    print "Loading all categories..."
    viewModel.loadAllCategories()
    
    ' Check state
    stateManager = viewModel.stateManager
    state = stateManager.getCategoryState(viewModel)
    print "Total categories: "; state.total
    print "Loaded categories: "; state.loaded
    print "Loading categories: "; state.loading
    print "Error categories: "; state.error
    
    print ""
    return true
end function


function TestMainViewModel_StateManagement() as Boolean
    print "--- Testing State Management ---"
    
    viewModel = CreateMainViewModel()
    viewModel.init()
    
    ' Test global error
    viewModel.stateManager.setGlobalError(viewModel, "Test error message")
    print "Has Error: "; viewModel.hasError
    print "Error Message: "; viewModel.errorMessage
    
    ' Clear error
    viewModel.stateManager.clearGlobalError(viewModel)
    print "After clear - Has Error: "; viewModel.hasError
    
    print ""
    return true
end function


function TestMainViewModel_ImageSelection() as Boolean
    print "--- Testing Image Selection ---"
    
    viewModel = CreateMainViewModel()
    viewModel.init()
    viewModel.loadCategory(0)
    
    ' Select image
    viewModel.handleImageSelection(0, 2)
    
    print "Selected Category Index: "; viewModel.selectedCategoryIndex
    print "Selected Image Index: "; viewModel.selectedImageIndex
    print "Navigation Requested: "; viewModel.navigationRequested
    
    print ""
    return true
end function
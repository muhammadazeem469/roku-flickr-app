' ******************************************************
' MainViewModel.brs
' Main ViewModel for the gallery screen
' Manages business logic and state for category swimlanes
' ******************************************************

' Constructor - Creates MainViewModel instance
function CreateMainViewModel() as Object
    ' Use associative array instead of ContentNode
    viewModel = {
        ' Data
        categories: []
        
        ' Global state
        isInitializing: true
        hasError: false
        errorMessage: ""
        
        ' Navigation
        selectedCategoryIndex: 0
        selectedImageIndex: 0
        
        ' Events (for view to observe) — counter increments on every update
        categoryUpdateCount: 0
        navigationRequested: false
        
        ' Helper modules
        categoryLoader: MainViewModel_CategoryLoader()
        stateManager: MainViewModel_StateManager()
        
        ' Methods
        init: MainViewModel_init
        loadAllCategories: MainViewModel_loadAllCategories
        loadCategory: MainViewModel_loadCategory
        refreshCategory: MainViewModel_refreshCategory
        handleImageSelection: MainViewModel_handleImageSelection
        cleanup: MainViewModel_cleanup
    }
    
    return viewModel
end function


' Initialize ViewModel - Load categories from config
function MainViewModel_init() as Void
    m.isInitializing = true

    ' Load category configurations
    categoryConfigs = GetCategories()

    if categoryConfigs = invalid or categoryConfigs.Count() = 0 then
        m.stateManager.setGlobalError(m, "Failed to load category configurations")
        return
    end if
    
    ' Initialize all categories from config
    categories = []
    for each config in categoryConfigs
        category = CreateCategoryModel(config.name, config.display_name, config.tags, config.method)
        categories.Push(category)
    end for
    
    m.categories = categories
    m.isInitializing = false
end function


' Load all categories using hybrid strategy (Featured first, then rest)
' FG-020: Real Flickr API integration
function MainViewModel_loadAllCategories() as Void
    if m.categories.Count() = 0 then
        return
    end if
    
    ' Delegate to CategoryLoader which implements hybrid loading:
    ' 1. Featured category first (priority)
    ' 2. Then remaining categories sequentially
    m.categoryLoader.loadAllCategories(m)
end function


' Load specific category by index
function MainViewModel_loadCategory(categoryIndex as Integer) as Void
    m.categoryLoader.loadCategory(m, categoryIndex)
end function


' Refresh specific category data
function MainViewModel_refreshCategory(categoryIndex as Integer) as Void
    m.categoryLoader.refreshCategory(m, categoryIndex)
end function


' Handle image selection - prepare for navigation to detail screen
function MainViewModel_handleImageSelection(categoryIndex as Integer, imageIndex as Integer) as Void
    
    if categoryIndex < 0 or categoryIndex >= m.categories.Count() then
        return
    end if
    
    category = m.categories[categoryIndex]
    
    if imageIndex < 0 or imageIndex >= category.images.Count() then
        return
    end if
    
    ' Store selection
    m.selectedCategoryIndex = categoryIndex
    m.selectedImageIndex = imageIndex
    
    ' Trigger navigation (view will observe this field)
    m.navigationRequested = true
end function


' Cleanup resources
function MainViewModel_cleanup() as Void
    ' Clear categories
    if m.categories <> invalid then
        m.categories.Clear()
    end if
end function
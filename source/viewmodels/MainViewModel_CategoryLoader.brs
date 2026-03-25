' ******************************************************
' MainViewModel_CategoryLoader.brs
' Handles category data loading for MainViewModel
' FG-020: Real Flickr API integration with TASK thread for HTTP
' CRITICAL FIX: HTTP requests must run on Task thread
' ******************************************************

function MainViewModel_CategoryLoader() as Object
    loader = {
        ' Public methods
        loadCategory:       MainViewModel_CategoryLoader_loadCategory
        refreshCategory:    MainViewModel_CategoryLoader_refreshCategory
        loadAllCategories:  MainViewModel_CategoryLoader_loadAllCategories
        
        ' Methods that need scene context
        loadCategoryWithTask:   MainViewModel_CategoryLoader_loadCategoryWithTask
        
        ' Private helper methods
        parseApiResponse:   MainViewModel_CategoryLoader_parseApiResponse
        handleApiError:     MainViewModel_CategoryLoader_handleApiError
        
        ' Legacy mock method (for fallback testing)
        createMockImages:   MainViewModel_CategoryLoader_createMockImages
    }
    
    return loader
end function


' ******************************************************
' Load all categories using hybrid strategy
' NOTE: This version needs to be called from MainScene with scene context
' ******************************************************
function MainViewModel_CategoryLoader_loadAllCategories(viewModel as Object) as Void
if viewModel.categories.Count() = 0 then
viewModel.stateManager.setGlobalError(viewModel, "No categories configured")
        return
    end if
    
    ' Store category indices to load
    viewModel.categoriesToLoad = []
    
    ' STEP 1: Find Featured category
    featuredIndex = -1
    for i = 0 to viewModel.categories.Count() - 1
        if viewModel.categories[i].name = "Featured" then
            featuredIndex = i
        else
            viewModel.categoriesToLoad.Push(i)
        end if
    end for
    
    ' Add Featured first if found
    if featuredIndex >= 0 then
        viewModel.loadQueue = [featuredIndex]
        viewModel.loadQueue.Append(viewModel.categoriesToLoad)
    else
        viewModel.loadQueue = viewModel.categoriesToLoad
    end if
end function


' ******************************************************
' Load category data - synchronous version for testing only
' ******************************************************
function MainViewModel_CategoryLoader_loadCategory(viewModel as Object, categoryIndex as Integer) as Void
' Validate index
    if categoryIndex < 0 or categoryIndex >= viewModel.categories.Count() then
        return
    end if

    category = viewModel.categories[categoryIndex]
    
    ' Set loading state
    category = category.setLoading(true)
    viewModel.categories[categoryIndex] = category
end function


' ******************************************************
' Load category using Task (called from MainScene)
' ******************************************************
function MainViewModel_CategoryLoader_loadCategoryWithTask(viewModel as Object, categoryIndex as Integer, scene as Object) as Object
' Validate index
    if categoryIndex < 0 or categoryIndex >= viewModel.categories.Count() then
        return invalid
    end if

    category = viewModel.categories[categoryIndex]

    ' Set loading state
    category = category.setLoading(true)
    viewModel.categories[categoryIndex] = category
    viewModel.categoryDataChanged = not viewModel.categoryDataChanged

    ' Validate method and tags
    if category.method = "flickr.photos.search" then
        if category.tags = invalid or category.tags = "" then
MainViewModel_CategoryLoader_handleApiError(viewModel, categoryIndex, "Couldn't load images. Please try again later.", "API_ERROR")
            return invalid
        end if
    end if

    ' Create Task node
    task = scene.createChild("CategoryLoadTask")
    
    if task = invalid then
MainViewModel_CategoryLoader_handleApiError(viewModel, categoryIndex, "Couldn't load images. Please try again later.", "API_ERROR")
        return invalid
    end if
    
    ' Set task parameters
    task.categoryMethod = category.method
    task.categoryTags = category.tags
    task.page = 1
    task.perPage = 20
    
    ' Store category index on task for callback
    task.addField("categoryIndex", "integer", false)
    task.categoryIndex = categoryIndex
' Return task so MainScene can observe it
    return task
end function


' ******************************************************
' Parse API response and update category
' ******************************************************
function MainViewModel_CategoryLoader_parseApiResponse(viewModel as Object, categoryIndex as Integer, result as Object) as Void
    category = viewModel.categories[categoryIndex]
' Check if API call was successful
    if not result.success then

        ' FG-022: Use the errorType set by CategoryLoadTask to pick
        ' the correct user-facing message per the ticket spec.
        errorType = ""
        if result.errorType <> invalid then errorType = result.errorType

        userMessage = MainViewModel_CategoryLoader_getUserMessage(errorType, result.error)
        MainViewModel_CategoryLoader_handleApiError(viewModel, categoryIndex, userMessage, errorType)
        return
    end if

    ' Validate data array
    if result.data = invalid then
MainViewModel_CategoryLoader_handleApiError(viewModel, categoryIndex, "Couldn't load images. Please try again later.", "API_ERROR")
        return
    end if

    photoCount = result.data.Count()
if photoCount = 0 then
MainViewModel_CategoryLoader_handleApiError(viewModel, categoryIndex, "No images found in this category.", "EMPTY")
        return
    end if
    
    ' FlickrService already converted photos to ImageModel objects
    ' result.data is an array of ImageModels ready to use
images = []
    
    for each imageModel in result.data
        ' Validate image has required fields
        if imageModel.id <> "" and imageModel.url_thumbnail <> "" then
            images.Push(imageModel)
        else
end if
    end for
' Update category with images
    imgManager = CategoryImageManager()
    category = imgManager.addImages(category, images)
    
    ' Update pagination info
    pagManager = CategoryPaginationManager()
    if result.pages <> invalid and result.pages > 0 then
        category = pagManager.setTotalPages(category, result.pages)
    end if
    
    ' Clear loading state and mark as loaded
    category = category.setLoading(false)
    category = category.setLoaded(true)
    
    ' Update category in viewModel
    viewModel.categories[categoryIndex] = category
    
    ' Trigger view update
    viewModel.categoryDataChanged = not viewModel.categoryDataChanged
end function


' ******************************************************
' Handle API errors gracefully
' FG-022: errorType ("NETWORK" | "API_ERROR" | "EMPTY") is
' stored on the category so MainScene can decide whether to
' offer a retry button and which icon/style to show.
' ******************************************************
function MainViewModel_CategoryLoader_handleApiError(viewModel as Object, categoryIndex as Integer, errorMessage as String, errorType as String) as Void
    category = viewModel.categories[categoryIndex]
' Clear loading state and set error
    category = category.setLoading(false)
    category = category.setError(errorMessage)

    ' FG-022: Store errorType so the UI layer can tailor the display
    category.errorType = errorType

    ' Update category in viewModel
    viewModel.categories[categoryIndex] = category

    ' Trigger view update
    viewModel.categoryDataChanged = not viewModel.categoryDataChanged
end function


' ******************************************************
' FG-022: Map errorType → user-facing message per ticket spec.
' Falls back to the raw message when type is unrecognised.
' ******************************************************
function MainViewModel_CategoryLoader_getUserMessage(errorType as String, rawMessage as String) as String
    if errorType = "NETWORK" then
        return "Unable to connect. Check your internet connection."
    else if errorType = "EMPTY" then
        return "No images found in this category."
    else if errorType = "API_ERROR" then
        return "Couldn't load images. Please try again later."
    end if

    ' Unknown type — surface the raw message so nothing is silently swallowed
    if rawMessage <> invalid and rawMessage <> "" then
        return rawMessage
    end if

    return "Couldn't load images. Please try again later."
end function


' ******************************************************
' Refresh category data (clear and reload)
' ******************************************************
function MainViewModel_CategoryLoader_refreshCategory(viewModel as Object, categoryIndex as Integer) as Void
if categoryIndex < 0 or categoryIndex >= viewModel.categories.Count() then
return
    end if

    category = viewModel.categories[categoryIndex]

    ' Clear existing images
    imgManager = CategoryImageManager()
    category = imgManager.clearImages(category)

    ' Reset pagination
    pagManager = CategoryPaginationManager()
    category = pagManager.resetPage(category)
    
    ' Clear error state
    category = category.clearError()

    ' Update in viewModel
    viewModel.categories[categoryIndex] = category

    ' Note: Actual reload must be done from MainScene using loadCategoryWithTask
end function


' ******************************************************
' LEGACY: Create mock images for testing
' Keep for fallback/testing purposes
' ******************************************************
function MainViewModel_CategoryLoader_createMockImages(categoryName as String, count as Integer) as Object
    images = []

    for i = 1 to count
        image = CreateImageModel()
        image.id          = "mock_" + categoryName + "_" + i.ToStr()
        image.title       = categoryName + " Image " + i.ToStr()
        image.description = "This is a sample description for testing DetailScene layout. Lorem ipsum dolor sit amet, consectetur adipiscing elit."
        image.owner       = "Sample Photographer " + i.ToStr()
        image.ownerId     = "mock_owner_" + i.ToStr()

        ' Use picsum.photos for actual working placeholder images
        baseId = (Asc(categoryName.Left(1)) * 100 + i) Mod 1000
        image.url_thumbnail = "https://picsum.photos/150/150?random=" + baseId.ToStr()
        image.url_small     = "https://picsum.photos/320/240?random=" + baseId.ToStr()
        image.url_medium    = "https://picsum.photos/640/480?random=" + baseId.ToStr()
        image.url_large     = "https://picsum.photos/1024/768?random=" + baseId.ToStr()

        image.width  = 1024
        image.height = 768
        image.tags   = [LCase(categoryName), "sample", "test"]
        image.views  = 100 * i
        image.datePosted = "1609459200"  ' Jan 1, 2021

        images.Push(image)
    end for

    return images
end function

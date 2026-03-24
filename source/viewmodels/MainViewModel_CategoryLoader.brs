' ******************************************************
' MainViewModel_CategoryLoader.brs
' Handles category data loading for MainViewModel
' In Sprint 3, this will make real API calls
' ******************************************************

function MainViewModel_CategoryLoader() as Object
    return {
        loadCategory:    MainViewModel_CategoryLoader_loadCategory
        refreshCategory: MainViewModel_CategoryLoader_refreshCategory
        createMockImages: MainViewModel_CategoryLoader_createMockImages
    }
end function


' Load category data (MOCK for Sprint 2, real API in Sprint 3)
function MainViewModel_CategoryLoader_loadCategory(viewModel as Object, categoryIndex as Integer) as Void
    print "[CategoryLoader] Loading category index: "; categoryIndex

    if categoryIndex < 0 or categoryIndex >= viewModel.categories.Count() then
        print "[CategoryLoader] ERROR: Invalid category index"
        return
    end if

    category = viewModel.categories[categoryIndex]

    ' Set loading state
    category = category.setLoading(true)
    viewModel.categories[categoryIndex] = category

    ' MOCK: Create sample images for testing
    ' In Sprint 3, this will be replaced with actual API call
    ' NOTE: call by full function name — m. does not refer to this AA here
    mockImages = MainViewModel_CategoryLoader_createMockImages(category.name, 10)

    ' Add images to category
    imageManager = CategoryImageManager()
    category = imageManager.addImages(category, mockImages)

    ' Set pagination (mock)
    paginationManager = CategoryPaginationManager()
    category = paginationManager.setTotalPages(category, 3)

    ' Clear loading state
    category = category.setLoading(false)

    ' Update category in viewModel
    viewModel.categories[categoryIndex] = category

    ' Trigger view update
    viewModel.categoryDataChanged = not viewModel.categoryDataChanged

    print "[CategoryLoader] Loaded "; mockImages.Count(); " images for "; category.name
end function


' Refresh category data
function MainViewModel_CategoryLoader_refreshCategory(viewModel as Object, categoryIndex as Integer) as Void
    print "[CategoryLoader] Refreshing category index: "; categoryIndex

    if categoryIndex < 0 or categoryIndex >= viewModel.categories.Count() then
        print "[CategoryLoader] ERROR: Invalid category index"
        return
    end if

    category = viewModel.categories[categoryIndex]

    ' Clear existing images
    imageManager = CategoryImageManager()
    category = imageManager.clearImages(category)

    ' Reset pagination
    paginationManager = CategoryPaginationManager()
    category = paginationManager.resetPage(category)

    ' Update in viewModel
    viewModel.categories[categoryIndex] = category

    ' Reload — call by full function name, not m.loadCategory
    MainViewModel_CategoryLoader_loadCategory(viewModel, categoryIndex)
end function


' Create mock images for testing (Sprint 2 only)
' In Sprint 3, this will be replaced with real API responses
function MainViewModel_CategoryLoader_createMockImages(categoryName as String, count as Integer) as Object
    images = []

    for i = 1 to count
        image = CreateImageModel()
        image.id          = "mock_" + categoryName + "_" + i.ToStr()
        image.title       = categoryName + " Image " + i.ToStr()
        image.description = "Mock description for " + categoryName
        image.owner       = "MockPhotographer"
        image.ownerId     = "mock_owner_123"

        ' Mock URLs — will show error placeholder until real API is wired up
        baseUrl           = "https://live.staticflickr.com/65535/" + image.id + "_secret"
        image.url_thumbnail = baseUrl + "_q.jpg"
        image.url_small     = baseUrl + "_n.jpg"
        image.url_medium    = baseUrl + "_z.jpg"
        image.url_large     = baseUrl + "_b.jpg"

        image.width  = 1024
        image.height = 768
        image.tags   = [LCase(categoryName), "mock", "test"]
        image.views  = 100 * i

        images.Push(image)
    end for

    return images
end function

' ******************************************************
' MainViewModel_CategoryLoader.brs
' Handles category data loading for MainViewModel
' MOCK DATA with working placeholder images for FG-017
' ******************************************************

function MainViewModel_CategoryLoader() as Object
    return {
        loadCategory:    MainViewModel_CategoryLoader_loadCategory
        refreshCategory: MainViewModel_CategoryLoader_refreshCategory
        createMockImages: MainViewModel_CategoryLoader_createMockImages
    }
end function


' Load category data (MOCK for development, real API in future ticket)
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


' Create mock images for testing - UPDATED with working URLs
' Compatible with DetailScene - uses "mock_" prefix so DetailScene can detect and skip PhotoInfoTask
function MainViewModel_CategoryLoader_createMockImages(categoryName as String, count as Integer) as Object
    images = []

    for i = 1 to count
        image = CreateImageModel()
        image.id          = "mock_" + categoryName + "_" + i.ToStr()
        image.title       = categoryName + " Image " + i.ToStr()
        image.description = "This is a sample description for testing DetailScene layout. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
        image.owner       = "Sample Photographer " + i.ToStr()
        image.ownerId     = "mock_owner_" + i.ToStr()

        ' FIXED: Use picsum.photos for actual working placeholder images
        ' Generate a semi-random ID based on category name + index
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
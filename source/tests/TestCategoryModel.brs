' ******************************************************
' TestCategoryModel.brs
' Unit tests for CategoryModel and related utilities
' ******************************************************

function TestCategoryModelSuite() as Boolean
    print ""
    print "================================================"
    print "TESTING CATEGORY MODEL SUITE (REFACTORED)"
    print "================================================"
    
    TestCategoryModel_Creation()
    TestCategoryModel_InlineStateMethods()
    TestCategoryModel_ImageManager()
    TestCategoryModel_PaginationManager()
    TestCategoryModel_Validator()
    TestCategoryModel_ContentNodeConverter()
    
    print "================================================"
    print "CATEGORY MODEL TESTS COMPLETE"
    print "================================================"
    print ""
    
    return true
end function


function TestCategoryModel_Creation() as Boolean
    print ""
    print "--- Testing Category Creation ---"
    
    category = CreateCategoryModel("nature", "Nature", "nature,landscape,outdoors", "flickr.photos.search")
    
    print "Category ID: "; category.id
    print "Category Name: "; category.name
    print "Category Tags: "; category.tags
    print "Category Method: "; category.method
    print "Initial Image Count: "; category.images.Count()
    print "Is Loading: "; category.isLoading
    print "Has Error: "; category.hasError
    print "Current Page: "; category.page
    print ""
    
    return true
end function


function TestCategoryModel_InlineStateMethods() as Boolean
    print "--- Testing Inline State Methods ---"
    
    category = CreateCategoryModel("test", "Test", "test", "flickr.photos.search")
    
    ' Test setLoading
    category = category.setLoading(true)
    print "Is Loading: "; category.isLoading
    
    category = category.setLoading(false)
    print "Loading Complete: "; not category.isLoading
    
    ' Test setError
    category = category.setError("Network timeout")
    print "Has Error: "; category.hasError
    print "Error Message: "; category.errorMessage
    print "Loading stopped: "; not category.isLoading
    
    ' Test clearError
    category = category.clearError()
    print "Error Cleared: "; not category.hasError
    print ""
    
    return true
end function


function TestCategoryModel_ImageManager() as Boolean
    print "--- Testing CategoryImageManager ---"
    
    category = CreateCategoryModel("animals", "Animals", "animals,wildlife", "flickr.photos.search")
    imageManager = CategoryImageManager()
    
    ' Create sample images
    image1 = CreateImageModel()
    image1.id = "img001"
    image1.title = "Lion"
    image1.url_medium = "https://example.com/lion.jpg"
    
    image2 = CreateImageModel()
    image2.id = "img002"
    image2.title = "Tiger"
    image2.url_medium = "https://example.com/tiger.jpg"
    
    image3 = CreateImageModel()
    image3.id = "img003"
    image3.title = "Bear"
    image3.url_medium = "https://example.com/bear.jpg"
    
    ' Test addImage
    category = imageManager.addImage(category, image1)
    print "After adding 1 image: "; imageManager.getImageCount(category)
    
    ' Test addImages (batch)
    imageArray = [image2, image3]
    category = imageManager.addImages(category, imageArray)
    print "After adding 2 more images: "; imageManager.getImageCount(category)
    
    ' Test removeImage
    category = imageManager.removeImage(category, "img002")
    print "After removing Tiger: "; imageManager.getImageCount(category)
    
    ' Test clearImages
    category = imageManager.clearImages(category)
    print "After clearing all: "; imageManager.getImageCount(category)
    print ""
    
    return true
end function


function TestCategoryModel_PaginationManager() as Boolean
    print "--- Testing CategoryPaginationManager ---"
    
    category = CreateCategoryModel("travel", "Travel", "travel,vacation", "flickr.photos.search")
    paginationManager = CategoryPaginationManager()
    
    print "Initial Page: "; paginationManager.getCurrentPage(category)
    
    ' Set total pages
    category = paginationManager.setTotalPages(category, 5)
    print "Total Pages Set: "; category.totalPages
    print "Has More Pages: "; category.hasMorePages
    
    ' Increment page
    category = paginationManager.incrementPage(category)
    print "After increment: "; paginationManager.getCurrentPage(category)
    
    category = paginationManager.incrementPage(category)
    print "After second increment: "; paginationManager.getCurrentPage(category)
    
    ' Test canLoadMore
    print "Can load more (page 3/5): "; paginationManager.canLoadMore(category)
    
    ' Reset page
    category = paginationManager.resetPage(category)
    print "After reset: "; paginationManager.getCurrentPage(category)
    print ""
    
    return true
end function


function TestCategoryModel_Validator() as Boolean
    print "--- Testing CategoryValidator ---"
    
    validator = CategoryValidator()
    
    ' Valid category
    validCategory = CreateCategoryModel("food", "Food", "food,cooking", "flickr.photos.search")
    print "Valid category is valid: "; validator.isValid(validCategory)
    print "Has required fields: "; validator.hasRequiredFields(validCategory)
    
    ' Invalid category
    invalidCategory = CreateCategoryModel("", "", "", "")
    print "Invalid category is valid: "; validator.isValid(invalidCategory)
    
    ' Test hasValidImages
    imageManager = CategoryImageManager()
    image = CreateImageModel()
    image.id = "test001"
    image.title = "Test"
    image.url_medium = "https://example.com/test.jpg"
    
    validCategory = imageManager.addImage(validCategory, image)
    print "Has valid images: "; validator.hasValidImages(validCategory)
    print ""
    
    return true
end function


function TestCategoryModel_ContentNodeConverter() as Boolean
    print "--- Testing CategoryContentNodeConverter ---"
    
    ' Create category
    category = CreateCategoryModel("popular", "Popular", "popular", "flickr.interestingness.getList")
    imageManager = CategoryImageManager()
    
    ' Add sample images
    image1 = CreateImageModel()
    image1.id = "pop001"
    image1.title = "Popular Image 1"
    image1.url_medium = "https://example.com/pop1.jpg"
    
    image2 = CreateImageModel()
    image2.id = "pop002"
    image2.title = "Popular Image 2"
    image2.url_medium = "https://example.com/pop2.jpg"
    
    category = imageManager.addImages(category, [image1, image2])
    
    ' Convert to ContentNode
    converter = CategoryContentNodeConverter()
    contentNode = converter.fromCategoryModel(category)
    
    print "ContentNode Title: "; contentNode.title
    print "ContentNode Category ID: "; contentNode.categoryId
    print "ContentNode Image Count: "; contentNode.imageCount
    print "ContentNode Children: "; contentNode.getChildCount()
    print "Current Page: "; contentNode.currentPage
    print "Total Pages: "; contentNode.totalPages
    
    ' Test empty node creation
    emptyNode = converter.createEmptyNode("Loading Category")
    print "Empty Node Title: "; emptyNode.title
    print "Empty Node Is Loading: "; emptyNode.isLoading
    print ""
    
    return true
end function
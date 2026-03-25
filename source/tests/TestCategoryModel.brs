' ******************************************************
' TestCategoryModel.brs
' Unit tests for CategoryModel and related utilities
' ******************************************************

function TestCategoryModelSuite() as Boolean
TestCategoryModel_Creation()
    TestCategoryModel_InlineStateMethods()
    TestCategoryModel_ImageManager()
    TestCategoryModel_PaginationManager()
    TestCategoryModel_Validator()
    TestCategoryModel_ContentNodeConverter()
return true
end function


function TestCategoryModel_Creation() as Boolean
category = CreateCategoryModel("nature", "Nature", "nature,landscape,outdoors", "flickr.photos.search")
return true
end function


function TestCategoryModel_InlineStateMethods() as Boolean
category = CreateCategoryModel("test", "Test", "test", "flickr.photos.search")
    
    ' Test setLoading
    category = category.setLoading(true)
    
    category = category.setLoading(false)
    
    ' Test setError
    category = category.setError("Network timeout")
    
    ' Test clearError
    category = category.clearError()
return true
end function


function TestCategoryModel_ImageManager() as Boolean
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
    
    ' Test addImages (batch)
    imageArray = [image2, image3]
    category = imageManager.addImages(category, imageArray)
    
    ' Test removeImage
    category = imageManager.removeImage(category, "img002")
    
    ' Test clearImages
    category = imageManager.clearImages(category)
return true
end function


function TestCategoryModel_PaginationManager() as Boolean
category = CreateCategoryModel("travel", "Travel", "travel,vacation", "flickr.photos.search")
    paginationManager = CategoryPaginationManager()
    
    ' Set total pages
    category = paginationManager.setTotalPages(category, 5)
    
    ' Increment page
    category = paginationManager.incrementPage(category)
    
    category = paginationManager.incrementPage(category)
    
    ' Test canLoadMore
    
    ' Reset page
    category = paginationManager.resetPage(category)
return true
end function


function TestCategoryModel_Validator() as Boolean
validator = CategoryValidator()
    
    ' Valid category
    validCategory = CreateCategoryModel("food", "Food", "food,cooking", "flickr.photos.search")
    
    ' Invalid category
    invalidCategory = CreateCategoryModel("", "", "", "")
    
    ' Test hasValidImages
    imageManager = CategoryImageManager()
    image = CreateImageModel()
    image.id = "test001"
    image.title = "Test"
    image.url_medium = "https://example.com/test.jpg"
    
    validCategory = imageManager.addImage(validCategory, image)
return true
end function


function TestCategoryModel_ContentNodeConverter() as Boolean
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
    
    ' Test empty node creation
    emptyNode = converter.createEmptyNode("Loading Category")
return true
end function
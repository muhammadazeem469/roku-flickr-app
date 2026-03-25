' ******************************************************
' CategoryStateManager.brs
' Manages state and operations for CategoryModel
' ******************************************************

function CategoryStateManager() as Object
    return {
        ' Image management
        addImage: CategoryStateManager_addImage
        addImages: CategoryStateManager_addImages
        clearImages: CategoryStateManager_clearImages
        getImageCount: CategoryStateManager_getImageCount
        
        ' State management
        setLoading: CategoryStateManager_setLoading
        setError: CategoryStateManager_setError
        clearError: CategoryStateManager_clearError
        
        ' Pagination
        incrementPage: CategoryStateManager_incrementPage
        resetPage: CategoryStateManager_resetPage
        
        ' Utility
        toContentNode: CategoryStateManager_toContentNode
    }
end function


' ======================================
' IMAGE MANAGEMENT METHODS
' ======================================

' Add a single image to the category
' @param category - CategoryModel object
' @param imageModel - ImageModel object to add
' @return Updated CategoryModel
function CategoryStateManager_addImage(category as Object, imageModel as Object) as Object
    if imageModel = invalid then
        return category
    end if
    
    ' Validate image using ImageValidator
    validator = ImageValidator()
    if not validator.isValid(imageModel) then
return category
    end if
    
    ' Add to images array
    category.images.Push(imageModel)
    category.totalImages = category.images.Count()
    
    ' Update timestamp
    category.lastUpdated = CreateObject("roDateTime").ToISOString()
    
    return category
end function


' Add multiple images to the category
' @param category - CategoryModel object
' @param imageArray - Array of ImageModel objects
' @return Updated CategoryModel
function CategoryStateManager_addImages(category as Object, imageArray as Object) as Object
    if imageArray = invalid or Type(imageArray) <> "roArray" then
return category
    end if
    
    validator = ImageValidator()
    addedCount = 0
    
    for each imageModel in imageArray
        if validator.isValid(imageModel) then
            category.images.Push(imageModel)
            addedCount = addedCount + 1
        else
end if
    end for
    
    category.totalImages = category.images.Count()
    category.lastUpdated = CreateObject("roDateTime").ToISOString()
    
    return category
end function


' Clear all images from the category
' @param category - CategoryModel object
' @return Updated CategoryModel
function CategoryStateManager_clearImages(category as Object) as Object
    category.images = []
    category.totalImages = 0
    category.page = 1
    category.hasMorePages = false
    
    return category
end function


' Get total image count
' @param category - CategoryModel object
' @return Integer count
function CategoryStateManager_getImageCount(category as Object) as Integer
    if category.images <> invalid then
        return category.images.Count()
    end if
    return 0
end function


' ======================================
' STATE MANAGEMENT METHODS
' ======================================

' Set loading state
' @param category - CategoryModel object
' @param state - Boolean loading state
' @return Updated CategoryModel
function CategoryStateManager_setLoading(category as Object, state as Boolean) as Object
    category.isLoading = state
    
    if state then
    else
    end if
    
    return category
end function


' Set error state with message
' @param category - CategoryModel object
' @param message - Error message string
' @return Updated CategoryModel
function CategoryStateManager_setError(category as Object, message as String) as Object
    category.hasError = true
    category.errorMessage = message
    category.isLoading = false
    
    return category
end function


' Clear error state
' @param category - CategoryModel object
' @return Updated CategoryModel
function CategoryStateManager_clearError(category as Object) as Object
    category.hasError = false
    category.errorMessage = ""
    
    return category
end function


' ======================================
' PAGINATION METHODS
' ======================================

' Increment page number
' @param category - CategoryModel object
' @return Updated CategoryModel
function CategoryStateManager_incrementPage(category as Object) as Object
    category.page = category.page + 1
    
    ' Check if more pages available
    if category.totalPages > 0 then
        category.hasMorePages = (category.page < category.totalPages)
    end if
    
    return category
end function


' Reset pagination to page 1
' @param category - CategoryModel object
' @return Updated CategoryModel
function CategoryStateManager_resetPage(category as Object) as Object
    category.page = 1
    
    return category
end function


' ======================================
' UTILITY METHODS
' ======================================

' Convert category to ContentNode for SceneGraph RowList
' @param category - CategoryModel object
' @return ContentNode with category data
function CategoryStateManager_toContentNode(category as Object) as Object
    node = CreateObject("roSGNode", "ContentNode")
    
    ' Set row title
    node.title = category.name
    
    ' Add custom fields
    node.addFields({
        categoryId: category.id
        categoryTags: category.tags
        categoryMethod: category.method
        imageCount: category.totalImages
        isLoading: category.isLoading
        hasError: category.hasError
    })
    
    ' Convert images to content nodes
    if category.images <> invalid and category.images.Count() > 0 then
        converter = ContentNodeConverter()
        
        for each imageModel in category.images
            imageNode = converter.fromImageModel(imageModel)
            if imageNode <> invalid then
                node.appendChild(imageNode)
            end if
        end for
    end if
    
    return node
end function
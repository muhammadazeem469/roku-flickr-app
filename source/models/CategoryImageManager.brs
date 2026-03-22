' ******************************************************
' CategoryImageManager.brs
' Manages image operations for CategoryModel
' Handles adding, removing, and counting images
' ******************************************************

function CategoryImageManager() as Object
    return {
        addImage: CategoryImageManager_addImage
        addImages: CategoryImageManager_addImages
        clearImages: CategoryImageManager_clearImages
        getImageCount: CategoryImageManager_getImageCount
        removeImage: CategoryImageManager_removeImage
    }
end function


' Add a single image to the category
' @param category - CategoryModel object
' @param imageModel - ImageModel object to add
' @return Updated CategoryModel
function CategoryImageManager_addImage(category as Object, imageModel as Object) as Object
    if imageModel = invalid then
        print "[CategoryImageManager] Cannot add invalid image to category: "; category.name
        return category
    end if
    
    ' Validate image
    validator = ImageValidator()
    if not validator.isValid(imageModel) then
        print "[CategoryImageManager] Invalid image data, skipping"
        return category
    end if
    
    ' Add to images array
    category.images.Push(imageModel)
    category.totalImages = category.images.Count()
    
    ' Update timestamp
    category.lastUpdated = CreateObject("roDateTime").ToISOString()
    
    print "[CategoryImageManager] Added image '"; imageModel.title; "' to "; category.name
    
    return category
end function


' Add multiple images to the category
' @param category - CategoryModel object
' @param imageArray - Array of ImageModel objects
' @return Updated CategoryModel
function CategoryImageManager_addImages(category as Object, imageArray as Object) as Object
    if imageArray = invalid or Type(imageArray) <> "roArray" then
        print "[CategoryImageManager] Invalid image array provided"
        return category
    end if
    
    if imageArray.Count() = 0 then
        print "[CategoryImageManager] Empty image array provided"
        return category
    end if
    
    validator = ImageValidator()
    addedCount = 0
    
    for each imageModel in imageArray
        if validator.isValid(imageModel) then
            category.images.Push(imageModel)
            addedCount = addedCount + 1
        else
            print "[CategoryImageManager] Skipping invalid image in batch"
        end if
    end for
    
    category.totalImages = category.images.Count()
    category.lastUpdated = CreateObject("roDateTime").ToISOString()
    
    print "[CategoryImageManager] Added "; addedCount; "/"; imageArray.Count(); " images to "; category.name
    
    return category
end function


' Clear all images from the category
' @param category - CategoryModel object
' @return Updated CategoryModel
function CategoryImageManager_clearImages(category as Object) as Object
    previousCount = category.images.Count()
    
    category.images = []
    category.totalImages = 0
    
    print "[CategoryImageManager] Cleared "; previousCount; " images from "; category.name
    
    return category
end function


' Get total image count
' @param category - CategoryModel object
' @return Integer count
function CategoryImageManager_getImageCount(category as Object) as Integer
    if category.images <> invalid then
        return category.images.Count()
    end if
    return 0
end function


' Remove a specific image by ID
' @param category - CategoryModel object
' @param imageId - Image ID to remove
' @return Updated CategoryModel
function CategoryImageManager_removeImage(category as Object, imageId as String) as Object
    if category.images = invalid or category.images.Count() = 0 then
        return category
    end if
    
    ' Find and remove image
    for i = category.images.Count() - 1 to 0 step -1
        if category.images[i].id = imageId then
            category.images.Delete(i)
            category.totalImages = category.images.Count()
            print "[CategoryImageManager] Removed image "; imageId; " from "; category.name
            exit for
        end if
    end for
    
    return category
end function
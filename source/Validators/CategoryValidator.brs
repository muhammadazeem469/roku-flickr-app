' ******************************************************
' CategoryValidator.brs
' Validates CategoryModel data
' ******************************************************

function CategoryValidator() as Object
    return {
        isValid: CategoryValidator_isValid
        hasRequiredFields: CategoryValidator_hasRequiredFields
        hasValidImages: CategoryValidator_hasValidImages
    }
end function


' Check if CategoryModel is valid
' @param category - CategoryModel object
' @return Boolean
function CategoryValidator_isValid(category as Object) as Boolean
    if category = invalid then
return false
    end if
    
    return m.hasRequiredFields(category)
end function


' Check if category has required fields
' @param category - CategoryModel object
' @return Boolean
function CategoryValidator_hasRequiredFields(category as Object) as Boolean
    hasId = (category.id <> invalid and category.id <> "")
    hasName = (category.name <> invalid and category.name <> "")
    hasMethod = (category.method <> invalid and category.method <> "")
    
    if not hasId then
end if
    
    if not hasName then
end if
    
    if not hasMethod then
end if
    
    return hasId and hasName and hasMethod
end function


' Check if category has valid images
' @param category - CategoryModel object
' @return Boolean
function CategoryValidator_hasValidImages(category as Object) as Boolean
    if category.images = invalid then return false
    if Type(category.images) <> "roArray" then return false
    
    return category.images.Count() > 0
end function
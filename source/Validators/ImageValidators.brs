' ImageValidator.brs
' Validates ImageModel data

function ImageValidator() as Object
    return {
        isValid: ImageValidator_isValid
        hasRequiredFields: ImageValidator_hasRequiredFields
        hasValidUrls: ImageValidator_hasValidUrls
    }
end function


' Check if ImageModel is valid
function ImageValidator_isValid(imageModel as Object) as Boolean
    if imageModel = invalid then return false
    
    return ImageValidator_hasRequiredFields(imageModel) and ImageValidator_hasValidUrls(imageModel)
end function


' Check required fields
function ImageValidator_hasRequiredFields(imageModel as Object) as Boolean
    hasId = (imageModel.id <> invalid and imageModel.id <> "")
    hasTitle = (imageModel.title <> invalid and imageModel.title <> "")
    
    return hasId and hasTitle
end function


' Check at least one valid URL exists
function ImageValidator_hasValidUrls(imageModel as Object) as Boolean
    hasUrl = (imageModel.url_medium <> invalid and imageModel.url_medium <> "")
    return hasUrl
end function
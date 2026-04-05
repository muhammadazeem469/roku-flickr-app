' ******************************************************
' CategoryContentNodeConverter.brs
' Converts CategoryModel to SceneGraph ContentNode
' Used for RowList and grid display
' ******************************************************

function CategoryContentNodeConverter() as Object
    return {
        fromCategoryModel: CategoryContentNodeConverter_fromCategoryModel
        createEmptyNode: CategoryContentNodeConverter_createEmptyNode
    }
end function


' Convert category to ContentNode for SceneGraph RowList
' @param category - CategoryModel object
' @return ContentNode with category data
function CategoryContentNodeConverter_fromCategoryModel(category as Object) as Object
    if category = invalid then
return invalid
    end if
    
    node = CreateObject("roSGNode", "ContentNode")
    
    ' Set row title
    node.title = category.name
    
    ' Add custom fields for category metadata
    node.addFields({
        categoryId: category.id
        categoryName: category.name
        categoryTags: category.tags
        categoryMethod: category.method
        imageCount: category.totalImages
        isLoading: category.isLoading
        hasError: category.hasError
        errorMessage: category.errorMessage
        currentPage: category.page
        totalPages: category.totalPages
        hasMorePages: category.hasMorePages
    })
    
    ' Convert images to content nodes (children)
    if category.images <> invalid and category.images.Count() > 0 then
        imageConverter = ContentNodeConverter()
        
        for each imageModel in category.images
            imageNode = imageConverter.fromImageModel(imageModel)
            if imageNode <> invalid then
                node.appendChild(imageNode)
            end if
        end for
    end if
    
    return node
end function


' Create an empty ContentNode for loading states
' @param categoryName - Display name for the row
' @return Empty ContentNode
function CategoryContentNodeConverter_createEmptyNode(categoryName as String) as Object
    node = CreateObject("roSGNode", "ContentNode")
    node.title = categoryName
    
    node.addFields({
        categoryId: ""
        categoryName: categoryName
        imageCount: 0
        isLoading: true
        hasError: false
    })
    
    return node
end function
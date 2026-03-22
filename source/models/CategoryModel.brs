' ******************************************************
' CategoryModel.brs
' Pure data model for a Flickr photo category/swimlane
' Includes inline state setter methods
' ******************************************************

' Constructor - Creates a new CategoryModel instance
' @param id - Unique category identifier
' @param name - Display name (e.g., "Nature", "Architecture")
' @param tags - Comma-separated search tags
' @param method - Flickr API method to use
' @return CategoryModel object
function CreateCategoryModel(id as String, name as String, tags as String, method as String) as Object
    model = {
        ' Core properties
        id: id
        name: name
        tags: tags
        method: method
        
        ' Image collection
        images: []
        
        ' State management
        isLoading: false
        hasError: false
        errorMessage: ""
        
        ' Pagination
        page: 1
        totalPages: 0
        hasMorePages: false
        
        ' Metadata
        totalImages: 0
        lastUpdated: ""
        
        ' Inline state setters
        setLoading: CategoryModel_setLoading
        setError: CategoryModel_setError
        clearError: CategoryModel_clearError
    }
    
    return model
end function


' Set loading state
function CategoryModel_setLoading(state as Boolean) as Object
    m.isLoading = state
    if state then
        print "[CategoryModel] Loading: "; m.name
    end if
    return m
end function


' Set error state with message
function CategoryModel_setError(message as String) as Object
    m.hasError = true
    m.errorMessage = message
    m.isLoading = false
    print "[CategoryModel] Error in "; m.name; ": "; message
    return m
end function


' Clear error state
function CategoryModel_clearError() as Object
    m.hasError = false
    m.errorMessage = ""
    return m
end function
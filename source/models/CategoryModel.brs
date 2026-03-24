' ******************************************************
' CategoryModel.brs
' Pure data model for a Flickr photo category/swimlane
' ******************************************************

' Constructor
' FIX 2: Added display_name as a proper field on the model.
'         Previously the constructor signature was:
'           CreateCategoryModel(id, name, tags, method)
'         but MainViewModel called it as:
'           CreateCategoryModel(config.name, config.display_name, config.tags, config.method)
'         — passing display_name as the "name" arg and never storing it on
'         the model at all. SwimLane then had no display_name to show.
'
'         New signature matches how MainViewModel already calls it:
'           CreateCategoryModel(name, display_name, tags, method)
'         and stores both fields explicitly on the model.
function CreateCategoryModel(name as String, display_name as String, tags as String, method as String) as Object
    model = {
        ' Core properties
        id:           name           ' use name as the unique key
        name:         name           ' internal identifier
        display_name: display_name   ' FIX: human-readable label for UI
        tags:         tags
        method:       method

        ' Image collection
        images: []

        ' State management
        isLoading:    false
        isLoaded:     false
        hasError:     false
        errorMessage: ""

        ' Pagination
        page:         1
        totalPages:   0
        hasMorePages: false

        ' Metadata
        totalImages:  0
        lastUpdated:  ""

        ' Inline state setters
        setLoading:  CategoryModel_setLoading
        setLoaded:   CategoryModel_setLoaded
        setError:    CategoryModel_setError
        clearError:  CategoryModel_clearError
    }

    return model
end function


function CategoryModel_setLoading(state as Boolean) as Object
    m.isLoading = state
    if state then
        print "[CategoryModel] Loading: "; m.name
    end if
    return m
end function


function CategoryModel_setLoaded(state as Boolean) as Object
    m.isLoaded = state
    if state then
        print "[CategoryModel] Loaded: "; m.name; " with "; m.images.Count(); " images"
    end if
    return m
end function


function CategoryModel_setError(message as String) as Object
    m.hasError    = true
    m.errorMessage = message
    m.isLoading   = false
    print "[CategoryModel] Error in "; m.name; ": "; message
    return m
end function


function CategoryModel_clearError() as Object
    m.hasError    = false
    m.errorMessage = ""
    return m
end function

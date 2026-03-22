' ******************************************************
' CategoryPaginationManager.brs
' Manages pagination state for CategoryModel
' Handles page increments, resets, and pagination metadata
' ******************************************************

function CategoryPaginationManager() as Object
    return {
        incrementPage: CategoryPaginationManager_incrementPage
        resetPage: CategoryPaginationManager_resetPage
        setTotalPages: CategoryPaginationManager_setTotalPages
        canLoadMore: CategoryPaginationManager_canLoadMore
        getCurrentPage: CategoryPaginationManager_getCurrentPage
    }
end function


' Increment page number
' @param category - CategoryModel object
' @return Updated CategoryModel
function CategoryPaginationManager_incrementPage(category as Object) as Object
    category.page = category.page + 1
    
    ' Update hasMorePages flag
    if category.totalPages > 0 then
        category.hasMorePages = (category.page < category.totalPages)
    end if
    
    print "[CategoryPaginationManager] "; category.name; " page: "; category.page; "/"; category.totalPages
    
    return category
end function


' Reset pagination to page 1
' @param category - CategoryModel object
' @return Updated CategoryModel
function CategoryPaginationManager_resetPage(category as Object) as Object
    category.page = 1
    category.hasMorePages = true
    
    print "[CategoryPaginationManager] Reset "; category.name; " to page 1"
    
    return category
end function


' Set total pages available
' @param category - CategoryModel object
' @param totalPages - Total number of pages
' @return Updated CategoryModel
function CategoryPaginationManager_setTotalPages(category as Object, totalPages as Integer) as Object
    category.totalPages = totalPages
    
    ' Update hasMorePages based on current page
    category.hasMorePages = (category.page < totalPages)
    
    print "[CategoryPaginationManager] "; category.name; " has "; totalPages; " total pages"
    
    return category
end function


' Check if category can load more pages
' @param category - CategoryModel object
' @return Boolean
function CategoryPaginationManager_canLoadMore(category as Object) as Boolean
    ' Can't load if already loading
    if category.isLoading then
        print "[CategoryPaginationManager] Cannot load - already loading"
        return false
    end if
    
    ' Can't load if has error
    if category.hasError then
        print "[CategoryPaginationManager] Cannot load - has error"
        return false
    end if
    
    ' Check if more pages available
    if category.totalPages > 0 then
        canLoad = (category.page < category.totalPages)
        if not canLoad then
            print "[CategoryPaginationManager] No more pages available"
        end if
        return canLoad
    end if
    
    ' If totalPages not set yet, allow loading
    return true
end function


' Get current page number
' @param category - CategoryModel object
' @return Integer page number
function CategoryPaginationManager_getCurrentPage(category as Object) as Integer
    return category.page
end function
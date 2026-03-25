' ******************************************************
' DetailViewModel_InfoParser.brs
' Handles parsing and formatting of photo metadata
' Extracts data from API responses and formats for display
' ******************************************************

function DetailViewModel_InfoParser() as Object
    return {
        initializeBasicMetadata: DetailViewModel_InfoParser_initializeBasicMetadata
        parseExtendedMetadata: DetailViewModel_InfoParser_parseExtendedMetadata
        parseDimensions: DetailViewModel_InfoParser_parseDimensions
        parseUploadDate: DetailViewModel_InfoParser_parseUploadDate
        parseDescription: DetailViewModel_InfoParser_parseDescription
        parseTags: DetailViewModel_InfoParser_parseTags
    }
end function


' Initialize basic metadata from ImageModel
' @param viewModel - Reference to DetailViewModel
function DetailViewModel_InfoParser_initializeBasicMetadata(viewModel as Object) as Void
' Set dimensions from image model if available
    viewModel.dimensions = ""
    if viewModel.image.width > 0 and viewModel.image.height > 0 then
        viewModel.dimensions = viewModel.image.width.ToStr() + " x " + viewModel.image.height.ToStr()
    end if
    
    ' Copy basic info
    viewModel.viewCount = viewModel.image.views
    viewModel.fullDescription = viewModel.image.description
end function


' Parse extended metadata from API response
' @param viewModel - Reference to DetailViewModel
' @param photoData - Photo data from API
function DetailViewModel_InfoParser_parseExtendedMetadata(viewModel as Object, photoData as Object) as Void
' Parse each metadata component
    m.parseDimensions(viewModel, photoData)
    m.parseUploadDate(viewModel, photoData)
    m.parseDescription(viewModel, photoData)
    m.parseTags(viewModel, photoData)
    
    ' Parse view count
    if photoData.views <> invalid then
        viewModel.viewCount = photoData.views.ToInt()
    end if
    
    ' Parse comment count
    if photoData.comments <> invalid and photoData.comments._content <> invalid then
        viewModel.commentCount = photoData.comments._content.ToInt()
    end if
    
    ' Update title if more detailed version available
    if photoData.title <> invalid and photoData.title._content <> invalid then
        fullTitle = photoData.title._content
        if fullTitle <> "" then
            viewModel.image.title = fullTitle
        end if
    end if
    
    ' Parse file size (not directly available in API)
    if photoData.originalsecret <> invalid then
        viewModel.fileSize = "Not available"
    end if
end function


' Parse image dimensions
' @param viewModel - Reference to DetailViewModel
' @param photoData - Photo data from API
function DetailViewModel_InfoParser_parseDimensions(viewModel as Object, photoData as Object) as Void
    ' Prefer original dimensions if available
    if photoData.originalformat <> invalid then
        if photoData.originalwidth <> invalid and photoData.originalheight <> invalid then
            width = photoData.originalwidth
            height = photoData.originalheight
            viewModel.dimensions = width.ToStr() + " x " + height.ToStr()
        end if
    end if
end function


' Parse upload date and format it
' @param viewModel - Reference to DetailViewModel
' @param photoData - Photo data from API
function DetailViewModel_InfoParser_parseUploadDate(viewModel as Object, photoData as Object) as Void
    if photoData.dates <> invalid and photoData.dates.posted <> invalid then
        timestamp = photoData.dates.posted.ToInt()
        viewModel.uploadDate = FormatUnixTimestamp(timestamp)
    end if
end function


' Parse and set full description
' @param viewModel - Reference to DetailViewModel
' @param photoData - Photo data from API
function DetailViewModel_InfoParser_parseDescription(viewModel as Object, photoData as Object) as Void
    if photoData.description <> invalid and photoData.description._content <> invalid then
        viewModel.fullDescription = photoData.description._content
else
        ' Fallback to basic description from image model
        if viewModel.image.description <> "" then
            viewModel.fullDescription = viewModel.image.description
        else
            viewModel.fullDescription = "No description available"
        end if
    end if
end function


' Parse tags from API response
' @param viewModel - Reference to DetailViewModel
' @param photoData - Photo data from API
function DetailViewModel_InfoParser_parseTags(viewModel as Object, photoData as Object) as Void
    if photoData.tags <> invalid and photoData.tags.tag <> invalid then
        tagArray = []
        for each tagObj in photoData.tags.tag
            if tagObj._content <> invalid then
                tagArray.Push(tagObj._content)
            end if
        end for
        viewModel.image.tags = tagArray
    end if
end function


' Helper function to format Unix timestamp to readable date
' @param timestamp - Unix timestamp (seconds since epoch)
' @return Formatted date string
function FormatUnixTimestamp(timestamp as Integer) as String
    ' Create date object from timestamp
    dateObj = CreateObject("roDateTime")
    dateObj.FromSeconds(timestamp)
    
    ' Format as readable string
    ' Example output: "March 15, 2024"
    months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    
    month = months[dateObj.GetMonth() - 1]
    day = dateObj.GetDayOfMonth()
    year = dateObj.GetYear()
    
    return month + " " + day.ToStr() + ", " + year.ToStr()
end function
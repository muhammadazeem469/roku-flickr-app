' ******************************************************
' DetailViewModel_InfoParser.brs
' Handles parsing and formatting of photo metadata.
' Populates display-ready strings on the ViewModel so
' the View only needs to assign label.text = vm.someText.
' ******************************************************

function DetailViewModel_InfoParser() as Object
    return {
        initializeBasicMetadata: DetailViewModel_InfoParser_initializeBasicMetadata
        parseExtendedMetadata:   DetailViewModel_InfoParser_parseExtendedMetadata
        parseDimensions:         DetailViewModel_InfoParser_parseDimensions
        parseUploadDate:         DetailViewModel_InfoParser_parseUploadDate
        parseDescription:        DetailViewModel_InfoParser_parseDescription
        parseTags:               DetailViewModel_InfoParser_parseTags
    }
end function


' Populate display-ready strings from the ImageModel.
' Called immediately when the detail screen opens (before the API task runs).
' @param viewModel - DetailViewModel reference
function DetailViewModel_InfoParser_initializeBasicMetadata(viewModel as Object) as Void
    img = viewModel.image

    ' Title
    if img.title <> invalid and img.title <> "" then
        viewModel.titleText = img.title
    else
        viewModel.titleText = "Untitled"
    end if

    ' Best available image URL (large preferred, medium fallback)
    if img.url_large <> invalid and img.url_large <> "" then
        viewModel.imageUrl = img.url_large
    else if img.url_medium <> invalid and img.url_medium <> "" then
        viewModel.imageUrl = img.url_medium
    else
        viewModel.imageUrl = ""
    end if

    ' Description
    if img.description <> invalid and img.description <> "" then
        viewModel.descriptionText = img.description
        viewModel.fullDescription = img.description
    else
        viewModel.descriptionText = "No description available"
        viewModel.fullDescription = ""
    end if

    ' Owner
    if img.owner <> invalid and img.owner <> "" then
        viewModel.ownerText = "Photo by: " + img.owner
    else
        viewModel.ownerText = "Photo by: Unknown"
    end if

    ' Views
    viewModel.viewCount = img.views
    if img.views > 0 then
        viewModel.viewsText = "Views: " + FormatNumber(img.views)
    else
        viewModel.viewsText = "Views: Not available"
    end if

    ' Dimensions from search-extras width/height (populated by ImageMapper)
    viewModel.dimensions = ""
    if img.width > 0 and img.height > 0 then
        viewModel.dimensions    = img.width.ToStr() + " x " + img.height.ToStr()
        viewModel.dimensionsText = "Dimensions: " + viewModel.dimensions
    else
        viewModel.dimensionsText = "Dimensions: Loading..."
    end if
end function


' Update display-ready strings from flickr.photos.getInfo response.
' Called after PhotoInfoTask completes successfully.
' @param viewModel - DetailViewModel reference
' @param photoData - photo object from API response
function DetailViewModel_InfoParser_parseExtendedMetadata(viewModel as Object, photoData as Object) as Void
    m.parseDimensions(viewModel, photoData)
    m.parseUploadDate(viewModel, photoData)
    m.parseDescription(viewModel, photoData)
    m.parseTags(viewModel, photoData)

    ' Views (API may have a fresher count)
    if photoData.views <> invalid then
        viewModel.viewCount = SafeToInt(photoData.views)
        if viewModel.viewCount > 0 then
            viewModel.viewsText = "Views: " + FormatNumber(viewModel.viewCount)
        end if
    end if

    ' Comments
    if photoData.comments <> invalid and photoData.comments._content <> invalid then
        viewModel.commentCount = SafeToInt(photoData.comments._content)
        if viewModel.commentCount > 0 then
            viewModel.commentsText  = "Comments: " + FormatNumber(viewModel.commentCount)
            viewModel.showComments  = true
        end if
    end if

    ' Title (getInfo may return a more complete version)
    if photoData.title <> invalid and photoData.title._content <> invalid then
        fullTitle = photoData.title._content
        if fullTitle <> "" then
            viewModel.image.title = fullTitle
            viewModel.titleText   = fullTitle
        end if
    end if

    ' File size is not returned by flickr.photos.getInfo
    viewModel.fileSizeText = "File Size: Not available"
end function


' Resolve image dimensions from the getInfo response.
' Prefers originalwidth/originalheight when present (requires owner
' to allow original downloads).  Falls back to the value already set
' by initializeBasicMetadata (from search-extras width_b / height_z).
' @param viewModel - DetailViewModel reference
' @param photoData - photo object from API response
function DetailViewModel_InfoParser_parseDimensions(viewModel as Object, photoData as Object) as Void
    if photoData.originalwidth <> invalid and photoData.originalheight <> invalid then
        w = SafeToInt(photoData.originalwidth)
        h = SafeToInt(photoData.originalheight)
        if w > 0 and h > 0 then
            viewModel.dimensions     = w.ToStr() + " x " + h.ToStr()
            viewModel.dimensionsText = "Dimensions: " + viewModel.dimensions
            return
        end if
    end if

    ' If search-extras already gave us dimensions keep them; otherwise mark N/A
    if viewModel.dimensions = "" then
        viewModel.dimensionsText = "Dimensions: Not available"
    end if
end function


' Format the upload date from the getInfo dates object.
' @param viewModel - DetailViewModel reference
' @param photoData - photo object from API response
function DetailViewModel_InfoParser_parseUploadDate(viewModel as Object, photoData as Object) as Void
    if photoData.dates <> invalid and photoData.dates.posted <> invalid then
        viewModel.uploadDate    = FormatUnixTimestamp(SafeToInt(photoData.dates.posted))
        viewModel.uploadDateText = "Uploaded: " + viewModel.uploadDate
    else
        viewModel.uploadDateText = "Uploaded: Not available"
    end if
end function


' Set the full description from the getInfo response.
' @param viewModel - DetailViewModel reference
' @param photoData - photo object from API response
function DetailViewModel_InfoParser_parseDescription(viewModel as Object, photoData as Object) as Void
    if photoData.description <> invalid and photoData.description._content <> invalid then
        viewModel.fullDescription = photoData.description._content
    else if viewModel.image.description <> "" then
        viewModel.fullDescription = viewModel.image.description
    else
        viewModel.fullDescription = "No description available"
    end if
    viewModel.descriptionText = viewModel.fullDescription
end function


' Extract tag strings from the getInfo tags object.
' @param viewModel - DetailViewModel reference
' @param photoData - photo object from API response
function DetailViewModel_InfoParser_parseTags(viewModel as Object, photoData as Object) as Void
    if photoData.tags = invalid or photoData.tags.tag = invalid then return
    tagArray = []
    for each tagObj in photoData.tags.tag
        if tagObj._content <> invalid then
            tagArray.Push(tagObj._content)
        end if
    end for
    viewModel.image.tags = tagArray
end function

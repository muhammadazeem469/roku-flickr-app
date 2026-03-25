' ******************************************************
' DetailScene.brs
' Component logic for the detail view
' Displays large image with metadata and description
' ******************************************************

sub init()
' Get UI references
    m.background = m.top.findNode("background")
    m.contentGroup = m.top.findNode("contentGroup")
    m.loadingGroup = m.top.findNode("loadingGroup")
    m.errorGroup = m.top.findNode("errorGroup")
    
    ' Image and metadata
    m.largeImage = m.top.findNode("largeImage")
    m.titleLabel = m.top.findNode("titleLabel")
    m.descriptionLabel = m.top.findNode("descriptionLabel")
    m.dimensionsLabel = m.top.findNode("dimensionsLabel")
    m.fileSizeLabel = m.top.findNode("fileSizeLabel")
    m.ownerLabel = m.top.findNode("ownerLabel")
    m.dateLabel = m.top.findNode("dateLabel")
    m.viewsLabel = m.top.findNode("viewsLabel")
    m.commentsLabel = m.top.findNode("commentsLabel")
    
    ' Loading and error
    m.loadingSpinner = m.top.findNode("loadingSpinner")
    m.loadingLabel = m.top.findNode("loadingLabel")
    m.errorLabel = m.top.findNode("errorLabel")

    ' Initialize ViewModel reference
    m.viewModel = invalid

    ' Set focus to scene
    m.top.setFocus(true)

    ' Observe imageModel field
    m.top.observeField("imageModel", "onImageModelSet")
end sub


' ******************************************************
' Handle imageModel being set
' ******************************************************
sub onImageModelSet()
imageModel = m.top.imageModel
    
    if imageModel = invalid then
showError("No image data available")
        return
    end if

    
    ' Print all fields
    if Type(imageModel) = "roAssociativeArray" then
        for each key in imageModel
            value = imageModel[key]
            if Type(value) = "roString" or Type(value) = "String" then

            else if Type(value) = "roInt" or Type(value) = "Integer" or Type(value) = "roInteger" then

            else
end if
        end for
    end if
' Set focus to overlay rectangle so we receive key events
    focusOverlay = m.top.findNode("focusOverlay")
    if focusOverlay <> invalid then
        focusOverlay.setFocus(true)
else
end if
    
    ' STEP 1: Initialize DetailViewModel with imageModel
m.viewModel = CreateDetailViewModel(imageModel)
    m.viewModel.init()
    
    ' STEP 2: Check for initialization errors
    if m.viewModel.hasError then

        showError(m.viewModel.errorMessage)
        return
    end if
    
    ' STEP 3: Display basic information immediately
displayBasicInfo()
    
    ' Show content immediately so image is visible
    showContent()
    
    ' STEP 4: Load extended information asynchronously
loadExtendedInfo()
end sub


' ******************************************************
' Display basic information (available immediately)
' ******************************************************
sub displayBasicInfo()
' Set title
    if m.viewModel.image.title <> invalid and m.viewModel.image.title <> "" then
        m.titleLabel.text = m.viewModel.image.title

    else
        m.titleLabel.text = "Untitled"
end if
    
    ' Set large image
    if m.viewModel.image.url_large <> invalid and m.viewModel.image.url_large <> "" then

        m.largeImage.uri = m.viewModel.image.url_large
    else if m.viewModel.image.url_medium <> invalid and m.viewModel.image.url_medium <> "" then

        m.largeImage.uri = m.viewModel.image.url_medium
    else
showError("Image not available")
        return
    end if
    
    ' Set description
    if m.viewModel.image.description <> invalid and m.viewModel.image.description <> "" then
        m.descriptionLabel.text = m.viewModel.image.description
    else
        m.descriptionLabel.text = "No description available"
    end if
    
    ' Set basic metadata
    if m.viewModel.dimensions <> "" then
        m.dimensionsLabel.text = "Dimensions: " + m.viewModel.dimensions
    else
        m.dimensionsLabel.text = "Dimensions: Not available"
    end if
    
    if m.viewModel.image.owner <> invalid and m.viewModel.image.owner <> "" then
        m.ownerLabel.text = "Photo by: " + m.viewModel.image.owner
    else
        m.ownerLabel.text = "Photo by: Unknown"
    end if
    
    if m.viewModel.image.views > 0 then
        m.viewsLabel.text = "Views: " + FormatNumber(m.viewModel.image.views)
    else
        m.viewsLabel.text = "Views: Not available"
    end if
    
    ' File size and date will be loaded via extended info
    m.fileSizeLabel.text = "File Size: Loading..."
    m.dateLabel.text = "Uploaded: Loading..."
    m.commentsLabel.visible = false
end sub


' ******************************************************
' Load extended information from API
' ******************************************************
sub loadExtendedInfo()
' *** TESTING OVERRIDE - CHANGE THIS TO TEST DIFFERENT SCENARIOS ***
    ' Uncomment ONE of these lines to test different cases:
    ' m.viewModel.image.id = "test_success"        ' All fields present
    ' m.viewModel.image.id = "test_minimal"        ' Missing optional fields
    ' m.viewModel.image.id = "test_notfound"       ' Photo not found error
    ' m.viewModel.image.id = "test_network_error"  ' Network error
    ' m.viewModel.image.id = "test_extreme"        ' Extreme values
    ' *** END TESTING OVERRIDE ***
    
    ' SKIP PhotoInfoTask for mock data
    if m.viewModel.image.id.Left(5) = "mock_" then
updateExtendedInfoOnError()
        return
    end if
    
    ' STEP 5: Show loading state for extended metadata
' Create task to load photo info
    m.photoInfoTask = CreateObject("roSGNode", "PhotoInfoTask")
    
    if m.photoInfoTask = invalid then
m.viewModel.handleError("Failed to create API task")
        updateExtendedInfoOnError()
        return
    end if
    
    ' Set photo ID
    m.photoInfoTask.photoId = m.viewModel.image.id
    
    ' Observe result
    m.photoInfoTask.observeField("result", "onPhotoInfoLoaded")
' Start task
    m.photoInfoTask.control = "RUN"
end sub


' ******************************************************
' Handle photo info loaded from API
' ******************************************************
sub onPhotoInfoLoaded()
result = m.photoInfoTask.result
    
    if result = invalid then
m.viewModel.handleError("Invalid API response")
        updateExtendedInfoOnError()
        return
    end if
    
    ' STEP 6 & 7: Process API response
    if result.success then
' Parse the photo data using ViewModel
        m.viewModel.parseImageInfo(result.data)
        
        ' STEP 7: Update UI with extended info
updateExtendedInfo()
else
        ' STEP 8: Handle error
m.viewModel.handleError(result.error)
        updateExtendedInfoOnError()
end if
    
    ' Clean up task
    m.photoInfoTask.unobserveField("result")
    m.photoInfoTask = invalid
end sub


' ******************************************************
' Update UI with extended information from ViewModel
' ******************************************************
sub updateExtendedInfo()
' Update description with full version
    if m.viewModel.fullDescription <> invalid and m.viewModel.fullDescription <> "" then
        m.descriptionLabel.text = m.viewModel.fullDescription
end if
    
    ' Update dimensions
    if m.viewModel.dimensions <> "" then
        m.dimensionsLabel.text = "Dimensions: " + m.viewModel.dimensions
    end if
    
    ' Update file size
    if m.viewModel.fileSize <> "" then
        m.fileSizeLabel.text = "File Size: " + m.viewModel.fileSize
    else
        m.fileSizeLabel.text = "File Size: Not available"
end if
    
    ' Update upload date
    if m.viewModel.uploadDate <> "" then
        m.dateLabel.text = "Uploaded: " + m.viewModel.uploadDate
    else
        m.dateLabel.text = "Uploaded: Not available"
end if
    
    ' Update view count
    if m.viewModel.viewCount > 0 then
        m.viewsLabel.text = "Views: " + FormatNumber(m.viewModel.viewCount)
    end if
    
    ' Show comment count if available
    if m.viewModel.commentCount > 0 then
        m.commentsLabel.text = "Comments: " + FormatNumber(m.viewModel.commentCount)
        m.commentsLabel.visible = true
    end if
end sub


' ******************************************************
' Update loading fields when extended info fails
' ******************************************************
sub updateExtendedInfoOnError()
m.fileSizeLabel.text = "File Size: Not available"
    m.dateLabel.text = "Uploaded: Not available"
end sub


' ******************************************************
' Show loading state
' ******************************************************
sub showLoading(message as String)
    m.loadingLabel.text = message
    m.loadingGroup.visible = true
    m.contentGroup.visible = false
    m.errorGroup.visible = false
    
    if m.loadingSpinner <> invalid then
        m.loadingSpinner.control = "start"
    end if
end sub


' ******************************************************
' Show content state
' ******************************************************
sub showContent()
m.loadingGroup.visible = false
    m.errorGroup.visible = false
    m.contentGroup.visible = true
    
    if m.loadingSpinner <> invalid then
        m.loadingSpinner.control = "stop"
    end if
end sub


' ******************************************************
' Show error state
' ******************************************************
sub showError(message as String)
    
    m.errorLabel.text = message
    m.errorGroup.visible = true
    m.loadingGroup.visible = false
    m.contentGroup.visible = false
    
    if m.loadingSpinner <> invalid then
        m.loadingSpinner.control = "stop"
    end if
end sub


' ******************************************************
' Format number with commas
' ******************************************************
function FormatNumber(num as Integer) as String
    numStr = num.ToStr()
    result = ""
    count = 0
    
    for i = numStr.Len() - 1 to 0 step -1
        if count = 3 then
            result = "," + result
            count = 0
        end if
        result = numStr.Mid(i, 1) + result
        count = count + 1
    end for
    
    return result
end function


' ******************************************************
' Handle key events
' ******************************************************
function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if key = "back" then
cleanup()
        m.top.closeRequested = true
        return true
    end if

    return false
end function


' ******************************************************
' Cleanup resources
' ******************************************************
sub cleanup()
if m.photoInfoTask <> invalid then
        m.photoInfoTask.control = "STOP"
        m.photoInfoTask.unobserveField("result")
        m.photoInfoTask = invalid
    end if
    
    if m.viewModel <> invalid then
        m.viewModel.cleanup()
        m.viewModel = invalid
    end if
end sub
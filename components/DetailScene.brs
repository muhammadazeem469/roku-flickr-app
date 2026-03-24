' ******************************************************
' DetailScene.brs
' Component logic for the detail view
' Displays large image with metadata and description
' ******************************************************

sub init()
    print "========================================="
    print "[DetailScene] INIT START"
    print "========================================="

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

    ' Set focus to scene
    m.top.setFocus(true)

    ' Observe imageModel field
    m.top.observeField("imageModel", "onImageModelSet")

    print "[DetailScene] INIT COMPLETE"
    print "========================================="
end sub


' ******************************************************
' Handle imageModel being set
' ******************************************************
sub onImageModelSet()
    print "[DetailScene] ========================================="
    print "[DetailScene] IMAGE MODEL SET"
    print "[DetailScene] ========================================="
    
    imageModel = m.top.imageModel
    
    if imageModel = invalid then
        print "[DetailScene] ERROR: Invalid image model"
        showError("No image data available")
        return
    end if
    
    print "[DetailScene] ImageModel received:"
    print "[DetailScene]   Type: "; Type(imageModel)
    
    ' Print all fields
    if Type(imageModel) = "roAssociativeArray" then
        for each key in imageModel
            value = imageModel[key]
            if Type(value) = "roString" or Type(value) = "String" then
                print "[DetailScene]   "; key; ": "; value
            else if Type(value) = "roInt" or Type(value) = "Integer" or Type(value) = "roInteger" then
                print "[DetailScene]   "; key; ": "; value
            else
                print "[DetailScene]   "; key; ": ["; Type(value); "]"
            end if
        end for
    end if
    
    print "[DetailScene] ========================================="
    
    ' Set focus to overlay rectangle so we receive key events
    focusOverlay = m.top.findNode("focusOverlay")
    if focusOverlay <> invalid then
        focusOverlay.setFocus(true)
        print "[DetailScene] Focus set to focusOverlay"
    else
        print "[DetailScene] WARNING: Could not find focusOverlay node"
    end if
    
    ' Create ViewModel
    m.viewModel = CreateDetailViewModel(imageModel)
    m.viewModel.init()
    
    ' Check for initialization errors
    if m.viewModel.hasError then
        print "[DetailScene] ViewModel initialization failed: "; m.viewModel.errorMessage
        showError(m.viewModel.errorMessage)
        return
    end if
    
    ' Display basic information immediately
    displayBasicInfo()
    
    ' Show content immediately so image is visible
    showContent()
    
    ' Load extended information asynchronously (in background)
    loadExtendedInfo()
end sub


' ******************************************************
' Display basic information (available immediately)
' ******************************************************
sub displayBasicInfo()
    print "[DetailScene] ========================================="
    print "[DetailScene] DISPLAYING BASIC INFO"
    print "[DetailScene] ========================================="
    
    ' DEBUG: Print entire image model
    print "[DetailScene] Image Model:"
    print "[DetailScene]   ID: "; m.viewModel.image.id
    print "[DetailScene]   Title: "; m.viewModel.image.title
    print "[DetailScene]   url_thumbnail: "; m.viewModel.image.url_thumbnail
    print "[DetailScene]   url_small: "; m.viewModel.image.url_small
    print "[DetailScene]   url_medium: "; m.viewModel.image.url_medium
    print "[DetailScene]   url_large: "; m.viewModel.image.url_large
    print "[DetailScene]   width: "; m.viewModel.image.width
    print "[DetailScene]   height: "; m.viewModel.image.height
    print "[DetailScene] ========================================="
    
    ' Set title
    if m.viewModel.image.title <> invalid and m.viewModel.image.title <> "" then
        m.titleLabel.text = m.viewModel.image.title
        print "[DetailScene] Title set to: "; m.titleLabel.text
    else
        m.titleLabel.text = "Untitled"
        print "[DetailScene] No title - using 'Untitled'"
    end if
    
    ' Set large image
    if m.viewModel.image.url_large <> invalid and m.viewModel.image.url_large <> "" then
        print "[DetailScene] ----------------------------------------"
        print "[DetailScene] SETTING LARGE IMAGE"
        print "[DetailScene] URL: "; m.viewModel.image.url_large
        print "[DetailScene] Poster node valid: "; (m.largeImage <> invalid)
        m.largeImage.uri = m.viewModel.image.url_large
        print "[DetailScene] Poster URI set to: "; m.largeImage.uri
        print "[DetailScene] Poster loadStatus: "; m.largeImage.loadStatus
        print "[DetailScene] ----------------------------------------"
    else if m.viewModel.image.url_medium <> invalid and m.viewModel.image.url_medium <> "" then
        ' Fallback to medium if large not available
        print "[DetailScene] ----------------------------------------"
        print "[DetailScene] LARGE NOT AVAILABLE - USING MEDIUM"
        print "[DetailScene] URL: "; m.viewModel.image.url_medium
        m.largeImage.uri = m.viewModel.image.url_medium
        print "[DetailScene] Poster URI set to: "; m.largeImage.uri
        print "[DetailScene] ----------------------------------------"
    else
        print "[DetailScene] ========================================="
        print "[DetailScene] ERROR: NO IMAGE URL AVAILABLE!"
        print "[DetailScene] url_large: "; m.viewModel.image.url_large
        print "[DetailScene] url_medium: "; m.viewModel.image.url_medium
        print "[DetailScene] ========================================="
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
    
    ' Dimensions
    if m.viewModel.dimensions <> "" then
        m.dimensionsLabel.text = "Dimensions: " + m.viewModel.dimensions
    else
        m.dimensionsLabel.text = "Dimensions: Not available"
    end if
    
    ' Owner
    if m.viewModel.image.owner <> invalid and m.viewModel.image.owner <> "" then
        m.ownerLabel.text = "Photo by: " + m.viewModel.image.owner
    else
        m.ownerLabel.text = "Photo by: Unknown"
    end if
    
    ' Views
    if m.viewModel.image.views > 0 then
        m.viewsLabel.text = "Views: " + FormatNumber(m.viewModel.image.views)
    else
        m.viewsLabel.text = "Views: Not available"
    end if
    
    ' File size (not available in basic data)
    m.fileSizeLabel.text = "File Size: Loading..."
    
    ' Date (not available in basic data)
    m.dateLabel.text = "Uploaded: Loading..."
    
    print "[DetailScene] Basic info displayed"
end sub


' ******************************************************
' Load extended information from API
' ******************************************************
sub loadExtendedInfo()
    print "[DetailScene] Loading extended info in background..."
    
    ' SKIP PhotoInfoTask for mock data (FG-017 development)
    ' Check if this is mock data by looking at ID prefix
    if m.viewModel.image.id.Left(5) = "mock_" then
        print "[DetailScene] Mock data detected - skipping PhotoInfoTask"
        updateExtendedInfoOnError()
        return
    end if
    
    ' Don't show loading state - content is already visible
    ' Just load the extended info quietly in the background
    
    ' Create task to load photo info
    m.photoInfoTask = CreateObject("roSGNode", "PhotoInfoTask")
    
    if m.photoInfoTask = invalid then
        print "[DetailScene] ERROR: Failed to create PhotoInfoTask"
        updateExtendedInfoOnError()
        ' Content already visible, just update the error fields
        return
    end if
    
    ' Observe task result
    m.photoInfoTask.observeField("result", "onPhotoInfoLoaded")
    
    ' Set photo ID and start task
    m.photoInfoTask.photoId = m.viewModel.image.id
    m.photoInfoTask.control = "RUN"
    
    print "[DetailScene] PhotoInfoTask started for ID: "; m.viewModel.image.id
end sub


' ******************************************************
' Handle photo info loaded from task
' ******************************************************
sub onPhotoInfoLoaded()
    print "[DetailScene] Photo info task completed"
    
    result = m.photoInfoTask.result
    
    if result = invalid then
        print "[DetailScene] ERROR: Invalid result from task"
        updateExtendedInfoOnError()
        showContent()
        return
    end if
    
    if result.success then
        print "[DetailScene] Photo info loaded successfully"
        
        ' Parse the photo data using ViewModel
        m.viewModel.parseImageInfo(result.data)
        
        ' Update UI with extended info
        updateExtendedInfo()
    else
        print "[DetailScene] Photo info loading failed: "; result.error
        updateExtendedInfoOnError()
    end if
    
    ' Content already visible, no need to call showContent()
    
    ' Clean up task
    m.photoInfoTask.unobserveField("result")
    m.photoInfoTask = invalid
end sub


' ******************************************************
' Update UI with extended information
' ******************************************************
sub updateExtendedInfo()
    print "[DetailScene] Updating extended info..."
    
    ' Update description with full version
    if m.viewModel.fullDescription <> invalid and m.viewModel.fullDescription <> "" then
        m.descriptionLabel.text = m.viewModel.fullDescription
    end if
    
    ' Update dimensions if we got more accurate ones
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
    
    ' Update view count if we got more accurate count
    if m.viewModel.viewCount > 0 then
        m.viewsLabel.text = "Views: " + FormatNumber(m.viewModel.viewCount)
    end if
    
    ' Show comment count if available
    if m.viewModel.commentCount > 0 then
        m.commentsLabel.text = "Comments: " + FormatNumber(m.viewModel.commentCount)
        m.commentsLabel.visible = true
    end if
    
    print "[DetailScene] Extended info updated"
end sub


' ******************************************************
' Update loading fields when extended info fails
' ******************************************************
sub updateExtendedInfoOnError()
    print "[DetailScene] Updating with error fallbacks..."
    
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
    
    ' Start spinner
    if m.loadingSpinner <> invalid then
        m.loadingSpinner.control = "start"
    end if
end sub


' ******************************************************
' Show content state
' ******************************************************
sub showContent()
    print "[DetailScene] ========================================="
    print "[DetailScene] SHOWING CONTENT"
    print "[DetailScene] ========================================="
    
    print "[DetailScene] Before visibility change:"
    print "[DetailScene]   loadingGroup.visible: "; m.loadingGroup.visible
    print "[DetailScene]   errorGroup.visible: "; m.errorGroup.visible
    print "[DetailScene]   contentGroup.visible: "; m.contentGroup.visible
    
    m.loadingGroup.visible = false
    m.errorGroup.visible = false
    m.contentGroup.visible = true
    
    print "[DetailScene] After visibility change:"
    print "[DetailScene]   loadingGroup.visible: "; m.loadingGroup.visible
    print "[DetailScene]   errorGroup.visible: "; m.errorGroup.visible
    print "[DetailScene]   contentGroup.visible: "; m.contentGroup.visible
    
    ' Check Poster node
    print "[DetailScene] Poster node status:"
    print "[DetailScene]   largeImage valid: "; (m.largeImage <> invalid)
    if m.largeImage <> invalid then
        print "[DetailScene]   largeImage.uri: "; m.largeImage.uri
        print "[DetailScene]   largeImage.loadStatus: "; m.largeImage.loadStatus
        print "[DetailScene]   largeImage.visible: "; m.largeImage.visible
        print "[DetailScene]   largeImage.opacity: "; m.largeImage.opacity
        print "[DetailScene]   largeImage.width: "; m.largeImage.width
        print "[DetailScene]   largeImage.height: "; m.largeImage.height
    end if
    
    ' Stop spinner
    if m.loadingSpinner <> invalid then
        m.loadingSpinner.control = "stop"
    end if
    
    print "[DetailScene] ========================================="
    print "[DetailScene] CONTENT SHOULD NOW BE VISIBLE"
    print "[DetailScene] ========================================="
end sub


' ******************************************************
' Show error state
' ******************************************************
sub showError(message as String)
    print "[DetailScene] Showing error: "; message
    
    m.errorLabel.text = message
    m.errorGroup.visible = true
    m.loadingGroup.visible = false
    m.contentGroup.visible = false
    
    ' Stop spinner
    if m.loadingSpinner <> invalid then
        m.loadingSpinner.control = "stop"
    end if
end sub


' ******************************************************
' Format number with commas (e.g., 1234567 -> "1,234,567")
' ******************************************************
function FormatNumber(num as Integer) as String
    numStr = num.ToStr()
    result = ""
    count = 0
    
    ' Process from right to left
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

    print "[DetailScene] Key: "; key

    ' Back button - return to main scene
    if key = "back" then
        print "[DetailScene] Back pressed - closing detail view"
        cleanup()
        m.top.closeRequested = true
        return true  ' Consume the event
    end if

    return false
end function


' ******************************************************
' Cleanup resources
' ******************************************************
sub cleanup()
    print "[DetailScene] Cleaning up..."
    
    ' Stop and cleanup task if running
    if m.photoInfoTask <> invalid then
        m.photoInfoTask.control = "STOP"
        m.photoInfoTask.unobserveField("result")
        m.photoInfoTask = invalid
    end if
    
    ' Cleanup ViewModel
    if m.viewModel <> invalid then
        m.viewModel.cleanup()
        m.viewModel = invalid
    end if
    
    print "[DetailScene] Cleanup complete"
end sub

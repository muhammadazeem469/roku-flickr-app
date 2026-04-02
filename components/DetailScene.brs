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
    m.spinnerAnim    = m.top.findNode("spinnerAnim")
    m.loadingLabel   = m.top.findNode("loadingLabel")
    m.errorLabel     = m.top.findNode("errorLabel")

    ' Initialize ViewModel reference
    m.viewModel = invalid

    ' Start spinner immediately — loadingGroup is visible by default
    if m.spinnerAnim <> invalid then m.spinnerAnim.control = "start"

    ' Assign a stable ID so animations can target this node's translation
    m.top.id = "detailSceneNode"

    ' Start off-screen to the right — MainScene starts the slide-in
    ' animation after appendChild + imageModel are both set, so the
    ' render thread is never blocked mid-animation.
    m.top.translation = [1920, 0]

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
    
    ' STEP 3: Display basic information immediately (sets labels + largeImage.uri)
displayBasicInfo()

    ' STEP 4: Load extended information asynchronously
loadExtendedInfo()

    ' STEP 5: Keep loadingGroup visible until the large image has loaded.
    ' showContent() is called from onLargeImageLoaded() once the Poster fires "ready".
    ' If displayBasicInfo() hit the no-URL error path it already called showError()
    ' and m.largeImage.uri is empty — skip the observer in that case.
    if m.largeImage.uri <> "" then
        m.largeImage.observeField("loadStatus", "onLargeImageLoaded")
    end if
end sub


' ******************************************************
' Called when largeImage Poster finishes loading or fails
' ******************************************************
sub onLargeImageLoaded()
    status = m.largeImage.loadStatus
    if status = "ready" then
        m.largeImage.unobserveField("loadStatus")
        showContent()
    else if status = "failed" then
        m.largeImage.unobserveField("loadStatus")
        showError("Image not available")
    end if
end sub


' ******************************************************
' Display basic information (available immediately)
' ******************************************************
sub displayBasicInfo()
    m.titleLabel.text       = m.viewModel.titleText
    m.descriptionLabel.text = m.viewModel.descriptionText
    m.ownerLabel.text       = m.viewModel.ownerText
    m.dimensionsLabel.text  = m.viewModel.dimensionsText
    m.viewsLabel.text       = m.viewModel.viewsText
    m.fileSizeLabel.text    = m.viewModel.fileSizeText
    m.dateLabel.text        = "Uploaded: Loading..."
    m.commentsLabel.visible = false

    if m.viewModel.imageUrl = "" then
        showError("Image not available")
        return
    end if
    m.largeImage.uri = m.viewModel.imageUrl
end sub


' ******************************************************
' Load extended information from API
' ******************************************************
sub loadExtendedInfo()
    ' Ask the ViewModel to create and configure the task.
    ' InfoLoader handles mock-ID skipping and creation errors internally.
    m.photoInfoTask = m.viewModel.loadExtendedInfo()

    if m.photoInfoTask = invalid then
        ' No task: either a mock ID (expected) or a creation failure
        ' (ViewModel already set its error state in the latter case).
        updateExtendedInfoOnError()
        return
    end if

    m.photoInfoTask.observeField("result", "onPhotoInfoLoaded")
    m.photoInfoTask.control = "RUN"
end sub


' ******************************************************
' Handle photo info loaded from API
' ******************************************************
sub onPhotoInfoLoaded()
    result = m.photoInfoTask.result

    ' Delegate all result interpretation to the ViewModel.
    ' After this call, m.viewModel.hasError reflects success or failure.
    m.viewModel.handlePhotoInfoResult(result)

    if m.viewModel.hasError then
        updateExtendedInfoOnError()
    else
        updateExtendedInfo()
    end if

    m.photoInfoTask.unobserveField("result")
    m.photoInfoTask = invalid
end sub


' ******************************************************
' Update UI with extended information from ViewModel
' ******************************************************
sub updateExtendedInfo()
    m.descriptionLabel.text = m.viewModel.descriptionText
    m.dimensionsLabel.text  = m.viewModel.dimensionsText
    m.fileSizeLabel.text    = m.viewModel.fileSizeText
    m.dateLabel.text        = m.viewModel.uploadDateText
    m.viewsLabel.text       = m.viewModel.viewsText
    m.commentsLabel.text    = m.viewModel.commentsText
    m.commentsLabel.visible = m.viewModel.showComments
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
    if m.spinnerAnim <> invalid then m.spinnerAnim.control = "start"
end sub


' ******************************************************
' Show content state
' ******************************************************
sub showContent()
    m.loadingGroup.visible = false
    m.errorGroup.visible = false
    m.contentGroup.visible = true
    if m.spinnerAnim <> invalid then m.spinnerAnim.control = "stop"
end sub


' ******************************************************
' Show error state
' ******************************************************
sub showError(message as String)
    m.errorLabel.text = message
    m.errorGroup.visible = true
    m.loadingGroup.visible = false
    m.contentGroup.visible = false
    if m.spinnerAnim <> invalid then m.spinnerAnim.control = "stop"
end sub


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
    if m.largeImage <> invalid then
        m.largeImage.unobserveField("loadStatus")
    end if
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
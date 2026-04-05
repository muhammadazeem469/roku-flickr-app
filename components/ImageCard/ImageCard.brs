' ******************************************************
' ImageCard.brs
' Image card component with focus states and loading
' Ticket: FG-013
'
' Placeholder states (driven by itemContent.placeholderState):
'   "loading" — API request in progress → shows "Loading..."
'   "retry"   — load failed → shows pink RETRY + hint text
' ******************************************************

sub init()
    m.top.id = "imageCard_" + Rnd(999999).ToStr()

    ' Node references
    m.cardBackground  = m.top.findNode("cardBackground")
    m.placeholder     = m.top.findNode("placeholder")
    m.loadingTextLabel = m.top.findNode("loadingTextLabel")
    m.retryIconPoster = m.top.findNode("retryIconPoster")
    m.retryHintLabel  = m.top.findNode("retryHintLabel")
    m.errorLabel      = m.top.findNode("errorLabel")
    m.thumbnail       = m.top.findNode("thumbnail")
    m.titleLabel      = m.top.findNode("titleLabel")

    m.top.observeField("imageModel",  "onImageModelChanged")
    m.top.observeField("showTitle",   "onShowTitleChanged")
    m.top.observeField("itemContent", "onItemContentChanged")

    m.thumbnail.observeField("loadStatus", "onImageLoadStatusChanged")

    m.imageLoaded = false
    m.hasError    = false
    m.fadeAnim    = invalid
end sub


' ******************************************************
' RowList assigns a ContentNode to this card slot.
' Three cases:
'   1. isPlaceholder + placeholderState="loading" → Loading...
'   2. isPlaceholder + placeholderState="retry"   → RETRY icon
'   3. imageData present                           → load image
' ******************************************************
sub onItemContentChanged()
    hideAllOverlays()

    itemContent = m.top.itemContent
    if itemContent = invalid then
        showDarkPlaceholder()
        return
    end if

    isPlaceholder = false
    if itemContent.doesExist("isPlaceholder") then isPlaceholder = itemContent.isPlaceholder

    if isPlaceholder then
        placeholderState = "loading"
        if itemContent.doesExist("placeholderState") then placeholderState = itemContent.placeholderState

        if placeholderState = "retry" then
            showRetryState()
        else
            showLoadingState()
        end if
        return
    end if

    ' Real image — show dark card while poster downloads
    showDarkPlaceholder()
    if itemContent.doesExist("imageData") then
        m.top.imageModel = itemContent.imageData
    end if
end sub


' ******************************************************
' imageModel set — start loading the thumbnail poster
' ******************************************************
sub onImageModelChanged()
    imageModel = m.top.imageModel

    if imageModel = invalid then
        showImageError()
        return
    end if

    m.imageLoaded = false
    m.hasError    = false
    showDarkPlaceholder()

    imageUrl = ""
    if imageModel.url_thumbnail <> invalid and imageModel.url_thumbnail <> "" then
        imageUrl = imageModel.url_thumbnail
    else if imageModel.url_small <> invalid and imageModel.url_small <> "" then
        imageUrl = imageModel.url_small
    else if imageModel.url_medium <> invalid and imageModel.url_medium <> "" then
        imageUrl = imageModel.url_medium
    end if

    if imageUrl <> "" then
        m.thumbnail.uri = imageUrl
    else
        showImageError()
    end if

    if imageModel.title <> invalid and imageModel.title <> "" then
        m.titleLabel.text = imageModel.title
    else
        m.titleLabel.text = "Untitled"
    end if

    updateTitleVisibility()
end sub


' ******************************************************
' Poster load status changed
' ******************************************************
sub onImageLoadStatusChanged()
    loadStatus = m.thumbnail.loadStatus

    if loadStatus = "ready" then
        m.imageLoaded = true
        m.hasError    = false
        showImage()
    else if loadStatus = "failed" then
        m.imageLoaded = false
        m.hasError    = true
        showImageError()
    end if
end sub


' ******************************************************
' Hide everything — used as a reset before showing a state
' ******************************************************
sub hideAllOverlays()
    if m.fadeAnim <> invalid then
        m.fadeAnim.control = "stop"
        m.top.removeChild(m.fadeAnim)
        m.fadeAnim = invalid
    end if

    m.thumbnail.visible        = false
    m.thumbnail.opacity        = 1.0
    m.placeholder.visible      = false
    m.loadingTextLabel.visible = false
    m.retryIconPoster.visible  = false
    m.retryHintLabel.visible   = false
    m.errorLabel.visible       = false
end sub


' ******************************************************
' Plain dark card — no text, used while poster downloads
' ******************************************************
sub showDarkPlaceholder()
    hideAllOverlays()
    m.placeholder.color   = "0x1A1A1AFF"
    m.placeholder.visible = true
end sub


' ******************************************************
' "Loading..." — API request is in progress
' ******************************************************
sub showLoadingState()
    hideAllOverlays()
    m.placeholder.color        = "0x1A1A1AFF"
    m.placeholder.visible      = true
    m.loadingTextLabel.visible = true
end sub


' ******************************************************
' RETRY icon + hint — category load failed, OK retries
' ******************************************************
sub showRetryState()
    hideAllOverlays()
    m.placeholder.color       = "0x1A1A1AFF"
    m.placeholder.visible     = true
    m.retryIconPoster.visible = true
    m.retryHintLabel.visible  = true
end sub


' ******************************************************
' Fade the thumbnail in over 0.3s (image downloaded OK)
' ******************************************************
sub showImage()
    hideAllOverlays()
    m.placeholder.visible = true   ' stays visible underneath during fade

    m.thumbnail.opacity = 0.0
    m.thumbnail.visible = true

    anim              = m.top.createChild("Animation")
    anim.duration     = 0.3
    anim.easeFunction = "linear"

    interp               = anim.createChild("FloatFieldInterpolator")
    interp.key           = [0.0, 1.0]
    interp.keyValue      = [0.0, 1.0]
    interp.fieldToInterp = "thumbnail.opacity"

    m.fadeAnim   = anim
    anim.control = "start"
end sub


' ******************************************************
' ✕ — thumbnail download failed (not a category error)
' ******************************************************
sub showImageError()
    hideAllOverlays()
    m.placeholder.color   = "0x333333FF"
    m.placeholder.visible = true
    m.errorLabel.visible  = true
end sub


sub updateTitleVisibility()
    m.titleLabel.visible = m.top.showTitle
end sub

sub onShowTitleChanged()
    updateTitleVisibility()
end sub


function onKeyEvent(key as String, press as Boolean) as Boolean
    if press and key = "OK" then
        m.top.itemSelected = m.top.imageModel
        return true
    end if
    return false
end function

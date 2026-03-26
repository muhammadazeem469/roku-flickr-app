' ******************************************************
' ImageCard.brs
' Image card component with focus states and loading
' Ticket: FG-013
' ******************************************************

sub init()
' Generate unique ID for this card instance (needed for animations)
    m.top.id = "imageCard_" + Rnd(999999).ToStr()

    ' Get references to child nodes
    m.cardBackground = m.top.findNode("cardBackground")
    m.placeholder    = m.top.findNode("placeholder")
    m.loadingLabel   = m.top.findNode("loadingLabel")
    m.errorLabel     = m.top.findNode("errorLabel")
    m.thumbnail      = m.top.findNode("thumbnail")
    m.focusBorder    = m.top.findNode("focusBorder")
    m.titleLabel     = m.top.findNode("titleLabel")

    ' Set up observers
    m.top.observeField("imageModel",   "onImageModelChanged")
    m.top.observeField("showTitle",    "onShowTitleChanged")
    m.top.observeField("cardWidth",    "onSizeChanged")
    m.top.observeField("cardHeight",   "onSizeChanged")
    m.top.observeField("focusedChild", "onFocusChanged")

    ' Observe poster loading states
    m.thumbnail.observeField("loadStatus", "onImageLoadStatusChanged")

    ' Initialize state
    m.imageLoaded = false
    m.hasError    = false
    m.fadeAnim    = invalid
    m.borderAnim  = invalid

    ' Apply initial size
    updateCardSize()
end sub


' ******************************************************
' Called when imageModel is set
' ******************************************************
sub onImageModelChanged()
    imageModel = m.top.imageModel

    if imageModel = invalid then
showError()
        return
    end if

    ' Reset state
    m.imageLoaded = false
    m.hasError    = false

    ' Show loading state
    showLoading()

    ' Set image URL (prefer thumbnail, fallback to small, then medium)
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
showError()
    end if

    ' Set title
    if imageModel.title <> invalid and imageModel.title <> "" then
        m.titleLabel.text = imageModel.title
    else
        m.titleLabel.text = "Untitled"
    end if

    ' Update title visibility based on showTitle setting
    updateTitleVisibility()
end sub


' ******************************************************
' Called when image load status changes
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
        showError()
end if
end sub


' ******************************************************
' Show loading state
' ******************************************************
sub showLoading()
    ' Cancel any in-progress fade so the next load starts clean
    if m.fadeAnim <> invalid then
        m.fadeAnim.control = "stop"
        m.top.removeChild(m.fadeAnim)
        m.fadeAnim = invalid
    end if

    m.thumbnail.opacity    = 1.0   ' reset for next fade-in
    m.thumbnail.visible    = false
    m.placeholder.visible  = true
    m.loadingLabel.visible = true
    m.errorLabel.visible   = false
end sub


' ******************************************************
' Show image — fades thumbnail in over 0.3s so the grey
' placeholder is always visible during the transition,
' even when the image loads instantly from Roku's cache.
' ******************************************************
sub showImage()
    m.loadingLabel.visible = false
    m.errorLabel.visible   = false

    ' Start transparent, render on top of placeholder, then fade in.
    ' Placeholder stays visible underneath until thumbnail is fully opaque.
    m.thumbnail.opacity = 0.0
    m.thumbnail.visible = true

    ' Cancel any previous fade before starting a new one
    if m.fadeAnim <> invalid then
        m.fadeAnim.control = "stop"
        m.top.removeChild(m.fadeAnim)
        m.fadeAnim = invalid
    end if

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
' Show error state
' ******************************************************
sub showError()
    ' Cancel any in-progress fade
    if m.fadeAnim <> invalid then
        m.fadeAnim.control = "stop"
        m.top.removeChild(m.fadeAnim)
        m.fadeAnim = invalid
    end if

    m.thumbnail.opacity    = 1.0
    m.thumbnail.visible    = false
    m.placeholder.visible  = true
    m.placeholder.color    = "0x555555"
    m.loadingLabel.visible = false
    m.errorLabel.visible   = true
end sub


' ******************************************************
' Handle focus changes
' ******************************************************
sub onFocusChanged()
    hasFocus = m.top.hasFocus()

    if hasFocus then
        applyFocusedState()
    else
        applyUnfocusedState()
    end if
end sub


' ******************************************************
' Apply focused visual state
' ******************************************************
sub applyFocusedState()
    ' Animate focus border fade-in (150ms)
    if m.borderAnim <> invalid then
        m.borderAnim.control = "stop"
        m.top.removeChild(m.borderAnim)
        m.borderAnim = invalid
    end if
    borderAnim = m.top.createChild("Animation")
    borderAnim.duration     = 0.15
    borderAnim.easeFunction = "linear"
    borderInterp = borderAnim.createChild("FloatFieldInterpolator")
    borderInterp.key           = [0.0, 1.0]
    borderInterp.keyValue      = [m.focusBorder.opacity, 1.0]
    borderInterp.fieldToInterp = "focusBorder.opacity"
    m.borderAnim = borderAnim
    borderAnim.control = "start"

    ' Animate scale 1.0 → 1.1 (200ms)
    scaleAnimation = m.top.createChild("Animation")
    scaleAnimation.duration     = 0.2   ' UIConfig.ANIMATION.FAST
    scaleAnimation.easeFunction = "outCubic"
    scaleInterpolator = scaleAnimation.createChild("Vector2DFieldInterpolator")
    scaleInterpolator.key           = [0, 1]
    scaleInterpolator.keyValue      = [[1.0, 1.0], [1.1, 1.1]]
    scaleInterpolator.fieldToInterp = m.top.id + ".scale"
    scaleAnimation.control = "start"

    if m.top.showTitle then
        m.titleLabel.visible = true
    end if
end sub


' ******************************************************
' Apply unfocused visual state
' ******************************************************
sub applyUnfocusedState()
    ' Animate focus border fade-out (150ms)
    if m.borderAnim <> invalid then
        m.borderAnim.control = "stop"
        m.top.removeChild(m.borderAnim)
        m.borderAnim = invalid
    end if
    borderAnim = m.top.createChild("Animation")
    borderAnim.duration     = 0.15
    borderAnim.easeFunction = "linear"
    borderInterp = borderAnim.createChild("FloatFieldInterpolator")
    borderInterp.key           = [0.0, 1.0]
    borderInterp.keyValue      = [m.focusBorder.opacity, 0.0]
    borderInterp.fieldToInterp = "focusBorder.opacity"
    m.borderAnim = borderAnim
    borderAnim.control = "start"

    ' Animate scale 1.1 → 1.0 (200ms)
    scaleAnimation = m.top.createChild("Animation")
    scaleAnimation.duration     = 0.2   ' UIConfig.ANIMATION.FAST
    scaleAnimation.easeFunction = "inCubic"
    scaleInterpolator = scaleAnimation.createChild("Vector2DFieldInterpolator")
    scaleInterpolator.key           = [0, 1]
    scaleInterpolator.keyValue      = [[1.1, 1.1], [1.0, 1.0]]
    scaleInterpolator.fieldToInterp = m.top.id + ".scale"
    scaleAnimation.control = "start"

    updateTitleVisibility()
end sub


' ******************************************************
' Update title visibility based on showTitle + focus
' ******************************************************
sub updateTitleVisibility()
    if m.top.showTitle then
        m.titleLabel.visible = m.top.hasFocus()
    else
        m.titleLabel.visible = false
    end if
end sub


' ******************************************************
' Called when showTitle changes
' ******************************************************
sub onShowTitleChanged()
    updateTitleVisibility()
end sub


' ******************************************************
' Called when cardWidth or cardHeight changes
' ******************************************************
sub onSizeChanged()
    updateCardSize()
end sub


' ******************************************************
' Apply size to all card elements
' ******************************************************
sub updateCardSize()
    width  = m.top.cardWidth
    height = m.top.cardHeight

    m.cardBackground.width  = width
    m.cardBackground.height = height

    m.placeholder.width  = width
    m.placeholder.height = height

    m.loadingLabel.width  = width
    m.loadingLabel.height = height

    m.errorLabel.width  = width
    m.errorLabel.height = height

    m.thumbnail.width  = width
    m.thumbnail.height = height

    m.focusBorder.width  = width
    m.focusBorder.height = height

    ' Update inner border rectangle (3px inset)
    innerBorder = m.focusBorder.getChild(0)
    if innerBorder <> invalid then
        innerBorder.width  = width - 6
        innerBorder.height = height - 6
    end if

    m.titleLabel.width       = width
    m.titleLabel.translation = [0, height + 5]
end sub


' ******************************************************
' Handle key events
' ******************************************************
function onKeyEvent(key as String, press as Boolean) as Boolean
    handled = false

    if press then

        if key = "OK" then
m.top.itemSelected = m.top.imageModel
            handled = true
        end if
    end if

    return handled
end function

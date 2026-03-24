' ******************************************************
' ImageCard.brs
' Image card component with focus states and loading
' Ticket: FG-013
' ******************************************************

sub init()
    print "[ImageCard] Initializing..."

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

    ' Apply initial size
    updateCardSize()

    print "[ImageCard] Initialization complete"
end sub


' ******************************************************
' Called when imageModel is set
' ******************************************************
sub onImageModelChanged()
    imageModel = m.top.imageModel

    if imageModel = invalid then
        print "[ImageCard] No image model provided"
        showError()
        return
    end if

    print "[ImageCard] Image model received: "; imageModel.id

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
        print "[ImageCard] Loading image: "; imageUrl
        m.thumbnail.uri = imageUrl
    else
        print "[ImageCard] No valid image URL found"
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

    print "[ImageCard] Image load status: "; loadStatus

    if loadStatus = "ready" then
        m.imageLoaded = true
        m.hasError    = false
        showImage()
        print "[ImageCard] Image loaded successfully"

    else if loadStatus = "failed" then
        m.imageLoaded = false
        m.hasError    = true
        showError()
        print "[ImageCard] Image load failed"
    end if
end sub


' ******************************************************
' Show loading state
' ******************************************************
sub showLoading()
    m.placeholder.visible  = true
    m.loadingLabel.visible = true
    m.errorLabel.visible   = false
    m.thumbnail.visible    = false
end sub


' ******************************************************
' Show image (hide loading/error)
' ******************************************************
sub showImage()
    m.placeholder.visible  = false
    m.loadingLabel.visible = false
    m.errorLabel.visible   = false
    m.thumbnail.visible    = true
end sub


' ******************************************************
' Show error state
' ******************************************************
sub showError()
    m.placeholder.visible  = true
    m.placeholder.color    = "0x555555"   ' UIConfig.COLORS.SECONDARY
    m.loadingLabel.visible = false
    m.errorLabel.visible   = true
    m.thumbnail.visible    = false
end sub


' ******************************************************
' Handle focus changes
' ******************************************************
sub onFocusChanged()
    hasFocus = m.top.hasFocus()
    print "[ImageCard] Focus changed: "; hasFocus

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
    m.focusBorder.opacity = 1.0

    ' Animate scale using node ID
    scaleAnimation = m.top.createChild("Animation")
    scaleAnimation.duration     = 0.2   ' UIConfig.ANIMATION.FAST
    scaleAnimation.easeFunction = "outCubic"

    scaleInterpolator = scaleAnimation.createChild("Vector2DFieldInterpolator")
    scaleInterpolator.key        = [0, 1]
    scaleInterpolator.keyValue   = [[1.0, 1.0], [1.05, 1.05]]
    scaleInterpolator.fieldToInterp = m.top.id + ".scale"

    scaleAnimation.control = "start"

    if m.top.showTitle then
        m.titleLabel.visible = true
    end if

    print "[ImageCard] Applied focused state"
end sub


' ******************************************************
' Apply unfocused visual state
' ******************************************************
sub applyUnfocusedState()
    m.focusBorder.opacity = 0.0

    ' Animate scale using node ID
    scaleAnimation = m.top.createChild("Animation")
    scaleAnimation.duration     = 0.2   ' UIConfig.ANIMATION.FAST
    scaleAnimation.easeFunction = "inCubic"

    scaleInterpolator = scaleAnimation.createChild("Vector2DFieldInterpolator")
    scaleInterpolator.key        = [0, 1]
    scaleInterpolator.keyValue   = [[1.05, 1.05], [1.0, 1.0]]
    scaleInterpolator.fieldToInterp = m.top.id + ".scale"

    scaleAnimation.control = "start"

    updateTitleVisibility()

    print "[ImageCard] Applied unfocused state"
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

    print "[ImageCard] Updating size: "; width; "x"; height

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
        print "[ImageCard] Key pressed: "; key

        if key = "OK" then
            print "[ImageCard] Card selected"
            m.top.itemSelected = m.top.imageModel
            handled = true
        end if
    end if

    return handled
end function

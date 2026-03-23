' ******************************************************
' MainScene.brs
' Root scene for Flickr Gallery.
' Integrates MainViewModel with 12 SwimLane components.
' Ticket: FG-015
' ******************************************************

sub init()
    print "[MainScene] Initializing..."

    ' Layout constants
    m.SWIMLANE_COUNT = 12

    ' --- Node references ---
    m.appTitle           = m.top.findNode("appTitle")
    m.loadingLabel       = m.top.findNode("loadingLabel")
    m.globalError        = m.top.findNode("globalError")
    m.swimlanesScroller  = m.top.findNode("swimlanesScroller")
    m.swimlanesContainer = m.top.findNode("swimlanesContainer")

    ' Collect all 12 swimlane node references into an array
    m.swimlanes = []
    for i = 0 to m.SWIMLANE_COUNT - 1
        lane = m.top.findNode("swimlane_" + i.toStr())
        m.swimlanes.push(lane)
        ' Observe itemSelected from each swimlane
        lane.observeField("itemSelected", "onImageSelected")
    end for

    ' --- Focus state ---
    m.focusedLaneIndex = 0

    ' --- Configuration fields from main.brs ---
    m.top.observeField("appBgColor",   "onBackgroundColorChanged")
    m.top.observeField("appTextColor", "onTextColorChanged")

    ' --- Initialize ViewModel ---
    m.viewModel = CreateMainViewModel()
    m.viewModel.init()

    ' Load all category data
    m.viewModel.loadAllCategories()

    ' Push data to swimlanes
    refreshSwimlanes()

    ' Set initial focus
    m.top.setFocus(true)
    setFocusToLane(0)

    print "[MainScene] Initialization complete"
end sub


' ******************************************************
' Push current ViewModel category data to all swimlanes
' ******************************************************
sub refreshSwimlanes()
    categories = m.viewModel.categories

    ' Handle global error
    if m.viewModel.hasError then
        showGlobalError(m.viewModel.errorMessage)
        return
    end if

    ' Handle still initializing
    if m.viewModel.isInitializing then
        m.loadingLabel.visible      = true
        m.swimlanesScroller.visible = false
        return
    end if

    ' Show swimlanes
    m.loadingLabel.visible      = false
    m.globalError.visible       = false
    m.swimlanesScroller.visible = true

    ' Bind each CategoryModel to its SwimLane
    for i = 0 to m.swimlanes.count() - 1
        if i < categories.count() then
            m.swimlanes[i].categoryModel = categories[i]
        end if
    end for

    print "[MainScene] Swimlanes refreshed with "; categories.count(); " categories"
end sub


' ******************************************************
' Show global error state
' ******************************************************
sub showGlobalError(message as String)
    m.loadingLabel.visible      = false
    m.swimlanesScroller.visible = false
    m.globalError.visible       = true
    m.globalError.text          = message
    print "[MainScene] Global error: "; message
end sub


' ******************************************************
' Focus management — set focus to a specific swimlane
' ******************************************************
sub setFocusToLane(index as Integer)
    if m.swimlanes.count() = 0 then return

    ' Clamp
    if index < 0 then index = 0
    if index >= m.swimlanes.count() then index = m.swimlanes.count() - 1

    m.focusedLaneIndex = index
    m.swimlanes[index].setFocusToCard(0)

    ' Scroll container to keep focused lane visible
    scrollToLane(index)

    print "[MainScene] Focus moved to lane "; index
end sub


' ******************************************************
' Scroll the container so the focused lane is visible
' ******************************************************
sub scrollToLane(index as Integer)
    ' Each swimlane is CARD_HEIGHT(300) + title(50) + spacing(40) = 390px
    laneHeight   = 390
    screenHeight = 980   ' usable height below header
    laneTop      = index * laneHeight

    ' Only scroll if lane is below visible area
    if laneTop > screenHeight / 2 then
        m.swimlanesScroller.translation = [60, 100 - (laneTop - screenHeight / 2)]
    else
        m.swimlanesScroller.translation = [60, 100]
    end if
end sub


' ******************************************************
' Called when appBgColor is set from main.brs
' ******************************************************
sub onBackgroundColorChanged()
    if m.top.appBgColor <> "" then
        m.top.backgroundColor = m.top.appBgColor
        print "[MainScene] Background color: "; m.top.appBgColor
    end if
end sub


' ******************************************************
' Called when appTextColor is set from main.brs
' ******************************************************
sub onTextColorChanged()
    if m.top.appTextColor <> "" then
        if m.appTitle <> invalid then
            m.appTitle.color = m.top.appTextColor
        end if
        if m.loadingLabel <> invalid then
            m.loadingLabel.color = m.top.appTextColor
        end if
        print "[MainScene] Text color: "; m.top.appTextColor
    end if
end sub


' ******************************************************
' Called when any swimlane fires itemSelected
' Delegate to ViewModel for detail navigation
' ******************************************************
sub onImageSelected()
    for i = 0 to m.swimlanes.count() - 1
        lane = m.swimlanes[i]
        if lane.itemSelected <> invalid then
            print "[MainScene] Image selected from lane "; i
            m.viewModel.handleImageSelection(i, lane.focusedCardIndex)

            if m.viewModel.navigationRequested then
                openDetailScreen(lane.itemSelected)
                m.viewModel.navigationRequested = false
            end if
            return
        end if
    end for
end sub


' ******************************************************
' Navigate to detail screen with selected image
' ******************************************************
sub openDetailScreen(imageModel as Object)
    print "[MainScene] Opening detail for: "; imageModel.title
    ' Detail screen integration handled in FG-016
end sub


' ******************************************************
' Handle remote key events — vertical swimlane navigation
' Left/Right delegated to focused swimlane
' ******************************************************
function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    print "[MainScene] Key: "; key

    if key = "down" then
        newIndex = m.focusedLaneIndex + 1
        if newIndex < m.swimlanes.count() then
            setFocusToLane(newIndex)
            return true
        end if

    else if key = "up" then
        newIndex = m.focusedLaneIndex - 1
        if newIndex >= 0 then
            setFocusToLane(newIndex)
            return true
        end if

    else if key = "back" then
        print "[MainScene] Back - allowing app exit"
        return false

    else if key = "options" then
        print "[MainScene] Options pressed"
        return true
    end if

    return false
end function

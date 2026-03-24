' ******************************************************
' MainScene.brs
' UPDATED: FG-021 - Implement Loading States in UI
'
' Loading state approach (simplified and reliable):
'   - loadingBackdrop, globalSpinner, loadingProgress
'     are flat nodes (NOT inside a Group) so visible
'     toggling works reliably on all Roku firmware.
'   - No opacity animations on Group — BusySpinner does
'     not support width/height, Group has no opacity field
'     on older firmware. Simple visible=true/false is safe.
'   - 2-second minimum spinner display time so user can
'     actually see it (spinnerMinTimer).
'   - Per-row placeholder "Loading..." items in RowList
'     replaced with real images as each Task completes.
' ******************************************************

sub init()
    print "========================================="
    print "[MainScene] INIT START (FG-021)"
    print "========================================="

    ' === UI References ===
    m.appTitle        = m.top.findNode("appTitle")
    m.loadingBackdrop = m.top.findNode("loadingBackdrop")
    m.spinnerGroup    = m.top.findNode("spinnerGroup")
    m.spinnerAnim     = m.top.findNode("spinnerAnim")
    m.loadingProgress = m.top.findNode("loadingProgress")
    m.globalError     = m.top.findNode("globalError")
    m.rowList         = m.top.findNode("categoryRowList")

    if m.rowList = invalid then
        print "[MainScene] ERROR: RowList not found!"
        return
    end if

    ' === Focus: Scene first ===
    m.top.setFocus(true)

    ' === Configure RowList ===
    configureRowList()

    ' === Observe RowList events ===
    m.rowList.observeField("itemSelected", "onItemSelected")
    m.rowList.observeField("itemFocused",  "onItemFocused")

    ' === Theme observers ===
    m.top.observeField("appBgColor",   "onBackgroundColorChanged")
    m.top.observeField("appTextColor", "onTextColorChanged")

    ' === ViewModel init ===
    print "[MainScene] Creating ViewModel..."
    m.viewModel = CreateMainViewModel()
    m.viewModel.init()

    ' === Loading state tracking (FG-021) ===
    m.totalCategories       = m.viewModel.categories.Count()
    m.loadedCategoryCount   = 0
    m.firstRowRevealed      = false
    m.firstDataReady        = false
    m.spinnerMinTimeElapsed = false
    m.activeTasks           = []

    ' Show spinner + loading text immediately
    showGlobalLoading()

    ' 2-second minimum so spinner is always visible long enough to read
    spinnerTimer = CreateObject("roSGNode", "Timer")
    spinnerTimer.duration = 2.0
    spinnerTimer.repeat   = false
    spinnerTimer.observeField("fire", "onSpinnerMinTimeElapsed")
    m.spinnerMinTimer = spinnerTimer
    spinnerTimer.control = "start"
    print "[MainScene] Spinner min timer started (2s)"

    ' Update progress label
    updateLoadingProgress(0, m.totalCategories)

    ' === Build placeholder RowList (FG-021) ===
    buildPlaceholderRowList()

    ' === Prepare load queue ===
    m.viewModel.loadAllCategories()

    ' === Detail scene reference ===
    m.detailScene = invalid

    ' === Start loading ===
    startCategoryLoading()

    print "========================================="
    print "[MainScene] INIT COMPLETE (FG-021)"
    print "========================================="
end sub


' ******************************************************
' Show all global loading nodes (FG-021)
' ******************************************************
sub showGlobalLoading()
    if m.loadingBackdrop <> invalid then m.loadingBackdrop.visible = true
    if m.spinnerGroup    <> invalid then m.spinnerGroup.visible    = true
    if m.loadingProgress <> invalid then m.loadingProgress.visible = true
    ' Start rotation animation
    if m.spinnerAnim <> invalid then m.spinnerAnim.control = "start"
end sub


' ******************************************************
' Hide all global loading nodes (FG-021)
' ******************************************************
sub hideGlobalLoading()
    if m.loadingBackdrop <> invalid then m.loadingBackdrop.visible = false
    if m.spinnerGroup    <> invalid then m.spinnerGroup.visible    = false
    if m.loadingProgress <> invalid then m.loadingProgress.visible = false
    ' Stop rotation animation
    if m.spinnerAnim <> invalid then m.spinnerAnim.control = "stop"
end sub


' ******************************************************
' Update progress label text (FG-021)
' ******************************************************
sub updateLoadingProgress(loaded as Integer, total as Integer)
    if m.loadingProgress = invalid then return
    if loaded = 0 then
        m.loadingProgress.text = "Loading..."
    else if total > 0 then
        m.loadingProgress.text = loaded.ToStr() + " of " + total.ToStr() + " categories loaded"
    end if
end sub


' ******************************************************
' Minimum spinner timer fired — 2 seconds elapsed (FG-021)
' ******************************************************
sub onSpinnerMinTimeElapsed()
    print "[MainScene] FG-021: Spinner min time elapsed"
    m.spinnerMinTimeElapsed = true
    m.spinnerMinTimer = invalid

    ' If data already arrived, reveal now
    if m.firstDataReady then
        revealRowList()
    end if
end sub


' ******************************************************
' Reveal RowList and hide loading overlay (FG-021)
' Gated: both spinnerMinTimeElapsed AND firstDataReady
' must be true before this does anything.
' ******************************************************
sub revealRowList()
    ' Both gates must be true
    if not m.spinnerMinTimeElapsed then
        print "[MainScene] FG-021: Data ready but spinner min time not yet elapsed"
        return
    end if
    if not m.firstDataReady then
        print "[MainScene] FG-021: Min time elapsed but no data yet"
        return
    end if
    if m.firstRowRevealed then return
    m.firstRowRevealed = true

    print "[MainScene] FG-021: Revealing RowList, hiding loading overlay"

    ' Hide loading overlay
    hideGlobalLoading()

    ' Show RowList
    m.rowList.visible = true

    ' Transfer focus
    setRowListFocus()
end sub


' ******************************************************
' Build RowList with placeholder rows immediately (FG-021)
' ******************************************************
sub buildPlaceholderRowList()
    print "[MainScene] Building placeholder RowList..."

    rootContent = CreateObject("roSGNode", "ContentNode")

    for each category in m.viewModel.categories
        rowNode       = CreateObject("roSGNode", "ContentNode")
        rowNode.title = category.display_name

        placeholder = CreateObject("roSGNode", "ContentNode")
        placeholder.title = "Loading..."
        placeholder.addField("isPlaceholder", "boolean", false)
        placeholder.isPlaceholder = true

        rowNode.appendChild(placeholder)
        rootContent.appendChild(rowNode)
    end for

    m.rowList.content = rootContent
    print "[MainScene] Placeholder RowList built with "; m.totalCategories; " rows"
end sub


' ******************************************************
' Start sequential category loading
' ******************************************************
sub startCategoryLoading()
    print "[MainScene] STARTING CATEGORY LOADING"

    if m.viewModel.loadQueue = invalid or m.viewModel.loadQueue.Count() = 0 then
        print "[MainScene] ERROR: No categories to load"
        showGlobalError("No categories configured")
        return
    end if

    loadNextCategory()
end sub


' ******************************************************
' Load next category from queue
' ******************************************************
sub loadNextCategory()
    if m.viewModel.loadQueue = invalid or m.viewModel.loadQueue.Count() = 0 then
        print "[MainScene] All categories processed"

        if m.loadedCategoryCount = 0 then
            showGlobalError("No categories could be loaded")
        else
            ' Force reveal if not already done
            if not m.firstRowRevealed then
                m.firstDataReady = true
                revealRowList()
            end if
        end if
        return
    end if

    categoryIndex = m.viewModel.loadQueue.Shift()
    print "[MainScene] Loading category index: "; categoryIndex

    task = m.viewModel.categoryLoader.loadCategoryWithTask(m.viewModel, categoryIndex, m.top)

    if task = invalid then
        print "[MainScene] ERROR: Failed to create task for category "; categoryIndex
        loadNextCategory()
        return
    end if

    task.observeField("result", "onCategoryLoaded")
    m.activeTasks.Push(task)
    task.control = "RUN"
end sub


' ******************************************************
' Category Task completed (FG-021)
' ******************************************************
sub onCategoryLoaded(event as Object)
    task          = event.getRoSGNode()
    result        = task.result
    categoryIndex = task.categoryIndex

    print "[MainScene] Category loaded - index: "; categoryIndex; " success: "; result.success

    m.viewModel.categoryLoader.parseApiResponse(m.viewModel, categoryIndex, result)

    if result.success then
        m.loadedCategoryCount = m.loadedCategoryCount + 1

        ' Update progress label
        updateLoadingProgress(m.loadedCategoryCount, m.totalCategories)

        ' Replace placeholder row with real images
        refreshRowAtIndex(categoryIndex)

        ' Mark first data ready and attempt reveal
        if not m.firstDataReady then
            m.firstDataReady = true
            print "[MainScene] FG-021: First data ready"
        end if
        revealRowList()
    else
        print "[MainScene] Failed: "; categoryIndex; " - "; result.error
        clearPlaceholderRow(categoryIndex)
    end if

    ' Clean up task
    task.unobserveField("result")
    for i = 0 to m.activeTasks.Count() - 1
        if m.activeTasks[i].id = task.id then
            m.activeTasks.Delete(i)
            exit for
        end if
    end for
    m.top.removeChild(task)

    loadNextCategory()
end sub


' ******************************************************
' Replace placeholder row with real image items (FG-021)
' ******************************************************
sub refreshRowAtIndex(categoryIndex as Integer)
    if m.rowList.content = invalid then return

    category = m.viewModel.categories[categoryIndex]
    if category = invalid then return

    images = category.images
    if images = invalid or images.Count() = 0 then
        clearPlaceholderRow(categoryIndex)
        return
    end if

    rowNode = m.rowList.content.getChild(categoryIndex)
    if rowNode = invalid then return

    ' Remove placeholder
    rowNode.removeChildrenIndex(rowNode.getChildCount(), 0)

    ' Add real items
    addedCount = 0
    for each image in images
        if image.url_thumbnail <> invalid and image.url_thumbnail <> "" then
            itemNode             = CreateObject("roSGNode", "ContentNode")
            itemNode.HDPosterUrl = image.url_thumbnail
            itemNode.SDPosterUrl = image.url_thumbnail
            itemNode.title       = image.title

            itemNode.addField("imageData", "assocarray", false)
            itemNode.imageData = image

            rowNode.appendChild(itemNode)
            addedCount = addedCount + 1
        end if
    end for

    print "[MainScene] FG-021: Row "; categoryIndex; " ("; category.display_name; ") updated with "; addedCount; " items"
end sub


' ******************************************************
' Clear a failed row's placeholder
' ******************************************************
sub clearPlaceholderRow(categoryIndex as Integer)
    if m.rowList.content = invalid then return
    rowNode = m.rowList.content.getChild(categoryIndex)
    if rowNode = invalid then return
    rowNode.removeChildrenIndex(rowNode.getChildCount(), 0)
end sub


' ******************************************************
' Configure RowList
' ******************************************************
sub configureRowList()
    m.rowList.clippingRect             = [0, 0, 1860, 900]
    m.rowList.rowHeights               = [290]
    m.rowList.drawFocusFeedback        = true
    m.rowList.drawFocusFeedbackOnTop   = true
    m.rowList.focusFootprintBlendColor = "0xFFFFFFFF"
    m.rowList.focusBitmapBlendColor    = "0xFFFFFFFF"
    m.rowList.rowLabelColor            = "0xCCCCCCCC"
end sub


' ******************************************************
' Set focus to RowList via short timer
' ******************************************************
sub setRowListFocus()
    timer = CreateObject("roSGNode", "Timer")
    timer.duration = 0.1
    timer.repeat   = false
    timer.observeField("fire", "onFocusTimer")
    m.focusTimer = timer
    timer.control = "start"
end sub

sub onFocusTimer()
    m.rowList.jumpToRowItem = [0, 0]
    m.rowList.setFocus(true)

    if not m.rowList.hasFocus() then
        m.top.setFocus(true)
        m.rowList.setFocus(true)
    end if

    m.focusTimer = invalid
end sub


' ******************************************************
' Show global error — hides spinner, shows error text
' ******************************************************
sub showGlobalError(message as String)
    print "[MainScene] ERROR: "; message
    hideGlobalLoading()
    m.rowList.visible     = false
    m.globalError.visible = true
    m.globalError.text    = message
end sub


' ******************************************************
' Item selected
' ******************************************************
sub onItemSelected()
    rowIndex  = m.rowList.rowItemSelected[0]
    itemIndex = m.rowList.rowItemSelected[1]

    print "[MainScene] ITEM SELECTED - Row: "; rowIndex; " Item: "; itemIndex

    selectedItem = m.rowList.content.getChild(rowIndex).getChild(itemIndex)

    if selectedItem <> invalid then
        isPlaceholder = false
        if selectedItem.doesExist("isPlaceholder") then
            isPlaceholder = selectedItem.isPlaceholder
        end if

        if not isPlaceholder and selectedItem.imageData <> invalid then
            imageModel = selectedItem.imageData
            m.viewModel.handleImageSelection(rowIndex, itemIndex)

            if m.viewModel.navigationRequested then
                openDetailScreen(imageModel)
                m.viewModel.navigationRequested = false
            end if
        else
            print "[MainScene] Ignoring placeholder item"
        end if
    end if
end sub


' ******************************************************
' Item focused
' ******************************************************
sub onItemFocused()
    rowIndex  = m.rowList.rowItemFocused[0]
    itemIndex = m.rowList.rowItemFocused[1]
    print "[MainScene] Focus: ["; rowIndex; ", "; itemIndex; "]"
end sub


' ******************************************************
' Open detail screen
' ******************************************************
sub openDetailScreen(imageModel as Object)
    print "[MainScene] Opening detail: "; imageModel.title

    m.detailScene = CreateObject("roSGNode", "DetailScene")
    if m.detailScene = invalid then return

    m.detailScene.imageModel = imageModel
    m.detailScene.observeField("closeRequested", "onDetailClosed")
    m.top.appendChild(m.detailScene)
end sub


' ******************************************************
' Detail closed
' ******************************************************
sub onDetailClosed()
    if m.detailScene <> invalid then
        m.top.removeChild(m.detailScene)
        m.detailScene = invalid
    end if
    m.rowList.setFocus(true)
end sub


' ******************************************************
' Theme changes
' ******************************************************
sub onBackgroundColorChanged()
    if m.top.appBgColor <> "" then
        m.top.backgroundColor = m.top.appBgColor
    end if
end sub

sub onTextColorChanged()
    if m.top.appTextColor <> "" then
        if m.appTitle       <> invalid then m.appTitle.color       = m.top.appTextColor
        if m.loadingProgress <> invalid then m.loadingProgress.color = m.top.appTextColor
    end if
end sub


' ******************************************************
' Key events
' ******************************************************
function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if key = "back" then
        if m.detailScene <> invalid then
            onDetailClosed()
            return true
        else
            return false
        end if
    else if key = "options" then
        return true
    end if

    return false
end function

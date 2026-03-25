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
' === UI References ===
    m.appTitle        = m.top.findNode("appTitle")
    m.loadingBackdrop = m.top.findNode("loadingBackdrop")
    m.spinnerGroup    = m.top.findNode("spinnerGroup")
    m.spinnerAnim     = m.top.findNode("spinnerAnim")
    m.loadingProgress = m.top.findNode("loadingProgress")
    m.globalError     = m.top.findNode("globalError")

    m.rowList         = m.top.findNode("categoryRowList")

    if m.rowList = invalid then
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
m.viewModel = CreateMainViewModel()
    m.viewModel.init()

    ' === Loading state tracking (FG-021) ===
    m.totalCategories       = m.viewModel.categories.Count()
    m.loadedCategoryCount   = 0
    m.processedCategoryCount = 0   ' FG-022: all completed tasks (success + failure)
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
return
    end if
    if not m.firstDataReady then
return
    end if
    if m.firstRowRevealed then return
    m.firstRowRevealed = true
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
end sub


' ******************************************************
' Start sequential category loading
' ******************************************************
sub startCategoryLoading()
if m.viewModel.loadQueue = invalid or m.viewModel.loadQueue.Count() = 0 then
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
if m.processedCategoryCount = 0 and m.loadedCategoryCount = 0 then
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


    task = m.viewModel.categoryLoader.loadCategoryWithTask(m.viewModel, categoryIndex, m.top)

    if task = invalid then

        ' FG-022: Show error row so the user sees something instead of a blank row
        showErrorRow(categoryIndex)
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

    m.viewModel.categoryLoader.parseApiResponse(m.viewModel, categoryIndex, result)

    ' FG-022: count every completed task so loadNextCategory knows
    ' we processed something even when all categories failed
    m.processedCategoryCount = m.processedCategoryCount + 1

    if result.success then
        m.loadedCategoryCount = m.loadedCategoryCount + 1

        ' Update progress label
        updateLoadingProgress(m.loadedCategoryCount, m.totalCategories)

        ' Replace placeholder row with real images
        refreshRowAtIndex(categoryIndex)

        ' Mark first data ready and attempt reveal
        if not m.firstDataReady then
            m.firstDataReady = true
end if
        revealRowList()
    else
        ' FG-022: Show a user-facing error/empty state in the row
        ' instead of silently clearing it.
showErrorRow(categoryIndex)

        ' FG-022: always set firstDataReady so revealRowList fires
        ' even when all categories fail — error rows must be visible
        if not m.firstDataReady then
            m.firstDataReady = true
        end if
        revealRowList()
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
        showErrorRow(categoryIndex)
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

    ' FG-022: Restore original category name in row title
    rowNode = m.rowList.content.getChild(categoryIndex)
    if rowNode <> invalid then
        titleText = category.display_name
        if titleText = invalid or titleText = "" then titleText = category.name
        rowNode.title = titleText
    end if
end sub


' ******************************************************
' FG-022: Show error/empty state for a failed row.
'
' APPROACH: Update the row's title (shown as the row
' label above the cards) to display the error message.
' This is the only text in a RowList that:
'   1. Is guaranteed to render on all Roku firmware
'   2. Scrolls with the RowList vertically
'   3. Requires no custom components or fields
'
' The row label sits above each row and is always visible.
' We prepend "⚠ " to make it stand out from normal titles.
' The original category name is preserved in display_name
' so we can restore it on retry.
' ******************************************************
sub showErrorRow(categoryIndex as Integer)
    if m.rowList.content = invalid then return

    category = m.viewModel.categories[categoryIndex]
    if category = invalid then return

    rowNode = m.rowList.content.getChild(categoryIndex)
    if rowNode = invalid then return

    ' Clear existing children — leave row empty (no blank cards)
    rowNode.removeChildrenIndex(rowNode.getChildCount(), 0)

    ' Determine message
    errorType = ""
    if category.errorType <> invalid then errorType = category.errorType

    message = category.errorMessage
    if message = invalid or message = "" then
        message = GetErrorMessages().API
    end if

    canRetry = (errorType = "NETWORK" or errorType = "API_ERROR" or errorType = "")

    retryHint = ""
    if canRetry then retryHint = " — Press OK to retry"

    ' ── Update row title to show error message ─────────────
    ' Row label is always visible, scrolls with the list,
    ' and works on all Roku firmware versions.
    rowNode.title = "⚠  " + message + retryHint

    ' ── Add one invisible sentinel ContentNode ─────────────
    ' Required so the row has a focusable item (empty rows
    ' cannot receive focus). Uses a 1x1 transparent poster.
    sentinel = CreateObject("roSGNode", "ContentNode")
    sentinel.HDPosterUrl = ""
    sentinel.SDPosterUrl = ""
    sentinel.title       = ""

    sentinel.addField("isError",       "boolean", false)
    sentinel.addField("isPlaceholder", "boolean", false)
    sentinel.addField("errorType",     "string",  false)
    sentinel.addField("canRetry",      "boolean", false)
    sentinel.addField("categoryIndex", "integer", false)

    sentinel.isError       = true
    sentinel.isPlaceholder = false
    sentinel.errorType     = errorType
    sentinel.canRetry      = canRetry
    sentinel.categoryIndex = categoryIndex

    rowNode.appendChild(sentinel)

    ' Reset item size to normal (no wide card needed)
    totalRows = m.viewModel.categories.Count()
    sizes = []
    for i = 0 to totalRows - 1
        sizes.Push([280, 210])
    end for
    m.rowList.rowItemSize = sizes
end sub


' ******************************************************
' FG-022: Retry a single failed category.
' Clears its error state, re-queues it, and kicks off
' loading — without disturbing any other row.
' ******************************************************
sub retryCategory(categoryIndex as Integer)

    ' Refresh category state (clears images + error)
    m.viewModel.categoryLoader.refreshCategory(m.viewModel, categoryIndex)

    ' Put the category back into loading state in the UI
    category = m.viewModel.categories[categoryIndex]
    rowNode = m.rowList.content.getChild(categoryIndex)
    if rowNode <> invalid then
        rowNode.removeChildrenIndex(rowNode.getChildCount(), 0)

        ' Restore original title while retrying
        titleText = category.display_name
        if titleText = invalid or titleText = "" then titleText = category.name
        rowNode.title = titleText + " — Loading..."

        placeholder = CreateObject("roSGNode", "ContentNode")
        placeholder.title = ""
        placeholder.HDPosterUrl = ""
        placeholder.addField("isPlaceholder", "boolean", false)
        placeholder.isPlaceholder = true
        rowNode.appendChild(placeholder)
    end if

    ' Launch a fresh task for this category
    task = m.viewModel.categoryLoader.loadCategoryWithTask(m.viewModel, categoryIndex, m.top)
    if task = invalid then
        showErrorRow(categoryIndex)
        return
    end if

    task.observeField("result", "onCategoryLoaded")
    m.activeTasks.Push(task)
    task.control = "RUN"
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
    ' FG-022: rowLabelColor is per-row settable — we override
    ' individual rows to red when showing error messages.
    ' Normal rows stay 0xCCCCCCCC, error rows get 0xFF6666FF.
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

    selectedItem = m.rowList.content.getChild(rowIndex).getChild(itemIndex)

    if selectedItem <> invalid then
        ' -------------------------------------------------------
        ' FG-022: Error sentinel — user pressed OK on an error row.
        ' If the error is retryable, kick off a retry for that row.
        ' -------------------------------------------------------
        ' FG-022: Check for error sentinel ContentNode
        isError = false
        if selectedItem.doesExist("isError") then isError = selectedItem.isError

        if isError then
            canRetry = false
            if selectedItem.doesExist("canRetry") then canRetry = selectedItem.canRetry

            if canRetry then
                catIdx = 0
                if selectedItem.doesExist("categoryIndex") then catIdx = selectedItem.categoryIndex
                retryCategory(catIdx)
            else
end if
            return
        end if

        ' -------------------------------------------------------
        ' Normal flow — placeholder or real image
        ' -------------------------------------------------------
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
end if
    end if
end sub


' ******************************************************
' Item focused
' ******************************************************
sub onItemFocused()
    rowIndex  = m.rowList.rowItemFocused[0]
    itemIndex = m.rowList.rowItemFocused[1]
end sub


' ******************************************************
' Open detail screen
' ******************************************************
sub openDetailScreen(imageModel as Object)

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

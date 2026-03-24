' ******************************************************
' MainScene.brs (RowList - FINAL FIX)
' CRITICAL FIX: Fixed focus sequence to prevent invalid focus state
' UPDATED: FG-017 - Integrated DetailScene navigation
' UPDATED: FG-020 - Task-based category loading for HTTP on Task thread
' ******************************************************

sub init()
    print "========================================="
    print "[MainScene] INIT START"
    print "========================================="

    ' Get UI references
    m.appTitle      = m.top.findNode("appTitle")
    m.loadingLabel  = m.top.findNode("loadingLabel")
    m.globalError   = m.top.findNode("globalError")
    m.rowList       = m.top.findNode("categoryRowList")

    if m.rowList = invalid then
        print "[MainScene] ERROR: RowList not found!"
        return
    end if

    print "[MainScene] RowList found successfully"

    ' === CRITICAL: Set focus on Scene FIRST ===
    print "[MainScene] Setting Scene focus FIRST..."
    m.top.setFocus(true)

    ' Configure RowList BEFORE setting content
    configureRowList()

    ' Observe RowList events
    m.rowList.observeField("itemSelected", "onItemSelected")
    m.rowList.observeField("itemFocused", "onItemFocused")

    ' Observe theme changes
    m.top.observeField("appBgColor", "onBackgroundColorChanged")
    m.top.observeField("appTextColor", "onTextColorChanged")

    ' Initialize ViewModel
    print "[MainScene] Creating ViewModel..."
    m.viewModel = CreateMainViewModel()
    m.viewModel.init()
    
    ' Initialize Task management for async loading
    m.activeTasks = []
    m.loadedCategoryCount = 0
    
    ' Prepare load queue
    m.viewModel.loadAllCategories()
    
    print "[MainScene] ViewModel initialized"

    ' Initialize detail scene reference
    m.detailScene = invalid

    ' Start loading categories with Tasks
    startCategoryLoading()

    print "========================================="
    print "[MainScene] INIT COMPLETE"
    print "========================================="
end sub


' ******************************************************
' Start loading categories using Task thread
' ******************************************************
sub startCategoryLoading()
    print "[MainScene] ========================================="
    print "[MainScene] STARTING CATEGORY LOADING"
    print "[MainScene] ========================================="
    
    ' Check if we have a load queue
    if m.viewModel.loadQueue = invalid or m.viewModel.loadQueue.Count() = 0 then
        print "[MainScene] ERROR: No categories to load"
        showGlobalError("No categories configured")
        return
    end if
    
    print "[MainScene] Categories to load: "; m.viewModel.loadQueue.Count()
    
    ' Load first category (triggers sequential loading)
    loadNextCategory()
end sub


' ******************************************************
' Load next category from queue using Task
' ******************************************************
sub loadNextCategory()
    ' Check if more categories to load
    if m.viewModel.loadQueue = invalid or m.viewModel.loadQueue.Count() = 0 then
        print "[MainScene] All categories loaded!"
        
        ' Populate UI with loaded data
        if m.loadedCategoryCount > 0 then
            populateRowList()
        else
            showGlobalError("No categories could be loaded")
        end if
        
        return
    end if
    
    ' Get next category index
    categoryIndex = m.viewModel.loadQueue.Shift()
    
    print "[MainScene] Loading category index: "; categoryIndex
    
    ' Create task for this category
    task = m.viewModel.categoryLoader.loadCategoryWithTask(m.viewModel, categoryIndex, m.top)
    
    if task = invalid then
        print "[MainScene] ERROR: Failed to create task for category "; categoryIndex
        
        ' Try next category
        loadNextCategory()
        return
    end if
    
    ' Observe task completion
    task.observeField("result", "onCategoryLoaded")
    
    ' Store task reference
    m.activeTasks.Push(task)
    
    ' Start task
    task.control = "RUN"
    
    print "[MainScene] Task started for category "; categoryIndex
end sub


' ******************************************************
' Handle category data loaded from Task
' ******************************************************
sub onCategoryLoaded(event as Object)
    print "[MainScene] ========================================="
    print "[MainScene] CATEGORY LOADED CALLBACK"
    print "[MainScene] ========================================="
    
    ' Get task and result
    task = event.getRoSGNode()
    result = task.result
    categoryIndex = task.categoryIndex
    
    print "[MainScene] Category index: "; categoryIndex
    print "[MainScene] Result success: "; result.success
    
    ' Parse the API response
    m.viewModel.categoryLoader.parseApiResponse(m.viewModel, categoryIndex, result)
    
    ' Update counter
    if result.success then
        m.loadedCategoryCount = m.loadedCategoryCount + 1
        print "[MainScene] Successfully loaded "; m.loadedCategoryCount; " categories so far"
    else
        print "[MainScene] Failed to load category "; categoryIndex; ": "; result.error
    end if
    
    ' Clean up task
    task.unobserveField("result")
    
    ' Remove from active tasks
    for i = 0 to m.activeTasks.Count() - 1
        if m.activeTasks[i].id = task.id then
            m.activeTasks.Delete(i)
            exit for
        end if
    end for
    
    ' Remove task from scene graph
    m.top.removeChild(task)
    
    ' Load next category
    loadNextCategory()
end sub


' ******************************************************
' Configure RowList appearance and behavior
' ******************************************************
sub configureRowList()
    print "[MainScene] Configuring RowList..."
    
    ' === CRITICAL: Set RowList dimensions using clippingRect ===
    m.rowList.clippingRect = [0, 0, 1860, 900]
    print "[MainScene] clippingRect set to: "; m.rowList.clippingRect
    
    ' Verify bounding rect after setting clippingRect
    boundingRect = m.rowList.boundingRect()
    print "[MainScene] boundingRect after clipping: "; boundingRect
    
    m.rowList.rowHeights = [290]
    print "[MainScene]   rowHeights = [290]"
    
    ' Focus configuration
    m.rowList.drawFocusFeedback = true
    m.rowList.drawFocusFeedbackOnTop = true
    m.rowList.focusFootprintBlendColor = "0xFFFFFFFF"
    m.rowList.focusBitmapBlendColor = "0xFFFFFFFF"
    print "[MainScene]   Focus configured"
    
    ' Row label color
    m.rowList.rowLabelColor = "0xCCCCCCCC"
    
    print "[MainScene] RowList configuration complete"
end sub


' ******************************************************
' Populate RowList with category data
' ******************************************************
sub populateRowList()
    print "========================================="
    print "[MainScene] POPULATE START"
    print "========================================="

    categories = m.viewModel.categories

    ' Handle error state
    if m.viewModel.hasError then
        showGlobalError(m.viewModel.errorMessage)
        return
    end if

    ' Validate categories
    if categories = invalid or categories.count() = 0 then
        print "[MainScene] ERROR: No categories available"
        showGlobalError("No categories available")
        return
    end if

    ' Hide loading, show content
    m.loadingLabel.visible = false
    m.globalError.visible = false

    ' Create ContentNode hierarchy
    print "[MainScene] Building ContentNode tree..."
    rootContent = CreateObject("roSGNode", "ContentNode")

    totalItems = 0
    rowIndex = 0

    for each category in categories
        print "[MainScene] ----------------------------------------"
        print "[MainScene] Row "; rowIndex; ": "; category.name
        
        ' Get images for this category
        images = category.images
        
        if images = invalid then
            print "[MainScene]   ERROR: images is invalid"
            rowIndex = rowIndex + 1
            continue for
        end if
        
        if images.count() = 0 then
            print "[MainScene]   WARNING: No images in category"
            rowIndex = rowIndex + 1
            continue for
        end if
        
        print "[MainScene]   Images in category: "; images.count()
        
        ' Create row node
        rowNode = CreateObject("roSGNode", "ContentNode")
        rowNode.title = category.display_name  ' Use display_name for UI
        
        ' Add images to row
        itemIndex = 0
        for each image in images
            ' Create item node
            itemNode = CreateObject("roSGNode", "ContentNode")
            
            ' === Set poster URLs ===
            if image.url_thumbnail <> invalid and image.url_thumbnail <> "" then
                itemNode.HDPosterUrl = image.url_thumbnail
                itemNode.SDPosterUrl = image.url_thumbnail
            else
                ' Skip items with no URL
                continue for
            end if
            
            ' Set title
            if image.title <> invalid then
                itemNode.title = image.title
            else
                itemNode.title = "Untitled"
            end if
            
            ' Store full image data for detail screen
            itemNode.addField("imageData", "assocarray", false)
            itemNode.imageData = image
            
            ' Add to row
            rowNode.appendChild(itemNode)
            itemIndex = itemIndex + 1
            totalItems = totalItems + 1
        end for
        
        print "[MainScene]   Added "; itemIndex; " items to row"
        
        ' Only add row if it has items
        if rowNode.getChildCount() > 0 then
            rootContent.appendChild(rowNode)
            rowIndex = rowIndex + 1
        end if
    end for

    print "[MainScene] ----------------------------------------"
    print "[MainScene] ContentNode tree complete"
    print "[MainScene]   Total rows: "; rootContent.getChildCount()
    print "[MainScene]   Total items: "; totalItems

    ' === SET CONTENT ON ROWLIST ===
    print "[MainScene] Setting content on RowList..."
    m.rowList.content = rootContent

    if m.rowList.content = invalid then
        print "[MainScene] ERROR: Failed to set content on RowList!"
        return
    end if

    print "[MainScene] Content set successfully"
    
    ' Show the RowList
    m.rowList.visible = true
    print "[MainScene] RowList made visible"

    ' === SET FOCUS - Scene already has focus from init() ===
    print "[MainScene] Transferring focus to RowList..."
    
    ' Jump to first item BEFORE setting focus
    m.rowList.jumpToRowItem = [0, 0]
    print "[MainScene] Jumped to [0, 0]"
    
    ' Small delay to ensure RowList is fully rendered
    ' This is critical for focus to work properly
    timer = CreateObject("roSGNode", "Timer")
    timer.duration = 0.1
    timer.repeat = false
    timer.observeField("fire", "onFocusTimer")
    m.focusTimer = timer
    timer.control = "start"

    print "========================================="
    print "[MainScene] POPULATE COMPLETE"
    print "========================================="
end sub


' ******************************************************
' Focus timer callback - sets focus after RowList renders
' ******************************************************
sub onFocusTimer()
    print "[MainScene] Focus timer fired - setting RowList focus"
    
    ' Give focus to RowList
    m.rowList.setFocus(true)
    
    ' Verify focus
    if m.rowList.hasFocus() then
        print "[MainScene] SUCCESS: RowList has focus!"
        print "[MainScene] Focus position: ["; m.rowList.rowItemFocused[0]; ", "; m.rowList.rowItemFocused[1]; "]"
    else
        print "[MainScene] WARNING: RowList does NOT have focus - retrying..."
        ' Force scene focus first, then RowList
        m.top.setFocus(true)
        m.rowList.setFocus(true)
        
        if m.rowList.hasFocus() then
            print "[MainScene] SUCCESS on retry!"
        else
            print "[MainScene] FAILED: Focus could not be set"
        end if
    end if
    
    ' Clean up timer
    m.focusTimer = invalid
end sub


' ******************************************************
' Show global error
' ******************************************************
sub showGlobalError(message as String)
    print "[MainScene] ERROR: "; message
    m.loadingLabel.visible = false
    m.rowList.visible = false
    m.globalError.visible = true
    m.globalError.text = message
end sub


' ******************************************************
' Handle item selection
' ******************************************************
sub onItemSelected()
    rowIndex = m.rowList.rowItemSelected[0]
    itemIndex = m.rowList.rowItemSelected[1]
    
    print "[MainScene] ========================================="
    print "[MainScene] ITEM SELECTED"
    print "[MainScene]   Row: "; rowIndex
    print "[MainScene]   Item: "; itemIndex
    print "[MainScene] ========================================="

    ' Get selected item
    selectedItem = m.rowList.content.getChild(rowIndex).getChild(itemIndex)
    
    if selectedItem <> invalid and selectedItem.imageData <> invalid then
        imageModel = selectedItem.imageData
        print "[MainScene]   Image: "; imageModel.title
        
        ' Notify ViewModel
        m.viewModel.handleImageSelection(rowIndex, itemIndex)
        
        if m.viewModel.navigationRequested then
            openDetailScreen(imageModel)
            m.viewModel.navigationRequested = false
        end if
    else
        print "[MainScene]   ERROR: Invalid selected item"
    end if
end sub


' ******************************************************
' Handle focus changes
' ******************************************************
sub onItemFocused()
    rowIndex = m.rowList.rowItemFocused[0]
    itemIndex = m.rowList.rowItemFocused[1]
    
    print "[MainScene] Focus: ["; rowIndex; ", "; itemIndex; "]"
end sub


' ******************************************************
' Open detail screen
' ******************************************************
sub openDetailScreen(imageModel as Object)
    print "[MainScene] ========================================="
    print "[MainScene] OPENING DETAIL SCREEN"
    print "[MainScene]   Title: "; imageModel.title
    if imageModel.url_large <> invalid then
        print "[MainScene]   URL: "; imageModel.url_large
    end if
    print "[MainScene] ========================================="
    
    ' Create DetailScene component
    m.detailScene = CreateObject("roSGNode", "DetailScene")
    
    if m.detailScene = invalid then
        print "[MainScene] ERROR: Failed to create DetailScene"
        return
    end if
    
    ' Set the image model
    m.detailScene.imageModel = imageModel
    
    ' Observe close event
    m.detailScene.observeField("closeRequested", "onDetailClosed")
    
    ' Add to scene
    m.top.appendChild(m.detailScene)
    
    print "[MainScene] DetailScene created and added to scene graph"
end sub


' ******************************************************
' Handle detail close
' ******************************************************
sub onDetailClosed()
    print "[MainScene] Detail screen closed, restoring focus"
    
    ' Remove detail scene from scene graph
    if m.detailScene <> invalid then
        m.top.removeChild(m.detailScene)
        m.detailScene = invalid
    end if
    
    ' Restore focus to RowList
    m.rowList.setFocus(true)
    
    print "[MainScene] Focus restored to RowList"
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
        if m.appTitle <> invalid then m.appTitle.color = m.top.appTextColor
        if m.loadingLabel <> invalid then m.loadingLabel.color = m.top.appTextColor
    end if
end sub


' ******************************************************
' Key event handling - RowList handles navigation automatically
' ******************************************************
function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    print "[MainScene] Key: "; key

    ' Back button
    if key = "back" then
        ' If DetailScene is open, close it instead of exiting app
        if m.detailScene <> invalid then
            print "[MainScene] DetailScene is open - closing it"
            onDetailClosed()
            return true  ' Consume the event - don't exit app
        else
            print "[MainScene] Back pressed - exiting app"
            return false  ' Return false to allow system to handle (exits app)
        end if
    
    ' Options button (for future settings/menu)
    else if key = "options" then
        print "[MainScene] Options pressed"
        return true  ' Consume the event
    end if

    ' Let RowList handle all directional navigation
    return false
end function

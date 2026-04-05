' ******************************************************
' MainScene_CategoryLoader.brs
' Manages category load queue, tasks, row population,
' error rows, and retry logic.
' ******************************************************


' ******************************************************
' Build RowList with placeholder rows immediately.
' placeholderState="loading" → ImageCard shows "Loading..."
' ******************************************************
sub buildPlaceholderRowList()
    rootContent = CreateObject("roSGNode", "ContentNode")

    categoryIndex = 0
    for each category in m.viewModel.categories
        rowNode       = CreateObject("roSGNode", "ContentNode")
        rowNode.title = category.display_name

        placeholder = createPlaceholderNode(categoryIndex, "loading")
        rowNode.appendChild(placeholder)
        rootContent.appendChild(rowNode)
        categoryIndex = categoryIndex + 1
    end for

    m.rowList.content = rootContent
end sub


' ******************************************************
' Helper: build a placeholder ContentNode for a row.
'   state = "loading" → ImageCard shows "Loading..."
'   state = "retry"   → ImageCard shows RETRY + hint
' ******************************************************
function createPlaceholderNode(categoryIndex as Integer, state as String) as Object
    node = CreateObject("roSGNode", "ContentNode")
    node.addField("isPlaceholder",   "boolean", false)
    node.addField("categoryIndex",   "integer", false)
    node.addField("placeholderState","string",  false)
    node.isPlaceholder    = true
    node.categoryIndex    = categoryIndex
    node.placeholderState = state
    return node
end function


' ******************************************************
' Start loading: first 3 categories in parallel, then
' the rest sequentially as each slot becomes free.
' ******************************************************
sub startCategoryLoading()
    if m.viewModel.loadQueue = invalid or m.viewModel.loadQueue.Count() = 0 then
        showGlobalError("No categories configured")
        return
    end if

    ' Clamp batch to however many categories actually exist
    batchSize = 3
    if m.viewModel.loadQueue.Count() < batchSize then
        batchSize = m.viewModel.loadQueue.Count()
    end if
    m.initialBatchSize      = batchSize
    m.initialBatchCompleted = 0

    for i = 0 to batchSize - 1
        loadNextCategory()
    end for
end sub


' ******************************************************
' Load next category from queue
' ******************************************************
sub loadNextCategory()
    if m.viewModel.loadQueue = invalid or m.viewModel.loadQueue.Count() = 0 then
        if m.processedCategoryCount = 0 and m.loadedCategoryCount = 0 then
            showGlobalError("No categories could be loaded")
        else
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
        showErrorRow(categoryIndex)
        loadNextCategory()
        return
    end if

    task.observeField("result", "onCategoryLoaded")
    m.activeTasks.Push(task)
    task.control = "RUN"
end sub


' ******************************************************
' Category task completed
' ******************************************************
sub onCategoryLoaded(event as Object)
    task          = event.getRoSGNode()
    result        = task.result
    categoryIndex = task.categoryIndex

    m.viewModel.categoryLoader.parseApiResponse(m.viewModel, categoryIndex, result)

    m.processedCategoryCount = m.processedCategoryCount + 1

    if result.success then
        m.loadedCategoryCount = m.loadedCategoryCount + 1
        updateLoadingProgress(m.loadedCategoryCount, m.totalCategories)
        refreshRowAtIndex(categoryIndex)
    else
        showErrorRow(categoryIndex)
    end if

    ' Reveal only after the entire initial batch (first 3) has completed
    if m.initialBatchCompleted < m.initialBatchSize then
        m.initialBatchCompleted = m.initialBatchCompleted + 1
        if m.initialBatchCompleted >= m.initialBatchSize then
            m.firstDataReady = true
            revealRowList()
        end if
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
' Replace placeholder with real image items on success
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

    rowNode.removeChildrenIndex(rowNode.getChildCount(), 0)

    for each image in images
        if image.url_thumbnail <> invalid and image.url_thumbnail <> "" then
            itemNode             = CreateObject("roSGNode", "ContentNode")
            itemNode.HDPosterUrl = image.url_thumbnail
            itemNode.SDPosterUrl = image.url_thumbnail
            itemNode.title       = image.title

            itemNode.addField("imageData", "assocarray", false)
            itemNode.imageData = image

            rowNode.appendChild(itemNode)
        end if
    end for

    rowNode = m.rowList.content.getChild(categoryIndex)
    if rowNode <> invalid then
        titleText = category.display_name
        if titleText = invalid or titleText = "" then titleText = category.name
        rowNode.title = titleText
    end if
end sub


' ******************************************************
' Show retry state for a failed row.
' Replaces the row content with a retry placeholder so
' ImageCard renders the pink RETRY icon + hint text.
' Row title stays clean (category name only).
' ******************************************************
sub showErrorRow(categoryIndex as Integer)
    if m.rowList.content = invalid then return

    category = m.viewModel.categories[categoryIndex]
    if category = invalid then return

    rowNode = m.rowList.content.getChild(categoryIndex)
    if rowNode = invalid then return

    rowNode.removeChildrenIndex(rowNode.getChildCount(), 0)

    ' Restore clean row title (no error text cluttering the label)
    titleText = category.display_name
    if titleText = invalid or titleText = "" then titleText = category.name
    rowNode.title = titleText

    errorType = ""
    if category.errorType <> invalid then errorType = category.errorType

    ' EMPTY errors are not retryable — show a neutral state
    placeholderState = "retry"
    if errorType = "EMPTY" then placeholderState = "empty"

    placeholder = createPlaceholderNode(categoryIndex, placeholderState)
    rowNode.appendChild(placeholder)
end sub


' ******************************************************
' Retry a single failed category.
' Switches placeholder back to "loading" state and fires
' a new CategoryLoadTask for that row.
' ******************************************************
sub retryCategory(categoryIndex as Integer)
    m.viewModel.categoryLoader.refreshCategory(m.viewModel, categoryIndex)

    category = m.viewModel.categories[categoryIndex]
    rowNode  = m.rowList.content.getChild(categoryIndex)
    if rowNode <> invalid then
        rowNode.removeChildrenIndex(rowNode.getChildCount(), 0)

        titleText = category.display_name
        if titleText = invalid or titleText = "" then titleText = category.name
        rowNode.title = titleText

        placeholder = createPlaceholderNode(categoryIndex, "loading")
        rowNode.appendChild(placeholder)
    end if

    task = m.viewModel.categoryLoader.loadCategoryWithTask(m.viewModel, categoryIndex, m.top)
    if task = invalid then
        showErrorRow(categoryIndex)
        return
    end if

    task.observeField("result", "onCategoryLoaded")
    m.activeTasks.Push(task)
    task.control = "RUN"
end sub

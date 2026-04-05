' ******************************************************
' MainScene_RowList.brs
' RowList configuration, focus management, and item
' selection / focus event handlers.
' ******************************************************


' ******************************************************
' Configure RowList appearance and behaviour
' ******************************************************
sub configureRowList()
    m.rowList.clippingRect             = [0, 0, 1860, 900]
    m.rowList.rowHeights               = [290]
    m.rowList.drawFocusFeedback        = true
    m.rowList.drawFocusFeedbackOnTop   = true
    m.rowList.focusBitmapBlendColor    = "0xFF6B9DFF"   ' pink focus box
    m.rowList.focusFootprintBlendColor = "0x00000000"   ' transparent
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
' Item selected
' ******************************************************
sub onItemSelected()
    rowIndex  = m.rowList.rowItemSelected[0]
    itemIndex = m.rowList.rowItemSelected[1]

    selectedItem = m.rowList.content.getChild(rowIndex).getChild(itemIndex)
    if selectedItem = invalid then return

    ' Placeholder selected — only retry if in "retry" state
    isPlaceholder = false
    if selectedItem.doesExist("isPlaceholder") then isPlaceholder = selectedItem.isPlaceholder

    if isPlaceholder then
        placeholderState = "loading"
        if selectedItem.doesExist("placeholderState") then placeholderState = selectedItem.placeholderState

        if placeholderState = "retry" then
            catIdx = 0
            if selectedItem.doesExist("categoryIndex") then catIdx = selectedItem.categoryIndex
            retryCategory(catIdx)
        end if
        return
    end if

    ' Normal image card
    if selectedItem.doesExist("imageData") and selectedItem.imageData <> invalid then
        imageModel = selectedItem.imageData
        m.viewModel.handleImageSelection(rowIndex, itemIndex)

        if m.viewModel.navigationRequested then
            openDetailScreen(imageModel)
            m.viewModel.navigationRequested = false
        end if
    end if
end sub


' ******************************************************
' Item focused
' ******************************************************
sub onItemFocused()
end sub

' ******************************************************
' ErrorRowItem.brs
' FG-022: RowList item component for error/empty states.
' RowList sets itemContent automatically when this
' component is used via rowItemComponentName.
' ******************************************************

sub init()
    m.msgLabel   = m.top.findNode("msgLabel")
    m.retryLabel = m.top.findNode("retryLabel")
    m.accentBar  = m.top.findNode("accentBar")
    m.icon       = m.top.findNode("icon")
    m.focusBorder = m.top.findNode("focusBorder")

    m.top.observeField("itemContent",  "onItemContentChanged")
    m.top.observeField("itemHasFocus", "onFocusChanged")
end sub


sub onItemContentChanged()
    content = m.top.itemContent
    if content = invalid then return

    ' Read errorMessage field
    msg = ""
    if content.doesExist("errorMessage") then msg = content.errorMessage
    if msg = "" and content.title <> invalid then msg = content.title
    if msg = "" then msg = "Couldn't load images. Please try again later."
    if m.msgLabel <> invalid then m.msgLabel.text = msg

    ' Read canRetry field
    canRetry = false
    if content.doesExist("canRetry") then canRetry = content.canRetry
    if m.retryLabel <> invalid then m.retryLabel.visible = canRetry

    ' Read errorType — grey accent for EMPTY, red for errors
    errorType = ""
    if content.doesExist("errorType") then errorType = content.errorType

    if errorType = "EMPTY" then
        if m.accentBar <> invalid then m.accentBar.color = "0x666666FF"
        if m.icon      <> invalid then
            m.icon.text  = "○"
            m.icon.color = "0x888888FF"
        end if
    else
        if m.accentBar <> invalid then m.accentBar.color = "0xFF4444FF"
        if m.icon      <> invalid then
            m.icon.text  = "!"
            m.icon.color = "0xFF6666FF"
        end if
    end if
end sub


sub onFocusChanged()
    if m.focusBorder <> invalid then
        m.focusBorder.visible = m.top.itemHasFocus
    end if
end sub

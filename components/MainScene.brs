' ******************************************************
' MainScene.brs
' Main scene component for Flickr Gallery
' Manages the root UI and coordinates swimlane rows
' ******************************************************

sub init()
    print "[MainScene] Initializing..."
    
    ' Get UI element references
    m.appTitle = m.top.findNode("appTitle")
    m.loadingLabel = m.top.findNode("loadingLabel")
    m.swimlaneContainer = m.top.findNode("swimlaneContainer")
    
    ' Set up observers for configuration fields
    m.top.observeField("appBgColor", "onBackgroundColorChanged")
    m.top.observeField("appTextColor", "onTextColorChanged")
    
    ' Set initial focus
    m.top.setFocus(true)
    
    print "[MainScene] Initialization complete"
    print "[MainScene] Waiting for configuration..."
end sub

' Called when appBgColor is set from main
sub onBackgroundColorChanged()
    if m.top.appBgColor <> "" then
        m.top.backgroundColor = m.top.appBgColor
        print "[MainScene] Background color set to: "; m.top.appBgColor
    end if
end sub

' Called when appTextColor is set from main
sub onTextColorChanged()
    if m.top.appTextColor <> "" then
        ' Apply text color to UI elements
        if m.appTitle <> invalid then
            m.appTitle.color = m.top.appTextColor
        end if
        
        if m.loadingLabel <> invalid then
            m.loadingLabel.color = m.top.appTextColor
        end if
        
        print "[MainScene] Text color set to: "; m.top.appTextColor
    end if
end sub

' Handle key events (remote control input)
function onKeyEvent(key as String, press as Boolean) as Boolean
    handled = false
    
    if press then
        print "[MainScene] Key pressed: "; key
        
        if key = "back" then
            ' Allow system to handle back button (exit app)
            print "[MainScene] Back button pressed - allowing app exit"
            handled = false
        else if key = "options" then
            ' Reserved for future options menu
            print "[MainScene] Options button pressed"
            handled = true
        end if
    end if
    
    return handled
end function

' Helper function to show/hide loading indicator
sub showLoading(visible as Boolean)
    if m.loadingLabel <> invalid then
        m.loadingLabel.visible = visible
    end if
end sub

' Helper function to show swimlane container
sub showContent(visible as Boolean)
    if m.swimlaneContainer <> invalid then
        m.swimlaneContainer.visible = visible
    end if
    
    ' Hide loading when showing content
    if visible then
        showLoading(false)
    end if
end sub
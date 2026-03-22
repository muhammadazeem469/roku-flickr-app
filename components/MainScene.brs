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
    m.top.observeField("backgroundColor", "onBackgroundColorChanged")
    m.top.observeField("textColor", "onTextColorChanged")
    
    ' Set initial focus
    m.top.setFocus(true)
    
    print "[MainScene] Initialization complete"
    print "[MainScene] Waiting for configuration..."
end sub

' Called when backgroundColor is set from main
sub onBackgroundColorChanged()
    if m.top.backgroundColor <> "" then
        m.top.backgroundColor = m.top.backgroundColor
        print "[MainScene] Background color set to: "; m.top.backgroundColor
    end if
end sub

' Called when textColor is set from main
sub onTextColorChanged()
    if m.top.textColor <> "" then
        ' Apply text color to UI elements
        if m.appTitle <> invalid then
            m.appTitle.color = m.top.textColor
        end if
        
        if m.loadingLabel <> invalid then
            m.loadingLabel.color = m.top.textColor
        end if
        
        print "[MainScene] Text color set to: "; m.top.textColor
    end if
end sub

' Handle key events (remote control input)
sub onKeyEvent(key as String, press as Boolean) as Boolean
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
end sub

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
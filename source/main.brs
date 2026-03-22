' ******************************************************
' main.brs
' Application entry point for Flickr Gallery
' ******************************************************

sub Main()
    
    print "========================================="
    print "Flickr Gallery Roku Channel Starting..."
    print "Version: 1.0.0"
    print "========================================="
    
    TestImageModelSuite()
    TestCategoryModelSuite()
    TestMainViewModelSuite()
    TestDetailViewModelSuite()
    TestNetworkUtilsSuite() 
    ' Initialize screen
    print "[INIT] Creating roSGScreen..."
    screen = CreateObject("roSGScreen")
    if screen = invalid then
        print "[ERROR] Failed to create roSGScreen"
        return
    end if
    print "[INIT] roSGScreen created successfully"
    
    ' Initialize message port
    print "[INIT] Creating message port..."
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)
    print "[INIT] Message port initialized"
    
    ' Create and display main scene
    print "[INIT] Loading MainScene component..."
    scene = screen.CreateScene("MainScene")
    if scene = invalid then
        print "[ERROR] Failed to create MainScene"
        print "[ERROR] Ensure components/MainScene.xml exists"
        return
    end if
    print "[INIT] MainScene loaded successfully"
    
    ' Load UI configuration and pass to scene
    print "[INIT] Loading UI configuration..."
    uiConfig = GetUIConfig()
    scene.appBgColor = uiConfig.COLORS.BACKGROUND
    scene.appTextColor = uiConfig.COLORS.TEXT_PRIMARY
    print "[INIT] UI configuration applied to scene"
    
    print "[INIT] Displaying screen..."
    screen.show()
    print "[INIT] Screen displayed"
    
    print "[READY] Application ready - Entering event loop"
    print "========================================="
    
    ' Main event loop
    while(true)
        msg = wait(0, m.port)
        msgType = type(msg)
        
        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed() then
                print "========================================="
                print "[SHUTDOWN] Screen closed by user"
                print "[SHUTDOWN] Flickr Gallery shutting down..."
                print "========================================="
                return
            end if
        end if
    end while
end sub
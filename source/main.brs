' ******************************************************
' main.brs
' Application entry point for Flickr Gallery
' ******************************************************

sub Main()
    ' NOTE: GetApiConfig() and all TestXxxSuite() calls have been removed.
    ' They reference functions that only exist inside SceneGraph component
    ' script scope and are not available here in main.brs — calling them
    ' crashes the app before the screen is ever created.
    ' Tests should be run from a dedicated test scene, not the entry point.

    print "========================================="
    print "Flickr Gallery Roku Channel Starting..."
    print "Version: 1.0.0"
    print "========================================="

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
    port = CreateObject("roMessagePort")
    screen.setMessagePort(port)
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

    ' Pass UI configuration to scene
    scene.appBgColor   = "0x000000"
    scene.appTextColor = "0xFFFFFF"
    print "[INIT] UI configuration applied to scene"

    screen.show()
    print "[READY] Application ready - Entering event loop"
    print "========================================="

    ' Main event loop
    while true
        msg = wait(0, port)
        if type(msg) = "roSGScreenEvent" then
            if msg.isScreenClosed() then
                print "[SHUTDOWN] Screen closed - exiting"
                return
            end if
        end if
    end while
end sub

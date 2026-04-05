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

    ' Initialize screen
    screen = CreateObject("roSGScreen")
    if screen = invalid then
        return
    end if

    ' Initialize message port
    port = CreateObject("roMessagePort")
    screen.setMessagePort(port)

    ' Create and display main scene
    scene = screen.CreateScene("MainScene")
    if scene = invalid then
        return
    end if

    scene.appBgColor   = "0x000000"
    scene.appTextColor = "0xFFFFFF"
    screen.show()

    ' Main event loop
    while true
        msg = wait(0, port)
        if type(msg) = "roSGScreenEvent" then
            if msg.isScreenClosed() then
                return
            end if
        end if
    end while
end sub

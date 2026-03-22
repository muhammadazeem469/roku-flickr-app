sub Main()
    ' Initialize the application
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)
    
    ' Create main scene
    scene = screen.CreateScene("MainScene")
    screen.show()
    
    ' Main event loop
    while(true)
        msg = wait(0, m.port)
        msgType = type(msg)
        
        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed() then return
        end if
    end while
end sub
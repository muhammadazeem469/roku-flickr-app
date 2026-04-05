' ******************************************************
' MainScene_Navigation.brs
' Handles opening and closing the DetailScene with
' slide-in / slide-out animations.
' ******************************************************


' ******************************************************
' Open detail screen
' ******************************************************
sub openDetailScreen(imageModel as Object)
    m.detailScene = CreateObject("roSGNode", "DetailScene")
    if m.detailScene = invalid then return

    ' Attach to scene tree — node starts off-screen at x=1920 (set in DetailScene init)
    m.detailScene.observeField("closeRequested", "onDetailClosed")
    m.top.appendChild(m.detailScene)

    ' Store imageModel — applied AFTER slide-in completes so the render
    ' thread isn't overloaded by layout + animation running simultaneously.
    m.pendingImageModel = imageModel

    ' Slide in from the right (300ms, outCubic)
    slideInAnim = m.top.createChild("Animation")
    slideInAnim.duration     = 0.3
    slideInAnim.easeFunction = "outCubic"
    slideInInterp = slideInAnim.createChild("Vector2DFieldInterpolator")
    slideInInterp.key           = [0.0, 1.0]
    slideInInterp.keyValue      = [[1920.0, 0.0], [0.0, 0.0]]
    slideInInterp.fieldToInterp = "detailSceneNode.translation"
    slideInAnim.control = "start"

    ' Hand off imageModel once animation finishes
    slideInTimer = CreateObject("roSGNode", "Timer")
    slideInTimer.duration = 0.3
    slideInTimer.repeat   = false
    slideInTimer.observeField("fire", "onSlideInComplete")
    m.slideInTimer = slideInTimer
    slideInTimer.control = "start"
end sub


' ******************************************************
' Fired when slide-in animation duration has elapsed.
' Now safe to set imageModel — render thread is idle.
' ******************************************************
sub onSlideInComplete()
    m.slideInTimer = invalid
    if m.detailScene <> invalid and m.pendingImageModel <> invalid then
        m.detailScene.imageModel = m.pendingImageModel
        m.pendingImageModel = invalid
    end if
end sub


' ******************************************************
' Detail closed — slide out to right (300ms) then remove
' ******************************************************
sub onDetailClosed()
    if m.detailScene = invalid then return
    if m.detailCloseTimer <> invalid then return  ' already sliding out

    ' Slide out to right (300ms, inCubic)
    slideOutAnim = m.top.createChild("Animation")
    slideOutAnim.duration     = 0.3
    slideOutAnim.easeFunction = "inCubic"
    slideOutInterp = slideOutAnim.createChild("Vector2DFieldInterpolator")
    slideOutInterp.key           = [0.0, 1.0]
    slideOutInterp.keyValue      = [[0.0, 0.0], [1920.0, 0.0]]
    slideOutInterp.fieldToInterp = "detailSceneNode.translation"
    slideOutAnim.control = "start"

    detailCloseTimer = CreateObject("roSGNode", "Timer")
    detailCloseTimer.duration = 0.3
    detailCloseTimer.repeat   = false
    detailCloseTimer.observeField("fire", "onDetailSlideOutComplete")
    m.detailCloseTimer = detailCloseTimer
    detailCloseTimer.control = "start"
end sub


' ******************************************************
' Remove DetailScene after slide-out animation finishes
' ******************************************************
sub onDetailSlideOutComplete()
    m.detailCloseTimer = invalid
    if m.detailScene <> invalid then
        m.top.removeChild(m.detailScene)
        m.detailScene = invalid
    end if
    m.rowList.setFocus(true)
end sub

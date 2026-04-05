' ******************************************************
' MainScene_LoadingState.brs
' Manages the global loading overlay: spinner, backdrop,
' progress label, reveal gate, and global error state.
' ******************************************************


' ******************************************************
' Show all global loading nodes
' ******************************************************
sub showGlobalLoading()
    if m.spinnerGroup    <> invalid then m.spinnerGroup.visible    = true
    if m.loadingProgress <> invalid then m.loadingProgress.visible = true
    if m.spinnerAnim     <> invalid then m.spinnerAnim.control     = "start"

    ' Fade-in backdrop from transparent (200ms)
    if m.loadingBackdrop <> invalid then
        m.loadingBackdrop.opacity = 0.0
        m.loadingBackdrop.visible = true
        fadeInAnim = m.top.createChild("Animation")
        fadeInAnim.duration     = 0.2
        fadeInAnim.easeFunction = "linear"
        interp = fadeInAnim.createChild("FloatFieldInterpolator")
        interp.key           = [0.0, 1.0]
        interp.keyValue      = [0.0, 1.0]
        interp.fieldToInterp = "loadingBackdrop.opacity"
        fadeInAnim.control   = "start"
    end if
end sub


' ******************************************************
' Hide all global loading nodes
' ******************************************************
sub hideGlobalLoading()
    if m.loadingBackdrop <> invalid then m.loadingBackdrop.visible = false
    if m.spinnerGroup    <> invalid then m.spinnerGroup.visible    = false
    if m.loadingProgress <> invalid then m.loadingProgress.visible = false
    if m.spinnerAnim     <> invalid then m.spinnerAnim.control     = "stop"
end sub


' ******************************************************
' Update progress label text
' ******************************************************
sub updateLoadingProgress(loaded as Integer, total as Integer)
    if m.loadingProgress = invalid then return
    if loaded = 0 then
        m.loadingProgress.text = "Loading..."
    else if total > 0 then
        m.loadingProgress.text = loaded.ToStr() + " of " + total.ToStr() + " categories loaded"
    end if
end sub


' ******************************************************
' Minimum spinner timer fired — 2 seconds elapsed
' ******************************************************
sub onSpinnerMinTimeElapsed()
    m.spinnerMinTimeElapsed = true
    m.spinnerMinTimer = invalid

    if m.firstDataReady then
        revealRowList()
    end if
end sub


' ******************************************************
' Reveal RowList and fade out loading overlay.
' Gated: both spinnerMinTimeElapsed AND firstDataReady
' must be true before this does anything.
' ******************************************************
sub revealRowList()
    if not m.spinnerMinTimeElapsed then return
    if not m.firstDataReady        then return
    if m.firstRowRevealed          then return
    m.firstRowRevealed = true

    ' Show RowList immediately under the fading backdrop
    m.rowList.visible = true

    ' Hide spinner/label so they don't float over the content
    if m.spinnerGroup    <> invalid then m.spinnerGroup.visible    = false
    if m.loadingProgress <> invalid then m.loadingProgress.visible = false
    if m.spinnerAnim     <> invalid then m.spinnerAnim.control     = "stop"

    ' Fade-out backdrop (200ms), revealing content underneath
    if m.loadingBackdrop <> invalid then
        fadeOutAnim = m.top.createChild("Animation")
        fadeOutAnim.duration     = 0.2
        fadeOutAnim.easeFunction = "linear"
        interp = fadeOutAnim.createChild("FloatFieldInterpolator")
        interp.key           = [0.0, 1.0]
        interp.keyValue      = [1.0, 0.0]
        interp.fieldToInterp = "loadingBackdrop.opacity"
        fadeOutAnim.control  = "start"
    end if

    ' Timer hides the backdrop node after the fade completes
    loadingFadeTimer = CreateObject("roSGNode", "Timer")
    loadingFadeTimer.duration = 0.2
    loadingFadeTimer.repeat   = false
    loadingFadeTimer.observeField("fire", "onLoadingFadeOutComplete")
    m.loadingFadeTimer = loadingFadeTimer
    loadingFadeTimer.control = "start"

    setRowListFocus()
end sub


' ******************************************************
' Called after loading fade-out completes
' ******************************************************
sub onLoadingFadeOutComplete()
    if m.loadingBackdrop <> invalid then m.loadingBackdrop.visible = false
    m.loadingFadeTimer = invalid
end sub


' ******************************************************
' Show global error — hides spinner, shows error label
' ******************************************************
sub showGlobalError(message as String)
    hideGlobalLoading()
    m.rowList.visible     = false
    m.globalError.visible = true
    m.globalError.text    = message
end sub

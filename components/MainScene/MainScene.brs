' ******************************************************
' MainScene.brs
' Scene entry point — wires UI nodes, initializes ViewModel,
' kicks off loading. Split into focused sub-modules:
'
'   MainScene_LoadingState.brs  — spinner / backdrop / progress
'   MainScene_CategoryLoader.brs — load queue, tasks, row refresh
'   MainScene_RowList.brs        — RowList config, focus, selection
'   MainScene_Navigation.brs     — detail screen open/close/slide
' ******************************************************

sub init()
    ' === UI References ===
    m.appTitle        = m.top.findNode("appTitle")
    m.loadingBackdrop = m.top.findNode("loadingBackdrop")
    m.spinnerGroup    = m.top.findNode("spinnerGroup")
    m.spinnerAnim     = m.top.findNode("spinnerAnim")
    m.loadingProgress = m.top.findNode("loadingProgress")
    m.globalError     = m.top.findNode("globalError")
    m.rowList         = m.top.findNode("categoryRowList")

    if m.rowList = invalid then return

    ' === Focus: Scene first ===
    m.top.setFocus(true)

    ' === Configure RowList ===
    configureRowList()

    ' === Observe RowList events ===
    m.rowList.observeField("itemSelected", "onItemSelected")
    m.rowList.observeField("itemFocused",  "onItemFocused")

    ' === Theme observers ===
    m.top.observeField("appBgColor",   "onBackgroundColorChanged")
    m.top.observeField("appTextColor", "onTextColorChanged")

    ' === ViewModel init ===
    m.viewModel = CreateMainViewModel()
    m.viewModel.init()

    ' === Loading state tracking ===
    m.totalCategories        = m.viewModel.categories.Count()
    m.loadedCategoryCount    = 0
    m.processedCategoryCount = 0
    m.firstRowRevealed       = false
    m.firstDataReady         = false
    m.spinnerMinTimeElapsed  = false
    m.activeTasks            = []

    ' Initial batch: reveal only after first 3 (or all, if fewer) categories complete
    m.initialBatchSize      = 0
    m.initialBatchCompleted = 0

    ' Show spinner immediately then start 2-second minimum timer
    showGlobalLoading()
    spinnerTimer = CreateObject("roSGNode", "Timer")
    spinnerTimer.duration = 2.0
    spinnerTimer.repeat   = false
    spinnerTimer.observeField("fire", "onSpinnerMinTimeElapsed")
    m.spinnerMinTimer = spinnerTimer
    spinnerTimer.control = "start"

    ' Update progress label
    updateLoadingProgress(0, m.totalCategories)

    ' === Build placeholder RowList ===
    buildPlaceholderRowList()

    ' === Prepare load queue ===
    m.viewModel.loadAllCategories()

    ' === Detail scene reference ===
    m.detailScene      = invalid
    m.detailCloseTimer = invalid

    ' === Splash overlay ===
    ' SplashScene sits on top while content loads behind it.
    ' When the animation finishes it sets done=true and we
    ' remove it, revealing whatever loading state is ready.
    m.splashOverlay = m.top.findNode("splashOverlay")
    if m.splashOverlay <> invalid then
        m.splashOverlay.observeField("done", "onSplashDone")
    end if

    ' === Start loading ===
    startCategoryLoading()
end sub


' ******************************************************
' Splash overlay finished — remove it from the tree and
' give focus to the RowList (or keep scene focus if still
' loading so the spinner stays interactive).
' ******************************************************
sub onSplashDone()
    if m.splashOverlay = invalid then return
    m.top.removeChild(m.splashOverlay)
    m.splashOverlay = invalid

    ' Hand focus to content if already revealed, else scene
    if m.rowList <> invalid and m.rowList.visible then
        m.rowList.setFocus(true)
    else
        m.top.setFocus(true)
    end if
end sub


' ******************************************************
' Theme changes
' ******************************************************
sub onBackgroundColorChanged()
    if m.top.appBgColor <> "" then
        m.top.backgroundColor = m.top.appBgColor
    end if
end sub

sub onTextColorChanged()
    if m.top.appTextColor <> "" then
        if m.appTitle        <> invalid then m.appTitle.color        = m.top.appTextColor
        if m.loadingProgress <> invalid then m.loadingProgress.color = m.top.appTextColor
    end if
end sub


' ******************************************************
' Key events
' ******************************************************
function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    ' Any key press during splash skips it immediately
    if m.splashOverlay <> invalid then
        m.splashOverlay.callFunc("skipSplash")
        return true
    end if

    if key = "back" then
        if m.detailScene <> invalid then
            onDetailClosed()
            return true
        else
            return false
        end if
    else if key = "options" then
        return true
    end if

    return false
end function

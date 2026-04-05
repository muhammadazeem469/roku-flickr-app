' ******************************************************
' SplashScene.brs — Rounded F logo "write" reveal
'
' F is built from three overlapping rounded Rectangles
' (fTopBar, fStem, fMidBar). A background-coloured mask
' sits on top of each stroke and is slid away by BRS in
' writing order, giving a pen-on-paper reveal effect.
'
' WRITE ORDER (mask slide direction):
'   maskTopBar → slides LEFT  260px  (right end visible first)
'   maskStem   → slides DOWN  460px  (top visible first, grows down)
'   maskMidBar → slides LEFT  185px  (right end visible first)
'
' FULL PIPELINE:
'   t=0.00  maskTopBar starts  (0.35s, outCubic)
'   t=0.35  maskStem   starts  (0.60s, outCubic)
'   t=0.55  maskMidBar starts  (0.28s, outCubic)
'   t=1.00  write done → FLICKR fades in + rises (0.35s)
'   t=1.35  hold (0.90s)
'   t=2.25  blossom swell 0→0.22 (0.30s)
'   t=2.55  blossom recede 0.22→0 (0.30s)
'   t=2.85  hold (0.50s)
'   t=3.35  fade to black (0.60s) → done = true
'
' GUARD:
'   m.done is set true on skipSplash() and onFadeOutDone().
'   Every deferred callback checks it first — no phase can
'   restart after the sequence has ended.
' ******************************************************

sub init()
    m.logoText       = m.top.findNode("logoText")
    m.blossomOverlay = m.top.findNode("blossomOverlay")
    m.splashFadeOut  = m.top.findNode("splashFadeOut")
    m.done           = false
    revealF()
end sub


' ══════════════════════════════════════════════════════
' Phase 1 — write the F  (three sequential mask slides)
'
' maskTopBar : [-130,-230] → [-390,-230]  slides LEFT  260px
' maskStem   : [-130,-230] → [-130, 230]  slides DOWN  460px
' maskMidBar : [-130, -45] → [-315, -45]  slides LEFT  185px
' ══════════════════════════════════════════════════════
sub revealF()
    ' Stroke A — top bar, starts immediately
    m.revealTopBar = buildVec2Anim("maskTopBar.translation", [-130.0, -230.0], [-390.0, -230.0], 0.35, "outCubic")
    m.revealTopBar.control = "start"

    ' Stroke B — stem, starts when top bar finishes (t=0.35s)
    m.t_stem = startTimer(0.35, "onStartStemReveal")

    ' Stroke C — mid bar, starts when stem passes mid level (t=0.55s)
    m.t_midbar = startTimer(0.55, "onStartMidBarReveal")

    ' Write phase complete at t=1.0s (stem finishes at 0.35+0.60=0.95s)
    m.t_writeDone = startTimer(1.0, "onRevealDone")
end sub

sub onStartStemReveal()
    if m.done then return
    m.t_stem = invalid
    m.revealStem = buildVec2Anim("maskStem.translation", [-130.0, -230.0], [-130.0, 230.0], 0.60, "outCubic")
    m.revealStem.control = "start"
end sub

sub onStartMidBarReveal()
    if m.done then return
    m.t_midbar = invalid
    m.revealMidBar = buildVec2Anim("maskMidBar.translation", [-130.0, -45.0], [-315.0, -45.0], 0.28, "outCubic")
    m.revealMidBar.control = "start"
end sub

sub onRevealDone()
    if m.done then return
    m.t_writeDone = invalid
    fadeInText()
end sub


' ══════════════════════════════════════════════════════
' Phase 2 — "F  L  I  C  K  R" fades in with subtle rise
'   opacity  0 → 1  over 0.35s
'   translation y: 793 → 775  over 0.35s  (18px upward)
' ══════════════════════════════════════════════════════
sub fadeInText()
    m.textAnim = buildFloatAnim("logoText.opacity", 0.0, 1.0, 0.35, "linear")
    m.textAnim.observeField("state", "onTextDone")
    m.textAnim.control = "start"

    m.textRiseAnim = buildVec2Anim("logoText.translation", [710.0, 793.0], [710.0, 775.0], 0.35, "outCubic")
    m.textRiseAnim.control = "start"
end sub

sub onTextDone()
    if m.done then return
    if m.textAnim = invalid then return
    if m.textAnim.state <> "stopped" then return
    m.textAnim = invalid
    m.t2 = startTimer(0.9, "onHold1Done")
end sub


' ══════════════════════════════════════════════════════
' Phase 3 + 4 + 5 — hold → blossom swell → blossom recede
' ══════════════════════════════════════════════════════
sub onHold1Done()
    if m.done then return
    m.t2 = invalid
    m.blossomUp = buildFloatAnim("blossomOverlay.opacity", 0.0, 0.22, 0.3, "outCubic")
    m.blossomUp.observeField("state", "onBlossomUpDone")
    m.blossomUp.control = "start"
end sub

sub onBlossomUpDone()
    if m.done then return
    if m.blossomUp = invalid then return
    if m.blossomUp.state <> "stopped" then return
    m.blossomUp = invalid
    m.blossomDown = buildFloatAnim("blossomOverlay.opacity", 0.22, 0.0, 0.3, "inCubic")
    m.blossomDown.observeField("state", "onBlossomDownDone")
    m.blossomDown.control = "start"
end sub

sub onBlossomDownDone()
    if m.done then return
    if m.blossomDown = invalid then return
    if m.blossomDown.state <> "stopped" then return
    m.blossomDown = invalid
    m.t3 = startTimer(0.5, "onHold2Done")
end sub


' ══════════════════════════════════════════════════════
' Phase 6 + 7 — hold → fade to black → signal done
' ══════════════════════════════════════════════════════
sub onHold2Done()
    if m.done then return
    m.t3 = invalid
    m.outAnim = buildFloatAnim("splashFadeOut.opacity", 0.0, 1.0, 0.6, "linear")
    m.outAnim.observeField("state", "onFadeOutDone")
    m.outAnim.control = "start"
end sub

sub onFadeOutDone()
    if m.done then return
    if m.outAnim = invalid then return
    if m.outAnim.state <> "stopped" then return
    m.outAnim = invalid
    m.done    = true
    m.top.done = true
end sub


' ══════════════════════════════════════════════════════
' Skip — called by MainScene on any key press
'
' Set m.done = true FIRST so every in-flight callback
' becomes a no-op, then stop all timers and animations.
' ══════════════════════════════════════════════════════
sub skipSplash()
    m.done = true

    ' Timers
    stopTimer(m.t_stem)
    stopTimer(m.t_midbar)
    stopTimer(m.t_writeDone)
    stopTimer(m.t2)
    stopTimer(m.t3)

    ' Write-reveal animations
    stopAnim(m.revealTopBar)
    stopAnim(m.revealStem)
    stopAnim(m.revealMidBar)

    ' Text animations
    stopAnim(m.textAnim)
    stopAnim(m.textRiseAnim)

    ' Blossom + fade-out
    stopAnim(m.blossomUp)
    stopAnim(m.blossomDown)
    stopAnim(m.outAnim)

    m.top.done = true
end sub


' ══════════════════════════════════════════════════════
' Helpers
' ══════════════════════════════════════════════════════
function buildFloatAnim(field as String, fromVal as Float, toVal as Float, dur as Float, ease as String) as Object
    anim           = m.top.createChild("Animation")
    anim.duration  = dur
    anim.easeFunction = ease
    interp = anim.createChild("FloatFieldInterpolator")
    interp.key           = [0.0, 1.0]
    interp.keyValue      = [fromVal, toVal]
    interp.fieldToInterp = field
    return anim
end function

function buildVec2Anim(field as String, fromVal as Object, toVal as Object, dur as Float, ease as String) as Object
    anim           = m.top.createChild("Animation")
    anim.duration  = dur
    anim.easeFunction = ease
    interp = anim.createChild("Vector2DFieldInterpolator")
    interp.key           = [0.0, 1.0]
    interp.keyValue      = [fromVal, toVal]
    interp.fieldToInterp = field
    return anim
end function

function startTimer(dur as Float, callback as String) as Object
    t          = CreateObject("roSGNode", "Timer")
    t.duration = dur
    t.repeat   = false
    t.observeField("fire", callback)
    t.control  = "start"
    return t
end function

sub stopAnim(a as Dynamic)
    if a <> invalid then a.control = "stop"
end sub

sub stopTimer(t as Dynamic)
    if t <> invalid then t.control = "stop"
end sub

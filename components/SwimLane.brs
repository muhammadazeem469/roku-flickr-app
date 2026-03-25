' ******************************************************
' SwimLane.brs
' Horizontal scrolling row of ImageCard components.
' Driven entirely by a CategoryModel assocarray.
' Ticket: FG-014
' TRULY FINAL: Manual left/right handling + proper scroll
' ******************************************************

sub init()
    ' Layout constants
    m.CARD_WIDTH   = 400
    m.CARD_HEIGHT  = 300
    m.TITLE_HEIGHT = 50
    m.LABEL_HEIGHT = 40

    ' Screen/viewport dimensions
    m.SCREEN_WIDTH   = 1920
    m.VIEWPORT_WIDTH = 1800

    ' Lazy loading — how many cards to preload beyond the visible window
    m.LOAD_AHEAD  = 3
    m.LOAD_BEHIND = 1

    ' Node references
    m.categoryTitle     = m.top.findNode("categoryTitle")
    m.cardClipContainer = m.top.findNode("cardClipContainer")
    m.cardContainer     = m.top.findNode("cardContainer")
    m.loadingIndicator  = m.top.findNode("loadingIndicator")
    m.emptyMessage      = m.top.findNode("emptyMessage")
    m.errorMessage      = m.top.findNode("errorMessage")

    ' Internal state
    m.cards         = []
    m.imageModels   = []   ' source data kept separate from card nodes
    m.loadedCards   = {}   ' tracks which indices have had imageModel set
    m.focusedIndex  = 0
    m.targetScrollX = 0    ' intended scroll target (may differ from actual while animating)
    m.scrollAnim    = invalid

    ' Observers
    m.top.observeField("categoryModel", "onCategoryModelChanged")
    m.top.observeField("cardSpacing",   "onCardSpacingChanged")
end sub


' ******************************************************
' Called when categoryModel is set or updated
' ******************************************************
sub onCategoryModelChanged()
    category = m.top.categoryModel

    if category = invalid then
return
    end if

    ' Use display_name for the visible title, fall back to name
    titleText = category.display_name
    if titleText = invalid or titleText = "" then titleText = category.name
    m.categoryTitle.text = titleText

    if category.isLoading then
        showLoading()
        return
    end if

    if category.hasError then
        showError(category.errorMessage)
        return
    end if

    if category.images = invalid or category.images.count() = 0 then
        showEmpty()
    else
        renderCards(category.images)
    end if
end sub


sub onCardSpacingChanged()
    m.cardContainer.itemSpacings = [m.top.cardSpacing]
end sub


' ******************************************************
' Build ImageCard nodes for each image
' ******************************************************
sub renderCards(images as Object)
    m.loadingIndicator.visible = false
    m.emptyMessage.visible     = false
    m.errorMessage.visible     = false

    m.cardContainer.removeChildrenIndex(m.cardContainer.getChildCount(), 0)
    m.cards       = []
    m.imageModels = images
    m.loadedCards = {}

    m.cardContainer.itemSpacings = [m.top.cardSpacing]

    ' Create card shells — imageModel is NOT set here.
    ' updateVisibleCards() will set it only for cards near the viewport,
    ' preventing all 20 thumbnails from downloading simultaneously.
    for each imageModel in images
        card = m.cardContainer.createChild("ImageCard")
        if card <> invalid then
            card.cardWidth  = m.CARD_WIDTH
            card.cardHeight = m.CARD_HEIGHT
            card.showTitle  = true
            card.observeField("itemSelected", "onCardSelected")
            m.cards.push(card)
        end if
    end for

    if m.cards.Count() > 0 then
        m.focusedIndex         = 0
        m.top.focusedCardIndex = 0
        m.targetScrollX        = 0
        m.cardContainer.translation = [0, 0]

        ' Kick off loading for initially visible cards
        updateVisibleCards()
    end if
end sub


' ******************************************************
' Set imageModel only for cards within the load window
' (visible range + LOAD_BEHIND behind + LOAD_AHEAD ahead).
' Cards outside the window stay as placeholder shells.
' ******************************************************
sub updateVisibleCards()
    if m.cards.Count() = 0 then return

    cardStep = m.CARD_WIDTH + m.top.cardSpacing

    ' Derive visible range from the intended scroll target
    firstVisible = Int(-m.targetScrollX / cardStep)
    lastVisible  = Int((-m.targetScrollX + m.VIEWPORT_WIDTH) / cardStep)

    if firstVisible < 0 then firstVisible = 0
    if lastVisible >= m.cards.Count() then lastVisible = m.cards.Count() - 1

    ' Expand for pre-loading
    loadFrom = firstVisible - m.LOAD_BEHIND
    loadTo   = lastVisible  + m.LOAD_AHEAD
    if loadFrom < 0 then loadFrom = 0
    if loadTo >= m.cards.Count() then loadTo = m.cards.Count() - 1

    ' Set imageModel once per card — never cleared (Roku's Poster caches by URL)
    for i = loadFrom to loadTo
        key = i.ToStr()
        if not m.loadedCards.DoesExist(key) then
            m.cards[i].imageModel = m.imageModels[i]
            m.loadedCards[key]    = true
        end if
    end for
end sub


sub showLoading()
m.loadingIndicator.visible = true
    m.emptyMessage.visible     = false
    m.errorMessage.visible     = false
    m.cardContainer.removeChildrenIndex(m.cardContainer.getChildCount(), 0)
    m.cards = []
end sub


sub showEmpty()
m.loadingIndicator.visible = false
    m.emptyMessage.visible     = true
    m.errorMessage.visible     = false
    m.cardContainer.removeChildrenIndex(m.cardContainer.getChildCount(), 0)
    m.cards = []
end sub


sub showError(message as String)
    m.loadingIndicator.visible = false
    m.emptyMessage.visible     = false
    m.errorMessage.visible     = true
    m.errorMessage.text        = message
    m.cardContainer.removeChildrenIndex(m.cardContainer.getChildCount(), 0)
    m.cards = []
end sub


sub onCardSelected()
    for each card in m.cards
        if card.itemSelected <> invalid then
            m.top.itemSelected = card.itemSelected
            return
        end if
    end for
end sub


' ******************************************************
' Set focus to a specific card (called from MainScene)
' ******************************************************
sub setFocusToCard(index as Integer)
    if m.cards.count() = 0 then 
return
    end if
    
    if index < 0 then index = 0
    if index >= m.cards.count() then index = m.cards.count() - 1

    ' Remove focus from previously focused card
    if m.focusedIndex >= 0 and m.focusedIndex < m.cards.count() then
        if m.focusedIndex <> index then
            m.cards[m.focusedIndex].setFocus(false)
        end if
    end if

    ' Update internal tracking
    m.focusedIndex         = index
    m.top.focusedCardIndex = index
    
    ' Set focus to the new card
    m.cards[index].setFocus(true)
    
    ' Scroll to make this card visible
    scrollToCard(index)
end sub


' ******************************************************
' Scroll the card container to keep the focused card visible
' ******************************************************
sub scrollToCard(cardIndex as Integer)
    if cardIndex < 0 or cardIndex >= m.cards.Count() then return

    spacing      = m.top.cardSpacing
    cardPositionX = (m.CARD_WIDTH + spacing) * cardIndex

    ' Use targetScrollX (the intended destination) rather than the actual
    ' translation, which may still be mid-animation from the previous keypress.
    currentX    = m.targetScrollX
    cardScreenX = cardPositionX + currentX

    leftMargin  = 50
    rightMargin = 150
    safeLeft    = leftMargin
    safeRight   = m.VIEWPORT_WIDTH - m.CARD_WIDTH - rightMargin

    targetX = currentX

    if cardScreenX > safeRight then targetX = safeRight - cardPositionX
    if cardScreenX < safeLeft  then targetX = safeLeft  - cardPositionX

    if targetX > 0 then targetX = 0

    totalWidth = (m.CARD_WIDTH + spacing) * m.cards.Count()
    minX = m.VIEWPORT_WIDTH - totalWidth
    if minX > 0 then minX = 0
    if targetX < minX then targetX = minX

    if targetX <> m.targetScrollX then
        m.targetScrollX = targetX
        animateScrollTo(targetX)
    end if

    ' Load images for cards now in (or entering) the visible window
    updateVisibleCards()
end sub


' ******************************************************
' Smooth-scroll the card container to targetX.
' Stops and replaces any in-progress scroll animation so
' rapid keypresses chain smoothly rather than queuing up.
' ******************************************************
sub animateScrollTo(targetX as Float)
    ' Stop and discard any running scroll animation
    if m.scrollAnim <> invalid then
        m.scrollAnim.control = "stop"
        m.top.removeChild(m.scrollAnim)
        m.scrollAnim = invalid
    end if

    startX = m.cardContainer.translation[0]

    ' Skip animation for sub-pixel moves
    if Abs(targetX - startX) < 2 then
        m.cardContainer.translation = [targetX, 0]
        return
    end if

    anim              = m.top.createChild("Animation")
    anim.duration     = 0.2
    anim.easeFunction = "outCubic"

    interp               = anim.createChild("Vector2DFieldInterpolator")
    interp.key           = [0.0, 1.0]
    interp.keyValue      = [[startX, 0.0], [targetX, 0.0]]
    interp.fieldToInterp = "cardContainer.translation"

    m.scrollAnim = anim
    anim.control = "start"
end sub


' ******************************************************
' Handle remote control key events
' ******************************************************
function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if m.cards.count() = 0 then return false

    if key = "right" then
        newIndex = m.focusedIndex + 1
        if newIndex < m.cards.count() then
            setFocusToCard(newIndex)
        else
        end if
        return true

    else if key = "left" then
        newIndex = m.focusedIndex - 1
        if newIndex >= 0 then
            setFocusToCard(newIndex)
        else
        end if
        return true

    else if key = "OK" then
        if m.focusedIndex >= 0 and m.focusedIndex < m.cards.count() then
            focusedCard = m.cards[m.focusedIndex]
            if focusedCard <> invalid and focusedCard.imageModel <> invalid then
                m.top.itemSelected = focusedCard.imageModel
                return true
            end if
        end if
    end if

    ' Return false for up/down so MainScene can handle lane switching
    return false
end function

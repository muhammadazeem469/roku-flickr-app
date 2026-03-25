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
    m.SCREEN_WIDTH = 1920
    m.VIEWPORT_WIDTH = 1800  ' Visible card area width

    ' Node references
    m.categoryTitle     = m.top.findNode("categoryTitle")
    m.cardClipContainer = m.top.findNode("cardClipContainer")
    m.cardContainer     = m.top.findNode("cardContainer")
    m.loadingIndicator  = m.top.findNode("loadingIndicator")
    m.emptyMessage      = m.top.findNode("emptyMessage")
    m.errorMessage      = m.top.findNode("errorMessage")

    ' Internal state
    m.cards        = []
    m.focusedIndex = 0

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
    m.cards = []

    m.cardContainer.itemSpacings = [m.top.cardSpacing]

    for each imageModel in images
        card = m.cardContainer.createChild("ImageCard")
        if card <> invalid then
            card.cardWidth  = m.CARD_WIDTH
            card.cardHeight = m.CARD_HEIGHT
            card.showTitle  = true
            card.imageModel = imageModel
            card.observeField("itemSelected", "onCardSelected")
            m.cards.push(card)
        else
end if
    end for

    if m.cards.count() > 0 then
        m.focusedIndex         = 0
        m.top.focusedCardIndex = 0
        
        ' Reset scroll position to show first cards
        m.cardContainer.translation = [0, 0]
    end if
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
    if cardIndex < 0 or cardIndex >= m.cards.count() then 
        return
    end if

    ' Calculate the X position of the focused card
    spacing = m.top.cardSpacing
    cardPositionX = (m.CARD_WIDTH + spacing) * cardIndex
    
    ' Get current container translation
    currentTranslation = m.cardContainer.translation
    currentX = currentTranslation[0]
    
    ' Calculate where this card appears on screen
    cardScreenX = cardPositionX + currentX
    
    ' Define safe viewing zone
    leftMargin = 50
    rightMargin = 150
    
    safeLeft = leftMargin
    safeRight = m.VIEWPORT_WIDTH - m.CARD_WIDTH - rightMargin
    
    ' Determine target scroll position
    targetX = currentX
    
    ' Card is too far right - scroll container left (negative X)
    if cardScreenX > safeRight then
        targetX = safeRight - cardPositionX
    end if
    
    ' Card is too far left - scroll container right (positive X)
    if cardScreenX < safeLeft then
        targetX = safeLeft - cardPositionX
    end if
    
    ' Don't scroll past the beginning (first card visible)
    if targetX > 0 then
        targetX = 0
    end if
    
    ' Don't scroll past the end (last card visible)
    totalWidth = (m.CARD_WIDTH + spacing) * m.cards.count()
    minX = m.VIEWPORT_WIDTH - totalWidth
    if minX > 0 then minX = 0  ' Content narrower than viewport
    if targetX < minX then
        targetX = minX
    end if
    
    ' Apply the scroll
    if targetX <> currentX then
        m.cardContainer.translation = [targetX, 0]
    else
end if
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

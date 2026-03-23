' ******************************************************
' SwimLane.brs
' Horizontal scrolling row of ImageCard components.
' Driven entirely by a CategoryModel assocarray.
' Ticket: FG-014
' ******************************************************

' ---- Layout constants (mirrors UIConfig.SWIMLANE) ----

' space reserved above the card container

sub init()
    print "[SwimLane] Initializing..."
    CARD_WIDTH      = 400
    CARD_HEIGHT     = 300
    TITLE_HEIGHT    = 50    
    LABEL_HEIGHT    = 40

    ' Node references
    m.categoryTitle   = m.top.findNode("categoryTitle")
    m.cardContainer   = m.top.findNode("cardContainer")
    m.loadingIndicator = m.top.findNode("loadingIndicator")
    m.emptyMessage    = m.top.findNode("emptyMessage")
    m.errorMessage    = m.top.findNode("errorMessage")

    ' Internal state
    m.cards           = []      ' holds references to created ImageCard nodes
    m.focusedIndex    = 0

    ' Observers
    m.top.observeField("categoryModel", "onCategoryModelChanged")
    m.top.observeField("cardSpacing",   "onCardSpacingChanged")

    print "[SwimLane] Initialization complete"
end sub


' ******************************************************
' Called when categoryModel is set or updated
' ******************************************************
sub onCategoryModelChanged()
    category = m.top.categoryModel

    if category = invalid then
        print "[SwimLane] No category model"
        return
    end if

    print "[SwimLane] Category model received: "; category.name

    ' Update title
    m.categoryTitle.text = category.name

    ' Reflect loading state
    if category.isLoading then
        showLoading()
        return
    end if

    ' Reflect error state
    if category.hasError then
        showError(category.errorMessage)
        return
    end if

    ' Render images
    if category.images = invalid or category.images.count() = 0 then
        showEmpty()
    else
        renderCards(category.images)
    end if
end sub


' ******************************************************
' Called when cardSpacing changes - rebuild layout
' ******************************************************
sub onCardSpacingChanged()
    spacing = m.top.cardSpacing
    m.cardContainer.itemSpacings = [spacing]
end sub


' ******************************************************
' Build ImageCard nodes for each image in the array
' ******************************************************
sub renderCards(images as Object)
    print "[SwimLane] Rendering "; images.count(); " cards"

    ' Hide status nodes
    m.loadingIndicator.visible = false
    m.emptyMessage.visible     = false
    m.errorMessage.visible     = false

    ' Remove existing cards
    m.cardContainer.removeChildrenIndex(m.cardContainer.getChildCount(), 0)
    m.cards = []

    ' Apply spacing from field
    m.cardContainer.itemSpacings = [m.top.cardSpacing]

    ' Create one ImageCard per image
    for each imageModel in images
        card = m.cardContainer.createChild("ImageCard")
        if card <> invalid then
            card.cardWidth   = m.CARD_WIDTH
            card.cardHeight  = m.CARD_HEIGHT
            card.showTitle   = true
            card.imageModel  = imageModel

            ' Observe selection from each card
            card.observeField("itemSelected", "onCardSelected")

            m.cards.push(card)
        else
            print "[SwimLane] WARNING: Failed to create ImageCard"
        end if
    end for

    ' Focus first card if we have any
    if m.cards.count() > 0 then
        m.focusedIndex        = 0
        m.top.focusedCardIndex = 0
    end if

    print "[SwimLane] Rendered "; m.cards.count(); " cards"
end sub


' ******************************************************
' Show loading state
' ******************************************************
sub showLoading()
    print "[SwimLane] Showing loading state"
    m.loadingIndicator.visible = true
    m.emptyMessage.visible     = false
    m.errorMessage.visible     = false
    m.cardContainer.removeChildrenIndex(m.cardContainer.getChildCount(), 0)
    m.cards = []
end sub


' ******************************************************
' Show empty state
' ******************************************************
sub showEmpty()
    print "[SwimLane] No images to display"
    m.loadingIndicator.visible = false
    m.emptyMessage.visible     = true
    m.errorMessage.visible     = false
    m.cardContainer.removeChildrenIndex(m.cardContainer.getChildCount(), 0)
    m.cards = []
end sub


' ******************************************************
' Show error state
' ******************************************************
sub showError(message as String)
    print "[SwimLane] Error: "; message
    m.loadingIndicator.visible = false
    m.emptyMessage.visible     = false
    m.errorMessage.visible     = true
    m.errorMessage.text        = message
    m.cardContainer.removeChildrenIndex(m.cardContainer.getChildCount(), 0)
    m.cards = []
end sub


' ******************************************************
' Called when a card fires itemSelected
' Bubble up to parent (MainScene / ViewModel)
' ******************************************************
sub onCardSelected()
    ' Find which card fired by checking all cards
    for each card in m.cards
        if card.itemSelected <> invalid then
            print "[SwimLane] Card selected: "; card.itemSelected.id
            m.top.itemSelected = card.itemSelected
            return
        end if
    end for
end sub


' ******************************************************
' Focus management — called by parent when this
' swimlane receives focus
' ******************************************************
sub setFocusToCard(index as Integer)
    if m.cards.count() = 0 then return

    ' Clamp index
    if index < 0 then index = 0
    if index >= m.cards.count() then index = m.cards.count() - 1

    m.focusedIndex         = index
    m.top.focusedCardIndex = index
    m.cards[index].setFocus(true)

    print "[SwimLane] Focus set to card "; index
end sub


' ******************************************************
' Handle remote key events
' ******************************************************
function onKeyEvent(key as String, press as Boolean) as Boolean
    handled = false

    if not press then return false
    if m.cards.count() = 0 then return false

    print "[SwimLane] Key: "; key

    if key = "right" then
        newIndex = m.focusedIndex + 1
        if newIndex < m.cards.count() then
            setFocusToCard(newIndex)
            handled = true
        end if
        ' If at last card, let parent handle (move to next swimlane)

    else if key = "left" then
        newIndex = m.focusedIndex - 1
        if newIndex >= 0 then
            setFocusToCard(newIndex)
            handled = true
        end if
        ' If at first card, let parent handle (move to previous swimlane)

    else if key = "OK" then
        ' Trigger selection on the focused card
        if m.focusedIndex < m.cards.count() then
            focusedCard = m.cards[m.focusedIndex]
            if focusedCard.imageModel <> invalid then
                print "[SwimLane] OK on card "; m.focusedIndex
                m.top.itemSelected = focusedCard.imageModel
                handled = true
            end if
        end if
    end if

    ' Up / Down are intentionally NOT handled here —
    ' the parent (MainScene) manages vertical swimlane navigation

    return handled
end function

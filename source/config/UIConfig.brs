

function GetUIConfig() as Object
    return {
        ' ===== Color Scheme =====
        COLORS: {
            BACKGROUND: "0x000000"          ' Black
            PRIMARY: "0x0099FF"             ' Blue
            SECONDARY: "0x555555"           ' Dark Gray
            TEXT_PRIMARY: "0xFFFFFF"        ' White
            TEXT_SECONDARY: "0xCCCCCC"      ' Light Gray
            FOCUS_RING: "0x00FF00"          ' Green
            ERROR: "0xFF0000"               ' Red
            SUCCESS: "0x00AA00"             ' Dark Green
            OVERLAY: "0x000000CC"           ' Semi-transparent black
        }
        
        ' ===== Grid Layout Configuration =====
        GRID: {
            COLUMNS: 4
            ROWS: 3
            ITEM_WIDTH: 400
            ITEM_HEIGHT: 300
            SPACING_H: 20       ' Horizontal spacing
            SPACING_V: 20       ' Vertical spacing
            PADDING: 40         ' Edge padding
        }
        
        ' ===== Swimlane Layout Configuration =====
        SWIMLANE: {
            HEIGHT: 350
            ITEM_WIDTH: 400
            ITEM_HEIGHT: 300
            SPACING: 20
            PADDING_LEFT: 60
            PADDING_TOP: 100
            ROW_SPACING: 40     ' Space between swimlane rows
        }
        
        ' ===== Detail Screen Layout =====
        DETAIL: {
            IMAGE_WIDTH: 1200
            IMAGE_HEIGHT: 800
            INFO_PANEL_WIDTH: 600
            PADDING: 60
        }
        
        ' ===== Typography =====
        FONTS: {
            TITLE: "font:LargeBoldSystemFont"
            SUBTITLE: "font:MediumBoldSystemFont"
            BODY: "font:MediumSystemFont"
            CAPTION: "font:SmallSystemFont"
        }
        
        ' ===== Animation Timing =====
        ANIMATION: {
            FAST: 0.2
            NORMAL: 0.3
            SLOW: 0.5
        }
        
        ' ===== Pagination Settings =====
        PAGINATION: {
            ITEMS_PER_PAGE: 20
            MAX_PAGES: 10
            PRELOAD_THRESHOLD: 5    ' Load more when 5 items from end
        }
    }
end function
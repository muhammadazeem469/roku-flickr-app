

function GetUIConfig() as Object
    return {
        ' ===== Color Scheme =====
        COLORS: {
            BACKGROUND: "0x000000"          ' Black
            PRIMARY: "0xFF6B9D"             ' Pink
            SECONDARY: "0x4A90E2"           ' Blue
            TEXT_PRIMARY: "0xFFFFFF"        ' White
            TEXT_SECONDARY: "0xCCCCCC"      ' Light Gray
            FOCUS_RING: "0xFF6B9D"          ' Pink (matches primary)
            ERROR: "0xFF0000"               ' Red
            SUCCESS: "0x00AA00"             ' Dark Green
            OVERLAY: "0x000000CC"           ' Semi-transparent black
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
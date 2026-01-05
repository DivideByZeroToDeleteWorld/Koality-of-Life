-- !Koality-of-Life: Constants

-- Font rendering
CHAR_LIGATURESFONT = "Interface\\AddOns\\!Koality-of-Life\\media\\fonts\\SourceCodePro-Bold.ttf"
CHAR_LIGATURESOUTLINE = "OUTLINE"

-- UI Navigation arrows
CHAR_ARROW_UPFILLED = "▲"
CHAR_ARROW_DOWNFILLED = "▼"
CHAR_ARROW_RIGHTFILLED = "▶"
CHAR_ARROW_LEFTFILLED = "◄"

-- UI Controls
CHAR_UI_MINIMIZE = "_"
CHAR_UI_MAXIMIZE = "+"
CHAR_UI_CLOSE = "✕"

-- Objective Tracking
CHAR_OBJECTIVE_BOX = "☐"
CHAR_OBJECTIVE_COMPLETE = "☑"

-- Status Indicators
CHAR_LIGHTNING = "⚡"
CHAR_IDLE = "■"
CHAR_BASE = "○"

-- Text Separators
CHAR_SEPARATOR = "|"
CHAR_SEPARATOR_1 = "•"
CHAR_SEPARATOR_2 = "◆"
CHAR_SEPARATOR_3 = "◊"
CHAR_SEPARATOR_4 = "│"
CHAR_SEPARATOR_5 = "∙"
CHAR_SEPARATOR_6 = "—"
CHAR_SEPARATOR_7 = "·"
CHAR_SEPARATOR_8 = "▪"
CHAR_SEPARATOR_9 = "▸"

-- Character data for CHAR() function
local CHAR_DATA = {
    ARROWS = {
        LEFT = "←", RIGHT = "→", UP = "↑", DOWN = "↓",
        UPLEFT = "↖", UPRIGHT = "↗", DOWNLEFT = "↙", DOWNRIGHT = "↘",
        LEFTRIGHT = "↔", UPDOWN = "↕", UPDOWNWITHBASE = "↨",
        DOUBLELEFT = "⇐", DOUBLERIGHT = "⇒", DOUBLEUP = "⇑", DOUBLEDOWN = "⇓",
        CIRCLELEFT = "↺", CIRCLERIGHT = "↻",
        RIGHTFILLED = "▶", DOWNFILLED = "▼", LEFTFILLED = "◄", UPFILLED = "▲",
    },
    OBJECTIVES = {
        BOX = "☐", COMPLETE = "☑", INCOMPLETE = "✕",
        PROGRESS = "…", BULLET = "•", STAR = "★",
        DASH = "–", ARROW = "➤",
    },
    UI = {
        MINIMIZE = "_", MAXIMIZE = "+", CLOSE = "✕", COG = "☼",
    },
    SHAPES = {
        FILLED_SQUARE = "■", FILLED_SMALL_SQUARE = "▪",
        FILLED_TRIANGLE_UP = "▲", FILLED_TRIANGLE_DOWN = "▼",
        FILLED_TRIANGLE_LEFT = "◄", FILLED_TRIANGLE_RIGHT = "▶",
        FILLED_SMALL_TRIANGLE_UP = "▴", FILLED_SMALL_TRIANGLE_DOWN = "▾",
        FILLED_SMALL_TRIANGLE_LEFT = "◂", FILLED_SMALL_TRIANGLE_RIGHT = "▸",
        FILLED_POINTER_RIGHT = "►", FILLED_CIRCLE = "●",
        FILLED_CIRCLE_LARGE = "◉", FILLED_DIAMOND = "◆",
        FILLED_CIRCLE_BULLSEYE = "◘", FILLED_CIRCLE_INVERSE = "◙",
        EMPTY_SQUARE = "□", EMPTY_SMALL_SQUARE = "▫",
        EMPTY_TRIANGLE_UP = "△", EMPTY_TRIANGLE_DOWN = "▽",
        EMPTY_TRIANGLE_LEFT = "◁", EMPTY_TRIANGLE_RIGHT = "▷",
        EMPTY_SMALL_TRIANGLE_UP = "▵", EMPTY_SMALL_TRIANGLE_DOWN = "▿",
        EMPTY_SMALL_TRIANGLE_LEFT = "◃", EMPTY_SMALL_TRIANGLE_RIGHT = "▹",
        EMPTY_CIRCLE = "○", EMPTY_CIRCLE_SMALL = "◦",
        EMPTY_CIRCLE_DOTTED = "◌", EMPTY_DIAMOND = "◊",
    },
    BLOCKS = {
        FULL = "█", DARK = "▓", MEDIUM = "▒", LIGHT = "░",
        LEFT_HALF = "▌", RIGHT_HALF = "▐", UPPER_HALF = "▀", LOWER_HALF = "▄",
        UPPER_ONE_EIGHTH = "▔", LOWER_ONE_EIGHTH = "▁", LOWER_ONE_QUARTER = "▂",
        LOWER_THREE_EIGHTHS = "▃", LOWER_FIVE_EIGHTHS = "▅", LOWER_THREE_QUARTERS = "▆",
        LOWER_SEVEN_EIGHTHS = "▇", LEFT_SEVEN_EIGHTHS = "▉", LEFT_THREE_QUARTERS = "▊",
        LEFT_FIVE_EIGHTHS = "▋", LEFT_ONE_HALF = "▌", LEFT_THREE_EIGHTHS = "▍",
        LEFT_ONE_QUARTER = "▎", LEFT_ONE_EIGHTH = "▏", RIGHT_ONE_EIGHTH = "▕",
        QUADRANT_LOWER_LEFT = "▖", QUADRANT_LOWER_RIGHT = "▗", QUADRANT_UPPER_LEFT = "▘",
        QUADRANT_UPPER_LEFT_LOWER_LEFT_LOWER_RIGHT = "▙", QUADRANT_UPPER_LEFT_LOWER_RIGHT = "▚",
        QUADRANT_UPPER_LEFT_UPPER_RIGHT_LOWER_LEFT = "▛", QUADRANT_UPPER_LEFT_UPPER_RIGHT_LOWER_RIGHT = "▜",
        QUADRANT_UPPER_RIGHT = "▝", QUADRANT_UPPER_RIGHT_LOWER_LEFT = "▞",
        QUADRANT_UPPER_RIGHT_LOWER_LEFT_LOWER_RIGHT = "▟",
    },
    BOX_DRAWING = {
        LIGHT_H = "─", HEAVY_H = "━", LIGHT_V = "│", HEAVY_V = "┃",
        DOUBLE_H = "═", DOUBLE_V = "║",
        LIGHT_TRIPLE_DASH_H = "┄", HEAVY_TRIPLE_DASH_H = "┅",
        LIGHT_TRIPLE_DASH_V = "┆", HEAVY_TRIPLE_DASH_V = "┇",
        LIGHT_QUAD_DASH_H = "┈", HEAVY_QUAD_DASH_H = "┉",
        LIGHT_QUAD_DASH_V = "┊", HEAVY_QUAD_DASH_V = "┋",
        LIGHT_DOWN_RIGHT = "┌", LIGHT_DOWN_HEAVY_RIGHT = "┍",
        HEAVY_DOWN_LIGHT_RIGHT = "┎", HEAVY_DOWN_RIGHT = "┏",
        LIGHT_DOWN_LEFT = "┐", DOWN_LIGHT_LEFT_HEAVY = "┑",
        DOWN_HEAVY_LEFT_LIGHT = "┒", HEAVY_DOWN_LEFT = "┓",
        LIGHT_UP_RIGHT = "└", UP_LIGHT_RIGHT_HEAVY = "┕",
        UP_HEAVY_RIGHT_LIGHT = "┖", HEAVY_UP_RIGHT = "┗",
        LIGHT_UP_LEFT = "┘", UP_LIGHT_LEFT_HEAVY = "┙",
        UP_HEAVY_LEFT_LIGHT = "┚", HEAVY_UP_LEFT = "┛",
        LIGHT_V_RIGHT = "├", V_LIGHT_RIGHT_HEAVY = "┝",
        UP_HEAVY_DOWN_LIGHT_RIGHT = "┞", DOWN_HEAVY_UP_LIGHT_RIGHT = "┟",
        V_HEAVY_RIGHT_LIGHT = "┠", DOWN_LIGHT_UP_HEAVY_RIGHT = "┡",
        UP_LIGHT_DOWN_HEAVY_RIGHT = "┢", HEAVY_V_RIGHT = "┣",
        LIGHT_V_LEFT = "┤", V_LIGHT_LEFT_HEAVY = "┥",
        UP_HEAVY_DOWN_LIGHT_LEFT = "┦", DOWN_HEAVY_UP_LIGHT_LEFT = "┧",
        V_HEAVY_LEFT_LIGHT = "┨", DOWN_LIGHT_UP_HEAVY_LEFT = "┩",
        UP_LIGHT_DOWN_HEAVY_LEFT = "┪", HEAVY_V_LEFT = "┫",
        LIGHT_H_DOWN = "┬", H_LIGHT_DOWN_HEAVY = "┭",
        LEFT_HEAVY_RIGHT_LIGHT_DOWN = "┮", RIGHT_HEAVY_LEFT_LIGHT_DOWN = "┯",
        H_HEAVY_DOWN_LIGHT = "┰", RIGHT_LIGHT_LEFT_HEAVY_DOWN = "┱",
        LEFT_LIGHT_RIGHT_HEAVY_DOWN = "┲", HEAVY_H_DOWN = "┳",
        LIGHT_H_UP = "┴", H_LIGHT_UP_HEAVY = "┵",
        LEFT_HEAVY_RIGHT_LIGHT_UP = "┶", RIGHT_HEAVY_LEFT_LIGHT_UP = "┷",
        H_HEAVY_UP_LIGHT = "┸", RIGHT_LIGHT_LEFT_HEAVY_UP = "┹",
        LEFT_LIGHT_RIGHT_HEAVY_UP = "┺", HEAVY_H_UP = "┻",
        LIGHT_V_H = "┼", V_LIGHT_H_HEAVY = "┽", UP_HEAVY_DOWN_LIGHT_H = "┾",
        DOWN_HEAVY_UP_LIGHT_H = "┿", V_HEAVY_H_LIGHT = "╀",
        DOWN_LIGHT_UP_HEAVY_H = "╁", UP_LIGHT_DOWN_HEAVY_H = "╂",
        H_LIGHT_V_HEAVY = "╃", LEFT_HEAVY_RIGHT_LIGHT_V = "╄",
        RIGHT_HEAVY_LEFT_LIGHT_V = "╅", H_HEAVY_V_LIGHT = "╆",
        RIGHT_LIGHT_LEFT_HEAVY_V = "╇", LEFT_LIGHT_RIGHT_HEAVY_V = "╈",
        HEAVY_V_H = "╉", V_LIGHT_H_DOUBLE = "╊", H_LIGHT_V_DOUBLE = "╋",
        LIGHT_DOUBLE_DASH_H = "╌", HEAVY_DOUBLE_DASH_H = "╍",
        LIGHT_DOUBLE_DASH_V = "╎", HEAVY_DOUBLE_DASH_V = "╏",
        DOUBLE_DOWN_RIGHT = "╔", DOUBLE_DOWN_LEFT = "╗",
        DOUBLE_UP_RIGHT = "╚", DOUBLE_UP_LEFT = "╝",
        DOUBLE_V_RIGHT = "╠", DOUBLE_V_LEFT = "╣",
        DOUBLE_H_DOWN = "╦", DOUBLE_H_UP = "╩", DOUBLE_V_H = "╬",
        DOWN_SINGLE_RIGHT_DOUBLE = "╒", DOWN_DOUBLE_RIGHT_SINGLE = "╓",
        DOWN_SINGLE_LEFT_DOUBLE = "╕", DOWN_DOUBLE_LEFT_SINGLE = "╖",
        UP_SINGLE_RIGHT_DOUBLE = "╘", UP_DOUBLE_RIGHT_SINGLE = "╙",
        UP_SINGLE_LEFT_DOUBLE = "╛", UP_DOUBLE_LEFT_SINGLE = "╜",
        V_SINGLE_RIGHT_DOUBLE = "╞", V_DOUBLE_RIGHT_SINGLE = "╟",
        V_SINGLE_LEFT_DOUBLE = "╡", V_DOUBLE_LEFT_SINGLE = "╢",
        H_SINGLE_DOWN_DOUBLE = "╤", H_DOUBLE_DOWN_SINGLE = "╥",
        H_SINGLE_UP_DOUBLE = "╧", H_DOUBLE_UP_SINGLE = "╨",
        V_SINGLE_H_DOUBLE = "╪", V_DOUBLE_H_SINGLE = "╫",
        LIGHT_ARC_DOWN_RIGHT = "╭", LIGHT_ARC_DOWN_LEFT = "╮",
        LIGHT_ARC_UP_LEFT = "╯", LIGHT_ARC_UP_RIGHT = "╰",
        LIGHT_DIAGONAL_UPPER_RIGHT_LOWER_LEFT = "╱",
        LIGHT_DIAGONAL_UPPER_LEFT_LOWER_RIGHT = "╲",
        LIGHT_DIAGONAL_CROSS = "╳", LIGHT_LEFT = "╴",
        LIGHT_UP = "╵", LIGHT_RIGHT = "╶", LIGHT_DOWN = "╷",
        HEAVY_LEFT = "╸", HEAVY_UP = "╹", HEAVY_RIGHT = "╺",
        HEAVY_DOWN = "╻", LIGHT_LEFT_HEAVY_RIGHT = "╼",
        LIGHT_UP_HEAVY_DOWN = "╽", HEAVY_LEFT_LIGHT_RIGHT = "╾",
        HEAVY_UP_LIGHT_DOWN = "╿",
    },
    MATH = {
        PLUSMINUS = "±", MULTIPLY = "×", DIVIDE = "÷",
        APPROX = "≈", NOTEQUAL = "≠", EQUAL = "≡",
        LESSEQUAL = "≤", GREATEREQUAL = "≥", INFINITY = "∞",
        DELTA = "∆", SUM = "∑", PRODUCT = "∏",
        SQRT = "√", MINUS = "−", FORALL = "∀",
        PARTIAL = "∂", EXISTS = "∃", ANGLE = "∟",
        INTERSECTION = "∩", UNION = "∪", INTEGRAL = "∫",
        DOUBLE_INTEGRAL = "∬", TRIPLE_INTEGRAL = "∭",
        CONTOUR_INTEGRAL = "∮", SURFACE_INTEGRAL = "∯",
        VOLUME_INTEGRAL = "∰", CLOCKWISE_INTEGRAL = "∱",
        CLOCKWISE_CONTOUR_INTEGRAL = "∲", ANTICLOCKWISE_CONTOUR_INTEGRAL = "∳",
        SLASH = "∕", DOT = "∙", PROPORTION = "∷",
        LBRACKET = "⟦", RBRACKET = "⟧",
    },
    SUPERSCRIPTS = {
        ["0"] = "⁰", ["1"] = "¹", ["2"] = "²", ["3"] = "³",
        ["4"] = "⁴", ["5"] = "⁵", ["6"] = "⁶", ["7"] = "⁷",
        ["8"] = "⁸", ["9"] = "⁹", PLUS = "⁺", MINUS = "⁻",
        EQUALS = "⁼", LPAREN = "⁽", RPAREN = "⁾",
        N = "ⁿ", I = "ⁱ",
    },
    SUBSCRIPTS = {
        ["0"] = "₀", ["1"] = "₁", ["2"] = "₂", ["3"] = "₃",
        ["4"] = "₄", ["5"] = "₅", ["6"] = "₆", ["7"] = "₇",
        ["8"] = "₈", ["9"] = "₉", PLUS = "₊", MINUS = "₋",
        EQUALS = "₌", LPAREN = "₍", RPAREN = "₎",
        SCHWA = "ₔ",
    },
    SYMBOLS = {
        TRADEMARK = "™", COPYRIGHT = "©", REGISTERED = "®",
        PHONOGRAPHIC = "℗", SERVICE_MARK = "℠", EURO = "€",
        EMPTY_SET = "∅", OMEGA = "Ω", NUMERO = "№",
        ESTIMATED = "℮",
    },
    PUNCTUATION = {
        DOUBLEEXCLAM = "‼", INTERROBANG = "‽", ENDDASH = "–",
        EMDASH = "—", ELLIPSIS = "…", BULLET = "•",
        DAGGER = "†", DOUBLEDAGGER = "‡", PERMILLE = "‰",
        PRIME = "′", DOUBLEPRIME = "″", TRIPLEPRIME = "‵",
        LSAQUO = "‹", RSAQUO = "›", OVERLINE = "‾",
        UNDERTIE = "‿", FRACTION_SLASH = "⁄",
        QUESTION_EXCLAM = "⁇", EXCLAM_QUESTION = "⁈",
        DOUBLE_QUESTION_EXCLAM = "⁉",
    },
    PROGRESS = {
        BAR_START = "[", BAR_END = "]", BAR_FILL = "=",
        BAR_EMPTY = "-", PERCENT = "%",
    },
    MISC = {
        COFFEE = "☕", SMILEY = "☺", SMILEY_FILLED = "☻",
        SUN = "☼", FEMALE = "♀", MALE = "♂",
        SPADE = "♠", CLUB = "♣", HEART = "♥",
        DIAMOND = "♦", NOTE = "♪", NOTES = "♫",
        CHECK = "✓", BOX = "❒", HEART_FILLED = "❤",
        CLEF_TREBLE = "𝄞", CLEF_BASS = "𝄢", CLEF_ALTO = "𝄡",
        CLEF_TENOR = "𝄜", CLEF_PERC = "𝄝", IRONY = "⸘",
        BRACKET_TOP_LEFT = "⸢", BRACKET_TOP_RIGHT = "⸣",
        BRACKET_BOTTOM_LEFT = "⸤", BRACKET_BOTTOM_RIGHT = "⸥",
        HOUSE = "⌂", CORNER_TOP_LEFT = "⌜", CORNER_TOP_RIGHT = "⌝",
        CORNER_BOTTOM_LEFT = "⌞", CORNER_BOTTOM_RIGHT = "⌟",
        INTEGRAL_TOP = "⌠", INTEGRAL_BOTTOM = "⌡", NEGATION = "⌐",
    },
}

local VARIABLE_CONSTANTS = {
    ARROW_UPFILLED = "CHAR_ARROW_UPFILLED",
    ARROW_DOWNFILLED = "CHAR_ARROW_DOWNFILLED",
    ARROW_RIGHTFILLED = "CHAR_ARROW_RIGHTFILLED",
    ARROW_LEFTFILLED = "CHAR_ARROW_LEFTFILLED",
    UI_MINIMIZE = "CHAR_UI_MINIMIZE",
    UI_MAXIMIZE = "CHAR_UI_MAXIMIZE",
    UI_CLOSE = "CHAR_UI_CLOSE",
    OBJECTIVE_BOX = "CHAR_OBJECTIVE_BOX",
    OBJECTIVE_COMPLETE = "CHAR_OBJECTIVE_COMPLETE",
}

function findExactMatch(searchTerm)
    for groupName, group in pairs(CHAR_DATA) do
        for key, char in pairs(group) do
            if key == searchTerm or groupName .. "_" .. key == searchTerm then
                return {key = key, char = char, group = groupName}
            end
        end
    end
    return nil
end

function findFuzzyMatches(searchTerm)
    local results = {}
    local terms = {}

    for word in string.gmatch(searchTerm, "[^%s]+") do
        table.insert(terms, word)
    end

    for groupName, group in pairs(CHAR_DATA) do
        for key, char in pairs(group) do
            local score = calculateMatchScore(key, groupName, terms)
            if score > 0 then
                table.insert(results, {key = key, char = char, score = score})
            end
        end
    end

    table.sort(results, function(a, b) return a.score > b.score end)
    return results
end

function calculateMatchScore(key, groupName, searchTerms)
    local score = 0
    local fullKey = groupName .. "_" .. key

    for _, term in ipairs(searchTerms) do
        if string.find(key, term, 1, true) then
            score = score + 10
        end
        if string.find(groupName, term, 1, true) then
            score = score + 5
        end
        if string.find(fullKey, term, 1, true) then
            score = score + 3
        end
    end

    return score
end

function CHAR_SEARCH(searchTerm)
    if not searchTerm or searchTerm == "" then
        return {}
    end

    local normalized = string.upper(string.gsub(searchTerm, "[_-%s]+", " "))

    local exactResult = findExactMatch(normalized)
    if exactResult then
        return {exactResult}
    end

    local fuzzyResults = findFuzzyMatches(normalized)
    return fuzzyResults
end

function CHAR(searchTerm)
    if not searchTerm or searchTerm == "" then
        return ""
    end

    local normalized = string.upper(string.gsub(searchTerm, "[_-%s]+", " "))

    local exactResult = findExactMatch(normalized)
    if exactResult then
        local varName = VARIABLE_CONSTANTS[exactResult.key]
        if varName then
            KoalityOfLife:DebugPrint("CHAR(): Performance tip - Use '" .. varName .. "' for better performance", 0)
        end
        return exactResult.char
    end

    local fuzzyResults = findFuzzyMatches(normalized)

    if #fuzzyResults == 0 then
        KoalityOfLife:DebugPrint("CHAR(): No match found for: " .. searchTerm, 0)
        return ""
    elseif #fuzzyResults == 1 then
        KoalityOfLife:DebugPrint("CHAR(): Fuzzy match '" .. fuzzyResults[1].key .. "' for '" .. searchTerm .. "'", 4)
        return fuzzyResults[1].char
    else
        KoalityOfLife:DebugPrint("CHAR(): Multiple matches for '" .. searchTerm .. "' - please specify:", 0)
        for i, result in ipairs(fuzzyResults) do
            KoalityOfLife:DebugPrint("  - " .. result.key .. " (" .. result.char .. ")", 0)
        end
        return ""
    end
end

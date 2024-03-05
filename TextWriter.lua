require("Annotations");
require("CharWidths");

---@type table<string, number>
local Constants = {
    GapSize = 15.4,         -- CSS Flex gapsize == 1em == 15.4px
    LeftPadding = 3,        -- In CSS: The left element, not the padding-left element!
    ExtraSpacePerText = 1;  -- Idk, the space might be too short without it
};


---@enum ParsingMode
local ParsingMode = {
    NotParsing = 0,
    ParsingFirstCharOfColor = 1,
    ParsingOtherCharsOfColor = 2
};

---@enum ElementType
local ElementType = {
    TextPiece = "TextPiece",
    Tag = "Tag",
    Newline = "Newline",
    WordBreak = "WordBreak"
}

---@class Element
---@field Type ElementType
---@field PositionInOriginal Position

---@class Position
---@field From integer
---@field To integer

---@class TextPiece: Element
---@field Text string
---@field Color? string

---@class Tag: Element
---@field Content string

---@class Newline: Element

---@class WordBreak: Element

---@class AddNewlinesResult
---@field Elements Element[]
---@field MaxWidth integer


---@class Line
---@field Width number
---@field Elements TextPiece[]

---Errors if Position field is not a number or negative, otherwise returns rounded field
---@param n integer
---@param varname string
---@return integer
local function TestPositionField(n, varname)
    if type(n) ~= "number" then
        error("'" .. varname .. "' is of type " .. type(n) .. " instead of integer");
    elseif n < 0 then
        error("'" .. varname .. "' is lower than 0");
    end
    return math.floor(n);
end

---Creates a Position from a line number and 2 text positions
---@param From integer
---@param To integer
---@return Position
local function CreatePosition(From, To)
    From = TestPositionField(From, "From")
    To = TestPositionField(To, "To")
    if From > To then
        error("'From' (" .. tostring(From) .. ") is higher than 'To' (" .. tostring(To) .. ")")
    end
    return { From = From, To = To };
end

---@param Position Position
local function TestPosition(Position)
    TestPositionField(Position.From, "From");
    TestPositionField(Position.To, "To");
    if Position.From > Position.To then
        error("'From' (" .. tostring(Position.From) .. ") is higher than 'To' (" .. tostring(Position.To) .. ")")
    end
end

---@param Content string
---@param PositionInOriginal Position
---@return Tag
local function CreateTag(Content, PositionInOriginal)
    if type(Content) ~= "string" then
        error("'Content' is of type " .. type(Content) .. "instead of string")
    end
    TestPosition(PositionInOriginal);
    return { Content = Content, Type = ElementType.Tag, PositionInOriginal = PositionInOriginal };
end

---@param PositionInOriginal Position
---@return Newline
local function CreateNewline(PositionInOriginal)
    TestPosition(PositionInOriginal);
    if PositionInOriginal.From ~= PositionInOriginal.To then
        error("Position.From (" ..
            tostring(PositionInOriginal.From) ..
            ") is not equal to Position.To (" .. tostring(PositionInOriginal.To) .. ")");
    end
    return { Type = ElementType.Newline, PositionInOriginal = PositionInOriginal };
end

---@param PositionInOriginal Position
---@return WordBreak
local function CreateWordBreak(PositionInOriginal)
    TestPosition(PositionInOriginal);
    return { Type = ElementType.WordBreak, PositionInOriginal = PositionInOriginal };
end

---Creates a TextPiece
---@param Text string
---@param PositionInOriginal Position
---@param Color? string
---@return TextPiece
local function CreateTextPiece(Text, PositionInOriginal, Color)
    if type(Text) ~= "string" then
        error("'Text' is of type " .. type(Text) .. " instead of string");
    end
    if type(Color) ~= "nil" and type(Color) ~= "string" then
        error("'Color' is of type " .. type(Color) .. " instead of string")
    end
    TestPosition(PositionInOriginal);

    return { Text = Text, PositionInOriginal = PositionInOriginal, Type = ElementType.TextPiece, Color = Color };
end

---@param Text string
---@return Element[]
local function GetElements(Text)
    ---@type Element[]
    local Elements = {};

    ---@type ParsingMode
    local parsingmode = ParsingMode.NotParsing;
    ---@type string
    local TextBuffer = "";
    ---@type integer
    local from = 1;
    ---@type integer
    local to = 0;

    for ci = 1, string.len(Text) do
        to = to + 1;

        ---@type string
        local c = string.sub(Text, ci, ci);
        if parsingmode == ParsingMode.NotParsing then
            if c == "<" then
                parsingmode = ParsingMode.ParsingFirstCharOfColor;
            else
                if c == "\n" then
                    if TextBuffer ~= "" then
                        table.insert(Elements, CreateTextPiece(TextBuffer, CreatePosition(from, to - 1)));
                    end
                    from = to;
                    TextBuffer = "";
                    table.insert(Elements, CreateNewline(CreatePosition(from, to)))
                else
                    TextBuffer = TextBuffer .. c;
                end
            end
        elseif parsingmode == ParsingMode.ParsingFirstCharOfColor then
            if c == "<" then
                parsingmode = ParsingMode.NotParsing;
                TextBuffer = TextBuffer .. "<";
            else
                parsingmode = ParsingMode.ParsingOtherCharsOfColor;
                if TextBuffer ~= "" then
                    table.insert(Elements, CreateTextPiece(TextBuffer, CreatePosition(from, to - 2)));
                end
                TextBuffer = c;
                from = to - 1;
            end
        elseif parsingmode == ParsingMode.ParsingOtherCharsOfColor then
            if c == ">" then
                parsingmode = ParsingMode.NotParsing;
                if string.lower(TextBuffer) == "wbr" then
                    table.insert(Elements, CreateWordBreak(CreatePosition(from, to)));
                else
                    table.insert(Elements, CreateTag(TextBuffer, CreatePosition(from, to)));
                end
                TextBuffer = "";
                from = to + 1;
            else
                TextBuffer = TextBuffer .. c;
            end
        else
            error("[Internal] unknown parsingmode " ..
                tostring(parsingmode) .. ". Please report this to the Warzone Modding Community")
        end
    end
    if parsingmode == ParsingMode.ParsingFirstCharOfColor or parsingmode == ParsingMode.ParsingOtherCharsOfColor then
        error("'<' never closed (From: " .. tostring(from) .. "; To: " .. tostring(to) .. ")")
    end
    if TextBuffer ~= "" then
        table.insert(Elements, CreateTextPiece(TextBuffer, CreatePosition(from, to)));
    end
    return Elements;
end

---Gets how many pixel the string takes up on the Warzone Website
---@param str string
---@return number
local function GetTextWidth(str)
    ---@type number
    local width = 0;
    for i = 1, #str do
        width = width + (W[string.sub(str, i, i)] or 10);
    end
    return width;
end

---@param TextPiece TextPiece
---@param CharIndex integer
---@return Element[]
local function AddNewlines(TextPiece, CharIndex)
    if #TextPiece.Text < CharIndex then
        error("TextPiece size (" .. tostring(#TextPiece.Text) ..
            ") is smaller than CharIndex (" .. tostring(CharIndex) .. ")")
    end

    CharIndex = CharIndex - 1;


    ---@type integer
    local from = TextPiece.PositionInOriginal.From;
    ---@type integer
    local to = TextPiece.PositionInOriginal.To;

    if CharIndex == 0 then
        return {
            CreateTextPiece("", CreatePosition(from - 1, from - 1), TextPiece.Color),
            CreateNewline(CreatePosition(from - 1, from - 1)),
            TextPiece
        };
    end

    if string.sub(TextPiece.Text, CharIndex + 1, CharIndex + 1) == " " then
        local before = string.sub(TextPiece.Text, 1, CharIndex);
        ---@type string
        local after = string.sub(TextPiece.Text, CharIndex + 2);
        return {
            CreateTextPiece(before, CreatePosition(from, from + CharIndex - 1), TextPiece.Color),
            CreateNewline(CreatePosition(from + CharIndex, from + CharIndex)),
            CreateTextPiece(after, CreatePosition(from + CharIndex + 1, to), TextPiece.Color)
        };
    end
    for ci = CharIndex, 1, -1 do
        ---@type string
        local c = string.sub(TextPiece.Text, ci, ci);
        if c == " " then
            ---@type string
            local before = string.sub(TextPiece.Text, 1, ci - 1);
            ---@type string
            local after = string.sub(TextPiece.Text, ci + 1);

            ---@type Position
            local beforePosition;
            if ci == 1 then
                beforePosition = CreatePosition(from-1, from-1);
            else
                beforePosition = CreatePosition(from, from + ci - 2);
            end
            return {
                CreateTextPiece(before, beforePosition, TextPiece.Color),
                CreateNewline(CreatePosition(from + ci - 1, from + ci - 1)),
                CreateTextPiece(after, CreatePosition(from + ci, to), TextPiece.Color),
            };
        end
    end
    local before = string.sub(TextPiece.Text, 1, CharIndex);
    ---@type string
    local after = string.sub(TextPiece.Text, CharIndex + 1);
    return {
        CreateTextPiece(before, CreatePosition(from, from + CharIndex - 1), TextPiece.Color),
        CreateNewline(CreatePosition(from + CharIndex - 1, from + CharIndex - 1)),
        CreateTextPiece(after, CreatePosition(from + CharIndex, to), TextPiece.Color)
    };
end

---@param a any[]
---@param b any[]
local function Extend(a, b)
    ---@type integer
    local originalLength = #a;
    for index, value in ipairs(b) do
        a[originalLength + index] = value;
    end
end

---@param Elements Element[]
---@param MaxWidth integer
---@return Line[]
local function ParseElements(Elements, MaxWidth)
    ---@type Line[]
    local toReturn = {}

    ---@type integer
    local i = 1;

    ---@type string
    local currentColor = "";

    ---@type {Width: number, Elements: TextPiece[]}
    local beforeWordbreak = { Width = -Constants.GapSize + Constants.LeftPadding, Elements = {} };

    ---@type {Width: number, Elements: TextPiece[]}
    local afterWordbreak = { Width = -Constants.GapSize + Constants.LeftPadding, Elements = {} };


    while i <= #Elements do
        ---@type Element
        local element = Elements[i];
        if element.Type == ElementType.Newline then
            ---@type {Width: number, Elements: TextPiece[]};
            local buffer = { Width = beforeWordbreak.Width, Elements = {} }
            Extend(buffer.Elements, beforeWordbreak.Elements);
            buffer.Width = buffer.Width + afterWordbreak.Width;
            Extend(buffer.Elements, afterWordbreak.Elements);
            table.insert(toReturn, buffer);

            beforeWordbreak = { Width = -Constants.GapSize + Constants.LeftPadding, Elements = {} };
            afterWordbreak = { Width = -Constants.GapSize + Constants.LeftPadding, Elements = {} };
            i = i + 1;
        elseif element.Type == ElementType.Tag then
            ---@cast element Tag
            currentColor = element.Content;
            i = i + 1;
        elseif element.Type == ElementType.WordBreak then
            beforeWordbreak.Width = beforeWordbreak.Width + afterWordbreak.Width + Constants.GapSize - Constants.LeftPadding;
            Extend(beforeWordbreak.Elements, afterWordbreak.Elements);
            afterWordbreak = { Width = -Constants.GapSize + Constants.LeftPadding, Elements = {} };
            i = i + 1;
        elseif element.Type == ElementType.TextPiece then
            i = i + 1;

            ---@cast element TextPiece
            element.Color = currentColor;
            ---@type number
            local currentWidth = beforeWordbreak.Width + afterWordbreak.Width + Constants.GapSize - Constants.LeftPadding;

            ---@type integer
            local ci = 1
            while ci <= #element.Text do
                ---@type string
                local c = string.sub(element.Text, ci, ci);
                ---@type number
                local width = W[c] or 10;
                if currentWidth + width + Constants.GapSize + Constants.LeftPadding >= MaxWidth then
                    ---@type string, integer
                    local _, count = string.gsub(element.Text, "%s", "", 1);
                    if count == 0 and #beforeWordbreak.Elements > 0 then
                        table.insert(toReturn, beforeWordbreak);
                        beforeWordbreak = { Width = -Constants.GapSize + Constants.LeftPadding, Elements = {} };
                        currentWidth = afterWordbreak.Width;
                        ci = 1;
                    else
                        ---@type Element[]
                        local result = AddNewlines(element, ci);

                        ---@type Element
                        local before = result[1];
                        ---@cast before TextPiece
                        ---@type Element
                        local after = result[3]
                        ---@cast after TextPiece

                        afterWordbreak.Width = afterWordbreak.Width + math.ceil(GetTextWidth(before.Text)) + Constants.ExtraSpacePerText + Constants.GapSize + Constants.LeftPadding;
                        table.insert(afterWordbreak.Elements, before);

                        table.insert(toReturn, afterWordbreak);
                        afterWordbreak = { Width = -Constants.GapSize + Constants.LeftPadding, Elements = {} };

                        element = after;
                        ci = 1;
                        currentWidth = 0;
                    end
                else
                    ci = ci + 1;
                    currentWidth = currentWidth + width;
                end
            end
            afterWordbreak.Width = beforeWordbreak.Width + afterWordbreak.Width + math.ceil(GetTextWidth(element.Text)) + Constants.ExtraSpacePerText + Constants.GapSize + Constants.LeftPadding;
            table.insert(afterWordbreak.Elements, element);
        end
    end

    ---@type {Width: number, Elements: TextPiece[]};
    local buffer = { Width = beforeWordbreak.Width, Elements = {} }
    Extend(buffer.Elements, beforeWordbreak.Elements);
    buffer.Width = buffer.Width + afterWordbreak.Width;
    Extend(buffer.Elements, afterWordbreak.Elements);
    table.insert(toReturn, buffer);

    return toReturn;
end

---Internal functions
---@type table<string, function | table<string, number>>
KaninchenLibTextWriter = {
    TestPositionField=TestPositionField,
    CreatePosition=CreatePosition,
    TestPosition=TestPosition,
    CreateTag=CreateTag,
    CreateNewline=CreateNewline,
    CreateWordBreak=CreateWordBreak,
    CreateTextPiece=CreateTextPiece,
    GetElements=GetElements,
    Extend=Extend,
    ParseElements=ParseElements,
    GetTextWidth=GetTextWidth,
    AddNewlines=AddNewlines,
    Constants=Constants,
    ParsingMode=ParsingMode,
    ElementType=ElementType
};

---@param UIGroup HorizontalLayoutGroup | VerticalLayoutGroup | EmptyUIObject
---@param Text string
---@param MaxWidth? integer
function AddStringToUI(UIGroup, Text, MaxWidth)
    if MaxWidth == nil then
        if UIGroup.GetPreferredWidth ~= nil then
            MaxWidth = UIGroup.GetPreferredWidth();
        else
            MaxWidth = 20;
        end
    end


    ---@type integer
    MaxWidth = math.max(20, MaxWidth);
    if UIGroup.SetPreferredWidth ~= nil then
        UIGroup.SetPreferredWidth(MaxWidth);
        UIGroup.SetFlexibleWidth(0);
    end

    for _, line in ipairs(ParseElements(GetElements(Text), MaxWidth)) do
        local hlg = UI.CreateHorizontalLayoutGroup(UIGroup);

        local toprint = ""
        for _, striiiiiing in ipairs(line.Elements) do
            toprint = toprint .. striiiiiing.Text .. "\\n";
        end

        print("---"..toprint.."---")

        print("line.width", line.Width)
        local tw = -15.4 + 3;
        for _, textpiece in ipairs(line.Elements) do
            ---@type Label
            local label = UI.CreateLabel(hlg);
            
            tw = tw + GetTextWidth(textpiece.Text) + 15.4 + 3;
            
            label.SetPreferredWidth(GetTextWidth(textpiece.Text));
            label.SetFlexibleWidth(0);
            print(textpiece.Text, GetTextWidth(textpiece.Text), label.GetPreferredWidth());
            if textpiece.Color ~= nil and not (textpiece.Color == "") then
                label.SetColor(textpiece.Color);
            end
            label.SetText(textpiece.Text);
        end
        print("Actual width", tw)
    end
end

--local a = ParseElements(GetElements("Hello<#ff0000>Wooooooooooooooooooooooooooooooooorld<wbr>It goes<#00ff00> over several lines <#0000ff> and has many colors!"), 200)

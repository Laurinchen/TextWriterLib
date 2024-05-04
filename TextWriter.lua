require("Annotations");
require("CharWidths");
require("Colors");

---@cast UI UI

---@type table<string, number>
local Constants = {
    GapSize = 15.4,        -- CSS Flex gapsize == 1em == 15.4px
    LeftPadding = 3,       -- In CSS: The left property, not the padding-left property!
    ExtraSpacePerText = 1, -- Idk, the space might be too short without it
    DefaultCharWidth = 10, -- If a given char is not present in CharWidths
    MinWidth = 30,         -- Without it, the code might loop infinitely with a too small MaxWidth
};

---@type string[]
local RecognisedSpecialTags = { "wbr", "/", };

---@enum ParsingMode
local ParsingMode = {
    NotParsing = 0,
    ParsingFirstCharOfTag = 1,
    ParsingOtherCharsOfTag = 2
};

---@enum ElementType
local ElementType = {
    TextPiece = "TextPiece",
    Tag = "Tag",
    Newline = "Newline",
    WordBreak = "WordBreak"
};



---@class ProblemHandler
---@field Cancel? boolean
---@field PrintToUI? boolean
---@field RaiseException? boolean

---@class Options
---@field MaxWidth? integer
---@field WarningHandler? ProblemHandler
---@field ErrorHandler? ProblemHandler
---@field AncestorCount? integer


---@class Element
---@field Type ElementType
---@field PositionInOriginal Position

---@class Position
---@field From integer
---@field To integer

---@enum ResultType
ResultType = {
    Success = 0,
    Warning = 1,
    Error = 2,
};

---@enum VerifyProblemType
VerifyProblemType = {
    --- Errors

    UnclosedLessThan = "UnclosedLessThan",
    MalformedHexCode = "MalformedHexCode",

    --- Warnings

    UnrecognisedTag = "UnrecognisedTag",
    UnrecognisedTagWithValidHexcode = "UnrecognisedTagWithValidHexcode",
    EmptyTag = "EmptyTag",
    SymbolWithNoWidthDefined = "SymbolWithNoWidthDefined"
};

---@class Problem
---@field VerifyProblemType VerifyProblemType
---@field Description string
---@field Position Position

---@class VerifyResult
---@field Type ResultType
---@field Problems? Problem[]

---@class TextPiece: Element
---@field Text string
---@field Color? string
---@field LastSpace? integer

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

---@class CreatedUIElements
---@field LayoutGroup HorizontalLayoutGroup | VerticalLayoutGroup
---@field Children Label[]

---@class AddStringToUIResult
---@field Success boolean
---@field List CreatedUIElements[]
---@field Problems? Problem[]

---@generic T
---@param obj T
---@param map table<any, T>
---@return any?
local function GetKeyFromValue(obj, map)
    for key, value in pairs(map) do
        if value == obj then
            return key
        end
    end
    return nil
end

---@param Cancel? boolean
---@param PrintToUI? boolean
---@param RaiseException? boolean
---@return ProblemHandler
---@nodiscard
function ProblemHandlerFactory(Cancel, PrintToUI, RaiseException)
    ---@type ProblemHandler
    local handler = {};
    handler.Cancel = Cancel or false;
    handler.PrintToUI = PrintToUI or false;
    handler.RaiseException = RaiseException or false;
    return handler;
end


---Errors if Position field is not a number or negative, otherwise returns rounded field
---@param n integer
---@param varname string
---@return integer
local function TestPositionField(n, varname)
    assert(type(n) == "number",
        "'" .. varname .. "' is of type " .. type(n) .. " instead of integer");
    assert(n >= 0, "'" .. varname .. "' is lower than 0");
    return math.floor(n);
end

---Creates a Position from a line number and 2 text positions
---@param From integer
---@param To integer
---@return Position
local function CreatePosition(From, To)
    From = TestPositionField(From, "From")
    To = TestPositionField(To, "To")

    assert(From <= To, "'From' (" .. tostring(From) .. ") is higher than 'To' (" .. tostring(To) .. ")");

    return { From = From, To = To };
end

---@param Position Position
local function TestPosition(Position)
    TestPositionField(Position.From, "From");
    TestPositionField(Position.To, "To");
    assert(Position.From <= Position.To,
        "'From' (" .. tostring(Position.From) .. ") is higher than 'To' (" .. tostring(Position.To) .. ")")
end

---@param Content string
---@param PositionInOriginal Position
---@return Tag
local function CreateTag(Content, PositionInOriginal)
    assert(type(Content) == "string", "'Content' is of type " .. type(Content) .. "instead of string");
    TestPosition(PositionInOriginal);
    return { Content = Content, Type = ElementType.Tag, PositionInOriginal = PositionInOriginal };
end

---@param PositionInOriginal Position
---@return Newline
local function CreateNewline(PositionInOriginal)
    TestPosition(PositionInOriginal);
    assert(PositionInOriginal.From == PositionInOriginal.To, "Position.From (" ..
        tostring(PositionInOriginal.From) ..
        ") is not equal to Position.To (" .. tostring(PositionInOriginal.To) .. ")");
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
    assert(type(Text) == "string",
        "'Text' is of type " .. type(Text) .. " instead of string");
    assert(type(Color) == "nil" or type(Color) == "string", "'Color' is of type " .. type(Color) .. " instead of string");
    TestPosition(PositionInOriginal);

    ---@type integer?, _
    local pos, _ = string.find(Text:reverse(), "%s");
    if pos ~= nil then
        pos = #Text - pos + 1;
    end


    return {
        Text = Text,
        PositionInOriginal = PositionInOriginal,
        Type = ElementType.TextPiece,
        Color = Color,
        LastSpace =
            pos
    };
end

---@param ProblemType VerifyProblemType
---@param Position Position
---@param Description string
---@return Problem
local function CreateVerifyProblem(ProblemType, Position, Description)
    assert(VerifyProblemType[ProblemType], "Unrecognised ProblemType: " .. ProblemType);
    TestPosition(Position);
    assert(type(Description) == "string", "'Description' is of type " .. type(Description) .. "instead of string");
    return { VerifyProblemType = ProblemType, Position = Position, Description = Description };
end

---@param code string
---@return boolean
local function IsColorCode(code)
    ---@type integer?, _
    local pos, _ = code:find("[a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9]");
    if pos then
        return true;
    else
        return false;
    end
end



---@param Text string
---@return VerifyResult
---@nodiscard
function VerifyString(Text)
    ---@type ResultType
    local resulttype = ResultType.Success;
    ---@type Problem[]
    local problems = {};
    ---@type ParsingMode
    local parsingmode = ParsingMode.NotParsing;
    ---@type string
    local TagBuffer = "";
    ---@type integer
    local from = 1;
    ---@type integer
    local to = 0;

    for ci = 1, #Text do
        to = to + 1;
        ---@type string
        local c = Text:sub(ci, ci);
        if parsingmode == ParsingMode.NotParsing then
            if c == "<" then
                parsingmode = ParsingMode.ParsingFirstCharOfTag
            elseif CharWidths[c] == nil and c ~= '\n' then
                table.insert(problems, CreateVerifyProblem(
                    VerifyProblemType.SymbolWithNoWidthDefined,
                    CreatePosition(ci, ci),
                    "'" .. c .. "' has no width defined in CharWidths.lua"
                ));
                resulttype = math.max(resulttype, ResultType.Warning);
            end
        elseif parsingmode == ParsingMode.ParsingFirstCharOfTag then
            if c == "<" then
                parsingmode = ParsingMode.NotParsing;
            else
                from = to - 1;
                if c ~= ">" then
                    TagBuffer = c;
                    parsingmode = ParsingMode.ParsingOtherCharsOfTag
                else
                    table.insert(problems, CreateVerifyProblem(
                        VerifyProblemType.EmptyTag,
                        CreatePosition(from, to),
                        '"</>" instead of "<>" should be used'
                    ))
                    resulttype = math.max(resulttype, ResultType.Warning);
                    parsingmode = ParsingMode.NotParsing
                    from = to+1;
                end
            end
        elseif parsingmode == ParsingMode.ParsingOtherCharsOfTag then
            if c == ">" then
                TagBuffer = TagBuffer:lower();
                if TagBuffer:sub(1, 1) == "#" then
                    if not IsColorCode(TagBuffer:sub(2)) then
                        table.insert(problems, CreateVerifyProblem(
                            VerifyProblemType.MalformedHexCode,
                            CreatePosition(from, to),
                            "Invalid hexcode '" .. TagBuffer .. "'"
                        ))
                        resulttype = math.max(resulttype, ResultType.Error);
                    end
                elseif (not Colors[TagBuffer]) and (not GetKeyFromValue(TagBuffer, RecognisedSpecialTags)) then
                    if IsColorCode(TagBuffer) then
                        table.insert(problems, CreateVerifyProblem(
                            VerifyProblemType.UnrecognisedTagWithValidHexcode,
                            CreatePosition(from, to),
                            "Unrecognised Tag '" .. TagBuffer .. "', seems like a # at the start was forgotten"
                        ));
                        resulttype = math.max(resulttype, ResultType.Warning);
                    else
                        table.insert(problems, CreateVerifyProblem(
                            VerifyProblemType.UnrecognisedTag,
                            CreatePosition(from, to),
                            "Unrecognised Tag '" .. TagBuffer .. "'"
                        ));
                        resulttype = math.max(resulttype, ResultType.Warning);
                    end
                end
                parsingmode = ParsingMode.NotParsing;
                TagBuffer = "";
            else
                TagBuffer = TagBuffer .. c;
            end
        else
            error("[Internal] unknown parsingmode " ..
                tostring(parsingmode) .. ". Please report this to the Warzone Modding Community")
        end
    end
    if parsingmode ~= ParsingMode.NotParsing then
        ---@type integer?, _
        local pos, _ = string.find(Text:reverse(), "<");
        pos = #Text - pos + 1;


        table.insert(problems, CreateVerifyProblem(
            VerifyProblemType.UnclosedLessThan,
            CreatePosition(pos, to),
            "Last '<' never has been closed"
        ))
        resulttype = math.max(resulttype, ResultType.Error);
    end


    ---@type VerifyResult
    local to_return = { Type = resulttype };
    if resulttype > 0 then
        to_return.Problems = problems;
    end
    return to_return
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

    for ci = 1, #Text do
        to = to + 1;

        ---@type string
        local c = string.sub(Text, ci, ci);
        if parsingmode == ParsingMode.NotParsing then
            if c == "<" then
                parsingmode = ParsingMode.ParsingFirstCharOfTag;
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
        elseif parsingmode == ParsingMode.ParsingFirstCharOfTag then
            if c == "<" then
                parsingmode = ParsingMode.NotParsing;
                TextBuffer = TextBuffer .. "<";
            else
                if TextBuffer ~= "" then
                    table.insert(Elements, CreateTextPiece(TextBuffer, CreatePosition(from, to - 2)));
                end
                if c ~= ">" then
                    parsingmode = ParsingMode.ParsingOtherCharsOfTag;
                    TextBuffer = c;
                    from = to - 1;
                else
                    parsingmode = ParsingMode.NotParsing;
                    table.insert(Elements, CreateTag("", CreatePosition(to - 1, to)));
                    TextBuffer = "";
                    from = to + 1;
                end
            end
        elseif parsingmode == ParsingMode.ParsingOtherCharsOfTag then
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
        width = width + (CharWidths[string.sub(str, i, i)] or Constants.DefaultCharWidth);
    end
    return width;
end

---@param str string
---@return integer
local function CalculateWidthToAdd(str)
    return math.ceil(GetTextWidth(str) + Constants.GapSize + Constants.ExtraSpacePerText);
end


---@param TextPiece TextPiece
---@param CharIndex integer
---@return Element[]
local function AddNewlines(TextPiece, CharIndex)
    assert(#TextPiece.Text >= CharIndex, "TextPiece size (" .. tostring(#TextPiece.Text) ..
        ") is smaller than CharIndex (" .. tostring(CharIndex) .. ")");

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
            CreateTextPiece(after, CreatePosition(from + CharIndex + 1, math.max(from + CharIndex + 1, to)),
                TextPiece.Color)
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
                beforePosition = CreatePosition(from - 1, from - 1);
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
---@param MaxWidth number
---@param ExpectedDepth integer
---@return Line[]
local function ParseElements(Elements, MaxWidth, ExpectedDepth)
    ---@type boolean
    local didAWordbreak = false;

    ---@type integer
    local i = 1;

    ---@type string
    local currentColor = "";

    ---@type {before: Line, after: Line, output: Line[], clearAll: fun(self), clearBefore: fun(self), clearAfter: fun(self), add: fun(self, toAdd: TextPiece), commitBefore: fun(self, includeLast: boolean), commitAll: fun(self), manageWordbreak: fun(self)}
    local buffer = {
        before = { Width = -Constants.GapSize + ExpectedDepth * Constants.LeftPadding, Elements = {} },
        after = { Width = -Constants.GapSize + ExpectedDepth * Constants.LeftPadding, Elements = {} },
        output = {}
    };

    function buffer.clearAll(self)
        self.before = { Width = -Constants.GapSize + ExpectedDepth * Constants.LeftPadding, Elements = {} };
        self.after = { Width = -Constants.GapSize + ExpectedDepth * Constants.LeftPadding, Elements = {} };
    end

    function buffer.clearBefore(self)
        self.before = { Width = -Constants.GapSize + ExpectedDepth * Constants.LeftPadding, Elements = {} };
    end

    function buffer.clearAfter(self)
        self.after = { Width = -Constants.GapSize + ExpectedDepth * Constants.LeftPadding, Elements = {} };
    end

    function buffer.add(self, toAdd)
        ---@type integer
        local length = #self.before.Elements;
        if didAWordbreak and length ~= 0 then
            ---@type TextPiece
            local latest = self.before.Elements[length];
            self.before.Width = self.before.Width + GetTextWidth(toAdd.Text);
            self.before.Elements[length] = CreateTextPiece(latest.Text .. toAdd.Text,
                CreatePosition(latest.PositionInOriginal.From, toAdd.PositionInOriginal.To), latest.Color)
        else
            self.after.Width = self.after.Width + CalculateWidthToAdd(toAdd.Text)
            table.insert(self.after.Elements, toAdd);
        end
    end

    ---@param includeLast boolean
    function buffer.commitBefore(self, includeLast)
        if includeLast == nil then
            includeLast = true;
        end
        if includeLast then
            table.insert(self.output, self.before)
            self:clearBefore();
        else
            ---@type TextPiece
            local latest = self.before.Elements[#self.before.Elements];
            table.remove(self.before.Elements, #self.before.Elements);
            table.insert(self.output, self.before);
            self.before = {
                Width = ExpectedDepth * Constants.LeftPadding +
                    GetTextWidth(latest.Text) + Constants.ExtraSpacePerText,
                Elements = { latest }
            };
        end
    end

    function buffer.commitAll(self)
        ---@type Line
        local buf = { Width = self.before.Width + self.after.Width + Constants.GapSize, Elements = {} };
        Extend(buf.Elements, self.before.Elements);
        Extend(buf.Elements, self.after.Elements);
        table.insert(self.output, buf);
        self:clearAll();
    end

    function buffer.manageWordbreak(self)
        if #self.after.Elements >= 1 then
            if didAWordbreak then
                assert(#self.after.Elements == 1,
                    "IMPOSSIBLE STATE DETECTED [#self.after.Elements != 1 and wordbreak]\nPlease contact the mod author");
                self.before.Width = self.before.Width + self.after.Width;

                ---@type TextPiece
                local Piece1 = self.before.Elements[#self.before.Elements];
                ---@type TextPiece
                local Piece2 = self.after.Elements[1];

                self.before.Elements[#self.before.Elements] = CreateTextPiece(
                    Piece1.Text .. Piece2.Text,
                    CreatePosition(Piece1.PositionInOriginal.From, Piece2.PositionInOriginal.To), Piece1.Color)
                self:clearAfter();
            else
                ---@type TextPiece
                local latest = self.after.Elements[#self.after.Elements]
                ---@type integer?, _

                if latest.LastSpace ~= nil then
                    table.remove(self.after.Elements, #self.after.Elements);

                    ---@type Element[]
                    local result = AddNewlines(latest, #latest.Text);
                    ---@type Element
                    local before = result[1];
                    ---@cast before TextPiece

                    ---@type Element
                    local after = result[3];
                    ---@cast after TextPiece

                    self.before.Width = self.before.Width + self.after.Width + Constants.GapSize
                    Extend(self.before.Elements, self.after.Elements)
                    Extend(self.before.Elements, { before, after })
                    self:clearAfter();
                else
                    self.before.Width = self.before.Width + self.after.Width + Constants.GapSize
                    Extend(self.before.Elements, self.after.Elements)
                    self:clearAfter();
                end
            end
            didAWordbreak = true;
        end
    end

    while i <= #Elements do
        ---@type Element
        local element = Elements[i];
        if element.Type == ElementType.Newline then
            buffer:commitAll();
            didAWordbreak = false;
            i = i + 1;
        elseif element.Type == ElementType.Tag then
            ---@cast element Tag
            currentColor = element.Content;
            didAWordbreak = false;
            i = i + 1;
        elseif element.Type == ElementType.WordBreak then
            buffer:manageWordbreak();
            i = i + 1;
        elseif element.Type == ElementType.TextPiece then
            i = i + 1;
            ---@cast element TextPiece
            element.Color = currentColor;

            ---@type number
            local currentWidth = buffer.before.Width + buffer.after.Width -
                Constants.LeftPadding;

            ---@type integer
            local ci = 1

            while ci <= #element.Text do
                ---@type string
                local c = string.sub(element.Text, ci, ci);
                ---@type number
                local width = CharWidths[c] or Constants.DefaultCharWidth;
                if c == " " and didAWordbreak then
                    ---@type Element[]
                    local result = AddNewlines(element, ci);

                    ---@type Element
                    local before = result[1]
                    ---@cast before TextPiece

                    ---@type Element
                    local after = result[3]
                    ---@cast after TextPiece

                    ---@type TextPiece
                    local lastBeforeElement = buffer.before.Elements[#buffer.before.Elements];
                    buffer.before.Elements[#buffer.before.Elements] = CreateTextPiece(
                        lastBeforeElement.Text .. before.Text,
                        CreatePosition(lastBeforeElement.PositionInOriginal.From, before.PositionInOriginal.To),
                        lastBeforeElement.Color
                    )

                    element = after;
                    ci = 1;

                    didAWordbreak = false;
                elseif math.ceil(currentWidth + width) + Constants.ExtraSpacePerText + Constants.GapSize + Constants.LeftPadding >= MaxWidth then
                    if #buffer.before.Elements > 0 and not didAWordbreak then
                        buffer:commitBefore(true);
                        currentWidth = buffer.after.Width
                    elseif #buffer.before.Elements > 1 and didAWordbreak then
                        buffer:commitBefore(false);
                        currentWidth = buffer.before.Width + buffer.after.Width -
                            Constants.LeftPadding;
                    else
                        ---@type Element[]
                        local result = AddNewlines(element, ci);

                        ---@type Element
                        local before = result[1];
                        ---@cast before TextPiece
                        ---@type Element
                        local after = result[3]
                        ---@cast after TextPiece

                        buffer:add(before)
                        buffer:commitAll();

                        element = after;
                        ci = 1;

                        didAWordbreak = false;

                        currentWidth = buffer.before.Width + buffer.after.Width -
                            Constants.LeftPadding + Constants.ExtraSpacePerText;
                    end
                else
                    ci = ci + 1;
                    currentWidth = currentWidth + width;
                end
            end
            buffer:add(element);
        end
    end

    buffer:commitAll();

    return buffer.output
end

---@param UIGroup UIObject
---@param Lines Line[]
---@return CreatedUIElements[]
local function AddElementsToUI(UIGroup, Lines)
    ---@type HorizontalLayoutGroup[]
    local created_elements = {};

    for _, line in ipairs(Lines) do
        ---@type HorizontalLayoutGroup
        local hlg = UI.CreateHorizontalLayoutGroup(UIGroup);

        ---@type CreatedUIElements
        local created_element = { Children = {}, LayoutGroup = hlg };

        for _, textpiece in ipairs(line.Elements) do
            if textpiece.Text ~= "" then
                ---@type Label
                local label = UI.CreateLabel(hlg);
                table.insert(created_element.Children, label);

                if string.sub(textpiece.Color, 1, 1) ~= "#" then
                    textpiece.Color = Colors[textpiece.Color]
                end

                if textpiece.Color ~= nil and not (textpiece.Color == "") then
                    label.SetColor(textpiece.Color);
                end
                label.SetText(textpiece.Text);
            end
        end
        table.insert(created_elements, created_element);
    end
    return created_elements;
end

---Internal functions
---@type table<string, function | table<string, number>>
KaninchenTextWriterLibInternals = {
    TestPositionField = TestPositionField,
    CreatePosition = CreatePosition,
    TestPosition = TestPosition,
    CreateTag = CreateTag,
    CreateNewline = CreateNewline,
    CreateWordBreak = CreateWordBreak,
    CreateTextPiece = CreateTextPiece,
    GetElements = GetElements,
    Extend = Extend,
    ParseElements = ParseElements,
    GetTextWidth = GetTextWidth,
    AddNewlines = AddNewlines,
    Constants = Constants,
    ParsingMode = ParsingMode,
    ElementType = ElementType,
    AddElementsToUI = AddElementsToUI,
    CalculateWidthToAdd = CalculateWidthToAdd
};


---@param UIGroup UIObject
---@param Text string
---@param Options? Options
---@return AddStringToUIResult?
function AddStringToUI(UIGroup, Text, Options)
    if Options == nil then
        Options = {};
    end

    ---@type integer
    local ancestorcount = Options.AncestorCount or 1;

    ---@type integer
    local maxwidth;
    if Options.MaxWidth == nil then
        if UIGroup.GetPreferredWidth ~= nil then
            maxwidth = UIGroup.GetPreferredWidth();
        else
            maxwidth = 500;
        end
    else
        maxwidth = Options.MaxWidth
    end
    maxwidth = math.max(Constants.MinWidth, maxwidth);

    ---@type VerifyResult
    local verifyresult = VerifyString(Text);


    if verifyresult.Type ~= ResultType.Success then
        ---@type ProblemHandler
        local warninghandler = Options.WarningHandler or {PrintToUI=true}
        ---@type ProblemHandler
        local errorhandler = Options.ErrorHandler or {PrintToUI = true, RaiseException = true};
        warninghandler = ProblemHandlerFactory(warninghandler.Cancel, warninghandler.PrintToUI, warninghandler.RaiseException);
        errorhandler = ProblemHandlerFactory(errorhandler.Cancel, errorhandler.PrintToUI, errorhandler.RaiseException);

        ---@type boolean
        local should_cancel = false;

        ---@type ResultType
        local resulttype = ResultType.Warning;

        ---@type CreatedUIElements
        local group;

        local exceptionToRaise = "";
        for index, value in ipairs(verifyresult.Problems) do
            ---@type boolean
            local iserror = false;
            if GetKeyFromValue(value.VerifyProblemType, { VerifyProblemType.MalformedHexCode, VerifyProblemType.UnclosedLessThan }) then
                iserror = true;
            end

            ---@type string
            local errstring = "\n=====";

            if iserror then
                errstring = errstring .. "ERROR ";
                resulttype = ResultType.Error;
            else
                errstring = errstring .. "WARNING ";
            end

            errstring = errstring .. tostring(index) .. " - " .. value.VerifyProblemType .. '=====\nAt: "'
                .. Text:sub(value.Position.From, value.Position.To) .. '"\nFrom: '
                .. tostring(value.Position.From) .. " to " .. tostring(value.Position.To) .. "\n" .. value.Description
            if iserror then
                if errorhandler.Cancel then
                    should_cancel = true;
                end
                if errorhandler.PrintToUI then
                    if group == nil then
                        group = {LayoutGroup=UI.CreateVerticalLayoutGroup(UIGroup), Children={}};
                    end

                    ---@type Label
                    local created_label = UI.CreateLabel(group.LayoutGroup);
                    created_label.SetText(errstring);
                    created_label.SetColor("#ff0000");

                    table.insert(group.Children, created_label);
                end
                if errorhandler.RaiseException then
                    exceptionToRaise = exceptionToRaise .. errstring;
                end
            else
                if warninghandler.Cancel then
                    should_cancel = true;
                end
                if warninghandler.PrintToUI then
                    if group == nil then
                        group = {LayoutGroup=UI.CreateVerticalLayoutGroup(UIGroup), Children={}};
                    end

                    ---@type Label
                    local created_label = UI.CreateLabel(group.LayoutGroup);
                    created_label.SetText(errstring);
                    created_label.SetColor("#ffff00");

                    table.insert(group.Children, created_label);
                end
                if warninghandler.RaiseException then
                    exceptionToRaise = exceptionToRaise .. errstring;
                end
            end
        end
        if group ~= nil then
            ---@type Label
            local report_info = UI.CreateLabel(group.LayoutGroup);
            report_info.SetText("\nPlease report this to the Mod Developer or on the Modmaker Discord");
            report_info.SetColor("#ff0000");
            table.insert(group.Children, report_info);
        end
        if #exceptionToRaise ~= 0 then
            error(exceptionToRaise);
        end
        ---@type CreatedUIElements[]
        local result = {group};
        if should_cancel ~= true then
            Extend(result, AddElementsToUI(UIGroup, ParseElements(GetElements(Text), maxwidth, ancestorcount)))
        end
        return {Type=resulttype, Problems=verifyresult.Problems, List=result}
    else
        return {Type=ResultType.Success, List=AddElementsToUI(UIGroup, ParseElements(GetElements(Text), maxwidth, ancestorcount))}
    end
end
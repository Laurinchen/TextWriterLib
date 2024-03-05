require("Annotations");
require("TextWriter");

---Client_PresentMenuUI hook
---@param rootParent RootParent
---@param setMaxSize fun(width: number, height: number) # Sets the max size of the dialog
---@param setScrollable fun(horizontallyScrollable: boolean, verticallyScrollable: boolean) # Set whether the dialog is scrollable both horizontal and vertically
---@param game GameClientHook
---@param close fun() # Zero parameter function that closes the dialog
function Client_PresentMenuUI(rootParent, setMaxSize, setScrollable, game, close)
    ---@type VerticalLayoutGroup
    local x = UI.CreateVerticalLayoutGroup(rootParent)

    setMaxSize(500, 500);

    local thingies = {"", 'Hello :pleading_face: cutiii',' ', '!', '"', '#', '$', '%', '&', "'", '(', ')', '*', '+', ',', '-', '.', '/', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ':', ';', '<', '=', '>', '?', '@', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '[', '\\', ']', '^', '_', '`', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '{', '|', '}', '~', '¡', '¢', '£', '¤', '¥', '¦', '§', '¨', '©', 'ª', '«', '¬', '®', '¯', '°', '±', '²', '³', '´', 'µ', '¶', '·', '¸', '¹', 'º', '»', '¼', '½', '¾', '¿', 'À', 'Á', 'Â', 'Ã', 'Ä', 'Å', 'Æ', 'Ç', 'È', 'É', 'Ê', 'Ë', 'Ì', 'Í', 'Î', 'Ï', 'Ð', 'Ñ', 'Ò', 'Ó', 'Ô', 'Õ', 'Ö', '×', 'Ø', 'Ù', 'Ú', 'Û', 'Ü', 'Ý', 'Þ', 'ß', 'à', 'á', 'â', 'ã', 'ä', 'å', 'æ', 'ç', 'è', 'é', 'ê', 'ë', 'ì', 'í', 'î', 'ï', 'ð', 'ñ', 'ò', 'ó', 'ô', 'õ', 'ö', '÷', 'ø', 'ù', 'ú', 'û', 'ü', 'ý', 'þ', 'ÿ'}
    for _, value in ipairs(thingies) do
        ---@type Label
        -- local a = UI.CreateLabel(x);
        -- a.SetText(value);
    end

    -- AddStringToUI(x,
    --     "Hello<#ff0000>Wooooooooooooooooooooooooooooooooorld<wbr>It goes<#00ff00> over several lines <#0000ff> and has many colors!",
    -- 400);
    AddStringToUI(x, "Lorem ipsum dolor <#ff0000>sit amet, consetetur sadipscing elitr, <#00ff00>sed diam nonumy eirmod tempor invidunt ut <#0000ff>labore et dolore magna aliquyam erat, sed diam volu<#ff0000>ptua. At vero eos et accusam et justo <#00ff00>duo dolores et ea rebum. Stet clita<#0000ff> kasd gubergren, no sea takimata<#ffff00> sanctus est Lorem ipsum dolor sit amet. <#ff0000>Lorem ipsum dolor sit amet, consetetur <#ffffff>sadipscing elitr, sed diam nonumy eir<#0000ff>mod tempor invidunt ut labore et dolore magna <#00ffaa>aliquyam erat, sed diam voluptua. At vero eos et <#ff0000>accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.", 200);
end

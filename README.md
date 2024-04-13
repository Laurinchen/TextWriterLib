# Textwriter Library
This is a library to easily add colorful Text to your UI of your Warzone Mod.

## Disclaimer
This Library is in Alpha. It does most likely only display correctly on the [Website](https://www.warzone.com/), not on the Standalone Client or Mobile Client (especially in portrait mode).<br>
You can discuss the library on [The Warzone Modmaker Discord](https://discord.com/invite/hqGkVXagyt).<br>
Feel free to make pull requests and open Issues

## Usage
### Which files to copy
- TextWriter.lua
- CharWidths.lua
- Colors.lua<br>
If not already in your Mod:
- Annotations.lua

### How to use
The main functions you will be using is `AddStringToUI`.<br>
It has following signature:
```cpp
AddStringToUI(
    HorizontalLayoutGroup | VerticalLayoutGroup | EmptyUIObject | RootParent UIGroup,
    string Text,
    number MaxWidth = 30,
    integer AncestorCount = 1
) -> table<HorizontalLayoutGroup: HorizontalLayoutGroup, Children: Label[]>;
```

#### UIGroup
<b>UIGroup</b>
This is the UI container which the elements will be added to.<br>
This must be either an element created by `UI.CreateHorizontalLayoutGroup(parent)`, `UI.CreateVerticalLayoutGroup(parent)`, `UI.CreateEmpty(parent)` or can be the `rootParent` itself<br>
Note that this library may not work as expected on other UI containers besides VerticalLayoutGroup and rootParent.

#### Text
A string with color tags.<br>
For example `"Hello, <red>this Text will be displayed as red, <#0000ff>and this Text as blue!"`<br>
A tag is denoted with a less than `<`, the tag content and a greater than `>`.<br>

There are 4 kinds of tag contents
- Literal color names
- Color Hexcode
- Literal `/`
- Literal `wbr`

##### Literal color name
Using `<red>`, `<blue>` or other color names built into Warzone (like `<cinnamon>`) will look up its Hexcode in the `Colors` table.<br>
If a color name is not recognized, the color will be the default Warzone Text color.<br>
Example: `"Hello <green>World"` will make "World" be displayed in a green color (#00ff05).<br>

##### Color Hexcode
If the tag content starts with a hashtag, it will parse the next 6 hexadecimal numbers (0-9, a-f) as a color code.<br>
[More information here](https://en.wikipedia.org/wiki/Web_colors#Hex_triplet)<br>
Example:`"This is <#ff0000>colorful"` will make "colorful" be displayed in a red color (#ff0000)<br>
<br>
Note that this library makes no attempt to check if the Hex color code is valid. Your mod will crash if you input an invalid Hex color code!<br>

##### Literal `/`
Using `</>` will make following Text be displayed in the default Warzone color (white-ish).<br>
Technically, you can use any non-recognized color name or just an empty `<>`,<br>
but using `</>` is considered following the convention<br>
Example: `"<red>This is red</>This is default"` Will make "This is red" be displayed in a red color but "This is default" in the default Warzone Text color.<br>

##### Literal `wbr`
This is per se not a color tag, but is instead used to indicate that a long word can be broken at this location (where `<wbr>` is).<br>
Note that the library will prefer to insert newlines on spaces instead.<br>
`wbr` means wordbreak. [More Information here](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/wbr)<br>
Example: `"ThisIs<wbr>AVeryLongWord"`<br>
If the given `MaxWidth` is too short to display the whole string, it may display<br>
"ThisIs" on the first line and<br>
"AVeryLongWord" on the second line<br>

##### Escaping `<`
If you want to write a literal `<` you can do this by typing two `<` in a row.<br>
For example `"This is a greater than: <<"` will display as "This is a greater than: <"

##### Newlines
Newlines can be freely added. It is denoted as a `\n`<br>
Example: `"<blue>This will be displayed on line 1 \nAnd this on line 2"`<br>
The blue color from the first line will continue on the second line.

#### MaxWidth
(Default 30)<br>
MaxWidth denotes how many pixels a line can take up. This includes gap size (internal), padding (internal) etc.<br>
If not set, it will default to the preferred width of the UIGroup. If this is -1 (fit content) or<br>
MaxWidth is smaller than 30, it will default to 30.<br>
The default is not enough to properly display Texts, but it is enough to display most characters so the Lib won't infinitly loop.<br>

#### AncestorCount
(Default 1)<br>
How many ancestors `UIGroup` has (including `rootParent`)<br>
For example:<br>
```
rootParent rootparent
    ↳VerticalLayoutGroup a
        ↳VerticalLayoutGroup b
            ↳VerticalLayoutGroup UIGroup
```
In this case, `UIGroup` has, not counting itself, 3 ancestors (`rootParent`, `a` and `b`).<br>
Therefore, a 3 should be passed.<br>

If you directly pass `rootParent` as `UIGroup` to `AddStringToUI`, then you should pass a 1 (default).<br>
If you first create a container class for the generated text, which inherits from rootParent, then you should pass a 2,<br>
etc.<br>

#### Return value
If fine control over some or all created UI elements is wanted, you can use the return table of this function.<br>
It returns an array of `CreatedUIElements`, which are basically the generated lines containing the parent HorizontalLayoutGroup and its children (colored Labels).<br>
The "table convention" is as follows:
```lua
---@class CreatedUIElements
---@field HorizontalLayoutGroup HorizontalLayoutGroup
---@field Children Label[]
```
The array is ordered after creation.

### Available Colors
Next to hexcodes you can use predefines colors, listed in `Colors.lua`<br>

### Internal functions.
You can access internal functions and tables via `KaninchenTextWriterLibInternals["NAME"]` where `NAME` is replaced by the function/table/enum name.<br>
Refer to the documentation of the functions.<br>
For Example `local width = KaninchenTextWriterLibInternals["GetTextWidth"]("Hello World!");`<br>
This is to prevent namespace pollution<br>

## Copyright and Credit
This library is available under the MIT-License, just as almost every other Warzone Mod.<br>
Please give credit to this library in the mod description.

## Contributing
You can open issues or make pull requests to every file including `README.md` but excluding `CharWidth.lua` and `LICENSE`
Please give Feedback about this library to "Kaninchen" on Warzone, "@laurinchen2" on Discord<br>
or in its channel on [The Warzone Modmaker Discord](https://discord.com/invite/hqGkVXagyt)
# Textwriter Library
This is a library to easily add colorful Text to your UI of your Warzone Mod.

## Disclaimer
This Library is in Alpha. It does most likely only display correctly on the [Website](https://www.warzone.com/), not on the Standalone Client or Mobile Client.<br>
You can discuss the library on [The Warzone Modmaker Discord](https://discord.com/invite/hqGkVXagyt).<br>
Feel free to make pull requests and open Issues

## Usage
### Which files to copy
- TextWriter.lua
- CharWidths.lua
- Colors.lua
If not already in your Mod:
- Annotations.lua

### How to use
The main functions you will be using is `AddStringToUI`.<br>
It has following signature:
```cpp
void AddStringToUI(HorizontalLayoutGroup | VerticalLayoutGroup | EmptyUIObject UIGroup, string Text, number MaxWidth = 20, integer ExpectedDepth = 2);
```
#### UIGroup
<b>UIGroup</b>
This is the UI container which the elements will be added to.<br>
This must be either an element created by `UI.CreateHorizontalLayoutGroup(parent)`, `UI.CreateVerticalLayoutGroup(parent)` or `CreateEmpty(parent)`.<br>
A `rootParent` is NOT allowed. Also note that this library may not work on other UI containers besides VerticalLayoutGroup.

#### Text
A string with color tags.<br>
For example `"Hello, <red>this Text will be displayed as red, <#0000ff>and this Text as blue!"`<br>
A tag is denoted with a less than `<`, the tag content and a greater than `>`.<br>

There are 4 kinds of tag contents
- Literal color Names
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
`wbr` means wordbreak. [More Information here](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/wbr?retiredLocale=de)<br>
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
(Default 20)<br>
MaxWidth denotes how many pixels a line can take up. This includes gap size (internal), padding (internal) etc.<br>
If not set, it will default to the preffered width of the UIGroup. If this is -1 (fit content) or<br>
MaxWidth is smaller than 20, it will default to 20.<br>
The default is not enough to properly display Texts, but it is enough to display most characters.<br>

#### ExpectedDepth
(Default 2)<br>
This is pretty internal, but should be used if your `UIGroup` is in another UI Container (excluding rootParent).<br>
It counts `UIGroup` as 1 and the `HorizontalLayoutGroup`s the library generates as 1, therefore the default is 1+1=2.<br>
The general rule of thumb is `Count of ancestors (parents) of UIGroup (excluding rootParent) + 2`.<br>
If `UIGroup` directly inherits `rootParent`, you won't need this parameter ever.<br>

### Available Colors
Next to hexcodes you can use predefines colors, listed in `Colors.lua`<br>

### Internal functions.
You can access internal functions and tables via KaninchenLibTextWriter["NAME"] where Name is replaced by the function/table/enum name.<br>
Refer to the documentation of the functions.<br>
For Example `local width = KaninchenLibTextWriter["GetTextWidth"]("Hello World!");`<br>
This is to prevent namespace pollution<br>

## Copyright and Credit
This library is available under the MIT-License, just as almost every other Warzone Mod.<br>
Please give credit to this library in the mod description.

## Contributing
You can open issues or make pull requests to every file including `README.md` but excluding `CharWidth.lua` and `LICENSE`
Please give Feedback about this library to "Kaninchen" on Warzone, "@laurinchen2" on Discord<br>
or in its channel on [The Warzone Modmaker Discord](https://discord.com/invite/hqGkVXagyt)
let
    text = "Heading 1",
    // Add Spaces Of Padding To The Left
    PadStart = Text.PadStart(text, 20),
    // Add Spaces Of Padding To The Right
    PadEnd = Text.PadEnd(text, 20),
    // Add Spaces Of Padding On Each Side
    PadBoth = Text.PadEnd(Text.PadStart(text, 20),20)
in
    PadEnd

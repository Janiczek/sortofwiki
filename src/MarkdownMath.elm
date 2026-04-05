module MarkdownMath exposing (postProcessBlocksWithEquations)

import Markdown.Block as Block


type Segment
    = PlainText String
    | InlineEquation String
    | BlockEquation String


type ParagraphSegment
    = ParagraphInlines (List Block.Inline)
    | ParagraphBlockEquation String


postProcessBlocksWithEquations : List Block.Block -> List Block.Block
postProcessBlocksWithEquations blocks =
    List.concatMap mapBlock blocks


mapBlock : Block.Block -> List Block.Block
mapBlock block =
    case block of
        Block.HtmlBlock html ->
            [ Block.HtmlBlock (mapHtml html) ]

        Block.UnorderedList spacing items ->
            [ Block.UnorderedList spacing (List.map mapListItem items) ]

        Block.OrderedList spacing start rows ->
            [ Block.OrderedList spacing start (List.map (List.concatMap mapBlock) rows) ]

        Block.BlockQuote inner ->
            [ Block.BlockQuote (List.concatMap mapBlock inner) ]

        Block.Heading level inlines ->
            [ Block.Heading level (expandInlineEquations inlines) ]

        Block.Paragraph inlines ->
            paragraphBlocksFromInlines inlines

        Block.Table headers rows ->
            [ Block.Table
                (List.map
                    (\header ->
                        { label = expandInlineEquations header.label
                        , alignment = header.alignment
                        }
                    )
                    headers
                )
                (List.map (List.map expandInlineEquations) rows)
            ]

        Block.CodeBlock _ ->
            [ block ]

        Block.ThematicBreak ->
            [ block ]


mapListItem : Block.ListItem Block.Block -> Block.ListItem Block.Block
mapListItem (Block.ListItem task children) =
    Block.ListItem task (List.concatMap mapBlock children)


mapHtml : Block.Html Block.Block -> Block.Html Block.Block
mapHtml html =
    case html of
        Block.HtmlElement name attrs children ->
            Block.HtmlElement name attrs (List.concatMap mapBlock children)

        Block.HtmlComment _ ->
            html

        Block.ProcessingInstruction _ ->
            html

        Block.HtmlDeclaration _ _ ->
            html

        Block.Cdata _ ->
            html


paragraphBlocksFromInlines : List Block.Inline -> List Block.Block
paragraphBlocksFromInlines inlines =
    inlines
        |> List.concatMap paragraphSegmentsFromInline
        |> combineParagraphSegments
        |> List.concatMap paragraphSegmentToBlocks


paragraphSegmentsFromInline : Block.Inline -> List ParagraphSegment
paragraphSegmentsFromInline inline =
    case inline of
        Block.Text text ->
            text
                |> segmentsFromPlainText True
                |> List.filterMap paragraphSegmentFromTextSegment

        Block.Link destination title children ->
            [ ParagraphInlines [ Block.Link destination title (expandInlineEquations children) ] ]

        Block.Image destination title children ->
            [ ParagraphInlines [ Block.Image destination title (expandInlineEquations children) ] ]

        Block.Emphasis children ->
            [ ParagraphInlines [ Block.Emphasis (expandInlineEquations children) ] ]

        Block.Strong children ->
            [ ParagraphInlines [ Block.Strong (expandInlineEquations children) ] ]

        Block.Strikethrough children ->
            [ ParagraphInlines [ Block.Strikethrough (expandInlineEquations children) ] ]

        Block.HtmlInline html ->
            [ ParagraphInlines [ Block.HtmlInline (mapHtml html) ] ]

        Block.CodeSpan _ ->
            [ ParagraphInlines [ inline ] ]

        Block.HardLineBreak ->
            [ ParagraphInlines [ inline ] ]


paragraphSegmentFromTextSegment : Segment -> Maybe ParagraphSegment
paragraphSegmentFromTextSegment segment =
    case segment of
        PlainText text ->
            if text == "" then
                Nothing

            else
                Just (ParagraphInlines [ Block.Text text ])

        InlineEquation equation ->
            Just (ParagraphInlines [ inlineEquationInline equation ])

        BlockEquation equation ->
            Just (ParagraphBlockEquation equation)


combineParagraphSegments : List ParagraphSegment -> List ParagraphSegment
combineParagraphSegments segments =
    case segments of
        (ParagraphInlines left) :: (ParagraphInlines right) :: rest ->
            combineParagraphSegments (ParagraphInlines (left ++ right) :: rest)

        first :: rest ->
            first :: combineParagraphSegments rest

        [] ->
            []


paragraphSegmentToBlocks : ParagraphSegment -> List Block.Block
paragraphSegmentToBlocks segment =
    case segment of
        ParagraphInlines inlines ->
            if List.isEmpty inlines then
                []

            else
                [ Block.Paragraph inlines ]

        ParagraphBlockEquation equation ->
            [ blockEquationBlock equation ]


expandInlineEquations : List Block.Inline -> List Block.Inline
expandInlineEquations inlines =
    List.concatMap expandInlineEquation inlines


expandInlineEquation : Block.Inline -> List Block.Inline
expandInlineEquation inline =
    case inline of
        Block.Text text ->
            text
                |> segmentsFromPlainText False
                |> List.filterMap inlineFromSegment

        Block.Link destination title children ->
            [ Block.Link destination title (expandInlineEquations children) ]

        Block.Image destination title children ->
            [ Block.Image destination title (expandInlineEquations children) ]

        Block.Emphasis children ->
            [ Block.Emphasis (expandInlineEquations children) ]

        Block.Strong children ->
            [ Block.Strong (expandInlineEquations children) ]

        Block.Strikethrough children ->
            [ Block.Strikethrough (expandInlineEquations children) ]

        Block.HtmlInline html ->
            [ Block.HtmlInline (mapHtml html) ]

        Block.CodeSpan _ ->
            [ inline ]

        Block.HardLineBreak ->
            [ inline ]


inlineFromSegment : Segment -> Maybe Block.Inline
inlineFromSegment segment =
    case segment of
        PlainText text ->
            if text == "" then
                Nothing

            else
                Just (Block.Text text)

        InlineEquation equation ->
            Just (inlineEquationInline equation)

        BlockEquation _ ->
            Nothing


inlineEquationInline : String -> Block.Inline
inlineEquationInline equation =
    Block.HtmlInline
        (Block.HtmlElement "inline-equation" [ equationAttribute equation ] [])


blockEquationBlock : String -> Block.Block
blockEquationBlock equation =
    Block.HtmlBlock
        (Block.HtmlElement "block-equation" [ equationAttribute equation ] [])


equationAttribute : String -> Block.HtmlAttribute
equationAttribute equation =
    { name = "data-equation"
    , value = equation
    }


segmentsFromPlainText : Bool -> String -> List Segment
segmentsFromPlainText allowBlockEquations source =
    segmentsFromPlainTextHelp allowBlockEquations source 0


segmentsFromPlainTextHelp : Bool -> String -> Int -> List Segment
segmentsFromPlainTextHelp allowBlockEquations source startIndex =
    case findNextDelimiter allowBlockEquations source startIndex of
        Nothing ->
            [ PlainText (String.slice startIndex (String.length source) source) ]

        Just ( delimiter, openIndex ) ->
            let
                delimiterText : String
                delimiterText =
                    delimiterString delimiter

                delimiterLength : Int
                delimiterLength =
                    String.length delimiterText
            in
            case findClosingDelimiter delimiter source (openIndex + delimiterLength) of
                Nothing ->
                    [ PlainText (String.slice startIndex (String.length source) source) ]

                Just closeIndex ->
                    let
                        textBefore : String
                        textBefore =
                            String.slice startIndex openIndex source

                        equation : String
                        equation =
                            String.slice (openIndex + delimiterLength) closeIndex source

                        remainingSegments : List Segment
                        remainingSegments =
                            segmentsFromPlainTextHelp allowBlockEquations source (closeIndex + delimiterLength)
                    in
                    if equation == "" then
                        prependPlain (textBefore ++ delimiterText ++ delimiterText) remainingSegments

                    else
                        prependPlain textBefore (segmentFromDelimiter delimiter equation :: remainingSegments)


type Delimiter
    = InlineDelimiter
    | BlockDelimiter


delimiterString : Delimiter -> String
delimiterString delimiter =
    case delimiter of
        InlineDelimiter ->
            "$$"

        BlockDelimiter ->
            "$$$"


segmentFromDelimiter : Delimiter -> String -> Segment
segmentFromDelimiter delimiter equation =
    case delimiter of
        InlineDelimiter ->
            InlineEquation equation

        BlockDelimiter ->
            BlockEquation equation


findNextDelimiter : Bool -> String -> Int -> Maybe ( Delimiter, Int )
findNextDelimiter allowBlockEquations source index =
    if index >= String.length source - 1 then
        Nothing

    else if allowBlockEquations && startsWithAt "$$$" source index then
        Just ( BlockDelimiter, index )

    else if startsWithAt "$$" source index then
        Just ( InlineDelimiter, index )

    else
        findNextDelimiter allowBlockEquations source (index + 1)


findClosingDelimiter : Delimiter -> String -> Int -> Maybe Int
findClosingDelimiter delimiter source index =
    let
        delimiterText : String
        delimiterText =
            delimiterString delimiter
    in
    if index > String.length source - String.length delimiterText then
        Nothing

    else if startsWithAt delimiterText source index then
        Just index

    else
        findClosingDelimiter delimiter source (index + 1)


startsWithAt : String -> String -> Int -> Bool
startsWithAt needle haystack index =
    String.slice index (index + String.length needle) haystack == needle


prependPlain : String -> List Segment -> List Segment
prependPlain text segments =
    if text == "" then
        segments

    else
        PlainText text :: segments

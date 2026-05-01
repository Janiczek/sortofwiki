module MarkdownTypographicDashes exposing (postProcessBlocksWithTypographicDashes)

import Markdown.Block as Block


postProcessBlocksWithTypographicDashes : List Block.Block -> List Block.Block
postProcessBlocksWithTypographicDashes blocks =
    List.map mapBlock blocks


mapBlock : Block.Block -> Block.Block
mapBlock block =
    case block of
        Block.HtmlBlock html ->
            Block.HtmlBlock (mapHtml html)

        Block.UnorderedList spacing items ->
            Block.UnorderedList spacing (List.map mapListItem items)

        Block.OrderedList spacing start rows ->
            Block.OrderedList spacing start (List.map (List.map mapBlock) rows)

        Block.BlockQuote inner ->
            Block.BlockQuote (List.map mapBlock inner)

        Block.Heading level inlines ->
            Block.Heading level (List.map mapInline inlines)

        Block.Paragraph inlines ->
            Block.Paragraph (List.map mapInline inlines)

        Block.Table headers rows ->
            Block.Table
                (List.map
                    (\header ->
                        { label = List.map mapInline header.label
                        , alignment = header.alignment
                        }
                    )
                    headers
                )
                (List.map (List.map (List.map mapInline)) rows)

        Block.CodeBlock _ ->
            block

        Block.ThematicBreak ->
            block


mapListItem : Block.ListItem Block.Block -> Block.ListItem Block.Block
mapListItem (Block.ListItem task children) =
    Block.ListItem task (List.map mapBlock children)


mapHtml : Block.Html Block.Block -> Block.Html Block.Block
mapHtml html =
    case html of
        Block.HtmlElement name attrs children ->
            Block.HtmlElement name attrs (List.map mapBlock children)

        Block.HtmlComment _ ->
            html

        Block.ProcessingInstruction _ ->
            html

        Block.HtmlDeclaration _ _ ->
            html

        Block.Cdata _ ->
            html


mapInline : Block.Inline -> Block.Inline
mapInline inline =
    case inline of
        Block.Text text ->
            Block.Text (toTypographicDashes text)

        Block.Link destination title children ->
            Block.Link destination title (List.map mapInline children)

        Block.Image destination title children ->
            Block.Image destination title (List.map mapInline children)

        Block.Emphasis children ->
            Block.Emphasis (List.map mapInline children)

        Block.Strong children ->
            Block.Strong (List.map mapInline children)

        Block.Strikethrough children ->
            Block.Strikethrough (List.map mapInline children)

        Block.HtmlInline html ->
            Block.HtmlInline (mapHtml html)

        Block.CodeSpan _ ->
            inline

        Block.HardLineBreak ->
            inline


toTypographicDashes : String -> String
toTypographicDashes text =
    text
        |> String.replace "---" "—"
        |> String.replace "--" "–"

module PageTodos exposing (todoTexts)

import Markdown.Block as Block
import Markdown.Parser as MarkdownParser
import TodoSyntax


todoTexts : String -> List String
todoTexts markdown =
    case MarkdownParser.parse markdown of
        Ok blocks ->
            todoTextsFromBlocks blocks

        Err _ ->
            []


todoTextsFromBlocks : List Block.Block -> List String
todoTextsFromBlocks blocks =
    blocks
        |> List.concatMap todoTextsFromBlock


todoTextsFromBlock : Block.Block -> List String
todoTextsFromBlock block =
    case block of
        Block.HtmlBlock html ->
            todoTextsFromHtml html

        Block.UnorderedList _ items ->
            items
                |> List.concatMap todoTextsFromListItem

        Block.OrderedList _ _ rows ->
            rows
                |> List.concatMap todoTextsFromBlocks

        Block.BlockQuote inner ->
            todoTextsFromBlocks inner

        Block.Heading _ inlines ->
            todoTextsFromInlines inlines

        Block.Paragraph inlines ->
            todoTextsFromInlines inlines

        Block.Table headers rows ->
            List.concat
                [ headers
                    |> List.concatMap (\header -> todoTextsFromInlines header.label)
                , rows
                    |> List.concatMap (List.concatMap todoTextsFromInlines)
                ]

        Block.CodeBlock _ ->
            []

        Block.ThematicBreak ->
            []


todoTextsFromListItem : Block.ListItem Block.Block -> List String
todoTextsFromListItem (Block.ListItem _ children) =
    todoTextsFromBlocks children


todoTextsFromHtml : Block.Html Block.Block -> List String
todoTextsFromHtml html =
    case html of
        Block.HtmlElement _ _ children ->
            todoTextsFromBlocks children

        Block.HtmlComment _ ->
            []

        Block.ProcessingInstruction _ ->
            []

        Block.HtmlDeclaration _ _ ->
            []

        Block.Cdata _ ->
            []


todoTextsFromInlines : List Block.Inline -> List String
todoTextsFromInlines inlines =
    inlines
        |> List.concatMap todoTextsFromInline


todoTextsFromInline : Block.Inline -> List String
todoTextsFromInline inline =
    case inline of
        Block.Text text ->
            TodoSyntax.todoTextsFromPlainText text

        Block.Link _ _ children ->
            todoTextsFromInlines children

        Block.Image _ _ children ->
            todoTextsFromInlines children

        Block.Emphasis children ->
            todoTextsFromInlines children

        Block.Strong children ->
            todoTextsFromInlines children

        Block.Strikethrough children ->
            todoTextsFromInlines children

        Block.HtmlInline html ->
            todoTextsFromHtml html

        Block.CodeSpan _ ->
            []

        Block.HardLineBreak ->
            []

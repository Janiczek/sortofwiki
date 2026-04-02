module WikiMarkdown exposing (postProcessBlocksWithWikiLinks)

import Markdown.Block as Block
import Wiki
import WikiLinkSyntax


{-| Turn `[[slug]]` / `[[slug|label]]` inside markdown `Text` inlines into `Link` inlines pointing at the published page on the given wiki.
-}
postProcessBlocksWithWikiLinks : Wiki.Slug -> List Block.Block -> List Block.Block
postProcessBlocksWithWikiLinks wikiSlug blocks =
    List.map (mapBlock wikiSlug) blocks


mapBlock : Wiki.Slug -> Block.Block -> Block.Block
mapBlock wikiSlug block =
    case block of
        Block.HtmlBlock html ->
            Block.HtmlBlock (mapHtml wikiSlug html)

        Block.UnorderedList spacing items ->
            Block.UnorderedList spacing (List.map (mapListItem wikiSlug) items)

        Block.OrderedList spacing start rows ->
            Block.OrderedList spacing start (List.map (List.map (mapBlock wikiSlug)) rows)

        Block.BlockQuote inner ->
            Block.BlockQuote (List.map (mapBlock wikiSlug) inner)

        Block.Heading level inlines ->
            Block.Heading level (expandInlines wikiSlug inlines)

        Block.Paragraph inlines ->
            Block.Paragraph (expandInlines wikiSlug inlines)

        Block.Table headers rows ->
            Block.Table
                (List.map
                    (\h ->
                        { label = expandInlines wikiSlug h.label
                        , alignment = h.alignment
                        }
                    )
                    headers
                )
                (List.map (List.map (expandInlines wikiSlug)) rows)

        Block.CodeBlock _ ->
            block

        Block.ThematicBreak ->
            block


mapListItem : Wiki.Slug -> Block.ListItem Block.Block -> Block.ListItem Block.Block
mapListItem wikiSlug (Block.ListItem task children) =
    Block.ListItem task (List.map (mapBlock wikiSlug) children)


mapHtml : Wiki.Slug -> Block.Html Block.Block -> Block.Html Block.Block
mapHtml wikiSlug html =
    case html of
        Block.HtmlElement name attrs children ->
            Block.HtmlElement name attrs (List.map (mapBlock wikiSlug) children)

        Block.HtmlComment _ ->
            html

        Block.ProcessingInstruction _ ->
            html

        Block.HtmlDeclaration _ _ ->
            html

        Block.Cdata _ ->
            html


expandInlines : Wiki.Slug -> List Block.Inline -> List Block.Inline
expandInlines wikiSlug inlines =
    List.concatMap (expandInline wikiSlug) inlines


expandInline : Wiki.Slug -> Block.Inline -> List Block.Inline
expandInline wikiSlug inline =
    case inline of
        Block.Text s ->
            WikiLinkSyntax.segmentsFromPlainText s
                |> List.map (segmentToInline wikiSlug)
                |> List.filter
                    (\il ->
                        case il of
                            Block.Text "" ->
                                False

                            _ ->
                                True
                    )

        Block.Link destination title children ->
            [ Block.Link destination title (expandInlines wikiSlug children) ]

        Block.Image destination title children ->
            [ Block.Image destination title (expandInlines wikiSlug children) ]

        Block.Emphasis children ->
            [ Block.Emphasis (expandInlines wikiSlug children) ]

        Block.Strong children ->
            [ Block.Strong (expandInlines wikiSlug children) ]

        Block.Strikethrough children ->
            [ Block.Strikethrough (expandInlines wikiSlug children) ]

        Block.HtmlInline html ->
            [ Block.HtmlInline (mapHtml wikiSlug html) ]

        Block.CodeSpan _ ->
            [ inline ]

        Block.HardLineBreak ->
            [ inline ]


segmentToInline : Wiki.Slug -> WikiLinkSyntax.Segment -> Block.Inline
segmentToInline wikiSlug seg =
    case seg of
        WikiLinkSyntax.Plain t ->
            Block.Text t

        WikiLinkSyntax.WikiRef slug display ->
            Block.Link (Wiki.publishedPageUrlPath wikiSlug slug) Nothing [ Block.Text display ]

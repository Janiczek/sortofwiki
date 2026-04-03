module WikiMarkdown exposing (postProcessBlocksWithWikiLinks)

import Markdown.Block as Block
import Page
import Wiki
import WikiLinkSyntax


{-| Turn `[[slug]]` / `[[slug|label]]` inside markdown `Text` inlines into `Link` inlines pointing at the published page on the given wiki.
Links to slugs where `publishedSlugExists` is false use title `sortofwiki:missing` so the HTML renderer can style them.
-}
postProcessBlocksWithWikiLinks : Wiki.Slug -> (Page.Slug -> Bool) -> List Block.Block -> List Block.Block
postProcessBlocksWithWikiLinks wikiSlug publishedSlugExists blocks =
    List.map (mapBlock wikiSlug publishedSlugExists) blocks


mapBlock : Wiki.Slug -> (Page.Slug -> Bool) -> Block.Block -> Block.Block
mapBlock wikiSlug publishedSlugExists block =
    case block of
        Block.HtmlBlock html ->
            Block.HtmlBlock (mapHtml wikiSlug publishedSlugExists html)

        Block.UnorderedList spacing items ->
            Block.UnorderedList spacing (List.map (mapListItem wikiSlug publishedSlugExists) items)

        Block.OrderedList spacing start rows ->
            Block.OrderedList spacing start (List.map (List.map (mapBlock wikiSlug publishedSlugExists)) rows)

        Block.BlockQuote inner ->
            Block.BlockQuote (List.map (mapBlock wikiSlug publishedSlugExists) inner)

        Block.Heading level inlines ->
            Block.Heading level (expandInlines wikiSlug publishedSlugExists inlines)

        Block.Paragraph inlines ->
            Block.Paragraph (expandInlines wikiSlug publishedSlugExists inlines)

        Block.Table headers rows ->
            Block.Table
                (List.map
                    (\h ->
                        { label = expandInlines wikiSlug publishedSlugExists h.label
                        , alignment = h.alignment
                        }
                    )
                    headers
                )
                (List.map (List.map (expandInlines wikiSlug publishedSlugExists)) rows)

        Block.CodeBlock _ ->
            block

        Block.ThematicBreak ->
            block


mapListItem : Wiki.Slug -> (Page.Slug -> Bool) -> Block.ListItem Block.Block -> Block.ListItem Block.Block
mapListItem wikiSlug publishedSlugExists (Block.ListItem task children) =
    Block.ListItem task (List.map (mapBlock wikiSlug publishedSlugExists) children)


mapHtml : Wiki.Slug -> (Page.Slug -> Bool) -> Block.Html Block.Block -> Block.Html Block.Block
mapHtml wikiSlug publishedSlugExists html =
    case html of
        Block.HtmlElement name attrs children ->
            Block.HtmlElement name attrs (List.map (mapBlock wikiSlug publishedSlugExists) children)

        Block.HtmlComment _ ->
            html

        Block.ProcessingInstruction _ ->
            html

        Block.HtmlDeclaration _ _ ->
            html

        Block.Cdata _ ->
            html


expandInlines : Wiki.Slug -> (Page.Slug -> Bool) -> List Block.Inline -> List Block.Inline
expandInlines wikiSlug publishedSlugExists inlines =
    List.concatMap (expandInline wikiSlug publishedSlugExists) inlines


expandInline : Wiki.Slug -> (Page.Slug -> Bool) -> Block.Inline -> List Block.Inline
expandInline wikiSlug publishedSlugExists inline =
    case inline of
        Block.Text s ->
            WikiLinkSyntax.segmentsFromPlainText s
                |> List.map (segmentToInline wikiSlug publishedSlugExists)
                |> List.filter
                    (\il ->
                        case il of
                            Block.Text "" ->
                                False

                            _ ->
                                True
                    )

        Block.Link destination title children ->
            [ Block.Link destination title (expandInlines wikiSlug publishedSlugExists children) ]

        Block.Image destination title children ->
            [ Block.Image destination title (expandInlines wikiSlug publishedSlugExists children) ]

        Block.Emphasis children ->
            [ Block.Emphasis (expandInlines wikiSlug publishedSlugExists children) ]

        Block.Strong children ->
            [ Block.Strong (expandInlines wikiSlug publishedSlugExists children) ]

        Block.Strikethrough children ->
            [ Block.Strikethrough (expandInlines wikiSlug publishedSlugExists children) ]

        Block.HtmlInline html ->
            [ Block.HtmlInline (mapHtml wikiSlug publishedSlugExists html) ]

        Block.CodeSpan _ ->
            [ inline ]

        Block.HardLineBreak ->
            [ inline ]


segmentToInline : Wiki.Slug -> (Page.Slug -> Bool) -> WikiLinkSyntax.Segment -> Block.Inline
segmentToInline wikiSlug publishedSlugExists seg =
    case seg of
        WikiLinkSyntax.Plain t ->
            Block.Text t

        WikiLinkSyntax.WikiRef slug display ->
            if publishedSlugExists slug then
                Block.Link (Wiki.publishedPageUrlPath wikiSlug slug) Nothing [ Block.Text display ]

            else
                Block.Link (Wiki.publishedPageUrlPath wikiSlug slug) (Just "sortofwiki:missing") [ Block.Text display ]

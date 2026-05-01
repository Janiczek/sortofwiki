module WikiPageMarkdownParse exposing (blocksWithHeadingSlugs)

import Markdown.Block as Block
import Markdown.Parser as MarkdownParser
import MarkdownHeadingSlugs
import MarkdownMath
import MarkdownTypographicSubstitutions
import Page
import Wiki
import WikiLinkSyntax
import WikiMarkdown


{-| Parsed blocks with `Maybe String` heading slug metadata (GitHub-style), after wiki-link expansion.
-}
blocksWithHeadingSlugs : Wiki.Slug -> (Page.Slug -> Bool) -> String -> Result String (List ( Block.Block, Maybe String ))
blocksWithHeadingSlugs wikiSlug publishedSlugExists source =
    source
        |> WikiLinkSyntax.escapeLabelPipesInWikiLinks
        |> MarkdownParser.parse
        |> Result.mapError (List.map MarkdownParser.deadEndToString >> String.join "\n")
        |> Result.map (WikiMarkdown.postProcessBlocksWithWikiLinks wikiSlug publishedSlugExists)
        |> Result.map MarkdownMath.postProcessBlocksWithEquations
        |> Result.map MarkdownTypographicSubstitutions.postProcessBlocksWithTypographicSubstitutions
        |> Result.map MarkdownHeadingSlugs.gatherHeadingOccurrences

module WikiPageMarkdownParse exposing (blocksWithHeadingSlugs)

import Markdown.Block as Block
import Markdown.Parser as MarkdownParser
import MarkdownHeadingSlugs
import Wiki
import WikiMarkdown


{-| Parsed blocks with `Maybe String` heading slug metadata (GitHub-style), after wiki-link expansion.
-}
blocksWithHeadingSlugs : Wiki.Slug -> String -> Result String (List ( Block.Block, Maybe String ))
blocksWithHeadingSlugs wikiSlug source =
    source
        |> MarkdownParser.parse
        |> Result.mapError deadEndsToString
        |> Result.map (WikiMarkdown.postProcessBlocksWithWikiLinks wikiSlug)
        |> Result.map MarkdownHeadingSlugs.gatherHeadingOccurrences


deadEndsToString deadEnds =
    deadEnds
        |> List.map MarkdownParser.deadEndToString
        |> String.join "\n"

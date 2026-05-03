module MarkdownWords exposing (count)

{-| Word count for wiki stats: `String.words` on published markdown body.

Markdown tokens (headings, link brackets) count as separate words; cheap, deterministic.
-}


count : String -> Int
count markdown =
    if String.isEmpty (String.trim markdown) then
        0

    else
        markdown
            |> String.words
            |> List.length

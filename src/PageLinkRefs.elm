module PageLinkRefs exposing (linkedPageSlugs)

import Page
import Set


{-| Published page slugs referenced from markdown in the given wiki (absolute `/w/.../p/...` links,
same-wiki `](p/slug)` and `](./p/slug)`, and `[[slug]]` / `[[slug|label]]` wiki links).
First argument is the wiki path segment (same as `Wiki.Slug`). Results are sorted and deduplicated.
-}
linkedPageSlugs : String -> String -> List Page.Slug
linkedPageSlugs wikiSlug markdown =
    [ collectWithPrefix ("](/w/" ++ wikiSlug ++ "/p/") markdown
    , collectWithPrefix "](p/" markdown
    , collectWithPrefix "](./p/" markdown
    , collectWikiLinks markdown
    ]
        |> List.concat
        |> Set.fromList
        |> Set.toList


collectWithPrefix : String -> String -> List Page.Slug
collectWithPrefix prefix content =
    collectWithPrefixHelp prefix content []


collectWithPrefixHelp : String -> String -> List Page.Slug -> List Page.Slug
collectWithPrefixHelp prefix remaining acc =
    case String.indexes prefix remaining |> List.head of
        Nothing ->
            acc

        Just i ->
            let
                fragment : String
                fragment =
                    remaining
                        |> String.dropLeft (i + String.length prefix)
            in
            case chompMarkdownUrlTarget fragment of
                Nothing ->
                    collectWithPrefixHelp prefix (String.dropLeft (i + 1) remaining) acc

                Just ( slug, consumed ) ->
                    collectWithPrefixHelp prefix
                        (String.dropLeft (i + String.length prefix + consumed) remaining)
                        (slug :: acc)


chompMarkdownUrlTarget : String -> Maybe ( Page.Slug, Int )
chompMarkdownUrlTarget s =
    let
        ( slug, slugEnd ) =
            readSlugChars s 0 ""
    in
    if slug == "" then
        Nothing

    else
        String.dropLeft slugEnd s
            |> skipToCloseParen
            |> Maybe.map (\n -> ( slug, slugEnd + n ))


readSlugChars : String -> Int -> String -> ( String, Int )
readSlugChars s offset acc =
    case String.uncons (String.dropLeft offset s) of
        Nothing ->
            ( acc, offset )

        Just ( c, _ ) ->
            if Char.isAlphaNum c || c == '-' || c == '_' then
                readSlugChars s (offset + 1) (acc ++ String.fromChar c)

            else
                ( acc, offset )


skipToCloseParen : String -> Maybe Int
skipToCloseParen s =
    case String.uncons s of
        Nothing ->
            Nothing

        Just ( ')', _ ) ->
            Just 1

        Just ( _, rest ) ->
            skipToCloseParen rest
                |> Maybe.map (\n -> n + 1)


collectWikiLinks : String -> List Page.Slug
collectWikiLinks content =
    collectWikiLinksHelp content []


collectWikiLinksHelp : String -> List Page.Slug -> List Page.Slug
collectWikiLinksHelp remaining acc =
    case String.indexes "[[" remaining |> List.head of
        Nothing ->
            acc

        Just i ->
            let
                inner : String
                inner =
                    remaining
                        |> String.dropLeft (i + 2)
            in
            case parseWikiLink inner of
                Nothing ->
                    collectWikiLinksHelp (String.dropLeft (i + 1) remaining) acc

                Just ( slug, consumed ) ->
                    collectWikiLinksHelp
                        (String.dropLeft (i + 2 + consumed) remaining)
                        (slug :: acc)


parseWikiLink : String -> Maybe ( Page.Slug, Int )
parseWikiLink s =
    let
        ( slug, slugEnd ) =
            readSlugChars s 0 ""
    in
    if slug == "" then
        Nothing

    else
        let
            afterSlug : String
            afterSlug =
                String.dropLeft slugEnd s
        in
        if String.startsWith "]]" afterSlug then
            Just ( slug, slugEnd + 2 )

        else if String.startsWith "|" afterSlug then
            String.dropLeft 1 afterSlug
                |> skipToDoubleBracketClose
                |> Maybe.map (\k -> ( slug, slugEnd + 1 + k ))

        else
            Nothing


skipToDoubleBracketClose : String -> Maybe Int
skipToDoubleBracketClose s =
    case String.indexes "]]" s |> List.head of
        Nothing ->
            Nothing

        Just j ->
            Just (j + 2)

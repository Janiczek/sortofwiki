module WikiLinkSyntax exposing (Segment(..), escapeLabelPipesInWikiLinks, segmentsFromPlainText, wikiRefSlugsFromPlainText)

import Page


{-| Plain text runs and `[[slug]]` / `[[slug|label]]` wiki references as they appear in markdown `Text` inlines.
-}
type Segment
    = Plain String
    | WikiRef Page.Slug String


{-| Slugs referenced by wiki links in a string (same scan semantics as backlink extraction for `[[...]]`).
-}
wikiRefSlugsFromPlainText : String -> List Page.Slug
wikiRefSlugsFromPlainText text =
    segmentsFromPlainText text
        |> List.filterMap
            (\seg ->
                case seg of
                    Plain _ ->
                        Nothing

                    WikiRef slug _ ->
                        Just slug
            )


{-| Escape `|` inside valid `[[slug|label]]` wiki links so markdown table parsing does not treat them as cell separators.
-}
escapeLabelPipesInWikiLinks : String -> String
escapeLabelPipesInWikiLinks content =
    escapeLabelPipesHelp content ""


escapeLabelPipesHelp : String -> String -> String
escapeLabelPipesHelp remaining acc =
    case String.indexes "[[" remaining |> List.head of
        Nothing ->
            acc ++ remaining

        Just i ->
            let
                before : String
                before =
                    String.left i remaining

                inner : String
                inner =
                    String.dropLeft (i + 2) remaining
            in
            case parseWikiLinkInner inner of
                Nothing ->
                    escapeLabelPipesHelp
                        (String.dropLeft (i + 1) remaining)
                        (acc ++ before ++ "[")

                Just parsed ->
                    let
                        rest : String
                        rest =
                            String.dropLeft (i + 2 + parsed.consumed) remaining

                        renderedWikiLink : String
                        renderedWikiLink =
                            if parsed.hasCustomDisplay then
                                "[[" ++ parsed.slug ++ "\\|" ++ String.replace "|" "\\|" parsed.display ++ "]]"

                            else
                                "[[" ++ parsed.slug ++ "]]"
                    in
                    escapeLabelPipesHelp rest (acc ++ before ++ renderedWikiLink)


{-| Split plain text into alternating plain segments and wiki links. Invalid `[[` sequences emit a literal `[` and rescan.
-}
segmentsFromPlainText : String -> List Segment
segmentsFromPlainText content =
    segmentsHelp content []


segmentsHelp : String -> List Segment -> List Segment
segmentsHelp remaining acc =
    case String.indexes "[[" remaining |> List.head of
        Nothing ->
            if remaining == "" then
                acc

            else
                acc ++ [ Plain remaining ]

        Just i ->
            let
                before : String
                before =
                    String.left i remaining

                inner : String
                inner =
                    String.dropLeft (i + 2) remaining
            in
            case parseWikiLinkInner inner of
                Nothing ->
                    let
                        acc1 : List Segment
                        acc1 =
                            if before == "" then
                                acc

                            else
                                acc ++ [ Plain before ]
                    in
                    segmentsHelp (String.dropLeft (i + 1) remaining) (acc1 ++ [ Plain "[" ])

                Just parsed ->
                    let
                        acc1 : List Segment
                        acc1 =
                            if before == "" then
                                acc

                            else
                                acc ++ [ Plain before ]

                        rest : String
                        rest =
                            String.dropLeft (i + 2 + parsed.consumed) remaining
                    in
                    segmentsHelp rest (acc1 ++ [ WikiRef parsed.slug parsed.display ])


type alias ParsedWikiLink =
    { slug : Page.Slug
    , display : String
    , consumed : Int
    , hasCustomDisplay : Bool
    }


parseWikiLinkInner : String -> Maybe ParsedWikiLink
parseWikiLinkInner s =
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
            Just
                { slug = slug
                , display = slug
                , consumed = slugEnd + 2
                , hasCustomDisplay = False
                }

        else if String.startsWith "|" afterSlug then
            let
                afterBar : String
                afterBar =
                    String.dropLeft 1 afterSlug
            in
            case String.indexes "]]" afterBar |> List.head of
                Nothing ->
                    Nothing

                Just j ->
                    Just
                        { slug = slug
                        , display = String.left j afterBar
                        , consumed = slugEnd + 1 + j + 2
                        , hasCustomDisplay = True
                        }

        else if String.startsWith "\\|" afterSlug then
            let
                afterEscapedBar : String
                afterEscapedBar =
                    String.dropLeft 2 afterSlug
            in
            case String.indexes "]]" afterEscapedBar |> List.head of
                Nothing ->
                    Nothing

                Just j ->
                    Just
                        { slug = slug
                        , display =
                            String.left j afterEscapedBar
                                |> String.replace "\\|" "|"
                        , consumed = slugEnd + 2 + j + 2
                        , hasCustomDisplay = True
                        }

        else
            Nothing


readSlugChars : String -> Int -> String -> ( String, Int )
readSlugChars s offset acc =
    case String.uncons (String.dropLeft offset s) of
        Nothing ->
            ( acc, offset )

        Just ( c, _ ) ->
            if isSlugLetterOrDigit c then
                readSlugChars s (offset + 1) (acc ++ String.fromChar c)

            else
                ( acc, offset )


isSlugLetterOrDigit : Char -> Bool
isSlugLetterOrDigit c =
    (Char.toLower c /= Char.toUpper c) || Char.isDigit c

module MarkdownHeadingSlugs exposing (gatherHeadingOccurrences)

{-| GitHub-style heading ids for markdown pages (aligned with dillonkearns/elm-markdown `GithubSlugs`).
-}

import Dict exposing (Dict)
import Markdown.Block as Block exposing (Block)
import Regex


gatherHeadingOccurrences : List Block -> List ( Block, Maybe String )
gatherHeadingOccurrences blocks =
    blocks
        |> Block.mapAndAccumulate
            (\soFar block ->
                case block of
                    Block.Heading level inlines ->
                        let
                            rawSlug : String
                            rawSlug =
                                Block.extractInlineText inlines
                                    |> toSlug

                            ( finalSlug, updatedOccurences ) =
                                trackOccurence rawSlug soFar
                        in
                        ( updatedOccurences
                        , ( Block.Heading level inlines, Just finalSlug )
                        )

                    _ ->
                        ( soFar, ( block, Nothing ) )
            )
            Dict.empty
        |> Tuple.second


specials : Regex.Regex
specials =
    "[\u{2000}-\u{206F}⸀-\u{2E7F}\\\\'!\"#$%&()*+,./:;<=>?@[\\\\]^`{|}~’]"
        |> Regex.fromString
        |> Maybe.withDefault Regex.never


whitespace : Regex.Regex
whitespace =
    "\\s"
        |> Regex.fromString
        |> Maybe.withDefault Regex.never


toSlug : String -> String
toSlug string =
    string
        |> String.toLower
        |> Regex.replace specials (\_ -> "")
        |> Regex.replace whitespace (\_ -> "-")


trackOccurence : String -> Dict String Int -> ( String, Dict String Int )
trackOccurence slug occurences =
    case Dict.get slug occurences of
        Just n ->
            occurences
                |> increment slug
                |> trackOccurence (slug ++ "-" ++ String.fromInt n)

        Nothing ->
            ( slug, occurences |> increment slug )


increment : String -> Dict String Int -> Dict String Int
increment value occurences =
    occurences
        |> Dict.update value
            (\maybeOccurence ->
                case maybeOccurence of
                    Just count ->
                        Just (count + 1)

                    Nothing ->
                        Just 1
            )

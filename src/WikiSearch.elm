module WikiSearch exposing (PrefixIndex, ResultItem, buildPrefixIndex, search, searchWithPrefixIndex)

import Dict exposing (Dict)
import Page
import Regex
import Set


type alias SearchDoc =
    { pageSlug : Page.Slug
    , title : String
    , body : String
    , titlePrefixes : List String
    , bodyPrefixes : List String
    }


type alias ResultItem =
    { pageSlug : Page.Slug
    , score : Float
    }


type alias PrefixIndex =
    Dict String (Dict Page.Slug Float)


search : String -> Dict Page.Slug String -> List ResultItem
search rawQuery publishedPageMarkdownSources =
    publishedPageMarkdownSources
        |> buildPrefixIndex
        |> searchWithPrefixIndex rawQuery


buildPrefixIndex : Dict Page.Slug String -> PrefixIndex
buildPrefixIndex publishedPageMarkdownSources =
    let
        docs : List SearchDoc
        docs =
            publishedPageMarkdownSources
                |> Dict.toList
                |> List.map
                    (\( pageSlug, markdown ) ->
                        { pageSlug = pageSlug
                        , title = pageSlug
                        , body = markdown
                        , titlePrefixes = prefixTokens pageSlug
                        , bodyPrefixes = prefixTokens markdown
                        }
                    )
    in
    docs
        |> List.foldl addDocToPrefixIndex Dict.empty


searchWithPrefixIndex : String -> PrefixIndex -> List ResultItem
searchWithPrefixIndex rawQuery prefixIndex =
    let
        query : String
        query =
            String.trim rawQuery
    in
    if String.isEmpty query then
        []

    else
        prefixIndex
            |> Dict.get (String.toLower query)
            |> Maybe.withDefault Dict.empty
            |> Dict.toList
            |> List.map
                (\( pageSlug, score ) ->
                    { pageSlug = pageSlug
                    , score = score
                    }
                )
            |> List.sortWith compareResults


compareResults : ResultItem -> ResultItem -> Order
compareResults left right =
    case compare right.score left.score of
        EQ ->
            compare left.pageSlug right.pageSlug

        nonEqual ->
            nonEqual


addDocToPrefixIndex : SearchDoc -> PrefixIndex -> PrefixIndex
addDocToPrefixIndex doc prefixIndex =
    let
        titlePrefixSet : Set.Set String
        titlePrefixSet =
            doc.titlePrefixes
                |> List.map String.toLower
                |> Set.fromList

        bodyPrefixSet : Set.Set String
        bodyPrefixSet =
            doc.bodyPrefixes
                |> List.map String.toLower
                |> Set.fromList
    in
    prefixIndex
        |> addPrefixSetScore doc.pageSlug 7 titlePrefixSet
        |> addPrefixSetScore doc.pageSlug 1 bodyPrefixSet


addPrefixSetScore : Page.Slug -> Float -> Set.Set String -> PrefixIndex -> PrefixIndex
addPrefixSetScore pageSlug score prefixSet prefixIndex =
    prefixSet
        |> Set.foldl
            (\prefix acc ->
                acc
                    |> Dict.update prefix
                        (\maybeScores ->
                            let
                                existingScores : Dict Page.Slug Float
                                existingScores =
                                    maybeScores
                                        |> Maybe.withDefault Dict.empty

                                previousScore : Float
                                previousScore =
                                    existingScores
                                        |> Dict.get pageSlug
                                        |> Maybe.withDefault 0
                            in
                            existingScores
                                |> Dict.insert pageSlug (previousScore + score)
                                |> Just
                        )
            )
            prefixIndex


prefixTokens : String -> List String
prefixTokens text =
    text
        |> tokenize
        |> List.concatMap tokenPrefixes


tokenPrefixes : String -> List String
tokenPrefixes token =
    let
        tokenLength : Int
        tokenLength =
            String.length token
    in
    if tokenLength < 3 then
        [ token ]

    else
        List.range 3 tokenLength
            |> List.map (\n -> String.left n token)


separatorRegex : Regex.Regex
separatorRegex =
    Regex.fromString "[\\s\\-]+"
        |> Maybe.withDefault Regex.never


tokenize : String -> List String
tokenize text =
    text
        |> String.trim
        |> String.toLower
        |> Regex.split separatorRegex
        |> List.filter (\token -> not (String.isEmpty token))

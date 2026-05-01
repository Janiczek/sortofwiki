module WikiSearch exposing (ResultItem, search)

import Dict exposing (Dict)
import ElmTextSearch
import Index.Defaults
import Page
import Regex


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


search : String -> Dict Page.Slug String -> List ResultItem
search rawQuery publishedPageMarkdownSources =
    let
        query : String
        query =
            String.trim rawQuery

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

        index : ElmTextSearch.Index SearchDoc
        index =
            ElmTextSearch.newWith
                { indexType = "WikiSearch Prefix v1"
                , ref = .pageSlug
                , fields =
                    [ ( .title, 7.0 )
                    , ( .body, 1.0 )
                    ]
                , listFields =
                    [ ( .titlePrefixes, 7.0 )
                    , ( .bodyPrefixes, 1.0 )
                    ]
                , initialTransformFactories = Index.Defaults.defaultInitialTransformFactories
                , transformFactories = []
                , filterFactories = Index.Defaults.defaultFilterFactories
                }
    in
    if String.isEmpty query then
        []

    else
        let
            ( indexWithDocs, addErrors ) =
                ElmTextSearch.addDocs docs index
        in
        if List.length docs == List.length addErrors then
            []

        else
            case ElmTextSearch.search query indexWithDocs of
                Ok ( _, scoredRefs ) ->
                    scoredRefs
                        |> List.map
                            (\( pageSlug, score ) ->
                                { pageSlug = pageSlug
                                , score = score
                                }
                            )

                Err _ ->
                    []


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
        |> List.filter (\token -> String.length token > 0)

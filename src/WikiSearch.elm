module WikiSearch exposing (ResultItem, search)

import Dict exposing (Dict)
import ElmTextSearch
import Page


type alias SearchDoc =
    { pageSlug : Page.Slug
    , title : String
    , body : String
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
                        }
                    )

        index : ElmTextSearch.Index SearchDoc
        index =
            ElmTextSearch.new
                { ref = .pageSlug
                , fields =
                    [ ( .title, 7.0 )
                    , ( .body, 1.0 )
                    ]
                , listFields = []
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

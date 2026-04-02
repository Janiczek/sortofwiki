module PageBacklinksTest exposing (suite)

import Dict exposing (Dict)
import Expect
import Fuzz
import Page
import PageBacklinks
import Test exposing (Test)


suite : Test
suite =
    Test.describe "PageBacklinks"
        [ Test.describe "slugsPointingTo"
            [ Test.test "lists source page with markdown link to target" <|
                \() ->
                    let
                        pages : Dict Page.Slug Page.Page
                        pages =
                            Dict.fromList
                                [ ( "a", Page.withPublished "a" "[x](/w/w/p/b)" )
                                , ( "b", Page.withPublished "b" "lonely" )
                                ]
                    in
                    PageBacklinks.slugsPointingTo "w" "b" pages
                        |> Expect.equal [ "a" ]
            , Test.test "lists source page with wiki link to target" <|
                \() ->
                    let
                        pages : Dict Page.Slug Page.Page
                        pages =
                            Dict.fromList
                                [ ( "a", Page.withPublished "a" "[[b]]" )
                                , ( "b", Page.withPublished "b" "x" )
                                ]
                    in
                    PageBacklinks.slugsPointingTo "w" "b" pages
                        |> Expect.equal [ "a" ]
            , Test.test "excludes the target page itself" <|
                \() ->
                    let
                        pages : Dict Page.Slug Page.Page
                        pages =
                            Dict.singleton "self" (Page.withPublished "self" "[](/w/w/p/self)")
                    in
                    PageBacklinks.slugsPointingTo "w" "self" pages
                        |> Expect.equal []
            , Test.test "deduplicates and sorts sources" <|
                \() ->
                    let
                        pages : Dict Page.Slug Page.Page
                        pages =
                            Dict.fromList
                                [ ( "m", Page.withPublished "m" "[](/w/w/p/t)[](/w/w/p/t)" )
                                , ( "z", Page.withPublished "z" "](p/t)" )
                                , ( "a", Page.withPublished "a" "](p/t)" )
                                , ( "t", Page.withPublished "t" "" )
                                ]
                    in
                    PageBacklinks.slugsPointingTo "w" "t" pages
                        |> Expect.equal [ "a", "m", "z" ]
            , Test.test "ignores links only in pending markdown" <|
                \() ->
                    let
                        pages : Dict Page.Slug Page.Page
                        pages =
                            Dict.fromList
                                [ ( "src", Page.withPublishedAndPending "src" "no" "[[tgt]]" )
                                , ( "tgt", Page.withPublished "tgt" "x" )
                                ]
                    in
                    PageBacklinks.slugsPointingTo "w" "tgt" pages
                        |> Expect.equal []
            , Test.fuzz (Fuzz.pair Fuzz.string Fuzz.string) "singleton wiki yields no backlinks for sole page" <|
                \( wikiSlug, pageSlug ) ->
                    let
                        pages : Dict Page.Slug Page.Page
                        pages =
                            Dict.singleton pageSlug (Page.withPublished pageSlug "solo")
                    in
                    PageBacklinks.slugsPointingTo wikiSlug pageSlug pages
                        |> Expect.equal []
            ]
        ]

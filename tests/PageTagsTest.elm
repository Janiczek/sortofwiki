module PageTagsTest exposing (suite)

import Dict exposing (Dict)
import Expect
import Page
import PageTags
import Test exposing (Test)


suite : Test
suite =
    Test.describe "PageTags"
        [ Test.describe "slugsPointingToTag"
            [ Test.test "finds pages tagged with target slug" <|
                \() ->
                    let
                        source : Page.Page
                        source =
                            let
                                base : Page.Page
                                base =
                                    Page.withPublished "Source" "x"
                            in
                            { base | tags = [ "Tag" ] }

                        pages : Dict Page.Slug Page.Page
                        pages =
                            Dict.fromList
                                [ ( "Source", source )
                                , ( "Tag", Page.withPublished "Tag" "body" )
                                ]
                    in
                    PageTags.slugsPointingToTag "Tag" pages
                        |> Expect.equal [ "Source" ]
            , Test.test "deduplicates and excludes target page itself" <|
                \() ->
                    let
                        tagPage : Page.Page
                        tagPage =
                            let
                                base : Page.Page
                                base =
                                    Page.withPublished "Tag" "x"
                            in
                            { base | tags = [ "Tag" ] }

                        pageB : Page.Page
                        pageB =
                            let
                                base : Page.Page
                                base =
                                    Page.withPublished "B" "x"
                            in
                            { base | tags = [ "Tag", "Tag" ] }

                        pageA : Page.Page
                        pageA =
                            let
                                base : Page.Page
                                base =
                                    Page.withPublished "A" "x"
                            in
                            { base | tags = [ "Tag" ] }

                        pages : Dict Page.Slug Page.Page
                        pages =
                            Dict.fromList
                                [ ( "Tag", tagPage )
                                , ( "B", pageB )
                                , ( "A", pageA )
                                ]
                    in
                    PageTags.slugsPointingToTag "Tag" pages
                        |> Expect.equal [ "A", "B" ]
            , Test.test "matches tag references case-insensitively" <|
                \() ->
                    let
                        source : Page.Page
                        source =
                            let
                                base : Page.Page
                                base =
                                    Page.withPublished "source" "x"
                            in
                            { base | tags = [ "TaG" ] }

                        pages : Dict Page.Slug Page.Page
                        pages =
                            Dict.fromList
                                [ ( "source", source )
                                , ( "tag", Page.withPublished "tag" "body" )
                                ]
                    in
                    PageTags.slugsPointingToTag "tag" pages
                        |> Expect.equal [ "source" ]
            ]
        ]

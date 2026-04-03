module PageLinkRefsTest exposing (suite)

import Expect
import Fuzz
import Fuzzers
import PageLinkRefs
import Test exposing (Test)


suite : Test
suite =
    Test.describe "PageLinkRefs"
        [ Test.describe "linkedPageSlugs"
            [ Test.test "parses absolute /w/wiki/p/slug markdown link" <|
                \() ->
                    PageLinkRefs.linkedPageSlugs "Demo" "[t](/w/Demo/p/guides)"
                        |> Expect.equal [ "guides" ]
            , Test.test "parses multiple absolute links and sorts uniquely" <|
                \() ->
                    PageLinkRefs.linkedPageSlugs "w"
                        "[a](/w/w/p/z) [b](/w/w/p/a) [c](/w/w/p/z)"
                        |> Expect.equal [ "a", "z" ]
            , Test.test "ignores links for a different wiki slug" <|
                \() ->
                    PageLinkRefs.linkedPageSlugs "Demo" "[t](/w/other/p/secret)"
                        |> Expect.equal []
            , Test.test "parses same-wiki ](p/slug) link" <|
                \() ->
                    PageLinkRefs.linkedPageSlugs "Demo" "See [x](p/about)."
                        |> Expect.equal [ "about" ]
            , Test.test "parses same-wiki ](./p/slug) link" <|
                \() ->
                    PageLinkRefs.linkedPageSlugs "Demo" "See [x](./p/about)."
                        |> Expect.equal [ "about" ]
            , Test.test "parses [[wiki]] link" <|
                \() ->
                    PageLinkRefs.linkedPageSlugs "Demo" "See [[home]] here."
                        |> Expect.equal [ "home" ]
            , Test.test "parses [[slug|label]] link" <|
                \() ->
                    PageLinkRefs.linkedPageSlugs "Demo" "[[guides|Help]]"
                        |> Expect.equal [ "guides" ]
            , Test.test "stops slug at URL fragment" <|
                \() ->
                    PageLinkRefs.linkedPageSlugs "Demo" "[t](/w/Demo/p/sec#x)"
                        |> Expect.equal [ "sec" ]
            , Test.fuzz Fuzzers.wikiSlug "absolute link target appears in result" <|
                \wikiSlug ->
                    let
                        pageSlug : String
                        pageSlug =
                            "pg"

                        body : String
                        body =
                            "[l](/w/" ++ wikiSlug ++ "/p/" ++ pageSlug ++ ")"
                    in
                    PageLinkRefs.linkedPageSlugs wikiSlug body
                        |> List.member pageSlug
                        |> Expect.equal True
            , Test.fuzz Fuzz.string "result has no empty strings" <|
                \noise ->
                    PageLinkRefs.linkedPageSlugs "any" noise
                        |> List.all (\s -> s /= "")
                        |> Expect.equal True
            ]
        ]

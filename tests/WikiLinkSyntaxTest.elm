module WikiLinkSyntaxTest exposing (suite)

import Expect
import Fuzz
import Page
import Test exposing (Test)
import WikiLinkSyntax


suite : Test
suite =
    Test.describe "WikiLinkSyntax"
        [ Test.describe "segmentsFromPlainText"
            [ Test.test "splits [[slug]] into wiki ref with slug as label" <|
                \() ->
                    WikiLinkSyntax.segmentsFromPlainText "See [[home]] here."
                        |> Expect.equal
                            [ WikiLinkSyntax.Plain "See "
                            , WikiLinkSyntax.WikiRef "home" "home"
                            , WikiLinkSyntax.Plain " here."
                            ]
            , Test.test "parses [[slug|label]]" <|
                \() ->
                    WikiLinkSyntax.segmentsFromPlainText "[[guides|Help]]"
                        |> Expect.equal [ WikiLinkSyntax.WikiRef "guides" "Help" ]
            , Test.test "invalid opener emits bracket and continues" <|
                \() ->
                    WikiLinkSyntax.segmentsFromPlainText "a [[x"
                        |> Expect.equal
                            [ WikiLinkSyntax.Plain "a "
                            , WikiLinkSyntax.Plain "["
                            , WikiLinkSyntax.Plain "[x"
                            ]
            , Test.fuzz (Fuzz.intRange 1 200) "embedded [[n]] yields that slug" <|
                \n ->
                    let
                        slug : String
                        slug =
                            "p" ++ String.fromInt n

                        s : String
                        s =
                            "pre[["
                                ++ slug
                                ++ "]]post"
                    in
                    WikiLinkSyntax.segmentsFromPlainText s
                        |> Expect.equal
                            [ WikiLinkSyntax.Plain "pre"
                            , WikiLinkSyntax.WikiRef slug slug
                            , WikiLinkSyntax.Plain "post"
                            ]
            , Test.fuzz Fuzz.string "concatenating segment texts round-trips when no wiki links" <|
                \noise ->
                    let
                        hasWiki : Bool
                        hasWiki =
                            String.contains "[[" noise
                    in
                    if hasWiki then
                        Expect.pass

                    else
                        WikiLinkSyntax.segmentsFromPlainText noise
                            |> List.map segmentToText
                            |> String.concat
                            |> Expect.equal noise
            ]
        , Test.describe "wikiRefSlugsFromPlainText"
            [ Test.fuzz (Fuzz.intRange 0 500) "slug inside valid link appears in list" <|
                \n ->
                    let
                        slug : Page.Slug
                        slug =
                            "s" ++ String.fromInt n
                    in
                    WikiLinkSyntax.wikiRefSlugsFromPlainText ("[[" ++ slug ++ "]]")
                        |> Expect.equal [ slug ]
            ]
        ]


segmentToText : WikiLinkSyntax.Segment -> String
segmentToText seg =
    case seg of
        WikiLinkSyntax.Plain t ->
            t

        WikiLinkSyntax.WikiRef slug display ->
            "[[" ++ slug ++ "|" ++ display ++ "]]"

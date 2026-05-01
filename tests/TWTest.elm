module TWTest exposing (suite)

import Fuzz
import Html
import Html.Attributes as Attr
import TW
import Test exposing (Test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    Test.describe "TW"
        [ Test.describe "cls"
            [ Test.test "sets class string" <|
                \() ->
                    Html.div [ TW.cls "a b" ] []
                        |> Query.fromHtml
                        |> Query.has [ Selector.classes [ "a", "b" ] ]
            ]
        , Test.describe "mod"
            [ Test.test "prefixes each utility" <|
                \() ->
                    Html.div [ TW.mod "hover" "bg-blue-400 text-[0.8125rem]" ] []
                        |> Query.fromHtml
                        |> Query.has
                            [ Selector.classes [ "hover:bg-blue-400", "hover:text-[0.8125rem]" ] ]
            , Test.test "ignores extra whitespace" <|
                \() ->
                    Html.div [ TW.mod "md" "  w-full  h-4  " ] []
                        |> Query.fromHtml
                        |> Query.has [ Selector.classes [ "md:w-full", "md:h-4" ] ]
            , Test.fuzz
                (Fuzz.map2 Tuple.pair
                    Fuzz.string
                    nonEmptyUtilities
                )
                "composed class string matches whitespace-split prefixing"
              <|
                \( variant, utilities ) ->
                    let
                        expected : String
                        expected =
                            utilities
                                |> String.words
                                |> List.filter (\w -> w /= "")
                                |> List.map (\u -> variant ++ ":" ++ u)
                                |> String.join " "
                    in
                    Html.div [ TW.mod variant utilities ] []
                        |> Query.fromHtml
                        |> Query.has [ Selector.attribute (Attr.class expected) ]
            ]
        ]


nonEmptyUtilities : Fuzz.Fuzzer String
nonEmptyUtilities =
    Fuzz.map2
        (\w ws ->
            (w :: ws)
                |> String.join " "
        )
        utilityToken
        (Fuzz.list utilityToken)


utilityToken : Fuzz.Fuzzer String
utilityToken =
    Fuzz.map (\n -> "u" ++ String.fromInt n) (Fuzz.intRange 0 100000)

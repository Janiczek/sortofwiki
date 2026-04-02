module HostedWikiSlugPolicyTest exposing (suite)

import Expect
import HostedWikiSlugPolicy
import Test exposing (Test)


suite : Test
suite =
    Test.describe "HostedWikiSlugPolicy"
        [ Test.describe "formValue"
            [ Test.test "StrictSlugs" <|
                \() ->
                    HostedWikiSlugPolicy.formValue HostedWikiSlugPolicy.StrictSlugs
                        |> Expect.equal "StrictSlugs"
            , Test.test "AllowAny" <|
                \() ->
                    HostedWikiSlugPolicy.formValue HostedWikiSlugPolicy.AllowAny
                        |> Expect.equal "AllowAny"
            ]
        , Test.describe "fromFormValue"
            [ Test.test "StrictSlugs" <|
                \() ->
                    HostedWikiSlugPolicy.fromFormValue "StrictSlugs"
                        |> Expect.equal (Just HostedWikiSlugPolicy.StrictSlugs)
            , Test.test "AllowAny" <|
                \() ->
                    HostedWikiSlugPolicy.fromFormValue "AllowAny"
                        |> Expect.equal (Just HostedWikiSlugPolicy.AllowAny)
            , Test.test "unknown" <|
                \() ->
                    HostedWikiSlugPolicy.fromFormValue "nope"
                        |> Expect.equal Nothing
            ]
        , Test.describe "label"
            [ Test.test "StrictSlugs mentions Strict" <|
                \() ->
                    HostedWikiSlugPolicy.label HostedWikiSlugPolicy.StrictSlugs
                        |> String.contains "Strict"
                        |> Expect.equal True
            , Test.test "AllowAny mentions Allow" <|
                \() ->
                    HostedWikiSlugPolicy.label HostedWikiSlugPolicy.AllowAny
                        |> String.contains "Allow"
                        |> Expect.equal True
            ]
        ]

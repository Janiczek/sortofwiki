module ColorThemeTest exposing (suite)

import ColorTheme exposing (ColorTheme(..), ColorThemePreference(..), Incoming(..), cyclePreference, effectiveColorTheme, encodePreferenceToJs, incomingDecoder)
import Expect
import Fuzz
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test)


suite : Test
suite =
    Test.describe "ColorTheme"
        [ Test.describe "effectiveColorTheme"
            [ Test.test "follows system when preference is FollowSystem" <|
                \() ->
                    effectiveColorTheme FollowSystem Dark
                        |> Expect.equal Dark
            , Test.test "uses fixed theme when set" <|
                \() ->
                    effectiveColorTheme (Fixed Light) Dark
                        |> Expect.equal Light
            ]
        , Test.describe "cyclePreference"
            [ Test.test "returns to FollowSystem after three steps" <|
                \() ->
                    FollowSystem
                        |> cyclePreference
                        |> cyclePreference
                        |> cyclePreference
                        |> Expect.equal FollowSystem
            , Test.test "first step from FollowSystem is fixed light" <|
                \() ->
                    cyclePreference FollowSystem
                        |> Expect.equal (Fixed Light)
            , Test.fuzz colorThemePreferenceFuzz "three cycles is identity" <|
                \pref ->
                    pref
                        |> cyclePreference
                        |> cyclePreference
                        |> cyclePreference
                        |> Expect.equal pref
            ]
        , Test.describe "incomingDecoder"
            [ Test.test "decodes sync" <|
                \() ->
                    """{"kind":"sync","preference":"system","systemScheme":"light"}"""
                        |> Decode.decodeString incomingDecoder
                        |> Expect.equal (Ok (Sync FollowSystem Light))
            , Test.test "decodes system-only" <|
                \() ->
                    """{"kind":"system","systemScheme":"dark"}"""
                        |> Decode.decodeString incomingDecoder
                        |> Expect.equal (Ok (System Dark))
            ]
        , Test.describe "encodePreferenceToJs"
            [ Test.test "encodes system" <|
                \() ->
                    encodePreferenceToJs FollowSystem
                        |> Expect.equal (Encode.object [ ( "preference", Encode.string "system" ) ])
            ]
        ]


colorThemePreferenceFuzz : Fuzz.Fuzzer ColorThemePreference
colorThemePreferenceFuzz =
    Fuzz.oneOf
        [ Fuzz.constant FollowSystem
        , Fuzz.constant (Fixed Light)
        , Fuzz.constant (Fixed Dark)
        ]

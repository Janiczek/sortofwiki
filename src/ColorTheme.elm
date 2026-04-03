module ColorTheme exposing
    ( ColorTheme(..)
    , ColorThemePreference(..)
    , Incoming(..)
    , cyclePreference
    , effectiveColorTheme
    , encodePreferenceToJs
    , incomingDecoder
    )

{-| UI color mode (light vs dark) and whether to follow the OS or use a fixed choice.
-}

import Json.Decode as Decode
import Json.Encode as Encode


type ColorTheme
    = Light
    | Dark


{-| `FollowSystem` tracks `prefers-color-scheme`; `Fixed` ignores it until the user returns to system mode.
-}
type ColorThemePreference
    = FollowSystem
    | Fixed ColorTheme


effectiveColorTheme : ColorThemePreference -> ColorTheme -> ColorTheme
effectiveColorTheme preference systemTheme =
    case preference of
        FollowSystem ->
            systemTheme

        Fixed theme ->
            theme


cyclePreference : ColorThemePreference -> ColorThemePreference
cyclePreference preference =
    case preference of
        FollowSystem ->
            Fixed Light

        Fixed Light ->
            Fixed Dark

        Fixed Dark ->
            FollowSystem


encodePreferenceToJs : ColorThemePreference -> Encode.Value
encodePreferenceToJs preference =
    Encode.object
        [ ( "preference", Encode.string (preferenceToStorageString preference) )
        ]


preferenceToStorageString : ColorThemePreference -> String
preferenceToStorageString preference =
    case preference of
        FollowSystem ->
            "system"

        Fixed Light ->
            "light"

        Fixed Dark ->
            "dark"


preferenceFromStorageString : String -> Maybe ColorThemePreference
preferenceFromStorageString raw =
    case raw of
        "light" ->
            Just (Fixed Light)

        "dark" ->
            Just (Fixed Dark)

        "system" ->
            Just FollowSystem

        _ ->
            Nothing


themeFromSchemeString : String -> Maybe ColorTheme
themeFromSchemeString raw =
    case raw of
        "light" ->
            Just Light

        "dark" ->
            Just Dark

        _ ->
            Nothing


{-| Messages from `elm-pkg-js/color-theme.js`.
-}
type Incoming
    = Sync ColorThemePreference ColorTheme
    | System ColorTheme


incomingDecoder : Decode.Decoder Incoming
incomingDecoder =
    Decode.field "kind" Decode.string
        |> Decode.andThen incomingFromKind


incomingFromKind : String -> Decode.Decoder Incoming
incomingFromKind kind =
    case kind of
        "sync" ->
            Decode.map2 Sync
                (Decode.field "preference" Decode.string
                    |> Decode.andThen decodePreferenceField
                )
                (Decode.field "systemScheme" Decode.string
                    |> Decode.andThen decodeSchemeField
                )

        "system" ->
            Decode.map System
                (Decode.field "systemScheme" Decode.string
                    |> Decode.andThen decodeSchemeField
                )

        _ ->
            Decode.fail ("Unknown color theme kind: " ++ kind)


decodePreferenceField : String -> Decode.Decoder ColorThemePreference
decodePreferenceField raw =
    case preferenceFromStorageString raw of
        Just pref ->
            Decode.succeed pref

        Nothing ->
            Decode.fail ("Unknown color theme preference: " ++ raw)


decodeSchemeField : String -> Decode.Decoder ColorTheme
decodeSchemeField raw =
    case themeFromSchemeString raw of
        Just theme ->
            Decode.succeed theme

        Nothing ->
            Decode.fail ("Unknown systemScheme: " ++ raw)

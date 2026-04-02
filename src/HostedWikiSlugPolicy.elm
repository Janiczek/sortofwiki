module HostedWikiSlugPolicy exposing (HostedWikiSlugPolicy(..), all, formValue, fromFormValue, label)


{-| How hosted wiki URL slugs are validated for new pages (metadata for operators; story 30).
-}
type HostedWikiSlugPolicy
    = StrictSlugs
    | AllowAny


{-| Ordered list for UI selects.
-}
all : List HostedWikiSlugPolicy
all =
    [ StrictSlugs, AllowAny ]


label : HostedWikiSlugPolicy -> String
label policy =
    case policy of
        StrictSlugs ->
            "Strict (letters, digits, underscore, hyphen)"

        AllowAny ->
            "Allow any slug characters (legacy)"


formValue : HostedWikiSlugPolicy -> String
formValue policy =
    case policy of
        StrictSlugs ->
            "StrictSlugs"

        AllowAny ->
            "AllowAny"


fromFormValue : String -> Maybe HostedWikiSlugPolicy
fromFormValue raw =
    case raw of
        "StrictSlugs" ->
            Just StrictSlugs

        "AllowAny" ->
            Just AllowAny

        _ ->
            Nothing

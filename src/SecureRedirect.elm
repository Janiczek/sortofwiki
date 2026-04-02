module SecureRedirect exposing
    ( contributorRedirectFromQuery
    , hostAdminRedirectFromQuery
    , pathAndQuery
    , safeHostAdminReturnPath
    )

import Url
import Wiki


{-| `path` plus optional `?query` for post-login return (same-origin path only; validated separately).
-}
pathAndQuery : { a | path : String, query : Maybe String } -> String
pathAndQuery url =
    url.path
        ++ (url.query |> Maybe.map (\q -> "?" ++ q) |> Maybe.withDefault "")


{-| Parse `redirect=` from a URL query string; percent-decode the value.
-}
redirectParamFromQuery : Maybe String -> Maybe String
redirectParamFromQuery maybeQuery =
    maybeQuery
        |> Maybe.andThen
            (\q ->
                q
                    |> String.split "&"
                    |> List.filterMap
                        (\pair ->
                            case splitOnceEq pair of
                                Just ( k, v ) ->
                                    if k == "redirect" then
                                        Url.percentDecode v

                                    else
                                        Nothing

                                Nothing ->
                                    Nothing
                        )
                    |> List.head
            )


splitOnceEq : String -> Maybe ( String, String )
splitOnceEq pair =
    case String.indexes "=" pair of
        [] ->
            Nothing

        i :: _ ->
            Just
                ( String.left i pair
                , String.dropLeft (i + 1) pair
                )


{-| Allowed return paths after wiki contributor login: `/`, wiki home, or same-wiki paths.
Rejects protocol-relative and other wikis' paths.
-}
safeContributorReturnPath : Wiki.Slug -> String -> Maybe String
safeContributorReturnPath wikiSlug path =
    if not (String.startsWith "/" path) || String.startsWith "//" path then
        Nothing

    else if path == "/" then
        Just path

    else if path == "/w/" ++ wikiSlug then
        Just path

    else if String.startsWith ("/w/" ++ wikiSlug ++ "/") path then
        Just path

    else
        Nothing


contributorRedirectFromQuery : Wiki.Slug -> Maybe String -> Maybe String
contributorRedirectFromQuery wikiSlug maybeQuery =
    redirectParamFromQuery maybeQuery
        |> Maybe.andThen (safeContributorReturnPath wikiSlug)


{-| Allowed return paths after host admin login: must start with `/admin`.
-}
safeHostAdminReturnPath : String -> Maybe String
safeHostAdminReturnPath path =
    if not (String.startsWith "/" path) || String.startsWith "//" path then
        Nothing

    else if String.startsWith "/admin" path then
        Just path

    else
        Nothing


hostAdminRedirectFromQuery : Maybe String -> Maybe String
hostAdminRedirectFromQuery maybeQuery =
    redirectParamFromQuery maybeQuery
        |> Maybe.andThen safeHostAdminReturnPath

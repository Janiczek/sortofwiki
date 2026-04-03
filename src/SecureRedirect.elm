module SecureRedirect exposing
    ( contributorRedirectFromQuery
    , hostAdminRedirectFromQuery
    , pathAndQuery
    , safeContributorReturnPath
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


{-| Split `path?query` after the first `?`; `queryWithMaybeFragment` includes `?` prefix when present.
-}
splitPathAndQuery : String -> ( String, String )
splitPathAndQuery s =
    case String.indexes "?" s |> List.head of
        Nothing ->
            ( s, "" )

        Just i ->
            ( String.left i s
            , String.dropLeft i s
            )


{-| Strip `#fragment` from a path-only segment (fragment is not part of the path for normalization).
-}
pathWithoutFragment : String -> String
pathWithoutFragment s =
    case String.indexes "#" s |> List.head of
        Nothing ->
            s

        Just i ->
            String.left i s


{-| Non-empty path segments between slashes (leading `/` dropped before splitting).
-}
absolutePathSegments : String -> List String
absolutePathSegments path =
    if not (String.startsWith "/" path) || String.startsWith "//" path then
        []

    else
        path
            |> String.dropLeft 1
            |> String.split "/"
            |> List.filter (\seg -> seg /= "")


{-| Resolve `.` / `..` in an absolute path; `Nothing` when `..` escapes above root.
-}
normalizeAbsolutePathSegments : List String -> Maybe (List String)
normalizeAbsolutePathSegments segments =
    List.foldl
        (\seg acc ->
            case acc of
                Nothing ->
                    Nothing

                Just stack ->
                    if seg == "." || seg == "" then
                        Just stack

                    else if seg == ".." then
                        case stack of
                            [] ->
                                Nothing

                            _ :: tail ->
                                Just tail

                    else
                        Just (seg :: stack)
        )
        (Just [])
        segments
        |> Maybe.map List.reverse


{-| Canonical absolute path: same logical location as `rawPath` without `.` / `..` segments.
-}
canonicalAbsolutePath : String -> Maybe String
canonicalAbsolutePath rawPath =
    let
        pathOnly : String
        pathOnly =
            rawPath |> pathWithoutFragment
    in
    if not (String.startsWith "/" pathOnly) || String.startsWith "//" pathOnly then
        Nothing

    else
        case normalizeAbsolutePathSegments (absolutePathSegments pathOnly) of
            Nothing ->
                Nothing

            Just [] ->
                Just "/"

            Just segs ->
                Just ("/" ++ String.join "/" segs)


{-| Rebuild redirect target: canonical path + original `?query#frag` suffix (query split preserved).
-}
canonicalRedirectTarget : String -> Maybe String
canonicalRedirectTarget raw =
    let
        ( pathRaw, querySuffix ) =
            splitPathAndQuery raw

        pathForCanon : String
        pathForCanon =
            pathWithoutFragment pathRaw
    in
    canonicalAbsolutePath pathForCanon
        |> Maybe.map (\c -> c ++ querySuffix)


{-| Allowed return paths after wiki contributor login: `/`, wiki home, or same-wiki paths.
Rejects protocol-relative, `..` escapes, and other wikis' paths (after canonicalization).
-}
safeContributorReturnPath : Wiki.Slug -> String -> Maybe String
safeContributorReturnPath wikiSlug raw =
    canonicalRedirectTarget raw
        |> Maybe.andThen
            (\canonFull ->
                let
                    ( pathOnly, _ ) =
                        splitPathAndQuery canonFull

                    pathCanon : String
                    pathCanon =
                        pathWithoutFragment pathOnly
                in
                if pathCanon == "/" then
                    Just canonFull

                else if pathCanon == "/w/" ++ wikiSlug then
                    Just canonFull

                else if String.startsWith ("/w/" ++ wikiSlug ++ "/") pathCanon then
                    Just canonFull

                else
                    Nothing
            )


contributorRedirectFromQuery : Wiki.Slug -> Maybe String -> Maybe String
contributorRedirectFromQuery wikiSlug maybeQuery =
    redirectParamFromQuery maybeQuery
        |> Maybe.andThen (safeContributorReturnPath wikiSlug)


{-| Allowed return paths after host admin login: canonical path must start with `/admin`.
-}
safeHostAdminReturnPath : String -> Maybe String
safeHostAdminReturnPath raw =
    canonicalRedirectTarget raw
        |> Maybe.andThen
            (\canonFull ->
                let
                    ( pathOnly, _ ) =
                        splitPathAndQuery canonFull

                    pathCanon : String
                    pathCanon =
                        pathWithoutFragment pathOnly
                in
                if String.startsWith "/admin" pathCanon then
                    Just canonFull

                else
                    Nothing
            )


hostAdminRedirectFromQuery : Maybe String -> Maybe String
hostAdminRedirectFromQuery maybeQuery =
    redirectParamFromQuery maybeQuery
        |> Maybe.andThen safeHostAdminReturnPath

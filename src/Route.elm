module Route exposing (Route(..), fromUrl, isWikiList)

import Url exposing (Url)


{-| Resolved client route from the URL path.
-}
type Route
    = WikiList
    | NotFound Url


{-| Map the browser URL to a route; only empty and `/` paths are the wiki catalog list.
-}
fromUrl : Url -> Route
fromUrl url =
    case url.path of
        "" ->
            WikiList

        "/" ->
            WikiList

        _ ->
            NotFound url


{-| Whether this route is the public hosted-wikis catalog (`/`).
-}
isWikiList : Route -> Bool
isWikiList route =
    case route of
        WikiList ->
            True

        NotFound _ ->
            False

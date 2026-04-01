module Route exposing
    ( Route(..)
    , fromUrl
    , isWikiList
    , notFoundPath
    , storeActions
    )

import Store exposing (Action(..))
import Url exposing (Url)


{-| Resolved client route from the URL path.
-}
type Route
    = WikiList
    | WikiHome { slug : String }
    | WikiArticles { slug : String }
    | NotFound Url


pathSegments : String -> List String
pathSegments path =
    path
        |> String.split "/"
        |> List.filter (\s -> s /= "")


{-| Map the browser URL to a route.
-}
fromUrl : Url -> Route
fromUrl url =
    case url.path of
        "" ->
            WikiList

        "/" ->
            WikiList

        _ ->
            case pathSegments url.path of
                [ "w", slug ] ->
                    if slug == "" then
                        NotFound url

                    else
                        WikiHome { slug = slug }

                [ "w", slug, "articles" ] ->
                    if slug == "" then
                        NotFound url

                    else
                        WikiArticles { slug = slug }

                _ ->
                    NotFound url


notFoundPath : Route -> Maybe String
notFoundPath route =
    case route of
        NotFound u ->
            Just u.path

        _ ->
            Nothing


{-| Whether this route is the public hosted-wikis catalog (`/`).
-}
isWikiList : Route -> Bool
isWikiList route =
    case route of
        WikiList ->
            True

        WikiHome _ ->
            False

        WikiArticles _ ->
            False

        NotFound _ ->
            False


storeActions : Route -> List Action
storeActions route =
    case route of
        WikiList ->
            [ AskForWikiCatalog ]

        WikiHome { slug } ->
            [ AskForWikiCatalog, AskForWikiFrontendDetails slug ]

        WikiArticles { slug } ->
            [ AskForWikiCatalog, AskForWikiFrontendDetails slug ]

        NotFound _ ->
            []

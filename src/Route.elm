module Route exposing
    ( Route(..)
    , fromUrl
    , isWikiList
    , notFoundPath
    , storeActions
    )

import Page
import Store exposing (Action(..))
import Url exposing (Url)
import Wiki


{-| Resolved client route from the URL path.
-}
type Route
    = WikiList
    | WikiHome Wiki.Slug
    | WikiPages Wiki.Slug
    | WikiPage Wiki.Slug Page.Slug
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
                        WikiHome slug

                [ "w", slug, "pages" ] ->
                    if slug == "" then
                        NotFound url

                    else
                        WikiPages slug

                [ "w", wikiSlug, "p", pageSlug ] ->
                    if wikiSlug == "" || pageSlug == "" then
                        NotFound url

                    else
                        WikiPage wikiSlug pageSlug

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

        WikiPages _ ->
            False

        WikiPage _ _ ->
            False

        NotFound _ ->
            False


storeActions : Route -> List Action
storeActions route =
    case route of
        WikiList ->
            [ AskForWikiCatalog ]

        WikiHome slug ->
            [ AskForWikiCatalog, AskForWikiFrontendDetails slug ]

        WikiPages slug ->
            [ AskForWikiCatalog, AskForWikiFrontendDetails slug ]

        WikiPage wikiSlug pageSlug ->
            [ AskForWikiCatalog
            , AskForWikiFrontendDetails wikiSlug
            , AskForPageFrontendDetails wikiSlug pageSlug
            ]

        NotFound _ ->
            []

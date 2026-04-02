module Route exposing
    ( Route(..)
    , fromUrl
    , isWikiList
    , notFoundPath
    , storeActions
    )

import Page
import SecureRedirect
import Store exposing (Action(..))
import Url exposing (Url)
import Wiki
import WikiAuditLog


{-| Resolved client route from the URL path.
-}
type Route
    = WikiList
    | HostAdmin (Maybe String)
    | HostAdminWikis
    | HostAdminWikiNew
    | HostAdminWikiDetail Wiki.Slug
    | WikiHome Wiki.Slug
    | WikiPages Wiki.Slug
    | WikiPage Wiki.Slug Page.Slug
    | WikiLogin Wiki.Slug (Maybe String)
    | WikiRegister Wiki.Slug
    | WikiSubmitNew Wiki.Slug
    | WikiSubmitEdit Wiki.Slug Page.Slug
    | WikiSubmitDelete Wiki.Slug Page.Slug
    | WikiSubmissionDetail Wiki.Slug String
    | WikiReview Wiki.Slug
    | WikiReviewDetail Wiki.Slug String
    | WikiAdminUsers Wiki.Slug
    | WikiAdminAudit Wiki.Slug
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
                [ "admin" ] ->
                    HostAdmin (SecureRedirect.hostAdminRedirectFromQuery url.query)

                [ "admin", "wikis" ] ->
                    HostAdminWikis

                [ "admin", "wikis", "new" ] ->
                    HostAdminWikiNew

                [ "admin", "wikis", wikiSlug ] ->
                    if wikiSlug == "" then
                        NotFound url

                    else
                        HostAdminWikiDetail wikiSlug

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

                [ "w", slug, "login" ] ->
                    if slug == "" then
                        NotFound url

                    else
                        WikiLogin slug (SecureRedirect.contributorRedirectFromQuery slug url.query)

                [ "w", slug, "register" ] ->
                    if slug == "" then
                        NotFound url

                    else
                        WikiRegister slug

                [ "w", wikiSlug, "review" ] ->
                    if wikiSlug == "" then
                        NotFound url

                    else
                        WikiReview wikiSlug

                [ "w", wikiSlug, "review", submissionId ] ->
                    if wikiSlug == "" || submissionId == "" then
                        NotFound url

                    else
                        WikiReviewDetail wikiSlug submissionId

                [ "w", wikiSlug, "admin", "users" ] ->
                    if wikiSlug == "" then
                        NotFound url

                    else
                        WikiAdminUsers wikiSlug

                [ "w", wikiSlug, "admin", "audit" ] ->
                    if wikiSlug == "" then
                        NotFound url

                    else
                        WikiAdminAudit wikiSlug

                -- /w/:wiki/submit/new (story 9); /w/:wiki/submit/edit/:page (story 10); /w/:wiki/submit/delete/:page (story 11); /w/:wiki/submit/:id (story 12)
                [ "w", wikiSlug, "submit", "new" ] ->
                    if wikiSlug == "" then
                        NotFound url

                    else
                        WikiSubmitNew wikiSlug

                [ "w", wikiSlug, "submit", "edit", pageSlug ] ->
                    if wikiSlug == "" || pageSlug == "" then
                        NotFound url

                    else
                        WikiSubmitEdit wikiSlug pageSlug

                [ "w", wikiSlug, "submit", "delete", pageSlug ] ->
                    if wikiSlug == "" || pageSlug == "" then
                        NotFound url

                    else
                        WikiSubmitDelete wikiSlug pageSlug

                [ "w", wikiSlug, "submit", submissionId ] ->
                    if wikiSlug == "" || submissionId == "" then
                        NotFound url

                    else
                        WikiSubmissionDetail wikiSlug submissionId

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

        HostAdmin _ ->
            False

        HostAdminWikis ->
            False

        HostAdminWikiNew ->
            False

        HostAdminWikiDetail _ ->
            False

        WikiHome _ ->
            False

        WikiPages _ ->
            False

        WikiPage _ _ ->
            False

        WikiLogin _ _ ->
            False

        WikiRegister _ ->
            False

        WikiSubmitNew _ ->
            False

        WikiSubmitEdit _ _ ->
            False

        WikiSubmitDelete _ _ ->
            False

        WikiSubmissionDetail _ _ ->
            False

        WikiReview _ ->
            False

        WikiReviewDetail _ _ ->
            False

        WikiAdminUsers _ ->
            False

        WikiAdminAudit _ ->
            False

        NotFound _ ->
            False


storeActions : Route -> List Action
storeActions route =
    case route of
        WikiList ->
            [ AskForWikiCatalog ]

        HostAdmin _ ->
            []

        HostAdminWikis ->
            []

        HostAdminWikiNew ->
            []

        HostAdminWikiDetail _ ->
            []

        WikiHome slug ->
            [ AskForWikiCatalog, AskForWikiFrontendDetails slug ]

        WikiPages slug ->
            [ AskForWikiCatalog, AskForWikiFrontendDetails slug ]

        WikiPage wikiSlug pageSlug ->
            [ AskForWikiCatalog
            , AskForWikiFrontendDetails wikiSlug
            , AskForPageFrontendDetails wikiSlug pageSlug
            ]

        WikiLogin slug _ ->
            [ AskForWikiCatalog, AskForWikiFrontendDetails slug ]

        WikiRegister slug ->
            [ AskForWikiCatalog, AskForWikiFrontendDetails slug ]

        WikiSubmitNew slug ->
            [ AskForWikiCatalog, AskForWikiFrontendDetails slug ]

        WikiSubmitEdit wikiSlug pageSlug ->
            [ AskForWikiCatalog
            , AskForWikiFrontendDetails wikiSlug
            , AskForPageFrontendDetails wikiSlug pageSlug
            ]

        WikiSubmitDelete wikiSlug pageSlug ->
            [ AskForWikiCatalog
            , AskForWikiFrontendDetails wikiSlug
            , AskForPageFrontendDetails wikiSlug pageSlug
            ]

        WikiSubmissionDetail slug submissionId ->
            [ AskForWikiCatalog
            , AskForWikiFrontendDetails slug
            , AskForSubmissionDetails slug submissionId
            ]

        WikiReview slug ->
            [ AskForWikiCatalog
            , AskForWikiFrontendDetails slug
            , AskForReviewQueue slug
            ]

        WikiReviewDetail wikiSlug submissionId ->
            [ AskForWikiCatalog
            , AskForWikiFrontendDetails wikiSlug
            , AskForReviewSubmissionDetail wikiSlug submissionId
            ]

        WikiAdminUsers slug ->
            [ AskForWikiCatalog
            , AskForWikiFrontendDetails slug
            , AskForWikiUsers slug
            ]

        WikiAdminAudit slug ->
            [ AskForWikiCatalog
            , AskForWikiFrontendDetails slug
            , AskForWikiAuditLog slug WikiAuditLog.emptyAuditLogFilter
            ]

        NotFound _ ->
            []

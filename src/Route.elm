module Route exposing
    ( NavAccessContext
    , Route(..)
    , canAccess
    , fromUrl
    , isWikiList
    , navUrlPath
    , notFoundPath
    , storeActions
    )

import Page
import SecureRedirect
import Store exposing (Action(..))
import Url exposing (Url)
import Wiki
import WikiAuditLog
import WikiRole exposing (WikiRole)


{-| Who may see which sidebar links: host-admin session, active wiki, and contributor role on that wiki.
-}
type alias NavAccessContext =
    { hostAdminAuthenticated : Bool
    , activeWikiSlug : Wiki.Slug
    , contributorOnActiveWiki : Maybe WikiRole
    }


{-| URL path for sidebar links (`href`). Covers every `Route` variant for exhaustiveness.
-}
navUrlPath : Route -> String
navUrlPath route =
    case route of
        WikiList ->
            Wiki.wikiListUrlPath

        HostAdmin Nothing ->
            "/admin"

        HostAdmin (Just returnPath) ->
            Wiki.hostAdminLoginUrlPathWithRedirect returnPath

        HostAdminWikis ->
            Wiki.hostAdminWikisUrlPath

        HostAdminWikiNew ->
            Wiki.hostAdminNewWikiUrlPath

        HostAdminWikiDetail slug ->
            Wiki.hostAdminWikiDetailUrlPath slug

        HostAdminAudit ->
            Wiki.hostAdminAuditUrlPath

        HostAdminBackup ->
            Wiki.hostAdminBackupUrlPath

        WikiHome wikiSlug ->
            Wiki.wikiHomeUrlPath wikiSlug

        WikiTodos wikiSlug ->
            Wiki.todosUrlPath wikiSlug

        WikiPage wikiSlug pageSlug ->
            Wiki.publishedPageUrlPath wikiSlug pageSlug

        WikiLogin wikiSlug maybeRedirect ->
            case maybeRedirect of
                Nothing ->
                    Wiki.loginUrlPath wikiSlug

                Just returnPath ->
                    Wiki.loginUrlPathWithRedirect wikiSlug returnPath

        WikiRegister wikiSlug ->
            Wiki.registerUrlPath wikiSlug

        WikiSubmitNew wikiSlug ->
            Wiki.submitNewPageUrlPath wikiSlug

        WikiSubmitEdit wikiSlug pageSlug ->
            Wiki.submitEditUrlPath wikiSlug pageSlug

        WikiSubmitDelete wikiSlug pageSlug ->
            Wiki.submitDeleteUrlPath wikiSlug pageSlug

        WikiSubmissionDetail wikiSlug submissionId ->
            Wiki.submissionDetailUrlPath wikiSlug submissionId

        WikiMySubmissions wikiSlug ->
            Wiki.mySubmissionsUrlPath wikiSlug

        WikiReview wikiSlug ->
            Wiki.reviewQueueUrlPath wikiSlug

        WikiReviewDetail wikiSlug submissionId ->
            Wiki.reviewDetailUrlPath wikiSlug submissionId

        WikiAdminUsers wikiSlug ->
            Wiki.adminUsersUrlPath wikiSlug

        WikiAdminAudit wikiSlug ->
            Wiki.adminAuditUrlPath wikiSlug

        NotFound u ->
            u.path


{-| Whether `ctx` may see a navigational link to `route` in the sidebar (not full server authorization).
-}
canAccess : NavAccessContext -> Route -> Bool
canAccess ctx route =
    let
        slugOk : Wiki.Slug -> Bool
        slugOk wikiSlug =
            wikiSlug == ctx.activeWikiSlug

        contributorOk : Bool
        contributorOk =
            ctx.contributorOnActiveWiki /= Nothing

        trustedOk : Bool
        trustedOk =
            ctx.contributorOnActiveWiki
                |> Maybe.map WikiRole.isTrustedModerator
                |> Maybe.withDefault False

        wikiAdminOk : Bool
        wikiAdminOk =
            ctx.contributorOnActiveWiki
                |> Maybe.map WikiRole.canAccessWikiAdminUsers
                |> Maybe.withDefault False
    in
    case route of
        WikiList ->
            True

        HostAdmin _ ->
            True

        HostAdminWikis ->
            ctx.hostAdminAuthenticated

        HostAdminWikiNew ->
            ctx.hostAdminAuthenticated

        HostAdminWikiDetail _ ->
            ctx.hostAdminAuthenticated

        HostAdminAudit ->
            ctx.hostAdminAuthenticated

        HostAdminBackup ->
            ctx.hostAdminAuthenticated

        WikiHome wikiSlug ->
            slugOk wikiSlug

        WikiTodos wikiSlug ->
            slugOk wikiSlug

        WikiPage wikiSlug _ ->
            slugOk wikiSlug

        WikiLogin wikiSlug _ ->
            slugOk wikiSlug

        WikiRegister wikiSlug ->
            slugOk wikiSlug

        WikiSubmitNew wikiSlug ->
            slugOk wikiSlug && contributorOk

        WikiSubmitEdit wikiSlug _ ->
            slugOk wikiSlug && contributorOk

        WikiSubmitDelete wikiSlug _ ->
            slugOk wikiSlug && contributorOk

        WikiSubmissionDetail wikiSlug _ ->
            slugOk wikiSlug && contributorOk

        WikiMySubmissions wikiSlug ->
            let
                mySubmissionsOk : Bool
                mySubmissionsOk =
                    ctx.contributorOnActiveWiki
                        |> Maybe.map WikiRole.hasMySubmissionsAccess
                        |> Maybe.withDefault False
            in
            slugOk wikiSlug && mySubmissionsOk

        WikiReview wikiSlug ->
            slugOk wikiSlug && trustedOk

        WikiReviewDetail wikiSlug _ ->
            slugOk wikiSlug && trustedOk

        WikiAdminUsers wikiSlug ->
            slugOk wikiSlug && wikiAdminOk

        WikiAdminAudit wikiSlug ->
            slugOk wikiSlug && wikiAdminOk

        NotFound _ ->
            False


{-| Resolved client route from the URL path.
-}
type Route
    = WikiList
    | HostAdmin (Maybe String)
    | HostAdminWikis
    | HostAdminWikiNew
    | HostAdminWikiDetail Wiki.Slug
    | HostAdminAudit
    | HostAdminBackup
    | WikiHome Wiki.Slug
    | WikiTodos Wiki.Slug
    | WikiPage Wiki.Slug Page.Slug
    | WikiLogin Wiki.Slug (Maybe String)
    | WikiRegister Wiki.Slug
    | WikiSubmitNew Wiki.Slug
    | WikiSubmitEdit Wiki.Slug Page.Slug
    | WikiSubmitDelete Wiki.Slug Page.Slug
    | WikiSubmissionDetail Wiki.Slug String
    | WikiMySubmissions Wiki.Slug
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

                [ "admin", "audit" ] ->
                    HostAdminAudit

                [ "admin", "backup" ] ->
                    HostAdminBackup

                [ "w", slug ] ->
                    if slug == "" then
                        NotFound url

                    else
                        WikiHome slug

                [ "w", wikiSlug, "todos" ] ->
                    if wikiSlug == "" then
                        NotFound url

                    else
                        WikiTodos wikiSlug

                [ "w", wikiSlug, "p", pageSlug ] ->
                    if wikiSlug == "" || pageSlug == "" then
                        NotFound url

                    else
                        WikiPage wikiSlug pageSlug

                [ "w", wikiSlug, "edit", pageSlug ] ->
                    if wikiSlug == "" || pageSlug == "" then
                        NotFound url

                    else
                        WikiSubmitEdit wikiSlug pageSlug

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

                [ "w", wikiSlug, "submissions" ] ->
                    if wikiSlug == "" then
                        NotFound url

                    else
                        WikiMySubmissions wikiSlug

                -- /w/:wiki/edit/:page; /w/:wiki/submit/new; /w/:wiki/submit/delete/:page; /w/:wiki/submit/:id
                [ "w", wikiSlug, "submit", "new" ] ->
                    if wikiSlug == "" then
                        NotFound url

                    else
                        WikiSubmitNew wikiSlug

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

        HostAdminAudit ->
            False

        HostAdminBackup ->
            False

        WikiHome _ ->
            False

        WikiTodos _ ->
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

        WikiMySubmissions _ ->
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

        HostAdminAudit ->
            []

        HostAdminBackup ->
            []

        WikiHome slug ->
            [ AskForWikiCatalog, AskForWikiFrontendDetails slug ]

        WikiTodos slug ->
            [ AskForWikiCatalog, AskForWikiFrontendDetails slug ]

        WikiPage wikiSlug pageSlug ->
            [ AskForWikiCatalog
            , AskForWikiFrontendDetails wikiSlug
            , AskForPageFrontendDetails wikiSlug pageSlug
            , AskForMyPendingSubmissions wikiSlug
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

        WikiMySubmissions slug ->
            [ AskForWikiCatalog
            , AskForWikiFrontendDetails slug
            , AskForMyPendingSubmissions slug
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

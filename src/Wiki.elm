module Wiki exposing
    ( CatalogEntry
    , FrontendDetails
    , Slug
    , Wiki
    , adminAuditUrlPath
    , adminAuditDiffUrlPath
    , adminUsersUrlPath
    , applyPublishedMarkdownEdit
    , catalogEntry
    , catalogUrlPath
    , frontendDetails
    , frontendDetailsForViewer
    , graphUrlPath
    , hostAdminAuditUrlPath
    , hostAdminAuditDiffUrlPath
    , hostAdminBackupUrlPath
    , hostAdminLoginUrlPathWithRedirect
    , hostAdminNewWikiUrlPath
    , hostAdminWikiDetailUrlPath
    , hostAdminWikisUrlPath
    , loginUrlPath
    , loginUrlPathWithRedirect
    , mySubmissionsUrlPath
    , pageGraphUrlPath
    , publicCatalogDict
    , publishNewPageOnWiki
    , publishedPageFrontendDetails
    , publishedPageUrlPath
    , registerUrlPath
    , removePublishedPage
    , reviewDetailUrlPath
    , reviewQueueUrlPath
    , searchUrlPath
    , submissionDetailUrlPath
    , submitDeleteUrlPath
    , submitEditUrlPath
    , submitNewPageUrlPath
    , submitNewPageUrlPathWithSuggestedSlug
    , todosUrlPath
    , wikiHomeUrlPath
    , wikiListUrlPath
    , wikiWithPages
    )

import ContributorWikiSession exposing (ContributorWikiSession)
import Dict exposing (Dict)
import Page
import PageBacklinks
import PageTags
import Url.Builder as UrlBuilder
import WikiRole


type alias Slug =
    String


type alias Wiki =
    { slug : String
    , name : String
    , summary : String
    , active : Bool
    , contentVersion : Int
    , pages : Dict Page.Slug Page.Page
    }


{-| Public catalog / host-admin row derived from a wiki (includes blurb and slug policy).
-}
type alias CatalogEntry =
    { slug : Slug
    , name : String
    , summary : String
    , active : Bool
    }


type alias FrontendDetails =
    { pageSlugs : List Page.Slug
    , publishedPageMarkdownSources : Dict Page.Slug String
    , publishedPageTags : Dict Page.Slug (List Page.Slug)
    , contentVersion : Int
    , pendingReviewCountForTrustedViewer : Maybe Int
    , viewerSession : Maybe ContributorWikiSession
    }


catalogEntry : Wiki -> CatalogEntry
catalogEntry w =
    { slug = w.slug
    , name = w.name
    , summary = w.summary
    , active = w.active
    }


{-| Public homepage catalog: active wikis only.
-}
publicCatalogDict : Dict Slug Wiki -> Dict Slug CatalogEntry
publicCatalogDict wikis =
    wikis
        |> Dict.filter (\_ w -> w.active)
        |> Dict.map (\_ w -> catalogEntry w)


{-| Wiki with empty public summary (tests and simple fixtures).
-}
wikiWithPages : Slug -> String -> Dict Page.Slug Page.Page -> Wiki
wikiWithPages slug name pages =
    { slug = slug
    , name = name
    , summary = ""
    , active = True
    , contentVersion = 1
    , pages = pages
    }


frontendDetails : Wiki -> FrontendDetails
frontendDetails w =
    let
        publishedPages : List ( Page.Slug, Page.Page )
        publishedPages =
            w.pages
                |> Dict.toList
                |> List.filter (\( _, page ) -> Page.hasPublished page)
    in
    { pageSlugs =
        publishedPages
            |> List.map Tuple.first
            |> List.sort
    , publishedPageMarkdownSources =
        publishedPages
            |> List.map
                (\( slug, page ) ->
                    ( slug, Page.publishedMarkdownForLinks page )
                )
            |> Dict.fromList
    , publishedPageTags =
        publishedPages
            |> List.map
                (\( slug, page ) ->
                    ( slug, page.tags )
                )
            |> Dict.fromList
    , contentVersion = w.contentVersion
    , pendingReviewCountForTrustedViewer = Nothing
    , viewerSession = Nothing
    }


{-| Wiki home / graph payload: pending count is only populated for trusted moderators (server sets `Maybe`).
-}
frontendDetailsForViewer : Wiki -> Maybe ContributorWikiSession -> Maybe Int -> FrontendDetails
frontendDetailsForViewer wiki maybeViewerSession maybePendingCount =
    let
        base : FrontendDetails
        base =
            frontendDetails wiki

        isTrusted : Bool
        isTrusted =
            maybeViewerSession
                |> Maybe.map (.role >> WikiRole.isTrustedModerator)
                |> Maybe.withDefault False
    in
    { base
        | pendingReviewCountForTrustedViewer =
            if isTrusted then
                maybePendingCount

            else
                Nothing
        , viewerSession = maybeViewerSession
    }


publishedPageFrontendDetails : Page.Slug -> Wiki -> Maybe Page.FrontendDetails
publishedPageFrontendDetails pageSlug wiki =
    case pageBySlugCaseInsensitive pageSlug wiki.pages of
        Nothing ->
            Just
                (Page.frontendDetails
                    Nothing
                    (PageBacklinks.slugsPointingTo wiki.slug pageSlug wiki.pages)
                    []
                    (PageTags.slugsPointingToTag pageSlug wiki.pages)
                )

        Just ( resolvedSlug, page ) ->
            case page.publishedMarkdown of
                Nothing ->
                    Just
                        (Page.frontendDetails
                            Nothing
                            []
                            page.tags
                            (PageTags.slugsPointingToTag resolvedSlug wiki.pages)
                        )

                Just markdown ->
                    Just
                        (Page.frontendDetails
                            (Just markdown)
                            (PageBacklinks.slugsPointingTo wiki.slug resolvedSlug wiki.pages)
                            page.tags
                            (PageTags.slugsPointingToTag resolvedSlug wiki.pages)
                        )


pageBySlugCaseInsensitive : Page.Slug -> Dict Page.Slug Page.Page -> Maybe ( Page.Slug, Page.Page )
pageBySlugCaseInsensitive rawSlug pages =
    let
        normalized : String
        normalized =
            String.toLower rawSlug
    in
    pages
        |> Dict.toList
        |> List.filter (\( slug, _ ) -> String.toLower slug == normalized)
        |> List.head


{-| Global wiki catalog (all wikis). Path: `/`.
-}
wikiListUrlPath : String
wikiListUrlPath =
    "/"


{-| Wiki homepage path for a slug (same as `catalogUrlPath` for that wiki).
-}
wikiHomeUrlPath : Slug -> String
wikiHomeUrlPath wikiSlug =
    "/w/" ++ wikiSlug


todosUrlPath : Slug -> String
todosUrlPath wikiSlug =
    "/w/" ++ wikiSlug ++ "/todos"


graphUrlPath : Slug -> String
graphUrlPath wikiSlug =
    "/w/" ++ wikiSlug ++ "/graph"


pageGraphUrlPath : Slug -> Page.Slug -> String
pageGraphUrlPath wikiSlug pageSlug =
    "/w/" ++ wikiSlug ++ "/pg/" ++ pageSlug


{-| Path segment after origin for the wiki homepage, e.g. `/w/my-wiki`.
-}
catalogUrlPath : CatalogEntry -> String
catalogUrlPath s =
    wikiHomeUrlPath s.slug


{-| Contributor login for a wiki.
-}
loginUrlPath : Slug -> String
loginUrlPath wikiSlug =
    "/w/" ++ wikiSlug ++ "/login"


{-| Wiki login with post-auth return path (must be validated with `SecureRedirect.safeContributorReturnPath`).
-}
loginUrlPathWithRedirect : Slug -> String -> String
loginUrlPathWithRedirect wikiSlug returnPath =
    loginUrlPath wikiSlug
        ++ UrlBuilder.toQuery [ UrlBuilder.string "redirect" returnPath ]


{-| Host admin login with return path (must be validated with `SecureRedirect.safeHostAdminReturnPath`).
-}
hostAdminLoginUrlPathWithRedirect : String -> String
hostAdminLoginUrlPathWithRedirect returnPath =
    "/admin"
        ++ UrlBuilder.toQuery [ UrlBuilder.string "redirect" returnPath ]


{-| Contributor registration for a wiki.
-}
registerUrlPath : Slug -> String
registerUrlPath wikiSlug =
    "/w/" ++ wikiSlug ++ "/register"


{-| Submit a new page draft for review. Path: `/w/:wikiSlug/submit/new`.
-}
submitNewPageUrlPath : Slug -> String
submitNewPageUrlPath wikiSlug =
    "/w/" ++ wikiSlug ++ "/submit/new"


{-| `submitNewPageUrlPath` with `?page=` (percent-encoded). Prefills the new-page slug field and keeps it read-only; plain `submitNewPageUrlPath` leaves the slug editable.
-}
submitNewPageUrlPathWithSuggestedSlug : Slug -> Page.Slug -> String
submitNewPageUrlPathWithSuggestedSlug wikiSlug pageSlug =
    submitNewPageUrlPath wikiSlug
        ++ UrlBuilder.toQuery [ UrlBuilder.string "page" pageSlug ]


{-| Propose an edit to a published page. Path: `/w/:wikiSlug/edit/:pageSlug`.
-}
submitEditUrlPath : Slug -> Page.Slug -> String
submitEditUrlPath wikiSlug pageSlug =
    "/w/" ++ wikiSlug ++ "/edit/" ++ pageSlug


{-| Request deletion of a published page for moderation. Path: `/w/:wikiSlug/submit/delete/:pageSlug`.
-}
submitDeleteUrlPath : Slug -> Page.Slug -> String
submitDeleteUrlPath wikiSlug pageSlug =
    "/w/" ++ wikiSlug ++ "/submit/delete/" ++ pageSlug


{-| Wiki admin user directory. Path: `/w/:wikiSlug/admin/users`.
-}
adminUsersUrlPath : Slug -> String
adminUsersUrlPath wikiSlug =
    "/w/" ++ wikiSlug ++ "/admin/users"


{-| Wiki admin audit log. Path: `/w/:wikiSlug/admin/audit`.
-}
adminAuditUrlPath : Slug -> String
adminAuditUrlPath wikiSlug =
    "/w/" ++ wikiSlug ++ "/admin/audit"


{-| Wiki admin audit diff detail. Path: `/w/:wikiSlug/admin/audit/diff/:eventIndex`.
-}
adminAuditDiffUrlPath : Slug -> Int -> String
adminAuditDiffUrlPath wikiSlug eventIndex =
    "/w/" ++ wikiSlug ++ "/admin/audit/diff/" ++ String.fromInt eventIndex


{-| Contributor list of submissions waiting for review. Path: `/w/:wikiSlug/submissions`.
-}
mySubmissionsUrlPath : Slug -> String
mySubmissionsUrlPath wikiSlug =
    "/w/" ++ wikiSlug ++ "/submissions"


{-| Trusted contributor review queue. Path: `/w/:wikiSlug/review`.
-}
reviewQueueUrlPath : Slug -> String
reviewQueueUrlPath wikiSlug =
    "/w/" ++ wikiSlug ++ "/review"


{-| Wiki search page. Path: `/w/:wikiSlug/search`.
-}
searchUrlPath : Slug -> String
searchUrlPath wikiSlug =
    "/w/" ++ wikiSlug ++ "/search"


{-| Review decision screen for one submission. Path: `/w/:wikiSlug/review/:submissionId`.
-}
reviewDetailUrlPath : Slug -> String -> String
reviewDetailUrlPath wikiSlug submissionId =
    "/w/" ++ wikiSlug ++ "/review/" ++ submissionId


{-| Contributor submission detail. Path: `/w/:wikiSlug/submit/:submissionId`.
-}
submissionDetailUrlPath : Slug -> String -> String
submissionDetailUrlPath wikiSlug submissionId =
    "/w/" ++ wikiSlug ++ "/submit/" ++ submissionId


{-| Create hosted wiki. Path: `/admin/wikis/new`.
-}
hostAdminNewWikiUrlPath : String
hostAdminNewWikiUrlPath =
    "/admin/wikis/new"


{-| Host-admin wiki list. Path: `/admin/wikis`.
-}
hostAdminWikisUrlPath : String
hostAdminWikisUrlPath =
    "/admin/wikis"


{-| Platform host-admin backup and restore. Path: `/admin/backup`.
-}
hostAdminBackupUrlPath : String
hostAdminBackupUrlPath =
    "/admin/backup"


{-| Platform host-admin audit log (all wikis). Path: `/admin/audit`.
-}
hostAdminAuditUrlPath : String
hostAdminAuditUrlPath =
    "/admin/audit"


{-| Platform host-admin audit diff detail. Path: `/admin/audit/diff/:wikiSlug/:eventIndex`.
-}
hostAdminAuditDiffUrlPath : Slug -> Int -> String
hostAdminAuditDiffUrlPath wikiSlug eventIndex =
    "/admin/audit/diff/" ++ wikiSlug ++ "/" ++ String.fromInt eventIndex


{-| Platform host-admin wiki detail. Path: `/admin/wikis/:wikiSlug`.
-}
hostAdminWikiDetailUrlPath : Slug -> String
hostAdminWikiDetailUrlPath wikiSlug =
    "/admin/wikis/" ++ wikiSlug


{-| Path to a published page, e.g. `/w/my-wiki/p/page-slug`.
-}
publishedPageUrlPath : Slug -> Page.Slug -> String
publishedPageUrlPath wikiSlug pageSlug =
    "/w/" ++ wikiSlug ++ "/p/" ++ pageSlug


{-| Trusted direct publish and approval of a new-page submission.
-}
publishNewPageOnWiki : { pageSlug : Page.Slug, markdown : String, tags : List Page.Slug } -> Wiki -> Wiki
publishNewPageOnWiki payload wiki =
    let
        basePage : Page.Page
        basePage =
            Page.withPublished payload.pageSlug payload.markdown

        newPage : Page.Page
        newPage =
            { basePage | tags = payload.tags }
    in
    { wiki
        | pages =
            Dict.insert payload.pageSlug newPage wiki.pages
        , contentVersion = wiki.contentVersion + 1
    }


{-| Replace published markdown for an existing page (trusted edit / approved edit submission).
-}
applyPublishedMarkdownEdit : Page.Slug -> String -> List Page.Slug -> Wiki -> Wiki
applyPublishedMarkdownEdit pageSlug markdown tags wiki =
    case Dict.get pageSlug wiki.pages of
        Nothing ->
            wiki

        Just page ->
            let
                nextPage : Page.Page
                nextPage =
                    { page
                        | publishedMarkdown = Just markdown
                        , tags = tags
                    }
                        |> Page.incrementPublishedRevision
            in
            { wiki
                | pages =
                    Dict.insert pageSlug nextPage wiki.pages
                , contentVersion = wiki.contentVersion + 1
            }


{-| Remove a published page from the wiki (trusted delete / approved delete submission).
-}
removePublishedPage : Page.Slug -> Wiki -> Wiki
removePublishedPage pageSlug wiki =
    { wiki
        | pages = Dict.remove pageSlug wiki.pages
        , contentVersion = wiki.contentVersion + 1
    }

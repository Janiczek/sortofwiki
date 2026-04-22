module Wiki exposing
    ( CatalogEntry
    , FrontendDetails
    , Slug
    , Wiki
    , adminAuditUrlPath
    , adminUsersUrlPath
    , applyPublishedMarkdownEdit
    , catalogEntry
    , catalogUrlPath
    , frontendDetails
    , frontendDetailsForViewer
    , graphUrlPath
    , hostAdminAuditUrlPath
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

import Dict exposing (Dict)
import Page
import PageBacklinks
import PageTags
import Url.Builder as UrlBuilder


type alias Slug =
    String


type alias Wiki =
    { slug : String
    , name : String
    , summary : String
    , active : Bool
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
    , pendingReviewCountForTrustedViewer : Maybe Int
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
    , pendingReviewCountForTrustedViewer = Nothing
    }


{-| Wiki home / graph payload: pending count is only populated for trusted moderators (server sets `Maybe`).
-}
frontendDetailsForViewer : Wiki -> Bool -> Maybe Int -> FrontendDetails
frontendDetailsForViewer wiki isTrusted maybePendingCount =
    let
        base : FrontendDetails
        base =
            frontendDetails wiki
    in
    { base
        | pendingReviewCountForTrustedViewer =
            if isTrusted then
                maybePendingCount

            else
                Nothing
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
            }


{-| Remove a published page from the wiki (trusted delete / approved delete submission).
-}
removePublishedPage : Page.Slug -> Wiki -> Wiki
removePublishedPage pageSlug wiki =
    { wiki | pages = Dict.remove pageSlug wiki.pages }

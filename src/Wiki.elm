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
    , hostAdminLoginUrlPathWithRedirect
    , hostAdminNewWikiUrlPath
    , hostAdminWikiDetailUrlPath
    , hostAdminWikisUrlPath
    , loginUrlPath
    , loginUrlPathWithRedirect
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
    , wikiWithPages
    )

import Dict exposing (Dict)
import Page
import PageBacklinks
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


{-| Public catalog / host-admin row derived from a wiki (story 30: includes blurb and slug policy).
-}
type alias CatalogEntry =
    { slug : Slug
    , name : String
    , summary : String
    , active : Bool
    }


type alias FrontendDetails =
    { pageSlugs : List Page.Slug
    }


catalogEntry : Wiki -> CatalogEntry
catalogEntry w =
    { slug = w.slug
    , name = w.name
    , summary = w.summary
    , active = w.active
    }


{-| Public homepage catalog: active wikis only (story 31).
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
    { pageSlugs =
        w.pages
            |> Dict.toList
            |> List.filter (\( _, page ) -> Page.hasPublished page)
            |> List.map Tuple.first
            |> List.sort
    }


publishedPageFrontendDetails : Page.Slug -> Wiki -> Maybe Page.FrontendDetails
publishedPageFrontendDetails pageSlug wiki =
    case pageBySlugCaseInsensitive pageSlug wiki.pages of
        Nothing ->
            Nothing

        Just ( resolvedSlug, page ) ->
            case page.publishedMarkdown of
                Nothing ->
                    Nothing

                Just markdown ->
                    Just
                        (Page.frontendDetails markdown
                            (PageBacklinks.slugsPointingTo wiki.slug resolvedSlug wiki.pages)
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


{-| Path segment after origin for the wiki homepage, e.g. `/w/my-wiki`.
-}
catalogUrlPath : CatalogEntry -> String
catalogUrlPath s =
    "/w/" ++ s.slug


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


{-| Submit a new page draft for review (story 9). Path: `/w/:wikiSlug/submit/new`.
-}
submitNewPageUrlPath : Slug -> String
submitNewPageUrlPath wikiSlug =
    "/w/" ++ wikiSlug ++ "/submit/new"


{-| Propose an edit to a published page (story 10). Path: `/w/:wikiSlug/submit/edit/:pageSlug`.
-}
submitEditUrlPath : Slug -> Page.Slug -> String
submitEditUrlPath wikiSlug pageSlug =
    "/w/" ++ wikiSlug ++ "/submit/edit/" ++ pageSlug


{-| Request deletion of a published page for moderation (story 11). Path: `/w/:wikiSlug/submit/delete/:pageSlug`.
-}
submitDeleteUrlPath : Slug -> Page.Slug -> String
submitDeleteUrlPath wikiSlug pageSlug =
    "/w/" ++ wikiSlug ++ "/submit/delete/" ++ pageSlug


{-| Wiki admin user directory (story 20). Path: `/w/:wikiSlug/admin/users`.
-}
adminUsersUrlPath : Slug -> String
adminUsersUrlPath wikiSlug =
    "/w/" ++ wikiSlug ++ "/admin/users"


{-| Wiki admin audit log (story 25). Path: `/w/:wikiSlug/admin/audit`.
-}
adminAuditUrlPath : Slug -> String
adminAuditUrlPath wikiSlug =
    "/w/" ++ wikiSlug ++ "/admin/audit"


{-| Trusted contributor review queue (story 15). Path: `/w/:wikiSlug/review`.
-}
reviewQueueUrlPath : Slug -> String
reviewQueueUrlPath wikiSlug =
    "/w/" ++ wikiSlug ++ "/review"


{-| Review decision screen for one submission (story 16+). Path: `/w/:wikiSlug/review/:submissionId`.
-}
reviewDetailUrlPath : Slug -> String -> String
reviewDetailUrlPath wikiSlug submissionId =
    "/w/" ++ wikiSlug ++ "/review/" ++ submissionId


{-| Contributor submission detail (stub until story 12). Path matches the opinionated URL map in `spec/user-stories.md`.
-}
submissionDetailUrlPath : Slug -> String -> String
submissionDetailUrlPath wikiSlug submissionId =
    "/w/" ++ wikiSlug ++ "/submit/" ++ submissionId


{-| Create hosted wiki (story 29). Path: `/admin/wikis/new`.
-}
hostAdminNewWikiUrlPath : String
hostAdminNewWikiUrlPath =
    "/admin/wikis/new"


{-| Host-admin wiki list (story 28). Path: `/admin/wikis`.
-}
hostAdminWikisUrlPath : String
hostAdminWikisUrlPath =
    "/admin/wikis"


{-| Platform host-admin wiki detail (story 30). Path: `/admin/wikis/:wikiSlug`.
-}
hostAdminWikiDetailUrlPath : Slug -> String
hostAdminWikiDetailUrlPath wikiSlug =
    "/admin/wikis/" ++ wikiSlug


{-| Path to a published page, e.g. `/w/my-wiki/p/page-slug`.
-}
publishedPageUrlPath : Slug -> Page.Slug -> String
publishedPageUrlPath wikiSlug pageSlug =
    "/w/" ++ wikiSlug ++ "/p/" ++ pageSlug


{-| Trusted direct publish (story 14) and approval of a new-page submission (story 17).
-}
publishNewPageOnWiki : { pageSlug : Page.Slug, markdown : String } -> Wiki -> Wiki
publishNewPageOnWiki payload wiki =
    { wiki
        | pages =
            Dict.insert payload.pageSlug (Page.withPublished payload.pageSlug payload.markdown) wiki.pages
    }


{-| Replace published markdown for an existing page (trusted edit / approved edit submission).
-}
applyPublishedMarkdownEdit : Page.Slug -> String -> Wiki -> Wiki
applyPublishedMarkdownEdit pageSlug markdown wiki =
    case Dict.get pageSlug wiki.pages of
        Nothing ->
            wiki

        Just page ->
            let
                nextPage : Page.Page
                nextPage =
                    { page
                        | publishedMarkdown = Just markdown
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

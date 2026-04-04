module Fuzzers exposing
    ( navAccessContext
    , page
    , pageSlug
    , wikiCatalogEntry
    , wikiRole
    , wikiSlug
    )

import Fuzz exposing (Fuzzer)
import Page
import Route
import Wiki
import WikiRole


page : Fuzzer Page.Page
page =
    Fuzz.map3
        (\slug published pending ->
            { slug = slug
            , publishedMarkdown = published
            , publishedRevision = 1
            , pendingMarkdown = pending
            }
        )
        pageSlug
        (Fuzz.maybe Fuzz.string)
        (Fuzz.maybe Fuzz.string)


wikiCatalogEntry : Fuzzer Wiki.CatalogEntry
wikiCatalogEntry =
    Fuzz.map4 Wiki.CatalogEntry
        wikiSlug
        wikiName
        Fuzz.string
        Fuzz.bool


wikiRole : Fuzzer WikiRole.WikiRole
wikiRole =
    Fuzz.oneOfValues
        [ WikiRole.UntrustedContributor
        , WikiRole.TrustedContributor
        , WikiRole.Admin
        ]


wikiSlug : Fuzzer Wiki.Slug
wikiSlug =
    nonEmptyString


navAccessContext : Fuzzer Route.NavAccessContext
navAccessContext =
    Fuzz.map3
        (\hostOk slug maybeRole ->
            { hostAdminAuthenticated = hostOk
            , activeWikiSlug = slug
            , contributorOnActiveWiki = maybeRole
            }
        )
        Fuzz.bool
        wikiSlug
        (Fuzz.maybe wikiRole)


pageSlug : Fuzzer Page.Slug
pageSlug =
    nonEmptyString


wikiName : Fuzzer String
wikiName =
    nonEmptyString


nonEmptyString : Fuzzer String
nonEmptyString =
    Fuzz.string
        |> Fuzz.map (\s -> "x" ++ s)

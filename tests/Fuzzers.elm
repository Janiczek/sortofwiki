module Fuzzers exposing
    ( page
    , pageSlug
    , wikiCatalogEntry
    , wikiRole
    , wikiSlug
    )

import Fuzz exposing (Fuzzer)
import HostedWikiSlugPolicy
import Page
import Wiki
import WikiRole


page : Fuzzer Page.Page
page =
    Fuzz.map3
        (\slug published pending ->
            { slug = slug
            , publishedMarkdown = published
            , pendingMarkdown = pending
            }
        )
        pageSlug
        (Fuzz.maybe Fuzz.string)
        (Fuzz.maybe Fuzz.string)


wikiCatalogEntry : Fuzzer Wiki.CatalogEntry
wikiCatalogEntry =
    Fuzz.map5 Wiki.CatalogEntry
        wikiSlug
        wikiName
        Fuzz.string
        (Fuzz.oneOf
            [ Fuzz.constant HostedWikiSlugPolicy.StrictSlugs
            , Fuzz.constant HostedWikiSlugPolicy.AllowAny
            ]
        )
        Fuzz.bool


wikiRole : Fuzzer WikiRole.WikiRole
wikiRole =
    Fuzz.oneOfValues
        [ WikiRole.Contributor
        , WikiRole.Trusted
        , WikiRole.Admin
        ]


wikiSlug : Fuzzer Wiki.Slug
wikiSlug =
    nonEmptyString


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

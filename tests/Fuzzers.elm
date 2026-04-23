module Fuzzers exposing
    ( GraphInput
    , GraphPairRelations
    , PageGraphNeighborhood
    , graphInput
    , graphPairRelations
    , navAccessContext
    , page
    , pageGraphNeighborhood
    , pageSlug
    , wikiCatalogEntry
    , wikiRole
    , wikiSlug
    )

import Dict exposing (Dict)
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
            , tags = []
            }
        )
        pageSlug
        (Fuzz.maybe Fuzz.string)
        (Fuzz.maybe Fuzz.string)


type alias GraphPairRelations =
    { leftToRightPageLink : Bool
    , rightToLeftPageLink : Bool
    , leftToRightTag : Bool
    , rightToLeftTag : Bool
    }


graphPairRelations : Fuzzer GraphPairRelations
graphPairRelations =
    Fuzz.map4
        (\leftToRightPageLink rightToLeftPageLink leftToRightTag rightToLeftTag ->
            { leftToRightPageLink = leftToRightPageLink
            , rightToLeftPageLink = rightToLeftPageLink
            , leftToRightTag = leftToRightTag
            , rightToLeftTag = rightToLeftTag
            }
        )
        Fuzz.bool
        Fuzz.bool
        Fuzz.bool
        Fuzz.bool


type alias PageGraphNeighborhood =
    { outgoingPageLink : Bool
    , incomingPageLink : Bool
    , outgoingTag : Bool
    , incomingTag : Bool
    }


pageGraphNeighborhood : Fuzzer PageGraphNeighborhood
pageGraphNeighborhood =
    Fuzz.map4
        (\outgoingPageLink incomingPageLink outgoingTag incomingTag ->
            { outgoingPageLink = outgoingPageLink
            , incomingPageLink = incomingPageLink
            , outgoingTag = outgoingTag
            , incomingTag = incomingTag
            }
        )
        Fuzz.bool
        Fuzz.bool
        Fuzz.bool
        Fuzz.bool


type alias GraphInput =
    { publishedPageMarkdownSources : Dict Page.Slug String
    , publishedPageTags : Dict Page.Slug (List Page.Slug)
    }


graphInput : Fuzzer GraphInput
graphInput =
    let
        alpha : Page.Slug
        alpha =
            "Alpha"

        beta : Page.Slug
        beta =
            "Beta"

        gamma : Page.Slug
        gamma =
            "Gamma"

        allPageSlugs : List Page.Slug
        allPageSlugs =
            [ alpha, beta, gamma ]

        relatedPageSlugs : Page.Slug -> Fuzzer (List Page.Slug)
        relatedPageSlugs sourceSlug =
            Fuzz.list (Fuzz.oneOfValues allPageSlugs)
                |> Fuzz.map (List.filter (\targetSlug -> targetSlug /= sourceSlug))
                |> Fuzz.map dedupeAndSortPageSlugs

        markdownFor : List Page.Slug -> String
        markdownFor targetSlugs =
            targetSlugs
                |> List.map (\targetSlug -> "[[" ++ targetSlug ++ "]]")
                |> String.join "\n"
    in
    Fuzz.map2
        (\markdownTargets tagsByPage ->
            { publishedPageMarkdownSources =
                Dict.fromList
                    [ ( alpha, markdownFor markdownTargets.alpha )
                    , ( beta, markdownFor markdownTargets.beta )
                    , ( gamma, markdownFor markdownTargets.gamma )
                    ]
            , publishedPageTags =
                Dict.fromList
                    [ ( alpha, tagsByPage.alpha )
                    , ( beta, tagsByPage.beta )
                    , ( gamma, tagsByPage.gamma )
                    ]
            }
        )
        (Fuzz.map3
            (\alphaTargets betaTargets gammaTargets ->
                { alpha = alphaTargets
                , beta = betaTargets
                , gamma = gammaTargets
                }
            )
            (relatedPageSlugs alpha)
            (relatedPageSlugs beta)
            (relatedPageSlugs gamma)
        )
        (Fuzz.map3
            (\alphaTags betaTags gammaTags ->
                { alpha = alphaTags
                , beta = betaTags
                , gamma = gammaTags
                }
            )
            (relatedPageSlugs alpha)
            (relatedPageSlugs beta)
            (relatedPageSlugs gamma)
        )


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
        [ WikiRole.UntrustedContributor WikiRole.defaultUntrustedContributorCaps
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


dedupeAndSortPageSlugs : List Page.Slug -> List Page.Slug
dedupeAndSortPageSlugs pageSlugs =
    pageSlugs
        |> List.foldl
            (\candidateSlug acc ->
                if List.member candidateSlug acc then
                    acc

                else
                    candidateSlug :: acc
            )
            []
        |> List.sortBy String.toLower

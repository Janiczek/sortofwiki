module Wiki exposing
    ( FrontendDetails
    , Slug
    , Summary
    , Wiki
    , catalogUrlPath
    , frontendDetails
    , pageIndexUrlPath
    , publishedPageFrontendDetails
    , publishedPageUrlPath
    , summary
    )

import Dict exposing (Dict)
import Page


type alias Slug =
    String


type alias Wiki =
    { slug : String
    , name : String
    , pages : Dict Page.Slug Page.Page
    }


type alias Summary =
    { slug : Slug
    , name : String
    }


type alias FrontendDetails =
    { pageSlugs : List Page.Slug
    }


summary : Wiki -> Summary
summary w =
    { slug = w.slug
    , name = w.name
    }


frontendDetails : Wiki -> FrontendDetails
frontendDetails w =
    { pageSlugs = Dict.keys w.pages
    }


publishedPageFrontendDetails : Page.Slug -> Wiki -> Maybe Page.FrontendDetails
publishedPageFrontendDetails pageSlug wiki =
    wiki.pages
        |> Dict.get pageSlug
        |> Maybe.map Page.frontendDetails


{-| Path segment after origin for the wiki homepage, e.g. `/w/my-wiki`.
-}
catalogUrlPath : Summary -> String
catalogUrlPath s =
    "/w/" ++ s.slug


{-| Published page index for a wiki, e.g. `/w/my-wiki/pages`.
-}
pageIndexUrlPath : Slug -> String
pageIndexUrlPath wikiSlug =
    "/w/" ++ wikiSlug ++ "/pages"


{-| Path to a published page, e.g. `/w/my-wiki/p/page-slug`.
-}
publishedPageUrlPath : Slug -> Page.Slug -> String
publishedPageUrlPath wikiSlug pageSlug =
    "/w/" ++ wikiSlug ++ "/p/" ++ pageSlug

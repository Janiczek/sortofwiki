module Wiki exposing
    ( FrontendDetails
    , Slug
    , Summary
    , Wiki
    , articleIndexUrlPath
    , catalogUrlPath
    , frontendDetails
    , publishedArticleUrlPath
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


{-| Path segment after origin for the wiki homepage, e.g. `/w/my-wiki`.
-}
catalogUrlPath : Summary -> String
catalogUrlPath s =
    "/w/" ++ s.slug


{-| Published article index for a wiki, e.g. `/w/my-wiki/articles`.
-}
articleIndexUrlPath : Slug -> String
articleIndexUrlPath wikiSlug =
    "/w/" ++ wikiSlug ++ "/articles"


{-| Path to a published article, e.g. `/w/my-wiki/articles/page-slug`.
-}
publishedArticleUrlPath : Slug -> Page.Slug -> String
publishedArticleUrlPath wikiSlug articleSlug =
    articleIndexUrlPath wikiSlug ++ "/" ++ articleSlug

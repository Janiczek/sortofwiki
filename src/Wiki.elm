module Wiki exposing
    ( FrontendDetails
    , Slug
    , Summary
    , Wiki
    , catalogUrlPath
    , frontendDetails
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

module Evergreen.V4.Wiki exposing (..)

import Dict
import Evergreen.V4.Page


type alias Slug =
    String


type alias CatalogEntry =
    { slug : Slug
    , name : String
    , summary : String
    , active : Bool
    }


type alias FrontendDetails =
    { pageSlugs : List Evergreen.V4.Page.Slug
    , publishedPageMarkdownSources : Dict.Dict Evergreen.V4.Page.Slug String
    , publishedPageTags : Dict.Dict Evergreen.V4.Page.Slug (List Evergreen.V4.Page.Slug)
    }


type alias Wiki =
    { slug : String
    , name : String
    , summary : String
    , active : Bool
    , pages : Dict.Dict Evergreen.V4.Page.Slug Evergreen.V4.Page.Page
    }

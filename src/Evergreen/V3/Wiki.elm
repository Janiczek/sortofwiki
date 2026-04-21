module Evergreen.V3.Wiki exposing (..)

import Dict
import Evergreen.V3.Page


type alias Slug =
    String


type alias CatalogEntry =
    { slug : Slug
    , name : String
    , summary : String
    , active : Bool
    }


type alias FrontendDetails =
    { pageSlugs : List Evergreen.V3.Page.Slug
    , publishedPageMarkdownSources : Dict.Dict Evergreen.V3.Page.Slug String
    }


type alias Wiki =
    { slug : String
    , name : String
    , summary : String
    , active : Bool
    , pages : Dict.Dict Evergreen.V3.Page.Slug Evergreen.V3.Page.Page
    }

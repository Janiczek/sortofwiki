module Evergreen.V1.Wiki exposing (..)

import Dict
import Evergreen.V1.Page


type alias Slug =
    String


type alias CatalogEntry =
    { slug : Slug
    , name : String
    , summary : String
    , active : Bool
    }


type alias FrontendDetails =
    { pageSlugs : List Evergreen.V1.Page.Slug
    }


type alias Wiki =
    { slug : String
    , name : String
    , summary : String
    , active : Bool
    , pages : Dict.Dict Evergreen.V1.Page.Slug Evergreen.V1.Page.Page
    }

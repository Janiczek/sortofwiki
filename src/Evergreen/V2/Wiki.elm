module Evergreen.V2.Wiki exposing (..)

import Dict
import Evergreen.V2.Page


type alias Slug =
    String


type alias CatalogEntry =
    { slug : Slug
    , name : String
    , summary : String
    , active : Bool
    }


type alias FrontendDetails =
    { pageSlugs : List Evergreen.V2.Page.Slug
    }


type alias Wiki =
    { slug : String
    , name : String
    , summary : String
    , active : Bool
    , pages : Dict.Dict Evergreen.V2.Page.Slug Evergreen.V2.Page.Page
    }

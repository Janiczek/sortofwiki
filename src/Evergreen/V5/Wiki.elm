module Evergreen.V5.Wiki exposing (..)

import Dict
import Evergreen.V5.Page


type alias Slug =
    String


type alias CatalogEntry =
    { slug : Slug
    , name : String
    , summary : String
    , active : Bool
    }


type alias FrontendDetails =
    { pageSlugs : List Evergreen.V5.Page.Slug
    , publishedPageMarkdownSources : Dict.Dict Evergreen.V5.Page.Slug String
    , publishedPageTags : Dict.Dict Evergreen.V5.Page.Slug (List Evergreen.V5.Page.Slug)
    , pendingReviewCountForTrustedViewer : Maybe Int
    }


type alias Wiki =
    { slug : String
    , name : String
    , summary : String
    , active : Bool
    , pages : Dict.Dict Evergreen.V5.Page.Slug Evergreen.V5.Page.Page
    }

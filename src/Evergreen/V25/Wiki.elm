module Evergreen.V25.Wiki exposing (..)

import Dict
import Evergreen.V25.ContributorWikiSession
import Evergreen.V25.Page


type alias Slug =
    String


type alias CatalogEntry =
    { slug : Slug
    , name : String
    , summary : String
    , active : Bool
    }


type alias FrontendDetails =
    { pageSlugs : List Evergreen.V25.Page.Slug
    , publishedPageMarkdownSources : Dict.Dict Evergreen.V25.Page.Slug String
    , publishedPageTags : Dict.Dict Evergreen.V25.Page.Slug (List Evergreen.V25.Page.Slug)
    , contentVersion : Int
    , pendingReviewCountForTrustedViewer : Maybe Int
    , viewerSession : Maybe Evergreen.V25.ContributorWikiSession.ContributorWikiSession
    }


type alias Wiki =
    { slug : String
    , name : String
    , summary : String
    , active : Bool
    , contentVersion : Int
    , pages : Dict.Dict Evergreen.V25.Page.Slug Evergreen.V25.Page.Page
    }

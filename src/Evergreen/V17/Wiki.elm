module Evergreen.V17.Wiki exposing (..)

import Dict
import Evergreen.V17.ContributorWikiSession
import Evergreen.V17.Page


type alias Slug =
    String


type alias CatalogEntry =
    { slug : Slug
    , name : String
    , summary : String
    , active : Bool
    }


type alias FrontendDetails =
    { pageSlugs : List Evergreen.V17.Page.Slug
    , publishedPageMarkdownSources : Dict.Dict Evergreen.V17.Page.Slug String
    , publishedPageTags : Dict.Dict Evergreen.V17.Page.Slug (List Evergreen.V17.Page.Slug)
    , contentVersion : Int
    , pendingReviewCountForTrustedViewer : Maybe Int
    , viewerSession : Maybe Evergreen.V17.ContributorWikiSession.ContributorWikiSession
    }


type alias Wiki =
    { slug : String
    , name : String
    , summary : String
    , active : Bool
    , contentVersion : Int
    , pages : Dict.Dict Evergreen.V17.Page.Slug Evergreen.V17.Page.Page
    }

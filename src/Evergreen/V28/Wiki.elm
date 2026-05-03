module Evergreen.V28.Wiki exposing (..)

import Dict
import Evergreen.V28.ContributorWikiSession
import Evergreen.V28.Page


type alias Slug =
    String


type alias CatalogEntry =
    { slug : Slug
    , name : String
    , summary : String
    , active : Bool
    }


type alias FrontendDetails =
    { pageSlugs : List Evergreen.V28.Page.Slug
    , publishedPageMarkdownSources : Dict.Dict Evergreen.V28.Page.Slug String
    , publishedPageTags : Dict.Dict Evergreen.V28.Page.Slug (List Evergreen.V28.Page.Slug)
    , contentVersion : Int
    , pendingReviewCountForTrustedViewer : Maybe Int
    , viewerSession : Maybe Evergreen.V28.ContributorWikiSession.ContributorWikiSession
    }


type alias Wiki =
    { slug : String
    , name : String
    , summary : String
    , active : Bool
    , contentVersion : Int
    , pages : Dict.Dict Evergreen.V28.Page.Slug Evergreen.V28.Page.Page
    }

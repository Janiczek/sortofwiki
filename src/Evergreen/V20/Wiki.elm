module Evergreen.V20.Wiki exposing (..)

import Dict
import Evergreen.V20.ContributorWikiSession
import Evergreen.V20.Page


type alias Slug =
    String


type alias CatalogEntry =
    { slug : Slug
    , name : String
    , summary : String
    , active : Bool
    }


type alias FrontendDetails =
    { pageSlugs : List Evergreen.V20.Page.Slug
    , publishedPageMarkdownSources : Dict.Dict Evergreen.V20.Page.Slug String
    , publishedPageTags : Dict.Dict Evergreen.V20.Page.Slug (List Evergreen.V20.Page.Slug)
    , contentVersion : Int
    , pendingReviewCountForTrustedViewer : Maybe Int
    , viewerSession : Maybe Evergreen.V20.ContributorWikiSession.ContributorWikiSession
    }


type alias Wiki =
    { slug : String
    , name : String
    , summary : String
    , active : Bool
    , contentVersion : Int
    , pages : Dict.Dict Evergreen.V20.Page.Slug Evergreen.V20.Page.Page
    }

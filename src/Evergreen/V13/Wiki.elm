module Evergreen.V13.Wiki exposing (..)

import Dict
import Evergreen.V13.ContributorWikiSession
import Evergreen.V13.Page


type alias Slug =
    String


type alias CatalogEntry =
    { slug : Slug
    , name : String
    , summary : String
    , active : Bool
    }


type alias FrontendDetails =
    { pageSlugs : List Evergreen.V13.Page.Slug
    , publishedPageMarkdownSources : Dict.Dict Evergreen.V13.Page.Slug String
    , publishedPageTags : Dict.Dict Evergreen.V13.Page.Slug (List Evergreen.V13.Page.Slug)
    , pendingReviewCountForTrustedViewer : Maybe Int
    , viewerSession : Maybe Evergreen.V13.ContributorWikiSession.ContributorWikiSession
    }


type alias Wiki =
    { slug : String
    , name : String
    , summary : String
    , active : Bool
    , pages : Dict.Dict Evergreen.V13.Page.Slug Evergreen.V13.Page.Page
    }

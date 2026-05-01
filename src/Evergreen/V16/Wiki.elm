module Evergreen.V16.Wiki exposing (..)

import Dict
import Evergreen.V16.ContributorWikiSession
import Evergreen.V16.Page


type alias Slug =
    String


type alias CatalogEntry =
    { slug : Slug
    , name : String
    , summary : String
    , active : Bool
    }


type alias FrontendDetails =
    { pageSlugs : List Evergreen.V16.Page.Slug
    , publishedPageMarkdownSources : Dict.Dict Evergreen.V16.Page.Slug String
    , publishedPageTags : Dict.Dict Evergreen.V16.Page.Slug (List Evergreen.V16.Page.Slug)
    , pendingReviewCountForTrustedViewer : Maybe Int
    , viewerSession : Maybe Evergreen.V16.ContributorWikiSession.ContributorWikiSession
    }


type alias Wiki =
    { slug : String
    , name : String
    , summary : String
    , active : Bool
    , pages : Dict.Dict Evergreen.V16.Page.Slug Evergreen.V16.Page.Page
    }

module Evergreen.V12.Wiki exposing (..)

import Dict
import Evergreen.V12.ContributorWikiSession
import Evergreen.V12.Page


type alias Slug =
    String


type alias CatalogEntry =
    { slug : Slug
    , name : String
    , summary : String
    , active : Bool
    }


type alias FrontendDetails =
    { pageSlugs : List Evergreen.V12.Page.Slug
    , publishedPageMarkdownSources : Dict.Dict Evergreen.V12.Page.Slug String
    , publishedPageTags : Dict.Dict Evergreen.V12.Page.Slug (List Evergreen.V12.Page.Slug)
    , pendingReviewCountForTrustedViewer : Maybe Int
    , viewerSession : Maybe Evergreen.V12.ContributorWikiSession.ContributorWikiSession
    }


type alias Wiki =
    { slug : String
    , name : String
    , summary : String
    , active : Bool
    , pages : Dict.Dict Evergreen.V12.Page.Slug Evergreen.V12.Page.Page
    }

module Evergreen.V27.Wiki exposing (..)

import Dict
import Evergreen.V27.ContributorWikiSession
import Evergreen.V27.Page


type alias Slug =
    String


type alias CatalogEntry =
    { slug : Slug
    , name : String
    , summary : String
    , active : Bool
    }


type alias FrontendDetails =
    { pageSlugs : List Evergreen.V27.Page.Slug
    , publishedPageMarkdownSources : Dict.Dict Evergreen.V27.Page.Slug String
    , publishedPageTags : Dict.Dict Evergreen.V27.Page.Slug (List Evergreen.V27.Page.Slug)
    , contentVersion : Int
    , pendingReviewCountForTrustedViewer : Maybe Int
    , viewerSession : Maybe Evergreen.V27.ContributorWikiSession.ContributorWikiSession
    }


type alias Wiki =
    { slug : String
    , name : String
    , summary : String
    , active : Bool
    , contentVersion : Int
    , pages : Dict.Dict Evergreen.V27.Page.Slug Evergreen.V27.Page.Page
    }

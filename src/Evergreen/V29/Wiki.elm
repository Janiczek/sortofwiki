module Evergreen.V29.Wiki exposing (..)

import Dict
import Evergreen.V29.ContributorWikiSession
import Evergreen.V29.Page


type alias Slug =
    String


type alias CatalogEntry =
    { slug : Slug
    , name : String
    , summary : String
    , active : Bool
    }


type alias FrontendDetails =
    { pageSlugs : List Evergreen.V29.Page.Slug
    , publishedPageMarkdownSources : Dict.Dict Evergreen.V29.Page.Slug String
    , publishedPageTags : Dict.Dict Evergreen.V29.Page.Slug (List Evergreen.V29.Page.Slug)
    , contentVersion : Int
    , pendingReviewCountForTrustedViewer : Maybe Int
    , viewerSession : Maybe Evergreen.V29.ContributorWikiSession.ContributorWikiSession
    }


type alias Wiki =
    { slug : String
    , name : String
    , summary : String
    , active : Bool
    , contentVersion : Int
    , pages : Dict.Dict Evergreen.V29.Page.Slug Evergreen.V29.Page.Page
    }

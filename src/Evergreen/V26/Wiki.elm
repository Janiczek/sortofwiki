module Evergreen.V26.Wiki exposing (..)

import Dict
import Evergreen.V26.ContributorWikiSession
import Evergreen.V26.Page


type alias Slug =
    String


type alias CatalogEntry =
    { slug : Slug
    , name : String
    , summary : String
    , active : Bool
    }


type alias FrontendDetails =
    { pageSlugs : List Evergreen.V26.Page.Slug
    , publishedPageMarkdownSources : Dict.Dict Evergreen.V26.Page.Slug String
    , publishedPageTags : Dict.Dict Evergreen.V26.Page.Slug (List Evergreen.V26.Page.Slug)
    , contentVersion : Int
    , pendingReviewCountForTrustedViewer : Maybe Int
    , viewerSession : Maybe Evergreen.V26.ContributorWikiSession.ContributorWikiSession
    }


type alias Wiki =
    { slug : String
    , name : String
    , summary : String
    , active : Bool
    , contentVersion : Int
    , pages : Dict.Dict Evergreen.V26.Page.Slug Evergreen.V26.Page.Page
    }

module Evergreen.V14.Wiki exposing (..)

import Dict
import Evergreen.V14.ContributorWikiSession
import Evergreen.V14.Page


type alias Slug =
    String


type alias CatalogEntry =
    { slug : Slug
    , name : String
    , summary : String
    , active : Bool
    }


type alias FrontendDetails =
    { pageSlugs : List Evergreen.V14.Page.Slug
    , publishedPageMarkdownSources : Dict.Dict Evergreen.V14.Page.Slug String
    , publishedPageTags : Dict.Dict Evergreen.V14.Page.Slug (List Evergreen.V14.Page.Slug)
    , pendingReviewCountForTrustedViewer : Maybe Int
    , viewerSession : Maybe Evergreen.V14.ContributorWikiSession.ContributorWikiSession
    }


type alias Wiki =
    { slug : String
    , name : String
    , summary : String
    , active : Bool
    , pages : Dict.Dict Evergreen.V14.Page.Slug Evergreen.V14.Page.Page
    }

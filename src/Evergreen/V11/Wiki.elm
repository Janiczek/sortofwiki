module Evergreen.V11.Wiki exposing (..)

import Dict
import Evergreen.V11.ContributorWikiSession
import Evergreen.V11.Page


type alias Slug =
    String


type alias CatalogEntry =
    { slug : Slug
    , name : String
    , summary : String
    , active : Bool
    }


type alias FrontendDetails =
    { pageSlugs : List Evergreen.V11.Page.Slug
    , publishedPageMarkdownSources : Dict.Dict Evergreen.V11.Page.Slug String
    , publishedPageTags : Dict.Dict Evergreen.V11.Page.Slug (List Evergreen.V11.Page.Slug)
    , pendingReviewCountForTrustedViewer : Maybe Int
    , viewerSession : Maybe Evergreen.V11.ContributorWikiSession.ContributorWikiSession
    }


type alias Wiki =
    { slug : String
    , name : String
    , summary : String
    , active : Bool
    , pages : Dict.Dict Evergreen.V11.Page.Slug Evergreen.V11.Page.Page
    }

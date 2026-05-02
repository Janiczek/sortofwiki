module Evergreen.V20.Page exposing (..)


type alias Slug =
    String


type alias FrontendDetails =
    { maybeMarkdownSource : Maybe String
    , backlinks : List Slug
    , tags : List Slug
    , taggedPageSlugs : List Slug
    }


type alias Page =
    { slug : Slug
    , publishedMarkdown : Maybe String
    , publishedRevision : Int
    , pendingMarkdown : Maybe String
    , tags : List Slug
    }

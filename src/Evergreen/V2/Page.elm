module Evergreen.V2.Page exposing (..)


type alias Slug =
    String


type alias FrontendDetails =
    { markdownSource : String
    , backlinks : List Slug
    }


type alias Page =
    { slug : Slug
    , publishedMarkdown : Maybe String
    , publishedRevision : Int
    , pendingMarkdown : Maybe String
    }

module Types exposing
    ( BackendModel
    , BackendMsg(..)
    , FrontendModel
    , FrontendMsg(..)
    , ToBackend(..)
    , ToFrontend(..)
    )

import Effect.Browser
import Effect.Browser.Navigation
import Route exposing (Route)
import Url exposing (Url)
import WikiSummary exposing (WikiSummary)


type alias FrontendModel =
    { key : Effect.Browser.Navigation.Key
    , route : Route
    , wikis : List WikiSummary
    }


type alias BackendModel =
    { wikis : List WikiSummary
    }


type FrontendMsg
    = UrlClicked Effect.Browser.UrlRequest
    | UrlChanged Url


type ToBackend
    = RequestWikiCatalog


type BackendMsg
    = NoOpBackendMsg


type ToFrontend
    = WikiCatalog (List WikiSummary)

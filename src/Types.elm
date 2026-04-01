module Types exposing
    ( BackendModel
    , BackendMsg(..)
    , FrontendModel
    , FrontendMsg(..)
    , ToBackend(..)
    , ToFrontend(..)
    )

import Dict exposing (Dict)
import Effect.Browser
import Effect.Browser.Navigation
import Page
import Route exposing (Route)
import Store exposing (Store)
import Url exposing (Url)
import Wiki exposing (Wiki)


type ToBackend
    = RequestWikiCatalog
    | RequestWikiFrontendDetails Wiki.Slug
    | RequestPageFrontendDetails Wiki.Slug Page.Slug


type ToFrontend
    = WikiCatalogResponse (Dict Wiki.Slug Wiki.Summary)
    | WikiFrontendDetailsResponse Wiki.Slug (Maybe Wiki.FrontendDetails)
    | PageFrontendDetailsResponse Wiki.Slug Page.Slug (Maybe Page.FrontendDetails)


type alias BackendModel =
    { wikis : Dict Wiki.Slug Wiki
    }


type BackendMsg
    = BackendNoOp


type alias FrontendModel =
    { key : Effect.Browser.Navigation.Key
    , route : Route
    , store : Store
    }


type FrontendMsg
    = UrlClicked Effect.Browser.UrlRequest
    | UrlChanged Url

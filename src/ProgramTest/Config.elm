module ProgramTest.Config exposing (config)

import Backend
import Effect.Test
import Frontend
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)
import Url exposing (Protocol(..), Url)


{-| Base URL for program-test (matches local `lamdera live`).
-}
unsafeDomainUrl : Url
unsafeDomainUrl =
    Url.fromString "http://localhost:8000"
        |> Maybe.withDefault
            { protocol = Http
            , host = "localhost"
            , port_ = Just 8000
            , path = ""
            , query = Nothing
            , fragment = Nothing
            }


{-| Shared Lamdera program-test configuration for SortOfWiki Frontend/Backend.
-}
config : Effect.Test.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel
config =
    { frontendApp = Frontend.app_
    , backendApp = Backend.app_
    , handleHttpRequest = always Effect.Test.NetworkErrorResponse
    , handlePortToJs = always Nothing
    , handleFileUpload = always Effect.Test.UnhandledFileUpload
    , handleMultipleFilesUpload = always Effect.Test.UnhandledMultiFileUpload
    , domain = unsafeDomainUrl
    }

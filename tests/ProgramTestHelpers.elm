module ProgramTestHelpers exposing (config)

import Backend
import Effect.Test
import Frontend
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)
import Url exposing (Url)


{-| Base URL for program-test (matches local `lamdera live`).
-}
unsafeDomainUrl : Url
unsafeDomainUrl =
    case Url.fromString "http://localhost:8000" of
        Just url ->
            url

        Nothing ->
            Debug.todo "Invalid url"


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

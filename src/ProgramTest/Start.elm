module ProgramTest.Start exposing (Config, EndToEndTest, connectFrontend, start, startWith)

{-| Wrappers around `Effect.Test.start` / `connectFrontend` with fixed simulated time,
800×600 viewport, and string session ids. Use `start` for one browser; `startWith` plus
`connectFrontend` for multiple clients or mixed step lists.
-}

import Backend
import Effect.Lamdera
import Effect.Test
import Effect.Time
import Frontend
import Types exposing (ToBackend, ToFrontend)


{-| `Effect.Test.Config` specialised to this app (shared by all program tests under `src/ProgramTest/`).
-}
type alias Config =
    Effect.Test.Config ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model


{-| `Effect.Test.EndToEndTest` specialised to this app.
-}
type alias EndToEndTest =
    Effect.Test.EndToEndTest ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model


{-| All program tests use the same simulated wall clock origin.
-}
startTime : Effect.Time.Posix
startTime =
    Effect.Time.millisToPosix 0


{-| Browser viewport for every `connectFrontend` in program tests.
-}
viewport : { width : Int, height : Int }
viewport =
    { width = 800, height = 600 }


{-| Default first argument to `Effect.Test.connectFrontend` (client id in the harness).
-}
defaultConnectClientMs : Effect.Test.DelayInMs
defaultConnectClientMs =
    100


{-| `Nothing` uses `defaultConnectClientMs` (100).
-}
resolveConnectClientMs : Maybe Int -> Effect.Test.DelayInMs
resolveConnectClientMs maybeMs =
    case maybeMs of
        Nothing ->
            defaultConnectClientMs

        Just ms ->
            toFloat ms


{-| One browser client; fixed `startTime`, `viewport`, and optional connect delay (`Nothing` → 100).
-}
start :
    { a
        | name : String
        , config : Effect.Test.Config toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
        , sessionId : String
        , path : String
        , connectClientMs : Maybe Int
        , clientSteps :
            Effect.Test.FrontendActions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
            -> List (Effect.Test.Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
    }
    -> Effect.Test.EndToEndTest toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
start args =
    startWith
        { name = args.name
        , config = args.config
        , steps =
            [ connectFrontend
                { sessionId = args.sessionId
                , path = args.path
                , connectClientMs = args.connectClientMs
                , steps = args.clientSteps
                }
            ]
        }


{-| Same as `Effect.Test.start` but with shared `startTime` and a pre-built step list (e.g. multiple `connectFrontend`).
-}
startWith :
    { a
        | name : String
        , config : Effect.Test.Config toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
        , steps : List (Effect.Test.Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
    }
    -> Effect.Test.EndToEndTest toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
startWith args =
    Effect.Test.start args.name startTime args.config args.steps


{-| `Effect.Test.connectFrontend` with `viewport`, string session id, and optional connect delay (`Nothing` → 100).
-}
connectFrontend :
    { a
        | connectClientMs : Maybe Int
        , sessionId : String
        , path : String
        , steps :
            Effect.Test.FrontendActions toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
            -> List (Effect.Test.Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel)
    }
    -> Effect.Test.Action toBackend frontendMsg frontendModel toFrontend backendMsg backendModel
connectFrontend args =
    Effect.Test.connectFrontend
        (resolveConnectClientMs args.connectClientMs)
        (Effect.Lamdera.sessionIdFromString args.sessionId)
        args.path
        viewport
        args.steps

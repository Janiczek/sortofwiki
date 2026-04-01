module Backend exposing (Model, app, app_)

import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Lamdera exposing (ClientId, SessionId)
import Effect.Subscription as Subscription exposing (Subscription)
import Lamdera
import Types
    exposing
        ( BackendModel
        , BackendMsg(..)
        , ToBackend(..)
        , ToFrontend(..)
        )
import WikiSummary exposing (WikiSummary)


type alias Model =
    BackendModel


seedWikis : List WikiSummary
seedWikis =
    [ { slug = "demo", name = "Demo Wiki" }
    , { slug = "elm-tips", name = "Elm Tips" }
    ]


init : ( Model, Command BackendOnly ToFrontend BackendMsg )
init =
    ( { wikis = seedWikis }
    , Command.none
    )


update : BackendMsg -> Model -> ( Model, Command BackendOnly ToFrontend BackendMsg )
update msg model =
    case msg of
        NoOpBackendMsg ->
            ( model, Command.none )


updateFromFrontend :
    SessionId
    -> ClientId
    -> ToBackend
    -> Model
    -> ( Model, Command BackendOnly ToFrontend BackendMsg )
updateFromFrontend _ clientId msg model =
    case msg of
        RequestWikiCatalog ->
            ( model
            , Effect.Lamdera.sendToFrontend clientId (WikiCatalog model.wikis)
            )


subscriptions : Model -> Subscription BackendOnly BackendMsg
subscriptions _ =
    Subscription.none


app_ :
    { init : ( Model, Command BackendOnly ToFrontend BackendMsg )
    , update : BackendMsg -> Model -> ( Model, Command BackendOnly ToFrontend BackendMsg )
    , updateFromFrontend :
        SessionId
        -> ClientId
        -> ToBackend
        -> Model
        -> ( Model, Command BackendOnly ToFrontend BackendMsg )
    , subscriptions : Model -> Subscription BackendOnly BackendMsg
    }
app_ =
    { init = init
    , update = update
    , updateFromFrontend = updateFromFrontend
    , subscriptions = subscriptions
    }


app :
    { init : ( Model, Cmd BackendMsg )
    , update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
    , updateFromFrontend : String -> String -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
    , subscriptions : Model -> Sub BackendMsg
    }
app =
    Effect.Lamdera.backend Lamdera.broadcast Lamdera.sendToFrontend app_

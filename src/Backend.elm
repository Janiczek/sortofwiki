module Backend exposing (Model, Msg, app, app_)

import Dict exposing (Dict)
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Lamdera exposing (ClientId, SessionId)
import Effect.Subscription as Subscription exposing (Subscription)
import Lamdera
import Types exposing (BackendModel, BackendMsg(..), ToBackend(..), ToFrontend(..))
import Wiki exposing (Slug, Wiki)


type alias Model =
    BackendModel


type alias Msg =
    BackendMsg


seedWikis : Dict Slug Wiki
seedWikis =
    [ { slug = "demo"
      , name = "Demo Wiki"
      , pages =
            [ { slug = "home", content = "Welcome to the Demo Wiki." }
            , { slug = "guides", content = "How to use this wiki." }
            ]
                |> slugDict
      }
    , { slug = "elm-tips"
      , name = "Elm Tips"
      , pages =
            [ { slug = "home", content = "Tips and notes about Elm." } ]
                |> slugDict
      }
    ]
        |> slugDict


slugDict : List { a | slug : String } -> Dict String { a | slug : String }
slugDict list =
    list
        |> List.map (\item -> ( item.slug, item ))
        |> Dict.fromList


init : ( Model, Command BackendOnly ToFrontend Msg )
init =
    ( { wikis = seedWikis }
    , Command.none
    )


update : Msg -> Model -> ( Model, Command BackendOnly ToFrontend Msg )
update msg model =
    case msg of
        BackendNoOp ->
            ( model, Command.none )


updateFromFrontend :
    SessionId
    -> ClientId
    -> ToBackend
    -> Model
    -> ( Model, Command BackendOnly ToFrontend Msg )
updateFromFrontend _ clientId msg model =
    case msg of
        RequestWikiCatalog ->
            ( model
            , Effect.Lamdera.sendToFrontend clientId
                (WikiCatalogResponse
                    (model.wikis |> Dict.map (\_ w -> Wiki.summary w))
                )
            )

        RequestWikiFrontendDetails slug ->
            ( model
            , Effect.Lamdera.sendToFrontend clientId
                (WikiFrontendDetailsResponse slug
                    (model.wikis
                        |> Dict.get slug
                        |> Maybe.map Wiki.frontendDetails
                    )
                )
            )


subscriptions : Model -> Subscription BackendOnly Msg
subscriptions _ =
    Subscription.none


app_ :
    { init : ( Model, Command BackendOnly ToFrontend Msg )
    , update : Msg -> Model -> ( Model, Command BackendOnly ToFrontend Msg )
    , updateFromFrontend :
        SessionId
        -> ClientId
        -> ToBackend
        -> Model
        -> ( Model, Command BackendOnly ToFrontend Msg )
    , subscriptions : Model -> Subscription BackendOnly Msg
    }
app_ =
    { init = init
    , update = update
    , updateFromFrontend = updateFromFrontend
    , subscriptions = subscriptions
    }


app :
    { init : ( Model, Cmd Msg )
    , update : Msg -> Model -> ( Model, Cmd Msg )
    , updateFromFrontend : String -> String -> ToBackend -> Model -> ( Model, Cmd Msg )
    , subscriptions : Model -> Sub Msg
    }
app =
    Effect.Lamdera.backend Lamdera.broadcast Lamdera.sendToFrontend app_

module Frontend exposing (Model, app, app_)

import Browser
import Browser.Navigation
import Effect.Browser exposing (UrlRequest)
import Effect.Browser.Navigation
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Lamdera
import Effect.Subscription as Subscription exposing (Subscription)
import Html
import Html.Attributes as Attr
import Lamdera
import Route exposing (Route)
import Types exposing (FrontendModel, FrontendMsg(..), ToBackend(..), ToFrontend(..))
import Url exposing (Url)
import WikiSummary exposing (WikiSummary)


type alias Model =
    FrontendModel


app_ :
    { init : Url -> Effect.Browser.Navigation.Key -> ( Model, Command FrontendOnly ToBackend FrontendMsg )
    , onUrlRequest : UrlRequest -> FrontendMsg
    , onUrlChange : Url -> FrontendMsg
    , update : FrontendMsg -> Model -> ( Model, Command FrontendOnly ToBackend FrontendMsg )
    , updateFromBackend : ToFrontend -> Model -> ( Model, Command FrontendOnly ToBackend FrontendMsg )
    , view : Model -> Effect.Browser.Document FrontendMsg
    , subscriptions : Model -> Subscription FrontendOnly FrontendMsg
    }
app_ =
    { init = init
    , onUrlRequest = UrlClicked
    , onUrlChange = UrlChanged
    , update = update
    , updateFromBackend = updateFromBackend
    , subscriptions = \_ -> Subscription.none
    , view = view
    }


app :
    { init : Url -> Browser.Navigation.Key -> ( Model, Cmd FrontendMsg )
    , view : Model -> Browser.Document FrontendMsg
    , update : FrontendMsg -> Model -> ( Model, Cmd FrontendMsg )
    , updateFromBackend : ToFrontend -> Model -> ( Model, Cmd FrontendMsg )
    , subscriptions : Model -> Sub FrontendMsg
    , onUrlRequest : UrlRequest -> FrontendMsg
    , onUrlChange : Url -> FrontendMsg
    }
app =
    Effect.Lamdera.frontend Lamdera.sendToBackend app_


init : Url -> Effect.Browser.Navigation.Key -> ( Model, Command FrontendOnly ToBackend FrontendMsg )
init url key =
    let
        route : Route
        route =
            Route.fromUrl url
    in
    ( { key = key
      , route = route
      , wikis = []
      }
    , if Route.isWikiList route then
        Effect.Lamdera.sendToBackend RequestWikiCatalog

      else
        Command.none
    )


update : FrontendMsg -> Model -> ( Model, Command FrontendOnly ToBackend FrontendMsg )
update msg model =
    case msg of
        UrlClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model
                    , Effect.Browser.Navigation.pushUrl model.key (Url.toString url)
                    )

                Browser.External url ->
                    ( model
                    , Effect.Browser.Navigation.load url
                    )

        UrlChanged url ->
            let
                route : Route
                route =
                    Route.fromUrl url

                cmd : Command FrontendOnly ToBackend FrontendMsg
                cmd =
                    if Route.isWikiList route then
                        Effect.Lamdera.sendToBackend RequestWikiCatalog

                    else
                        Command.none
            in
            ( { model | route = route }, cmd )


updateFromBackend : ToFrontend -> Model -> ( Model, Command FrontendOnly ToBackend FrontendMsg )
updateFromBackend msg model =
    case msg of
        WikiCatalog wikis ->
            ( { model | wikis = wikis }, Command.none )


viewWikiList : List WikiSummary -> Html.Html FrontendMsg
viewWikiList wikis =
    Html.div
        [ Attr.id "catalog-page"
        ]
        [ Html.h1 [] [ Html.text "Hosted wikis" ]
        , Html.ul
            [ Attr.id "wiki-catalog"
            ]
            (List.map viewWikiRow wikis)
        ]


viewWikiRow : WikiSummary -> Html.Html FrontendMsg
viewWikiRow wiki =
    Html.li []
        [ Html.a
            [ Attr.href (WikiSummary.catalogUrlPath wiki)
            , Attr.attribute "data-wiki-slug" wiki.slug
            ]
            [ Html.text wiki.name ]
        ]


viewNotFound : Html.Html FrontendMsg
viewNotFound =
    Html.div
        [ Attr.id "not-found-page"
        ]
        [ Html.h1 [] [ Html.text "Page not found" ]
        , Html.p [] [ Html.text "This URL is not part of SortOfWiki yet." ]
        ]


view : Model -> Effect.Browser.Document FrontendMsg
view model =
    { title =
        if Route.isWikiList model.route then
            "SortOfWiki — hosted wikis"

        else
            "404 — SortOfWiki"
    , body =
        [ Html.div
            [ Attr.style "font-family" "system-ui, sans-serif"
            , Attr.style "max-width" "40rem"
            , Attr.style "margin" "2rem auto"
            , Attr.style "padding" "0 1rem"
            ]
            [ if Route.isWikiList model.route then
                viewWikiList model.wikis

              else
                viewNotFound
            ]
        ]
    }

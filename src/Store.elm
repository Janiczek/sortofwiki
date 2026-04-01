module Store exposing
    ( Action(..)
    , Config
    , Store
    , empty
    , get
    , get_
    , perform
    )

import Dict exposing (Dict)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Lamdera
import RemoteData exposing (RemoteData(..))
import Wiki


{-| Client cache; survives route changes.
`wikiCatalog` tracks catalog fetch lifecycle.
Per-slug `wikiDetails` uses `Failure ()` when the backend reports the wiki is not hosted.
-}
type alias Store =
    { wikiCatalog : RemoteData () (Dict Wiki.Slug Wiki.Summary)
    , wikiDetails : Dict Wiki.Slug (RemoteData () Wiki.FrontendDetails)
    }


type Action
    = AskForWikiCatalog
    | AskForWikiFrontendDetails Wiki.Slug


empty : Store
empty =
    { wikiCatalog = NotAsked
    , wikiDetails = Dict.empty
    }


type alias Config toBackend =
    { requestWikiCatalog : toBackend
    , requestWikiFrontendDetails : Wiki.Slug -> toBackend
    }


perform : Config toBackend -> Action -> Store -> ( Store, Command FrontendOnly toBackend msg )
perform config action store =
    case action of
        AskForWikiCatalog ->
            case store.wikiCatalog of
                Success _ ->
                    ( store, Command.none )

                Loading ->
                    ( store, Command.none )

                NotAsked ->
                    ( { store | wikiCatalog = Loading }
                    , Effect.Lamdera.sendToBackend config.requestWikiCatalog
                    )

                Failure _ ->
                    ( { store | wikiCatalog = Loading }
                    , Effect.Lamdera.sendToBackend config.requestWikiCatalog
                    )

        AskForWikiFrontendDetails slug ->
            case Dict.get slug store.wikiDetails of
                Just (Success _) ->
                    ( store, Command.none )

                Just Loading ->
                    ( store, Command.none )

                Just (Failure _) ->
                    ( store, Command.none )

                Just NotAsked ->
                    ( { store | wikiDetails = Dict.insert slug Loading store.wikiDetails }
                    , Effect.Lamdera.sendToBackend (config.requestWikiFrontendDetails slug)
                    )

                Nothing ->
                    ( { store | wikiDetails = Dict.insert slug Loading store.wikiDetails }
                    , Effect.Lamdera.sendToBackend (config.requestWikiFrontendDetails slug)
                    )


get : comparable -> RemoteData f (Dict comparable b) -> RemoteData f b
get key remoteData =
    case remoteData of
        Success dict ->
            case Dict.get key dict of
                Nothing ->
                    NotAsked

                Just val ->
                    Success val

        Loading ->
            Loading

        NotAsked ->
            NotAsked

        Failure error ->
            Failure error


get_ : comparable -> Dict comparable (RemoteData f b) -> RemoteData f b
get_ key dict =
    case Dict.get key dict of
        Just remoteData ->
            remoteData

        Nothing ->
            NotAsked

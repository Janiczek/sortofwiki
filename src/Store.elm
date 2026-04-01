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
import Page
import RemoteData exposing (RemoteData(..))
import Wiki


{-| Client cache; survives route changes.
`wikiCatalog` tracks catalog fetch lifecycle.
-}
type alias Store =
    { wikiCatalog : RemoteData () (Dict Wiki.Slug Wiki.Summary)
    , wikiDetails : Dict Wiki.Slug (RemoteData () Wiki.FrontendDetails)
    , publishedPages : Dict ( Wiki.Slug, Page.Slug ) (RemoteData () Page.FrontendDetails)
    }


type Action
    = AskForWikiCatalog
    | AskForWikiFrontendDetails Wiki.Slug
    | AskForPageFrontendDetails Wiki.Slug Page.Slug


empty : Store
empty =
    { wikiCatalog = NotAsked
    , wikiDetails = Dict.empty
    , publishedPages = Dict.empty
    }


type alias Config toBackend =
    { requestWikiCatalog : toBackend
    , requestWikiFrontendDetails : Wiki.Slug -> toBackend
    , requestPageFrontendDetails : Wiki.Slug -> Page.Slug -> toBackend
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

                Failure _ ->
                    ( store, Command.none )

                NotAsked ->
                    ( { store | wikiCatalog = Loading }
                    , Effect.Lamdera.sendToBackend config.requestWikiCatalog
                    )

        AskForWikiFrontendDetails slug ->
            case Dict.get slug store.wikiDetails |> join of
                Success _ ->
                    ( store, Command.none )

                Loading ->
                    ( store, Command.none )

                Failure _ ->
                    ( store, Command.none )

                NotAsked ->
                    ( { store | wikiDetails = Dict.insert slug Loading store.wikiDetails }
                    , Effect.Lamdera.sendToBackend (config.requestWikiFrontendDetails slug)
                    )

        AskForPageFrontendDetails wikiSlug pageSlug ->
            let
                key : ( Wiki.Slug, Page.Slug )
                key =
                    ( wikiSlug, pageSlug )
            in
            case Dict.get key store.publishedPages |> join of
                Success _ ->
                    ( store, Command.none )

                Loading ->
                    ( store, Command.none )

                Failure _ ->
                    ( store, Command.none )

                NotAsked ->
                    ( { store
                        | publishedPages =
                            Dict.insert key Loading store.publishedPages
                      }
                    , Effect.Lamdera.sendToBackend
                        (config.requestPageFrontendDetails wikiSlug pageSlug)
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


join : Maybe (RemoteData f b) -> RemoteData f b
join maybeRemoteData =
    case maybeRemoteData of
        Just remoteData ->
            remoteData

        Nothing ->
            NotAsked

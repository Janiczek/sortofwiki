module WikiFrontendSubscription exposing
    ( WikiFrontendClientSets
    , WikiFrontendListeners
    , emptyClientSets
    , listenerSessionsForWiki
    , remapSlugInWikiFrontendClients
    , removeWikiSubscribers
    , subscribeViewer
    , wikiSlugsListeningForSession
    )

import Dict exposing (Dict)
import Effect.Lamdera exposing (ClientId)
import Set exposing (Set)
import Wiki


type alias WikiFrontendListeners =
    { sessions : Dict String (Set String)
    }


type alias WikiFrontendClientSets =
    Dict Wiki.Slug WikiFrontendListeners


emptyWikiListeners : WikiFrontendListeners
emptyWikiListeners =
    { sessions = Dict.empty }


emptyClientSets : WikiFrontendClientSets
emptyClientSets =
    Dict.empty


subscribeViewer : Wiki.Slug -> String -> ClientId -> WikiFrontendClientSets -> WikiFrontendClientSets
subscribeViewer wikiSlug sessionKey clientId subs =
    let
        clientKey : String
        clientKey =
            Effect.Lamdera.clientIdToString clientId

        cleanedSubs : WikiFrontendClientSets
        cleanedSubs =
            unsubscribeClientEverywhere clientId subs
    in
    Dict.update wikiSlug
        (\maybeWiki ->
            let
                wikiListeners : WikiFrontendListeners
                wikiListeners =
                    Maybe.withDefault emptyWikiListeners maybeWiki

                nextSessions : Dict String (Set String)
                nextSessions =
                    Dict.update sessionKey
                        (\maybeSet ->
                            Just (Set.insert clientKey (Maybe.withDefault Set.empty maybeSet))
                        )
                        wikiListeners.sessions
            in
            Just { sessions = nextSessions }
        )
        cleanedSubs


listenerSessionsForWiki : Wiki.Slug -> WikiFrontendClientSets -> Dict String (Set String)
listenerSessionsForWiki wikiSlug subs =
    Dict.get wikiSlug subs
        |> Maybe.map .sessions
        |> Maybe.withDefault Dict.empty


wikiSlugsListeningForSession : String -> WikiFrontendClientSets -> List Wiki.Slug
wikiSlugsListeningForSession sessionKey subs =
    subs
        |> Dict.toList
        |> List.filterMap
            (\( wikiSlug, listeners ) ->
                if Dict.member sessionKey listeners.sessions then
                    Just wikiSlug

                else
                    Nothing
            )


pruneClientFromWikiListeners : ClientId -> WikiFrontendListeners -> WikiFrontendListeners
pruneClientFromWikiListeners clientId wikiListeners =
    let
        clientKey : String
        clientKey =
            Effect.Lamdera.clientIdToString clientId
    in
    { sessions =
        wikiListeners.sessions
            |> Dict.map (\_ set -> Set.remove clientKey set)
            |> Dict.filter (\_ set -> not (Set.isEmpty set))
    }


unsubscribeClientEverywhere : ClientId -> WikiFrontendClientSets -> WikiFrontendClientSets
unsubscribeClientEverywhere clientId subs =
    subs
        |> Dict.map (\_ listeners -> pruneClientFromWikiListeners clientId listeners)
        |> Dict.filter (\_ listeners -> not (Dict.isEmpty listeners.sessions))


remapSlugInWikiFrontendClients : Wiki.Slug -> Wiki.Slug -> WikiFrontendClientSets -> WikiFrontendClientSets
remapSlugInWikiFrontendClients oldSlug newSlug subs =
    case Dict.get oldSlug subs of
        Nothing ->
            subs

        Just wikiListeners ->
            subs
                |> Dict.remove oldSlug
                |> Dict.update newSlug
                    (\maybe ->
                        case maybe of
                            Nothing ->
                                Just wikiListeners

                            Just existing ->
                                Just
                                    { sessions =
                                        Dict.foldl
                                            (\sessionKey clientIds acc ->
                                                Dict.insert sessionKey
                                                    (Set.union clientIds (Dict.get sessionKey acc |> Maybe.withDefault Set.empty))
                                                    acc
                                            )
                                            existing.sessions
                                            wikiListeners.sessions
                                    }
                    )


removeWikiSubscribers : Wiki.Slug -> WikiFrontendClientSets -> WikiFrontendClientSets
removeWikiSubscribers wikiSlug subs =
    Dict.remove wikiSlug subs

module PendingReviewCount exposing
    ( PendingReviewClientSets
    , WikiPendingListeners
    , emptyClientSets
    , emptyCountMap
    , wikiSlugsListeningForSession
    , evictSessionFromAllWikis
    , evictSessionFromWikiListeners
    , listenerClientIdsForWiki
    , mergeIntoStoreWikiDetails
    , recallFromSubmissions
    , remapSlugInPendingCounts
    , remapSlugInPendingReviewClients
    , removeWikiSubscribers
    , subscribeTrustedViewer
    , unsubscribeClientEverywhere
    , unsubscribeSessionFromWiki
    )

import Dict exposing (Dict)
import Effect.Lamdera exposing (ClientId)
import RemoteData exposing (RemoteData(..))
import Set exposing (Set)
import Store exposing (Store)
import Submission
import Wiki


{-| Server-derived pending submission count per wiki (same cardinality as review queue list).
-}
emptyCountMap : Dict Wiki.Slug Int
emptyCountMap =
    Dict.empty


{-| Recompute counts for every wiki that has at least one submission (for import / bulk replace).
-}
recallFromSubmissions : Dict String Submission.Submission -> Dict Wiki.Slug Int
recallFromSubmissions submissions =
    submissions
        |> Dict.values
        |> List.filter (\sub -> sub.status == Submission.Pending)
        |> List.map .wikiSlug
        |> List.foldl
            (\slug acc ->
                Dict.update slug
                    (\maybe ->
                        case maybe of
                            Nothing ->
                                Just 1

                            Just n ->
                                Just (n + 1)
                    )
                    acc
            )
            Dict.empty


{-| Move cached count key when hosted wiki slug renames (count unchanged).
-}
remapSlugInPendingCounts : Wiki.Slug -> Wiki.Slug -> Dict Wiki.Slug Int -> Dict Wiki.Slug Int
remapSlugInPendingCounts oldSlug newSlug counts =
    case Dict.get oldSlug counts of
        Nothing ->
            Dict.remove oldSlug counts

        Just n ->
            counts
                |> Dict.remove oldSlug
                |> Dict.insert newSlug n


{-| Per Lamdera browser session (`sessionIdToString`): client tabs that loaded wiki details as trusted (Review badge).

Used to push `PendingReviewCountUpdated` only to trusted moderators / wiki admins — not broadcast.

-}
type alias WikiPendingListeners =
    { trustedSessions : Dict String (Set ClientId)
    }


{-| Wiki slug → listener buckets keyed by Lamdera session id string.
-}
type alias PendingReviewClientSets =
    Dict Wiki.Slug WikiPendingListeners


emptyWikiListeners : WikiPendingListeners
emptyWikiListeners =
    { trustedSessions = Dict.empty }


emptyClientSets : PendingReviewClientSets
emptyClientSets =
    Dict.empty


subscribeTrustedViewer : Wiki.Slug -> String -> ClientId -> PendingReviewClientSets -> PendingReviewClientSets
subscribeTrustedViewer wikiSlug sessionKey clientId subs =
    Dict.update wikiSlug
        (\maybeWiki ->
            let
                wikiListeners : WikiPendingListeners
                wikiListeners =
                    Maybe.withDefault emptyWikiListeners maybeWiki

                nextTrusted : Dict String (Set ClientId)
                nextTrusted =
                    Dict.update sessionKey
                        (\maybeSet ->
                            Just (Set.insert clientId (Maybe.withDefault Set.empty maybeSet))
                        )
                        wikiListeners.trustedSessions
            in
            Just { trustedSessions = nextTrusted }
        )
        subs


{-| Drop one browser session's subscriptions for a wiki (logout on wiki, demotion, or loading details as non-trusted).
-}
wikiSlugsListeningForSession : String -> PendingReviewClientSets -> List Wiki.Slug
wikiSlugsListeningForSession sessionKey subs =
    subs
        |> Dict.toList
        |> List.filterMap
            (\( wikiSlug, wl ) ->
                if Dict.member sessionKey wl.trustedSessions then
                    Just wikiSlug

                else
                    Nothing
            )


evictSessionFromAllWikis : String -> PendingReviewClientSets -> PendingReviewClientSets
evictSessionFromAllWikis sessionKey subs =
    subs
        |> Dict.map
            (\_ wl ->
                { trustedSessions = Dict.remove sessionKey wl.trustedSessions }
            )
        |> Dict.filter (\_ wl -> not (Dict.isEmpty wl.trustedSessions))


evictSessionFromWikiListeners : Wiki.Slug -> String -> PendingReviewClientSets -> PendingReviewClientSets
evictSessionFromWikiListeners wikiSlug sessionKey subs =
    case Dict.get wikiSlug subs of
        Nothing ->
            subs

        Just wikiListeners ->
            let
                nextTrusted : Dict String (Set ClientId)
                nextTrusted =
                    Dict.remove sessionKey wikiListeners.trustedSessions
            in
            if Dict.isEmpty nextTrusted then
                Dict.remove wikiSlug subs

            else
                Dict.insert wikiSlug { trustedSessions = nextTrusted } subs


{-| Same as `evictSessionFromWikiListeners` but only removes `clientId` from that session bucket (same tab reconnect edge cases).
-}
unsubscribeSessionFromWiki : Wiki.Slug -> String -> ClientId -> PendingReviewClientSets -> PendingReviewClientSets
unsubscribeSessionFromWiki wikiSlug sessionKey clientId subs =
    case Dict.get wikiSlug subs of
        Nothing ->
            subs

        Just wikiListeners ->
            case Dict.get sessionKey wikiListeners.trustedSessions of
                Nothing ->
                    subs

                Just set ->
                    let
                        nextSet : Set ClientId
                        nextSet =
                            Set.remove clientId set
                    in
                    if Set.isEmpty nextSet then
                        evictSessionFromWikiListeners wikiSlug sessionKey subs

                    else
                        Dict.insert wikiSlug
                            { trustedSessions =
                                Dict.insert sessionKey nextSet wikiListeners.trustedSessions
                            }
                            subs


pruneClientFromWikiListeners : ClientId -> WikiPendingListeners -> WikiPendingListeners
pruneClientFromWikiListeners clientId wikiListeners =
    { trustedSessions =
        wikiListeners.trustedSessions
            |> Dict.map (\_ set -> Set.remove clientId set)
            |> Dict.filter (\_ set -> not (Set.isEmpty set))
    }


unsubscribeClientEverywhere : ClientId -> PendingReviewClientSets -> PendingReviewClientSets
unsubscribeClientEverywhere clientId subs =
    subs
        |> Dict.map (\_ wl -> pruneClientFromWikiListeners clientId wl)
        |> Dict.filter (\_ wl -> not (Dict.isEmpty wl.trustedSessions))


remapSlugInPendingReviewClients : Wiki.Slug -> Wiki.Slug -> PendingReviewClientSets -> PendingReviewClientSets
remapSlugInPendingReviewClients oldSlug newSlug subs =
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
                                    { trustedSessions =
                                        Dict.foldl
                                            (\k v acc ->
                                                Dict.insert k
                                                    (Set.union v (Dict.get k acc |> Maybe.withDefault Set.empty))
                                                    acc
                                            )
                                            existing.trustedSessions
                                            wikiListeners.trustedSessions
                                    }
                    )


removeWikiSubscribers : Wiki.Slug -> PendingReviewClientSets -> PendingReviewClientSets
removeWikiSubscribers wikiSlug subs =
    Dict.remove wikiSlug subs


listenerClientIdsForWiki : Wiki.Slug -> PendingReviewClientSets -> List ClientId
listenerClientIdsForWiki wikiSlug subs =
    Dict.get wikiSlug subs
        |> Maybe.map .trustedSessions
        |> Maybe.withDefault Dict.empty
        |> Dict.values
        |> List.foldl Set.union Set.empty
        |> Set.toList


{-| Patch cached wiki frontend details when server broadcasts a new pending count (trusted-only field).
-}
mergeIntoStoreWikiDetails : Wiki.Slug -> Int -> Store -> Store
mergeIntoStoreWikiDetails wikiSlug count store =
    case Store.get_ wikiSlug store.wikiDetails of
        Success details ->
            { store
                | wikiDetails =
                    Dict.insert wikiSlug
                        (Success { details | pendingReviewCountForTrustedViewer = Just count })
                        store.wikiDetails
            }

        _ ->
            store

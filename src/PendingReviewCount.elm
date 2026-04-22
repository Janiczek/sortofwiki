module PendingReviewCount exposing
    ( PendingReviewClientSets
    , WikiPendingListeners
    , emptyClientSets
    , emptyCountMap
    , evictSessionFromWikiListeners
    , listenerClientIdsForWiki
    , mergeIntoStoreWikiDetails
    , recallFromSubmissions
    , remapSlugInPendingCounts
    , remapSlugInPendingReviewClients
    , removeWikiSubscribers
    , subscribeTrustedViewer
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
    { trustedSessions : Dict String (Set String)
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
    let
        clientKey : String
        clientKey =
            Effect.Lamdera.clientIdToString clientId
    in
    Dict.update wikiSlug
        (\maybeWiki ->
            let
                wikiListeners : WikiPendingListeners
                wikiListeners =
                    Maybe.withDefault emptyWikiListeners maybeWiki

                nextTrusted : Dict String (Set String)
                nextTrusted =
                    Dict.update sessionKey
                        (\maybeSet ->
                            Just (Set.insert clientKey (Maybe.withDefault Set.empty maybeSet))
                        )
                        wikiListeners.trustedSessions
            in
            Just { trustedSessions = nextTrusted }
        )
        subs


evictSessionFromWikiListeners : Wiki.Slug -> String -> PendingReviewClientSets -> PendingReviewClientSets
evictSessionFromWikiListeners wikiSlug sessionKey subs =
    case Dict.get wikiSlug subs of
        Nothing ->
            subs

        Just wikiListeners ->
            let
                nextTrusted : Dict String (Set String)
                nextTrusted =
                    Dict.remove sessionKey wikiListeners.trustedSessions
            in
            if Dict.isEmpty nextTrusted then
                Dict.remove wikiSlug subs

            else
                Dict.insert wikiSlug { trustedSessions = nextTrusted } subs


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
    (Dict.get wikiSlug subs
        |> Maybe.map .trustedSessions
        |> Maybe.withDefault Dict.empty
    )
        |> Dict.foldl (always Set.union) Set.empty
        |> Set.toList
        |> List.map Effect.Lamdera.clientIdFromString


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

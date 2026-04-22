module PendingReviewCount exposing
    ( emptyCountMap
    , mergeIntoStoreWikiDetails
    , recallFromSubmissions
    , remapSlugInPendingCounts
    )

import Dict exposing (Dict)
import RemoteData exposing (RemoteData(..))
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

module WikiUser exposing
    ( SessionContributorOnWiki(..)
    , SessionTable
    , WikiBindings
    , bindContributor
    , contributorIdForWiki
    , dropBindingsForWiki
    , emptySessions
    , remapSessionsForWikiSlugRename
    , sessionContributorOnWiki
    , sessionKeysForContributorOnWiki
    , unbindContributor
    , unionSessionOverlayPreferred
    )

import ContributorAccount
import Dict exposing (Dict)
import Wiki


{-| Per Lamdera session: contributor account ids keyed by wiki slug (multiple wikis at once).
-}
type alias WikiBindings =
    Dict Wiki.Slug ContributorAccount.Id


type alias SessionTable =
    Dict String WikiBindings


{-| Resolve whether the client is logged into `wikiSlug` specifically.
-}
type SessionContributorOnWiki
    = SessionNotLoggedIn
    | SessionWrongWiki
    | SessionHasAccount ContributorAccount.Id


emptySessions : SessionTable
emptySessions =
    Dict.empty


bindContributor : String -> Wiki.Slug -> ContributorAccount.Id -> SessionTable -> SessionTable
bindContributor sessionKey wikiSlug accountId sessions =
    let
        inner : WikiBindings
        inner =
            sessions
                |> Dict.get sessionKey
                |> Maybe.withDefault Dict.empty
                |> Dict.insert wikiSlug accountId
    in
    Dict.insert sessionKey inner sessions


unbindContributor : String -> Wiki.Slug -> SessionTable -> SessionTable
unbindContributor sessionKey wikiSlug sessions =
    case Dict.get sessionKey sessions of
        Nothing ->
            sessions

        Just inner ->
            let
                nextInner : WikiBindings
                nextInner =
                    Dict.remove wikiSlug inner
            in
            if Dict.isEmpty nextInner then
                Dict.remove sessionKey sessions

            else
                Dict.insert sessionKey nextInner sessions


contributorIdForWiki : String -> Wiki.Slug -> SessionTable -> Maybe ContributorAccount.Id
contributorIdForWiki sessionKey wikiSlug sessions =
    sessions
        |> Dict.get sessionKey
        |> Maybe.andThen (Dict.get wikiSlug)


{-| Session keys whose Lamdera cookie is bound to `accountId` on `wikiSlug` (promotion/demotion cleanup).
-}
sessionKeysForContributorOnWiki : Wiki.Slug -> ContributorAccount.Id -> SessionTable -> List String
sessionKeysForContributorOnWiki wikiSlug accountId sessions =
    sessions
        |> Dict.foldr
            (\sessionKey inner acc ->
                case Dict.get wikiSlug inner of
                    Just aid ->
                        if aid == accountId then
                            sessionKey :: acc

                        else
                            acc

                    Nothing ->
                        acc
            )
            []


sessionContributorOnWiki : String -> Wiki.Slug -> SessionTable -> SessionContributorOnWiki
sessionContributorOnWiki sessionKey wikiSlug sessions =
    case Dict.get sessionKey sessions of
        Nothing ->
            SessionNotLoggedIn

        Just inner ->
            if Dict.isEmpty inner then
                SessionNotLoggedIn

            else
                case Dict.get wikiSlug inner of
                    Nothing ->
                        SessionWrongWiki

                    Just accountId ->
                        SessionHasAccount accountId


{-| Merge session tables: for each session key, inner maps are combined; `overlay` wins on the same wiki slug.
-}
unionSessionOverlayPreferred : SessionTable -> SessionTable -> SessionTable
unionSessionOverlayPreferred overlay base =
    Dict.foldl
        (\sessionKey overlayInner acc ->
            Dict.update sessionKey
                (\maybeBaseInner ->
                    overlayInner
                        |> Dict.union (maybeBaseInner |> Maybe.withDefault Dict.empty)
                        |> Just
                )
                acc
        )
        base
        overlay


{-| Remove sessions bound to a wiki (e.g. after the wiki is deleted).
-}
dropBindingsForWiki : Wiki.Slug -> SessionTable -> SessionTable
dropBindingsForWiki wikiSlug sessions =
    sessions
        |> Dict.toList
        |> List.map
            (\( sk, inner ) ->
                ( sk, Dict.remove wikiSlug inner )
            )
        |> List.filter (\( _, inner ) -> not (Dict.isEmpty inner))
        |> Dict.fromList


{-| Contributor sessions reference the wiki slug; keep them consistent after a rename.
-}
remapSessionsForWikiSlugRename : Wiki.Slug -> Wiki.Slug -> SessionTable -> SessionTable
remapSessionsForWikiSlugRename oldSlug newSlug sessions =
    Dict.map
        (\_ inner ->
            inner
                |> Dict.toList
                |> List.map
                    (\( slug, accId ) ->
                        if slug == oldSlug then
                            ( newSlug, ContributorAccount.remapIdForWikiSlug oldSlug newSlug accId )

                        else
                            ( slug, accId )
                    )
                |> Dict.fromList
        )
        sessions

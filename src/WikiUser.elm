module WikiUser exposing
    ( Binding(..)
    , SessionTable
    , bindContributor
    , contributorIdForWiki
    , dropBindingsForWiki
    , emptySessions
    , remapSessionsForWikiSlugRename
    )

import ContributorAccount
import Dict exposing (Dict)
import Wiki


{-| Session is logged into one wiki as one contributor account (MVP).
-}
type Binding
    = Binding Wiki.Slug ContributorAccount.Id


type alias SessionTable =
    Dict String Binding


emptySessions : SessionTable
emptySessions =
    Dict.empty


bindContributor : String -> Wiki.Slug -> ContributorAccount.Id -> SessionTable -> SessionTable
bindContributor sessionKey wikiSlug accountId =
    Dict.insert sessionKey (Binding wikiSlug accountId)


contributorIdForWiki : String -> Wiki.Slug -> SessionTable -> Maybe ContributorAccount.Id
contributorIdForWiki sessionKey wikiSlug sessions =
    case Dict.get sessionKey sessions of
        Nothing ->
            Nothing

        Just (Binding boundWiki accountId) ->
            if boundWiki == wikiSlug then
                Just accountId

            else
                Nothing


{-| Remove sessions bound to a wiki (e.g. after the wiki is deleted).
-}
dropBindingsForWiki : Wiki.Slug -> SessionTable -> SessionTable
dropBindingsForWiki wikiSlug sessions =
    Dict.filter
        (\_ binding ->
            case binding of
                Binding slug _ ->
                    slug /= wikiSlug
        )
        sessions


{-| Contributor sessions and account ids reference the wiki slug; keep them consistent after a rename.
-}
remapSessionsForWikiSlugRename : Wiki.Slug -> Wiki.Slug -> SessionTable -> SessionTable
remapSessionsForWikiSlugRename oldSlug newSlug sessions =
    Dict.map
        (\_ binding ->
            case binding of
                Binding slug accId ->
                    if slug == oldSlug then
                        Binding newSlug (ContributorAccount.remapIdForWikiSlug oldSlug newSlug accId)

                    else
                        binding
        )
        sessions

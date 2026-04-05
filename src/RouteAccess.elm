module RouteAccess exposing
    ( ContributorRouteRedirect(..)
    , contributorForcedRedirect
    , contributorRestrictedReturnPath
    )

import ContributorWikiSession exposing (ContributorWikiSession)
import Dict exposing (Dict)
import Route exposing (Route)
import SecureRedirect
import Url exposing (Url)
import Wiki
import WikiRole


{-| Client-side adjustment before rendering a contributor-gated wiki route.
-}
type ContributorRouteRedirect
    = ToContributorLogin Wiki.Slug String
    | AwayFromMySubmissions Wiki.Slug


{-| When anonymous (or logged in on another wiki), restricted wiki routes redirect to login with return path.
Logged-in contributors without sufficient role still reach the route so the server can respond with an error instead of a client-only redirect — except `WikiMySubmissions`, where trusted/admin are sent to wiki home.
-}
contributorForcedRedirect : Dict Wiki.Slug ContributorWikiSession -> Url -> Route -> Maybe ContributorRouteRedirect
contributorForcedRedirect sessions url route =
    let
        returnPath : String
        returnPath =
            SecureRedirect.pathAndQuery url

        loggedInHere : Wiki.Slug -> Bool
        loggedInHere wikiSlug =
            Dict.member wikiSlug sessions

        trustedHere : Wiki.Slug -> Bool
        trustedHere wikiSlug =
            sessions
                |> Dict.get wikiSlug
                |> Maybe.map (.role >> WikiRole.isTrustedModerator)
                |> Maybe.withDefault False

        adminHere : Wiki.Slug -> Bool
        adminHere wikiSlug =
            sessions
                |> Dict.get wikiSlug
                |> Maybe.map (.role >> WikiRole.canAccessWikiAdminUsers)
                |> Maybe.withDefault False

        mySubmissionsHere : Wiki.Slug -> Bool
        mySubmissionsHere wikiSlug =
            sessions
                |> Dict.get wikiSlug
                |> Maybe.map (.role >> WikiRole.hasMySubmissionsAccess)
                |> Maybe.withDefault False
    in
    case route of
        Route.WikiReview wikiSlug ->
            if trustedHere wikiSlug then
                Nothing

            else if loggedInHere wikiSlug then
                Nothing

            else
                Just (ToContributorLogin wikiSlug returnPath)

        Route.WikiReviewDetail wikiSlug _ ->
            if trustedHere wikiSlug then
                Nothing

            else if loggedInHere wikiSlug then
                Nothing

            else
                Just (ToContributorLogin wikiSlug returnPath)

        Route.WikiAdminUsers wikiSlug ->
            if adminHere wikiSlug then
                Nothing

            else if loggedInHere wikiSlug then
                Nothing

            else
                Just (ToContributorLogin wikiSlug returnPath)

        Route.WikiAdminAudit wikiSlug ->
            if adminHere wikiSlug then
                Nothing

            else if loggedInHere wikiSlug then
                Nothing

            else
                Just (ToContributorLogin wikiSlug returnPath)

        Route.WikiSubmitNew wikiSlug ->
            if loggedInHere wikiSlug then
                Nothing

            else
                Just (ToContributorLogin wikiSlug returnPath)

        Route.WikiSubmitEdit wikiSlug _ ->
            if loggedInHere wikiSlug then
                Nothing

            else
                Just (ToContributorLogin wikiSlug returnPath)

        Route.WikiSubmitDelete wikiSlug _ ->
            if loggedInHere wikiSlug then
                Nothing

            else
                Just (ToContributorLogin wikiSlug returnPath)

        Route.WikiSubmissionDetail wikiSlug _ ->
            if loggedInHere wikiSlug then
                Nothing

            else
                Just (ToContributorLogin wikiSlug returnPath)

        Route.WikiMySubmissions wikiSlug ->
            if mySubmissionsHere wikiSlug then
                Nothing

            else if loggedInHere wikiSlug then
                Just (AwayFromMySubmissions wikiSlug)

            else
                Just (ToContributorLogin wikiSlug returnPath)

        Route.WikiList ->
            Nothing

        Route.HostAdmin _ ->
            Nothing

        Route.HostAdminWikis ->
            Nothing

        Route.HostAdminWikiNew ->
            Nothing

        Route.HostAdminWikiDetail _ ->
            Nothing

        Route.HostAdminAudit ->
            Nothing

        Route.HostAdminBackup ->
            Nothing

        Route.WikiHome _ ->
            Nothing

        Route.WikiPage _ _ ->
            Nothing

        Route.WikiLogin _ _ ->
            Nothing

        Route.WikiRegister _ ->
            Nothing

        Route.NotFound _ ->
            Nothing


{-| Same routes as `contributorForcedRedirect` for anonymous clients, with a path-only return value (no query).
Used after logout to replace the URL with login + redirect when the user was on a contributor-only screen.
-}
contributorRestrictedReturnPath : Route -> Maybe ( Wiki.Slug, String )
contributorRestrictedReturnPath route =
    case route of
        Route.WikiReview wikiSlug ->
            Just ( wikiSlug, Wiki.reviewQueueUrlPath wikiSlug )

        Route.WikiReviewDetail wikiSlug submissionId ->
            Just ( wikiSlug, Wiki.reviewDetailUrlPath wikiSlug submissionId )

        Route.WikiAdminUsers wikiSlug ->
            Just ( wikiSlug, Wiki.adminUsersUrlPath wikiSlug )

        Route.WikiAdminAudit wikiSlug ->
            Just ( wikiSlug, Wiki.adminAuditUrlPath wikiSlug )

        Route.WikiSubmitNew wikiSlug ->
            Just ( wikiSlug, Wiki.submitNewPageUrlPath wikiSlug )

        Route.WikiSubmitEdit wikiSlug pageSlug ->
            Just ( wikiSlug, Wiki.submitEditUrlPath wikiSlug pageSlug )

        Route.WikiSubmitDelete wikiSlug pageSlug ->
            Just ( wikiSlug, Wiki.submitDeleteUrlPath wikiSlug pageSlug )

        Route.WikiSubmissionDetail wikiSlug submissionId ->
            Just ( wikiSlug, Wiki.submissionDetailUrlPath wikiSlug submissionId )

        Route.WikiMySubmissions wikiSlug ->
            Just ( wikiSlug, Wiki.mySubmissionsUrlPath wikiSlug )

        Route.WikiList ->
            Nothing

        Route.HostAdmin _ ->
            Nothing

        Route.HostAdminWikis ->
            Nothing

        Route.HostAdminWikiNew ->
            Nothing

        Route.HostAdminWikiDetail _ ->
            Nothing

        Route.HostAdminAudit ->
            Nothing

        Route.HostAdminBackup ->
            Nothing

        Route.WikiHome _ ->
            Nothing

        Route.WikiPage _ _ ->
            Nothing

        Route.WikiLogin _ _ ->
            Nothing

        Route.WikiRegister _ ->
            Nothing

        Route.NotFound _ ->
            Nothing

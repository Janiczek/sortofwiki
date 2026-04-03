module RouteAccessTest exposing (suite)

import Expect
import Route
import RouteAccess
import Test exposing (Test)
import Url
import Wiki
import WikiRole


anon : RouteAccess.ContributorSession
anon =
    { contributorWikiSession = Nothing
    , contributorWikiRole = Nothing
    }


contribDemo : RouteAccess.ContributorSession
contribDemo =
    { contributorWikiSession = Just "Demo"
    , contributorWikiRole = Just WikiRole.UntrustedContributor
    }


trustedDemo : RouteAccess.ContributorSession
trustedDemo =
    { contributorWikiSession = Just "Demo"
    , contributorWikiRole = Just WikiRole.TrustedContributor
    }


suite : Test
suite =
    Test.describe "RouteAccess"
        [ Test.describe "contributorForcedRedirect"
            [ Test.test "anonymous opening review is sent to login with return path" <|
                \() ->
                    case Url.fromString "https://example.com/w/Demo/review" of
                        Just u ->
                            RouteAccess.contributorForcedRedirect anon u (Route.WikiReview "Demo")
                                |> Expect.equal (Just ( "Demo", "/w/Demo/review" ))

                        Nothing ->
                            Expect.fail "url"
            , Test.test "trusted moderator is not redirected from review" <|
                \() ->
                    case Url.fromString "https://example.com/w/Demo/review" of
                        Just u ->
                            RouteAccess.contributorForcedRedirect trustedDemo u (Route.WikiReview "Demo")
                                |> Expect.equal Nothing

                        Nothing ->
                            Expect.fail "url"
            , Test.test "contributor stays on review route (server enforces)" <|
                \() ->
                    case Url.fromString "https://example.com/w/Demo/review" of
                        Just u ->
                            RouteAccess.contributorForcedRedirect contribDemo u (Route.WikiReview "Demo")
                                |> Expect.equal Nothing

                        Nothing ->
                            Expect.fail "url"
            , Test.test "anonymous opening submit/new redirects" <|
                \() ->
                    case Url.fromString "https://example.com/w/Demo/submit/new" of
                        Just u ->
                            RouteAccess.contributorForcedRedirect anon u (Route.WikiSubmitNew "Demo")
                                |> Expect.equal (Just ( "Demo", "/w/Demo/submit/new" ))

                        Nothing ->
                            Expect.fail "url"
            , Test.test "anonymous opening my submissions redirects with return path" <|
                \() ->
                    case Url.fromString "https://example.com/w/Demo/submissions" of
                        Just u ->
                            RouteAccess.contributorForcedRedirect anon u (Route.WikiMySubmissions "Demo")
                                |> Expect.equal (Just ( "Demo", Wiki.mySubmissionsUrlPath "Demo" ))

                        Nothing ->
                            Expect.fail "url"
            , Test.test "logged-in contributor is not redirected from my submissions" <|
                \() ->
                    case Url.fromString "https://example.com/w/Demo/submissions" of
                        Just u ->
                            RouteAccess.contributorForcedRedirect contribDemo u (Route.WikiMySubmissions "Demo")
                                |> Expect.equal Nothing

                        Nothing ->
                            Expect.fail "url"
            ]
        , Test.describe "contributorRestrictedReturnPath"
            [ Test.test "submit/new maps to submit path" <|
                \() ->
                    RouteAccess.contributorRestrictedReturnPath (Route.WikiSubmitNew "Demo")
                        |> Expect.equal (Just ( "Demo", Wiki.submitNewPageUrlPath "Demo" ))
            , Test.test "wiki home yields nothing" <|
                \() ->
                    RouteAccess.contributorRestrictedReturnPath (Route.WikiHome "Demo")
                        |> Expect.equal Nothing
            ]
        ]

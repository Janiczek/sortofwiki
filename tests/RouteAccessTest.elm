module RouteAccessTest exposing (suite)

import Expect
import Route
import RouteAccess
import Test exposing (Test)
import Url
import WikiRole


anon : RouteAccess.ContributorSession
anon =
    { contributorWikiSession = Nothing
    , contributorWikiRole = Nothing
    }


contribDemo : RouteAccess.ContributorSession
contribDemo =
    { contributorWikiSession = Just "demo"
    , contributorWikiRole = Just WikiRole.Contributor
    }


trustedDemo : RouteAccess.ContributorSession
trustedDemo =
    { contributorWikiSession = Just "demo"
    , contributorWikiRole = Just WikiRole.Trusted
    }


suite : Test
suite =
    Test.describe "RouteAccess"
        [ Test.describe "contributorForcedRedirect"
            [ Test.test "anonymous opening review is sent to login with return path" <|
                \() ->
                    case Url.fromString "https://example.com/w/demo/review" of
                        Just u ->
                            RouteAccess.contributorForcedRedirect anon u (Route.WikiReview "demo")
                                |> Expect.equal (Just ( "demo", "/w/demo/review" ))

                        Nothing ->
                            Expect.fail "url"
            , Test.test "trusted moderator is not redirected from review" <|
                \() ->
                    case Url.fromString "https://example.com/w/demo/review" of
                        Just u ->
                            RouteAccess.contributorForcedRedirect trustedDemo u (Route.WikiReview "demo")
                                |> Expect.equal Nothing

                        Nothing ->
                            Expect.fail "url"
            , Test.test "contributor stays on review route (server enforces)" <|
                \() ->
                    case Url.fromString "https://example.com/w/demo/review" of
                        Just u ->
                            RouteAccess.contributorForcedRedirect contribDemo u (Route.WikiReview "demo")
                                |> Expect.equal Nothing

                        Nothing ->
                            Expect.fail "url"
            , Test.test "anonymous opening submit/new redirects" <|
                \() ->
                    case Url.fromString "https://example.com/w/demo/submit/new" of
                        Just u ->
                            RouteAccess.contributorForcedRedirect anon u (Route.WikiSubmitNew "demo")
                                |> Expect.equal (Just ( "demo", "/w/demo/submit/new" ))

                        Nothing ->
                            Expect.fail "url"
            ]
        ]

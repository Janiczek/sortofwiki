module RouteAccessTest exposing (suite)

import ContributorWikiSession exposing (ContributorWikiSession)
import Dict
import Expect
import Route
import RouteAccess
import Test exposing (Test)
import Url
import Wiki
import WikiRole


anon : Dict.Dict Wiki.Slug ContributorWikiSession
anon =
    Dict.empty


contribDemo : Dict.Dict Wiki.Slug ContributorWikiSession
contribDemo =
    Dict.singleton "Demo"
        { role = WikiRole.UntrustedContributor
        , displayUsername = "u"
        }


trustedDemo : Dict.Dict Wiki.Slug ContributorWikiSession
trustedDemo =
    Dict.singleton "Demo"
        { role = WikiRole.TrustedContributor
        , displayUsername = "u"
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

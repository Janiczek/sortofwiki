module ProgramTest.Story47_FrontendRouteGuards exposing (endToEndTests)

import Dict
import Effect.Browser.Dom
import Env
import ProgramTest.Actions
import ProgramTest.Config
import ProgramTest.Model
import ProgramTest.Query
import ProgramTest.Start
import RemoteData
import Route
import Wiki


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.start
        { name = "47 — anonymous /review becomes login with redirect; no review queue fetch"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story47-anon-review"
        , path = "/w/Demo/review"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                [ client.checkModel 400
                    (\model ->
                        ProgramTest.Model.expectRoute (Route.WikiLogin "Demo" (Just "/w/Demo/review"))
                            "expected gated login route with redirect back to review"
                            model
                            |> Result.andThen
                                (\_ ->
                                    case Dict.get "Demo" model.store.reviewQueues of
                                        Nothing ->
                                            Ok ()

                                        Just _ ->
                                            Err "review queue should not be requested before login"
                                )
                    )
                , client.checkView 100
                    (ProgramTest.Query.expectWikiLoginPageShowsSlug "Demo")
                ]
        }
    , ProgramTest.Start.start
        { name = "47 — login with redirect lands on return path (review), not default wiki home"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story47-login-redirect"
        , path =
            Wiki.loginUrlPathWithRedirect "Demo" "/w/Demo/review"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                List.concat
                    [ ProgramTest.Actions.submitWikiLoginForm
                        { username = "trustedpub"
                        , password = "password12"
                        }
                        client
                    , [ client.checkModel 500
                            (ProgramTest.Model.expectRoute (Route.WikiReview "Demo")
                                "expected post-login URL to honor redirect=/w/Demo/review (WikiReview), not WikiHome"
                            )
                      , client.checkView 500
                            (ProgramTest.Query.withinId "wiki-review-queue-page"
                                (ProgramTest.Query.withinId "wiki-review-queue-empty"
                                    (ProgramTest.Query.expectHasText "No pending submissions.")
                                )
                            )
                      ]
                    ]
        }
    , ProgramTest.Start.start
        { name = "47 — anonymous /admin/wikis/new ends on host login with redirect"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story47-host-new"
        , path = "/admin/wikis/new"
        , connectClientMs = Just 200
        , clientSteps =
            \client ->
                [ client.checkModel 500
                    (ProgramTest.Model.expectRoute (Route.HostAdmin (Just "/admin/wikis/new"))
                        "expected host admin login route preserving return path"
                    )
                , client.checkView 100
                    (ProgramTest.Query.withinId "host-admin-login-password"
                        ProgramTest.Query.expectEmpty
                    )
                ]
        }
    , ProgramTest.Start.start
        { name = "47 — anonymous /admin/wikis/ElmTips ends on host login with redirect"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story47-host-wiki-detail-anon"
        , path = "/admin/wikis/ElmTips"
        , connectClientMs = Just 202
        , clientSteps =
            \client ->
                [ client.checkModel 500
                    (ProgramTest.Model.expectRoute (Route.HostAdmin (Just "/admin/wikis/ElmTips"))
                        "expected host admin login route preserving return path to wiki detail"
                    )
                , client.checkView 100
                    (ProgramTest.Query.withinId "host-admin-login-password"
                        ProgramTest.Query.expectEmpty
                    )
                ]
        }
    , ProgramTest.Start.startWith
        { name = "47 — host-authenticated cold open /admin/wikis/ElmTips loads detail (not NotAsked ellipsis)"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , steps =
            [ ProgramTest.Start.connectFrontend
                { sessionId = "session-story47-host-wiki-detail-auth"
                , path = "/admin"
                , connectClientMs = Just 203
                , steps =
                    \client ->
                        [ client.input 100 (Effect.Browser.Dom.id "host-admin-login-password") Env.hostAdminPassword
                        , client.click 100 (Effect.Browser.Dom.id "host-admin-login-submit")
                        , client.checkView 300
                            (ProgramTest.Query.withinId "host-admin-wikis-list"
                                ProgramTest.Query.expectEmpty
                            )
                        ]
                }
            , ProgramTest.Start.connectFrontend
                { sessionId = "session-story47-host-wiki-detail-auth"
                , path = "/admin/wikis/ElmTips"
                , connectClientMs = Just 204
                , steps =
                    \client ->
                        [ client.checkModel 500
                            (\model ->
                                case model.hostAdminWikiDetailDraft.load of
                                    RemoteData.NotAsked ->
                                        Err "detail load should not stay NotAsked after cold open (RequestHostWikiDetail must apply)"

                                    _ ->
                                        Ok ()
                            )
                        , client.checkView 400
                            (ProgramTest.Query.withinId "host-admin-wiki-detail-slug"
                                (ProgramTest.Query.expectHasInputValue "ElmTips")
                            )
                        ]
                }
            ]
        }
    ]

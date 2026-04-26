module BackendWikiFrontendSubscriptionTest exposing (suite)

import Backend
import ContributorAccount
import Dict
import Effect.Command as Command
import Effect.Lamdera
import Expect
import ProgramTest.Config
import Submission
import Test exposing (Test)
import Time
import Types exposing (ToBackend(..), ToFrontend(..))
import Wiki
import WikiFrontendSubscription
import WikiRole
import WikiUser


requestSessionKey : String
requestSessionKey =
    "wiki-details-request-session"


requestClientKey : String
requestClientKey =
    "wiki-details-request-client"


initialModel : Backend.Model
initialModel =
    Tuple.first Backend.app_.init


pagesFixture : Backend.Model
pagesFixture =
    ProgramTest.Config.replayInitStepsOntoModel ProgramTest.Config.demoWikiPagesSteps


withContributorSession : String -> ContributorAccount.Id -> String -> Backend.Model -> Backend.Model
withContributorSession wikiSlug accountId sessionKey model =
    { model
        | contributorSessions =
            WikiUser.bindContributor sessionKey wikiSlug accountId model.contributorSessions
    }


suite : Test
suite =
    Test.describe "BackendWikiFrontendSubscription"
        [ Test.describe "RequestWikiFrontendDetails"
            [ Test.test "tracks requester on target wiki and removes same client from old wiki listeners" <|
                \() ->
                    let
                        before : Backend.Model
                        before =
                            { initialModel
                                | wikiFrontendClients =
                                    WikiFrontendSubscription.emptyClientSets
                                        |> WikiFrontendSubscription.subscribeViewer
                                            "ElmTips"
                                            "old-session"
                                            (Effect.Lamdera.clientIdFromString requestClientKey)
                            }

                        ( after, _ ) =
                            Backend.updateFromFrontendWithTime
                                (Effect.Lamdera.sessionIdFromString requestSessionKey)
                                (Effect.Lamdera.clientIdFromString requestClientKey)
                                (RequestWikiFrontendDetails "Demo")
                                (Time.millisToPosix 0)
                                before
                    in
                    after.wikiFrontendClients
                        |> Expect.equal
                            (WikiFrontendSubscription.emptyClientSets
                                |> WikiFrontendSubscription.subscribeViewer
                                    "Demo"
                                    requestSessionKey
                                    (Effect.Lamdera.clientIdFromString requestClientKey)
                            )
            , Test.test "logged-in viewer gets same-session auth details in payload" <|
                \() ->
                    let
                        viewerSessionKey : String
                        viewerSessionKey =
                            "wiki-details-viewer-session"

                        viewerClient : Effect.Lamdera.ClientId
                        viewerClient =
                            Effect.Lamdera.clientIdFromString "wiki-details-viewer-client"

                        before : Backend.Model
                        before =
                            pagesFixture
                                |> withContributorSession
                                    "Demo"
                                    (ContributorAccount.newAccountId "Demo" "demo_trusted_publisher")
                                    viewerSessionKey

                        ( _, cmd ) =
                            Backend.updateFromFrontendWithTime
                                (Effect.Lamdera.sessionIdFromString viewerSessionKey)
                                viewerClient
                                (RequestWikiFrontendDetails "Demo")
                                (Time.millisToPosix 0)
                                before

                        expectedPayload : Maybe Wiki.FrontendDetails
                        expectedPayload =
                            Dict.get "Demo" before.wikis
                                |> Maybe.map
                                    (\wiki ->
                                        Wiki.frontendDetailsForViewer wiki
                                            (Just
                                                { role = WikiRole.TrustedContributor
                                                , displayUsername = "demo_trusted_publisher"
                                                }
                                            )
                                            (Just 0)
                                    )
                    in
                    cmd
                        |> Expect.equal
                            (Effect.Lamdera.sendToFrontend viewerClient
                                (WikiFrontendDetailsResponse "Demo" expectedPayload)
                            )
            ]
        , Test.describe "broadcastWikiFrontendDetails"
            [ Test.test "trusted immediate page edit sends wiki details only to listening clients for that wiki" <|
                \() ->
                    let
                        trustedEditorSession : String
                        trustedEditorSession =
                            "trusted-editor-session"

                        trustedEditorClient : Effect.Lamdera.ClientId
                        trustedEditorClient =
                            Effect.Lamdera.clientIdFromString "trusted-editor-client"

                        demoListenerClient : Effect.Lamdera.ClientId
                        demoListenerClient =
                            Effect.Lamdera.clientIdFromString "demo-listener-client"

                        otherWikiListenerClient : Effect.Lamdera.ClientId
                        otherWikiListenerClient =
                            Effect.Lamdera.clientIdFromString "other-listener-client"

                        before : Backend.Model
                        before =
                            pagesFixture
                                |> withContributorSession
                                    "Demo"
                                    (ContributorAccount.newAccountId "Demo" "demo_trusted_publisher")
                                    trustedEditorSession
                                |> (\model ->
                                        { model
                                            | wikiFrontendClients =
                                                WikiFrontendSubscription.emptyClientSets
                                                    |> WikiFrontendSubscription.subscribeViewer
                                                        "Demo"
                                                        "demo-listener-session"
                                                        demoListenerClient
                                                    |> WikiFrontendSubscription.subscribeViewer
                                                        "ElmTips"
                                                        "other-listener-session"
                                                        otherWikiListenerClient
                                        }
                                   )

                        ( after, cmd ) =
                            Backend.updateFromFrontendWithTime
                                (Effect.Lamdera.sessionIdFromString trustedEditorSession)
                                trustedEditorClient
                                (SubmitPageEdit "Demo" "Home" "## Updated Home" "")
                                (Time.millisToPosix 0)
                                before

                        demoPayload : Maybe Wiki.FrontendDetails
                        demoPayload =
                            Dict.get "Demo" after.wikis
                                |> Maybe.map (\wiki -> Wiki.frontendDetailsForViewer wiki Nothing Nothing)
                    in
                    cmd
                        |> Expect.equal
                            (Command.batch
                                [ Effect.Lamdera.sendToFrontend trustedEditorClient
                                    (SubmitPageEditResponse "Demo" (Ok Submission.EditPublishedImmediately))
                                , Command.batch
                                    [ Command.batch
                                        [ Effect.Lamdera.sendToFrontend demoListenerClient
                                            (WikiFrontendDetailsResponse "Demo" demoPayload)
                                        ]
                                    ]
                                ]
                            )
            ]
        , Test.describe "LogoutContributor"
            [ Test.test "refreshes only clients listening to each wiki after session role changes" <|
                \() ->
                    let
                        logoutSessionKey : String
                        logoutSessionKey =
                            "logout-session"

                        logoutClient : Effect.Lamdera.ClientId
                        logoutClient =
                            Effect.Lamdera.clientIdFromString "logout-client"

                        demoListenerClient : Effect.Lamdera.ClientId
                        demoListenerClient =
                            Effect.Lamdera.clientIdFromString "logout-demo-listener-client"

                        elmTipsListenerClient : Effect.Lamdera.ClientId
                        elmTipsListenerClient =
                            Effect.Lamdera.clientIdFromString "logout-elmtips-listener-client"

                        before : Backend.Model
                        before =
                            pagesFixture
                                |> withContributorSession
                                    "Demo"
                                    (ContributorAccount.newAccountId "Demo" "demo_contributor")
                                    logoutSessionKey
                                |> (\model ->
                                        { model
                                            | wikiFrontendClients =
                                                WikiFrontendSubscription.emptyClientSets
                                                    |> WikiFrontendSubscription.subscribeViewer
                                                        "Demo"
                                                        logoutSessionKey
                                                        demoListenerClient
                                                    |> WikiFrontendSubscription.subscribeViewer
                                                        "ElmTips"
                                                        logoutSessionKey
                                                        elmTipsListenerClient
                                        }
                                   )

                        ( after, cmd ) =
                            Backend.updateFromFrontendWithTime
                                (Effect.Lamdera.sessionIdFromString logoutSessionKey)
                                logoutClient
                                (LogoutContributor "Demo")
                                (Time.millisToPosix 0)
                                before

                        demoPayload : Maybe Wiki.FrontendDetails
                        demoPayload =
                            Dict.get "Demo" after.wikis
                                |> Maybe.map (\wiki -> Wiki.frontendDetailsForViewer wiki Nothing Nothing)

                        elmTipsPayload : Maybe Wiki.FrontendDetails
                        elmTipsPayload =
                            Dict.get "ElmTips" after.wikis
                                |> Maybe.map (\wiki -> Wiki.frontendDetailsForViewer wiki Nothing Nothing)
                    in
                    cmd
                        |> Expect.equal
                            (Command.batch
                                [ Effect.Lamdera.sendToFrontend logoutClient (LogoutContributorResponse "Demo")
                                , Command.batch
                                    [ Command.batch
                                        [ Command.batch
                                            [ Effect.Lamdera.sendToFrontend demoListenerClient
                                                (WikiFrontendDetailsResponse "Demo" demoPayload)
                                            ]
                                        ]
                                    , Command.batch
                                        [ Command.batch
                                            [ Effect.Lamdera.sendToFrontend elmTipsListenerClient
                                                (WikiFrontendDetailsResponse "ElmTips" elmTipsPayload)
                                            ]
                                        ]
                                    ]
                                ]
                            )
            ]
        ]

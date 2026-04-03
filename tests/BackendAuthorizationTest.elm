module BackendAuthorizationTest exposing (suite)

import Backend
import ContributorAccount
import Dict
import Effect.Lamdera
import Expect
import ProgramTest.Config
import Test exposing (Test)
import Time
import Types exposing (ToBackend(..))
import WikiAuditLog
import WikiUser


sessionKey : String
sessionKey =
    "backend-authz-test-session"


clientKey : String
clientKey =
    "backend-authz-test-client"


initialModel : Backend.Model
initialModel =
    Tuple.first Backend.app_.init


pagesFixture : Backend.Model
pagesFixture =
    ProgramTest.Config.replayInitStepsOntoModel ProgramTest.Config.demoWikiPagesSteps


moderationFixture : Backend.Model
moderationFixture =
    ProgramTest.Config.replayInitStepsOntoModel ProgramTest.Config.demoWikiModerationSteps


withContributorSession : WikiUser.Binding -> Backend.Model -> Backend.Model
withContributorSession binding model =
    { model
        | contributorSessions =
            Dict.insert sessionKey binding model.contributorSessions
    }


statusdemoOnDemo : Backend.Model
statusdemoOnDemo =
    withContributorSession
        (WikiUser.Binding "Demo" (ContributorAccount.newAccountId "Demo" "statusdemo"))
        pagesFixture


trustedpubOnDemo : Backend.Model
trustedpubOnDemo =
    withContributorSession
        (WikiUser.Binding "Demo" (ContributorAccount.newAccountId "Demo" "trustedpub"))
        pagesFixture


statusdemoOnDemoModeration : Backend.Model
statusdemoOnDemoModeration =
    withContributorSession
        (WikiUser.Binding "Demo" (ContributorAccount.newAccountId "Demo" "statusdemo"))
        moderationFixture


trustedpubOnDemoModeration : Backend.Model
trustedpubOnDemoModeration =
    withContributorSession
        (WikiUser.Binding "Demo" (ContributorAccount.newAccountId "Demo" "trustedpub"))
        moderationFixture


{-| Demo wiki `active = False` (hosted wiki deactivated); contributor sessions unchanged.
-}
withDemoWikiInactive : Backend.Model -> Backend.Model
withDemoWikiInactive model =
    case Dict.get "Demo" model.wikis of
        Nothing ->
            model

        Just w ->
            { model | wikis = Dict.insert "Demo" { w | active = False } model.wikis }


expectUnchanged : Backend.Model -> ToBackend -> Expect.Expectation
expectUnchanged before msg =
    let
        ( after, _ ) =
            Backend.updateFromFrontendWithTime
                (Effect.Lamdera.sessionIdFromString sessionKey)
                (Effect.Lamdera.clientIdFromString clientKey)
                msg
                (Time.millisToPosix 0)
                before
    in
    after
        |> Expect.equal before


suite : Test
suite =
    Test.describe "Backend authorization (story 33)"
        [ Test.describe "updateFromFrontend"
            [ Test.describe "no contributor session leaves model unchanged on protected messages"
                (List.map
                    (\( label, msg ) ->
                        Test.test label <|
                            \() ->
                                expectUnchanged initialModel msg
                    )
                    [ ( "RequestMyPendingSubmissions", RequestMyPendingSubmissions "Demo" )
                    , ( "RequestReviewQueue", RequestReviewQueue "Demo" )
                    , ( "RequestReviewSubmissionDetail", RequestReviewSubmissionDetail "Demo" "sub_1" )
                    , ( "RequestWikiUsers", RequestWikiUsers "Demo" )
                    , ( "RequestWikiAuditLog", RequestWikiAuditLog "Demo" WikiAuditLog.emptyAuditLogFilter )
                    , ( "PromoteContributorToTrusted", PromoteContributorToTrusted "Demo" "x" )
                    , ( "DemoteTrustedToContributor", DemoteTrustedToContributor "Demo" "x" )
                    , ( "GrantWikiAdmin", GrantWikiAdmin "Demo" "x" )
                    , ( "RevokeWikiAdmin", RevokeWikiAdmin "Demo" "x" )
                    , ( "RequestSubmissionDetails", RequestSubmissionDetails "Demo" "sub_1" )
                    , ( "SubmitNewPage", SubmitNewPage "Demo" { rawPageSlug = "NewPage", rawMarkdown = "## Body" } )
                    , ( "SubmitPageEdit", SubmitPageEdit "Demo" "Home" "## Edit" )
                    , ( "SubmitPageDelete", SubmitPageDelete "Demo" "Home" "reason" )
                    , ( "ApproveSubmission", ApproveSubmission "Demo" "sub_1" )
                    , ( "RejectSubmission", RejectSubmission "Demo" { submissionId = "sub_1", reasonText = "no" } )
                    , ( "RequestSubmissionChanges", RequestSubmissionChanges "Demo" { submissionId = "sub_1", guidanceText = "fix it" } )
                    , ( "HostAdminLogin wrong password", HostAdminLogin "not-the-host-password" )
                    , ( "RequestHostWikiList", RequestHostWikiList )
                    , ( "RequestHostAuditLog", RequestHostAuditLog WikiAuditLog.emptyHostAuditLogFilter )
                    , ( "RequestHostWikiDetail", RequestHostWikiDetail "Demo" )
                    , ( "CreateHostedWiki"
                      , CreateHostedWiki
                            { rawSlug = "Newwiki"
                            , rawName = "Name"
                            , initialAdminUsername = "wikiadmin"
                            , initialAdminPassword = "password12"
                            }
                      )
                    , ( "UpdateHostedWikiMetadata"
                      , UpdateHostedWikiMetadata "Demo" { rawName = "N", rawSummary = "S", rawSlugDraft = "Demo" }
                      )
                    , ( "DeactivateHostedWiki", DeactivateHostedWiki "Demo" )
                    , ( "ReactivateHostedWiki", ReactivateHostedWiki "Demo" )
                    , ( "DeleteHostedWiki", DeleteHostedWiki "Demo" "wrong" )
                    , ( "RequestHostAdminDataExport", RequestHostAdminDataExport )
                    , ( "ImportHostAdminDataSnapshot", ImportHostAdminDataSnapshot "{}" )
                    , ( "RequestHostAdminWikiDataExport", RequestHostAdminWikiDataExport "Demo" )
                    , ( "ImportHostAdminWikiDataSnapshot", ImportHostAdminWikiDataSnapshot "Demo" "{}" )
                    ]
                )
            , Test.describe "standard contributor on demo"
                [ Test.test "RequestReviewQueue returns forbidden without changing model" <|
                    \() ->
                        expectUnchanged statusdemoOnDemoModeration (RequestReviewQueue "Demo")
                , Test.test "RequestReviewSubmissionDetail returns forbidden without changing model" <|
                    \() ->
                        expectUnchanged statusdemoOnDemoModeration (RequestReviewSubmissionDetail "Demo" "sub_1")
                , Test.test "RequestWikiUsers returns forbidden without changing model" <|
                    \() ->
                        expectUnchanged statusdemoOnDemo (RequestWikiUsers "Demo")
                , Test.test "RequestWikiAuditLog returns forbidden without changing model" <|
                    \() ->
                        expectUnchanged statusdemoOnDemo (RequestWikiAuditLog "Demo" WikiAuditLog.emptyAuditLogFilter)
                , Test.test "RequestHostAuditLog leaves model unchanged without host session" <|
                    \() ->
                        expectUnchanged statusdemoOnDemo (RequestHostAuditLog WikiAuditLog.emptyHostAuditLogFilter)
                , Test.test "ApproveSubmission returns forbidden without changing model" <|
                    \() ->
                        expectUnchanged statusdemoOnDemoModeration (ApproveSubmission "Demo" "sub_1")
                , Test.test "RejectSubmission returns forbidden without changing model" <|
                    \() ->
                        expectUnchanged statusdemoOnDemoModeration (RejectSubmission "Demo" { submissionId = "sub_1", reasonText = "no" })
                , Test.test "RequestSubmissionChanges returns forbidden without changing model" <|
                    \() ->
                        expectUnchanged statusdemoOnDemoModeration (RequestSubmissionChanges "Demo" { submissionId = "sub_1", guidanceText = "note" })
                , Test.test "PromoteContributorToTrusted returns forbidden without changing model" <|
                    \() ->
                        expectUnchanged statusdemoOnDemo (PromoteContributorToTrusted "Demo" "statusdemo")
                ]
            , Test.describe "trusted but not wiki admin"
                [ Test.test "RequestWikiUsers returns forbidden without changing model" <|
                    \() ->
                        expectUnchanged trustedpubOnDemo (RequestWikiUsers "Demo")
                ]
            , Test.describe "session wiki does not match payload wiki"
                [ Test.test "SubmitNewPage to other wiki returns wrong session without changing model" <|
                    \() ->
                        expectUnchanged statusdemoOnDemo (SubmitNewPage "ElmTips" { rawPageSlug = "P", rawMarkdown = "## x" })
                , Test.test "RequestReviewQueue for other wiki returns wrong session without changing model" <|
                    \() ->
                        expectUnchanged statusdemoOnDemo (RequestReviewQueue "ElmTips")
                , Test.test "RequestMyPendingSubmissions for other wiki returns wrong session without changing model" <|
                    \() ->
                        expectUnchanged statusdemoOnDemo (RequestMyPendingSubmissions "ElmTips")
                ]
            , Test.describe "inactive demo wiki (deactivated tenant)"
                [ Test.test "trusted RequestReviewQueue leaves model unchanged" <|
                    \() ->
                        trustedpubOnDemoModeration
                            |> withDemoWikiInactive
                            |> (\m -> expectUnchanged m (RequestReviewQueue "Demo"))
                , Test.test "contributor SubmitNewPage leaves model unchanged" <|
                    \() ->
                        statusdemoOnDemo
                            |> withDemoWikiInactive
                            |> (\m -> expectUnchanged m (SubmitNewPage "Demo" { rawPageSlug = "NewPage", rawMarkdown = "## Body" }))
                , Test.test "trusted ApproveSubmission leaves model unchanged" <|
                    \() ->
                        trustedpubOnDemoModeration
                            |> withDemoWikiInactive
                            |> (\m -> expectUnchanged m (ApproveSubmission "Demo" "sub_1"))
                , Test.test "contributor RequestMyPendingSubmissions leaves model unchanged" <|
                    \() ->
                        statusdemoOnDemo
                            |> withDemoWikiInactive
                            |> (\m -> expectUnchanged m (RequestMyPendingSubmissions "Demo"))
                ]
            , Test.describe "logout"
                [ Test.test "LogoutContributor with no session leaves contributorSessions empty" <|
                    \() ->
                        expectUnchanged initialModel LogoutContributor
                , Test.test "LogoutContributor clears bound contributor session" <|
                    \() ->
                        let
                            ( after, _ ) =
                                Backend.updateFromFrontendWithTime
                                    (Effect.Lamdera.sessionIdFromString sessionKey)
                                    (Effect.Lamdera.clientIdFromString clientKey)
                                    LogoutContributor
                                    (Time.millisToPosix 0)
                                    statusdemoOnDemo
                        in
                        after.contributorSessions
                            |> Dict.get sessionKey
                            |> Expect.equal Nothing
                ]
            ]
        ]

module ProgramTest.Story61_AuditDiffByMillis exposing (endToEndTests, kitchenSinkTrustedPublishAuditAtMillis)

import Dict
import ProgramTest.Actions
import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Time
import Wiki
import WikiAuditLog


{-| Deterministic millis for `TrustedPublishedNewPage` KitchenSink in `demoWikiPagesSteps` init replay.
If `demoWikiPagesSeedSteps` ordering changes, update together with `tests/WikiAuditLogTest` guard test.
-}
kitchenSinkTrustedPublishAuditAtMillis : Int
kitchenSinkTrustedPublishAuditAtMillis =
    ProgramTest.Config.replayInitStepsOntoModel ProgramTest.Config.demoWikiPagesSteps
        |> .wikiAuditEvents
        |> Dict.get "Demo"
        |> Maybe.withDefault []
        |> List.filterMap kitchenSinkMillisIfTrustedNew
        |> List.reverse
        |> List.head
        |> Maybe.withDefault -1


kitchenSinkMillisIfTrustedNew : WikiAuditLog.AuditEvent -> Maybe Int
kitchenSinkMillisIfTrustedNew e =
    case e.kind of
        WikiAuditLog.ApprovedSubmission _ ->
            Nothing

        WikiAuditLog.ApprovedPublishedNewPage _ ->
            Nothing

        WikiAuditLog.ApprovedPublishedPageEdit _ ->
            Nothing

        WikiAuditLog.ApprovedPublishedPageDelete _ ->
            Nothing

        WikiAuditLog.RejectedSubmission _ ->
            Nothing

        WikiAuditLog.RequestedSubmissionChanges _ ->
            Nothing

        WikiAuditLog.PromotedContributorToTrusted _ ->
            Nothing

        WikiAuditLog.DemotedTrustedToContributor _ ->
            Nothing

        WikiAuditLog.GrantedWikiAdmin _ ->
            Nothing

        WikiAuditLog.RevokedWikiAdmin _ ->
            Nothing

        WikiAuditLog.TrustedPublishedNewPage r ->
            if r.pageSlug == "KitchenSink" then
                Just (Time.posixToMillis e.at)

            else
                Nothing

        WikiAuditLog.TrustedPublishedPageEdit _ ->
            Nothing

        WikiAuditLog.TrustedPublishedPageDelete _ ->
            Nothing


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    ProgramTest.Start.bothViewports
        { baseName = "61 — wiki admin audit diff URL uses stable event millis"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story61-audit-diff-millis"
        , path = "/"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                List.concat
                    [ ProgramTest.Actions.loginToWiki
                        { wikiSlug = "Demo"
                        , username = "demo_wiki_admin"
                        , password = "password12"
                        }
                        client
                    , client.checkView 300
                        (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                        :: ProgramTest.Actions.navigateToPath (Wiki.adminAuditDiffUrlPath "Demo" kitchenSinkTrustedPublishAuditAtMillis) client
                        ++ [ client.checkView 600
                                (ProgramTest.Query.withinId "wiki-admin-audit-diff-page"
                                    (ProgramTest.Query.withinId "wiki-review-diff-new-preview"
                                        (ProgramTest.Query.expectHasText "Kitchen sink")
                                    )
                                )
                           ]
                    ]
        }

module ProgramTest.Viewer exposing (main)

import Backend
import Effect.Test
import Frontend
import ProgramTest.Story01_WikiList as Story01
import ProgramTest.Story02_WikiHome as Story02
import ProgramTest.Story04_PublishedPage as Story04
import ProgramTest.Story05_Backlinks as Story05
import ProgramTest.Story06_OnlyPublished as Story06
import ProgramTest.Story07_Register as Story07
import ProgramTest.Story08_Login as Story08
import ProgramTest.Story09_NewPageSubmission as Story09
import ProgramTest.Story10_PageEditSubmission as Story10
import ProgramTest.Story11_PageDeleteSubmission as Story11
import ProgramTest.Story12_SubmissionStatus as Story12
import ProgramTest.Story13_ReviewerNotes as Story13
import ProgramTest.Story14_TrustedDirectPublish as Story14
import ProgramTest.Story15_ReviewQueue as Story15
import ProgramTest.Story16_ReviewSubmissionDiff as Story16
import ProgramTest.Story17_ApproveSubmission as Story17
import ProgramTest.Story18_RejectSubmission as Story18
import ProgramTest.Story19_RequestChanges as Story19
import ProgramTest.Story20_AdminUsers as Story20
import ProgramTest.Story21_PromoteTrusted as Story21
import ProgramTest.Story22_DemoteTrusted as Story22
import ProgramTest.Story23_GrantWikiAdmin as Story23
import ProgramTest.Story24_RevokeWikiAdmin as Story24
import ProgramTest.Story25_AuditLog as Story25
import ProgramTest.Story26_AuditLogFilters as Story26
import ProgramTest.Story27_HostAdminLogin as Story27
import ProgramTest.Story28_HostWikiList as Story28
import ProgramTest.Story29_CreateHostedWiki as Story29
import ProgramTest.Story30_EditHostedWikiMetadata as Story30
import ProgramTest.Story31_DeactivateHostedWiki as Story31
import ProgramTest.Story32_DeleteHostedWiki as Story32
import ProgramTest.Story33_BackendAuthorization as Story33
import ProgramTest.Story34_ModerationAuditTrail as Story34
import ProgramTest.Story35_NotFound as Story35
import ProgramTest.Story46_WikiLinksInMarkdown as Story46
import ProgramTest.Story47_FrontendRouteGuards as Story47
import ProgramTest.Story48_ConcurrentEditConflicts as Story48
import ProgramTest.Story49_MissingPageNavAndWikiLinks as Story49
import ProgramTest.Story50_MySubmissionsList as Story50
import ProgramTest.Story51_HostAdminAuditLog as Story51
import ProgramTest.Story52_HostAdminWikiBackup as Story52
import ProgramTest.Story53_MultiWikiContributorSessions as Story53
import ProgramTest.Story54_MySubmissionsRoleGate as Story54
import ProgramTest.Story55_MarkdownKitchenSink as Story55
import ProgramTest.Story56_TodosPage as Story56
import ProgramTest.Story57_WikiGraphPage as Story57
import ProgramTest.Story58_WikiSearch as Story58
import ProgramTest.Story59_SubmissionDetailTrustedRedirect as Story59
import Types exposing (ToBackend, ToFrontend)


main :
    Program
        ()
        (Effect.Test.Model ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
        (Effect.Test.Msg ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
main =
    [ Story01.endToEndTests
    , Story02.endToEndTests
    , Story04.endToEndTests
    , Story05.endToEndTests
    , Story06.endToEndTests
    , Story07.endToEndTests
    , Story08.endToEndTests
    , Story09.endToEndTests
    , Story10.endToEndTests
    , Story11.endToEndTests
    , Story12.endToEndTests
    , Story13.endToEndTests
    , Story14.endToEndTests
    , Story15.endToEndTests
    , Story16.endToEndTests
    , Story17.endToEndTests
    , Story18.endToEndTests
    , Story19.endToEndTests
    , Story20.endToEndTests
    , Story21.endToEndTests
    , Story22.endToEndTests
    , Story23.endToEndTests
    , Story24.endToEndTests
    , Story25.endToEndTests
    , Story26.endToEndTests
    , Story27.endToEndTests
    , Story28.endToEndTests
    , Story29.endToEndTests
    , Story30.endToEndTests
    , Story31.endToEndTests
    , Story32.endToEndTests
    , Story33.endToEndTests
    , Story34.endToEndTests
    , Story35.endToEndTests
    , Story46.endToEndTests
    , Story47.endToEndTests
    , Story48.endToEndTests
    , Story49.endToEndTests
    , Story50.endToEndTests
    , Story51.endToEndTests
    , Story52.endToEndTests
    , Story53.endToEndTests
    , Story54.endToEndTests
    , Story55.endToEndTests
    , Story56.endToEndTests
    , Story57.endToEndTests
    , Story58.endToEndTests
    , Story59.endToEndTests
    ]
        |> List.concat
        |> Effect.Test.viewer

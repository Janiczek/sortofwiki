module Evergreen.V14.Types exposing (..)

import Dict
import Effect.Browser
import Effect.Browser.Navigation
import Effect.File
import Effect.Lamdera
import Evergreen.V14.ColorTheme
import Evergreen.V14.ContributorAccount
import Evergreen.V14.ContributorWikiSession
import Evergreen.V14.HostAdmin
import Evergreen.V14.Page
import Evergreen.V14.PendingReviewCount
import Evergreen.V14.Route
import Evergreen.V14.Store
import Evergreen.V14.Submission
import Evergreen.V14.SubmissionReviewDetail
import Evergreen.V14.Wiki
import Evergreen.V14.WikiAdminUsers
import Evergreen.V14.WikiAuditLog
import Evergreen.V14.WikiContributors
import Evergreen.V14.WikiFrontendSubscription
import Evergreen.V14.WikiMarkdownEditorPane
import Evergreen.V14.WikiRole
import Evergreen.V14.WikiUser
import RemoteData
import Set
import Time
import Url


type alias RegisterDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V14.ContributorAccount.RegisterContributorError ())
    }


type alias LoginDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V14.ContributorAccount.LoginContributorError ())
    }


type alias NewPageSubmitDraft =
    { pageSlug : String
    , pageSlugLockedFromQuery : Bool
    , markdownBody : String
    , tagsInput : String
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V14.Submission.SubmitNewPageError Evergreen.V14.Submission.NewPageSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V14.Submission.SaveNewPageDraftError Evergreen.V14.Submission.Id)
    }


type alias PageEditSubmitDraft =
    { markdownBody : String
    , tagsInput : String
    , publishedRowCollapsed : Bool
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V14.Submission.SubmitPageEditError Evergreen.V14.Submission.EditSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V14.Submission.SavePageEditDraftError Evergreen.V14.Submission.Id)
    }


type alias PageDeleteSubmitDraft =
    { reasonText : String
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V14.Submission.PageDeleteFormError Evergreen.V14.Submission.PageDeleteFormSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V14.Submission.SavePageDeleteDraftError Evergreen.V14.Submission.Id)
    }


type alias ReviewApproveDraft =
    { inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V14.Submission.ApproveSubmissionError ())
    }


type ReviewDecision
    = ReviewDecisionApprove
    | ReviewDecisionRequestChanges
    | ReviewDecisionReject


type alias ReviewRejectDraft =
    { reasonText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V14.Submission.RejectSubmissionError ())
    }


type alias ReviewRequestChangesDraft =
    { guidanceText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V14.Submission.RequestChangesSubmissionError ())
    }


type alias SubmissionDetailEditDraft =
    { markdownBody : String
    , newPageSlug : String
    , saveDraftInFlight : Bool
    , submitForReviewInFlight : Bool
    , withdrawInFlight : Bool
    , deleteInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastError : Maybe String
    }


type alias HostAdminLoginDraft =
    { password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V14.HostAdmin.LoginError ())
    }


type alias HostAdminCreateWikiDraft =
    { slug : String
    , name : String
    , initialAdminUsername : String
    , initialAdminPassword : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V14.HostAdmin.CreateHostedWikiError Evergreen.V14.Wiki.CatalogEntry)
    }


type alias HostAdminWikiDetailDraft =
    { wikiSlug : Evergreen.V14.Wiki.Slug
    , load : RemoteData.RemoteData () (Result Evergreen.V14.HostAdmin.HostWikiDetailError Evergreen.V14.Wiki.CatalogEntry)
    , slugDraft : String
    , nameDraft : String
    , summaryDraft : String
    , saveInFlight : Bool
    , lastSaveResult : Maybe (Result Evergreen.V14.HostAdmin.UpdateHostedWikiMetadataError ())
    , lifecycleInFlight : Bool
    , lastLifecycleResult : Maybe (Result Evergreen.V14.HostAdmin.WikiLifecycleError ())
    , deleteConfirmDraft : String
    , deleteInFlight : Bool
    , lastDeleteResult : Maybe (Result Evergreen.V14.HostAdmin.DeleteHostedWikiError ())
    }


type alias FrontendModel =
    { key : Effect.Browser.Navigation.Key
    , colorThemePreference : Evergreen.V14.ColorTheme.ColorThemePreference
    , systemColorTheme : Evergreen.V14.ColorTheme.ColorTheme
    , route : Evergreen.V14.Route.Route
    , navigationFragment : Maybe String
    , store : Evergreen.V14.Store.Store
    , contributorWikiSessions : Dict.Dict Evergreen.V14.Wiki.Slug Evergreen.V14.ContributorWikiSession.ContributorWikiSession
    , registerDraft : RegisterDraft
    , loginDraft : LoginDraft
    , headerSearchQuery : String
    , wikiSearchPageQuery : String
    , newPageSubmitDraft : NewPageSubmitDraft
    , pageEditSubmitDraft : PageEditSubmitDraft
    , pageDeleteSubmitDraft : PageDeleteSubmitDraft
    , reviewApproveDraft : ReviewApproveDraft
    , reviewDecision : ReviewDecision
    , reviewRejectDraft : ReviewRejectDraft
    , reviewRequestChangesDraft : ReviewRequestChangesDraft
    , submissionDetailEditDraft : SubmissionDetailEditDraft
    , adminPromoteError : Maybe String
    , adminDemoteError : Maybe String
    , adminGrantAdminError : Maybe String
    , adminRevokeAdminError : Maybe String
    , wikiAdminAuditFilterActorDraft : String
    , wikiAdminAuditFilterPageDraft : String
    , wikiAdminAuditFilterSelectedKindTags : List Evergreen.V14.WikiAuditLog.AuditEventKindFilterTag
    , wikiAdminAuditAppliedFilter : Evergreen.V14.WikiAuditLog.AuditLogFilter
    , hostAdminAuditFilterWikiDraft : String
    , hostAdminAuditFilterActorDraft : String
    , hostAdminAuditFilterPageDraft : String
    , hostAdminAuditFilterSelectedKindTags : List Evergreen.V14.WikiAuditLog.AuditEventKindFilterTag
    , hostAdminAuditAppliedFilter : Evergreen.V14.WikiAuditLog.HostAuditLogFilter
    , hostAdminAuditLog : RemoteData.RemoteData () (Result Evergreen.V14.HostAdmin.ProtectedError (List Evergreen.V14.WikiAuditLog.ScopedAuditEvent))
    , hostAdminLoginDraft : HostAdminLoginDraft
    , hostAdminCreateWikiDraft : HostAdminCreateWikiDraft
    , hostAdminWikiDetailDraft : HostAdminWikiDetailDraft
    , hostAdminWikis : RemoteData.RemoteData () (Result Evergreen.V14.HostAdmin.ProtectedError (List Evergreen.V14.Wiki.CatalogEntry))
    , hostAdminSessionAuthenticated : Bool
    , hostAdminExportInFlight : Bool
    , hostAdminImportInFlight : Bool
    , hostAdminBackupNotice : Maybe String
    , hostAdminWikiExportInFlightSlug : Maybe Evergreen.V14.Wiki.Slug
    , hostAdminWikiImportInFlightSlug : Maybe Evergreen.V14.Wiki.Slug
    , hostAdminWikiImportPendingSlug : Maybe Evergreen.V14.Wiki.Slug
    , hostAdminWikisNotice : Maybe String
    , sideNavOpen : Bool
    , wikiMarkdownEditorPane : Evergreen.V14.WikiMarkdownEditorPane.WikiMarkdownEditorPane
    }


type alias BackendModel =
    { wikis : Dict.Dict Evergreen.V14.Wiki.Slug Evergreen.V14.Wiki.Wiki
    , contributors : Evergreen.V14.WikiContributors.Registry
    , contributorSessions : Evergreen.V14.WikiUser.SessionTable
    , hostSessions : Set.Set String
    , submissions : Dict.Dict String Evergreen.V14.Submission.Submission
    , nextSubmissionCounter : Int
    , wikiAuditEvents : Dict.Dict Evergreen.V14.Wiki.Slug (List Evergreen.V14.WikiAuditLog.AuditEvent)
    , pendingReviewCounts : Dict.Dict Evergreen.V14.Wiki.Slug Int
    , pendingReviewClients : Evergreen.V14.PendingReviewCount.PendingReviewClientSets
    , wikiFrontendClients : Evergreen.V14.WikiFrontendSubscription.WikiFrontendClientSets
    }


type FrontendMsg
    = UrlClicked Effect.Browser.UrlRequest
    | UrlChanged Url.Url
    | UrlFragmentScrollDone
    | ColorThemeToggled
    | ColorThemeFromJs (Maybe Evergreen.V14.ColorTheme.Incoming)
    | RegisterFormUsernameChanged String
    | RegisterFormPasswordChanged String
    | RegisterFormSubmitted
    | LoginFormUsernameChanged String
    | LoginFormPasswordChanged String
    | LoginFormSubmitted
    | HeaderSearchQueryChanged String
    | HeaderSearchSubmitted
    | WikiSearchPageQueryChanged String
    | ContributorLogoutWiki Evergreen.V14.Wiki.Slug
    | NewPageSubmitMarkdownChanged String
    | NewPageSubmitSlugChanged String
    | NewPageSubmitTagsChanged String
    | NewPageSubmitFormSubmitted
    | PageEditSubmitMarkdownChanged String
    | PageEditSubmitTagsChanged String
    | PageEditPublishedRowToggled
    | PageEditSubmitFormSubmitted
    | PageDeleteSubmitReasonChanged String
    | PageDeleteRequestDeletionSubmitted
    | PageDeletePublishedImmediatelySubmitted
    | NewPageSaveDraftClicked
    | PageEditSaveDraftClicked
    | PageDeleteSaveDraftClicked
    | SubmissionDetailNewMarkdownChanged String
    | SubmissionDetailNewPageSlugChanged String
    | SubmissionDetailSaveDraftClicked
    | SubmissionDetailSubmitForReviewClicked
    | SubmissionDetailWithdrawClicked
    | SubmissionDetailDeleteClicked
    | ReviewDecisionChanged ReviewDecision
    | ReviewDecisionSubmitted
    | ReviewRejectReasonChanged String
    | ReviewRequestChangesNoteChanged String
    | WikiAdminPromoteToTrustedClicked String
    | WikiAdminDemoteToContributorClicked String
    | WikiAdminGrantAdminClicked String
    | WikiAdminRevokeAdminClicked String
    | WikiAdminAuditFilterActorChanged String
    | WikiAdminAuditFilterPageChanged String
    | WikiAdminAuditFilterTypeTagToggled Evergreen.V14.WikiAuditLog.AuditEventKindFilterTag Bool
    | HostAdminLoginPasswordChanged String
    | HostAdminLoginSubmitted
    | HostAdminCreateWikiSlugChanged String
    | HostAdminCreateWikiNameChanged String
    | HostAdminCreateWikiInitialAdminUsernameChanged String
    | HostAdminCreateWikiInitialAdminPasswordChanged String
    | HostAdminCreateWikiSubmitted
    | HostAdminWikiDetailNameChanged String
    | HostAdminWikiDetailSlugChanged String
    | HostAdminWikiDetailSummaryChanged String
    | HostAdminWikiDetailSaveClicked
    | HostAdminWikiDetailDeactivateClicked
    | HostAdminWikiDetailReactivateClicked
    | HostAdminWikiDetailDeleteConfirmChanged String
    | HostAdminWikiDetailDeleteSubmitted
    | HostAdminAuditFilterWikiChanged String
    | HostAdminAuditFilterActorChanged String
    | HostAdminAuditFilterPageChanged String
    | HostAdminAuditFilterTypeTagToggled Evergreen.V14.WikiAuditLog.AuditEventKindFilterTag Bool
    | HostAdminDataExportClicked
    | HostAdminDataImportPickRequested
    | HostAdminDataImportFileSelected Effect.File.File
    | HostAdminDataImportFileRead (Result () String)
    | HostAdminWikisDataImportPickRequested
    | HostAdminWikisDataImportFileSelected Effect.File.File
    | HostAdminWikisDataImportFileRead (Result () String)
    | HostAdminWikiDataExportClicked Evergreen.V14.Wiki.Slug
    | HostAdminWikiDataImportPickRequested Evergreen.V14.Wiki.Slug
    | HostAdminWikiDataImportFileSelected Effect.File.File
    | HostAdminWikiDataImportFileRead Evergreen.V14.Wiki.Slug (Result () String)
    | SideNavOpened
    | SideNavClosed
    | WikiMarkdownEditorPaneSelected Evergreen.V14.WikiMarkdownEditorPane.WikiMarkdownEditorPane


type alias RegisterContributorPayload =
    { username : String
    , password : String
    }


type alias LoginContributorPayload =
    { username : String
    , password : String
    }


type alias SubmitNewPagePayload =
    { rawPageSlug : String
    , rawMarkdown : String
    , rawTags : String
    }


type alias RejectSubmissionPayload =
    { submissionId : String
    , reasonText : String
    }


type alias RequestSubmissionChangesPayload =
    { submissionId : String
    , guidanceText : String
    }


type alias CreateHostedWikiPayload =
    { rawSlug : String
    , rawName : String
    , initialAdminUsername : String
    , initialAdminPassword : String
    }


type alias UpdateHostedWikiMetadataPayload =
    { rawName : String
    , rawSummary : String
    , rawSlugDraft : String
    }


type ToBackend
    = RequestWikiCatalog
    | RequestWikiFrontendDetails Evergreen.V14.Wiki.Slug
    | RequestPageFrontendDetails Evergreen.V14.Wiki.Slug Evergreen.V14.Page.Slug
    | RequestMyPendingSubmissions Evergreen.V14.Wiki.Slug
    | RequestReviewQueue Evergreen.V14.Wiki.Slug
    | RequestReviewSubmissionDetail Evergreen.V14.Wiki.Slug String
    | RequestWikiUsers Evergreen.V14.Wiki.Slug
    | RequestWikiAuditLog Evergreen.V14.Wiki.Slug Evergreen.V14.WikiAuditLog.AuditLogFilter
    | PromoteContributorToTrusted Evergreen.V14.Wiki.Slug String
    | DemoteTrustedToContributor Evergreen.V14.Wiki.Slug String
    | GrantWikiAdmin Evergreen.V14.Wiki.Slug String
    | RevokeWikiAdmin Evergreen.V14.Wiki.Slug String
    | RequestSubmissionDetails Evergreen.V14.Wiki.Slug String
    | RegisterContributor Evergreen.V14.Wiki.Slug RegisterContributorPayload
    | LoginContributor Evergreen.V14.Wiki.Slug LoginContributorPayload
    | LogoutContributor Evergreen.V14.Wiki.Slug
    | SubmitNewPage Evergreen.V14.Wiki.Slug SubmitNewPagePayload
    | SubmitPageEdit Evergreen.V14.Wiki.Slug Evergreen.V14.Page.Slug String String
    | RequestPublishedPageDeletion Evergreen.V14.Wiki.Slug Evergreen.V14.Page.Slug String
    | DeletePublishedPageImmediately Evergreen.V14.Wiki.Slug Evergreen.V14.Page.Slug String
    | SaveNewPageDraft
        Evergreen.V14.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , rawPageSlug : String
        , rawMarkdown : String
        , rawTags : String
        }
    | SavePageEditDraft
        Evergreen.V14.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V14.Page.Slug
        , rawMarkdown : String
        , rawTags : String
        }
    | SavePageDeleteDraft
        Evergreen.V14.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V14.Page.Slug
        , rawReason : String
        }
    | SubmitDraftForReview Evergreen.V14.Wiki.Slug String
    | WithdrawSubmission Evergreen.V14.Wiki.Slug String
    | DeleteMySubmission Evergreen.V14.Wiki.Slug String
    | ApproveSubmission Evergreen.V14.Wiki.Slug String
    | RejectSubmission Evergreen.V14.Wiki.Slug RejectSubmissionPayload
    | RequestSubmissionChanges Evergreen.V14.Wiki.Slug RequestSubmissionChangesPayload
    | HostAdminLogin String
    | RequestHostWikiList
    | RequestHostAuditLog Evergreen.V14.WikiAuditLog.HostAuditLogFilter
    | RequestHostWikiDetail Evergreen.V14.Wiki.Slug
    | CreateHostedWiki CreateHostedWikiPayload
    | UpdateHostedWikiMetadata Evergreen.V14.Wiki.Slug UpdateHostedWikiMetadataPayload
    | DeactivateHostedWiki Evergreen.V14.Wiki.Slug
    | ReactivateHostedWiki Evergreen.V14.Wiki.Slug
    | DeleteHostedWiki Evergreen.V14.Wiki.Slug String
    | RequestHostAdminDataExport
    | ImportHostAdminDataSnapshot String
    | RequestHostAdminWikiDataExport Evergreen.V14.Wiki.Slug
    | ImportHostAdminWikiDataSnapshot Evergreen.V14.Wiki.Slug String
    | ImportHostAdminWikiDataSnapshotAuto String


type BackendMsg
    = ToBackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Time.Posix


type ToFrontend
    = WikiCatalogResponse (Dict.Dict Evergreen.V14.Wiki.Slug Evergreen.V14.Wiki.CatalogEntry)
    | PendingReviewCountUpdated Evergreen.V14.Wiki.Slug Int
    | WikiFrontendDetailsResponse Evergreen.V14.Wiki.Slug (Maybe Evergreen.V14.Wiki.FrontendDetails)
    | PageFrontendDetailsResponse Evergreen.V14.Wiki.Slug Evergreen.V14.Page.Slug (Maybe Evergreen.V14.Page.FrontendDetails)
    | MyPendingSubmissionsResponse Evergreen.V14.Wiki.Slug (Result Evergreen.V14.Submission.MyPendingSubmissionsError (List Evergreen.V14.Submission.MyPendingSubmissionListItem))
    | ReviewQueueResponse Evergreen.V14.Wiki.Slug (Result Evergreen.V14.Submission.ReviewQueueError (List Evergreen.V14.Submission.ReviewQueueItem))
    | ReviewSubmissionDetailResponse Evergreen.V14.Wiki.Slug String (Result Evergreen.V14.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V14.SubmissionReviewDetail.SubmissionReviewDetail)
    | WikiUsersResponse Evergreen.V14.Wiki.Slug (Result Evergreen.V14.WikiAdminUsers.Error (List Evergreen.V14.WikiAdminUsers.ListedUser))
    | WikiAuditLogResponse Evergreen.V14.Wiki.Slug Evergreen.V14.WikiAuditLog.AuditLogFilter (Result Evergreen.V14.WikiAuditLog.Error (List Evergreen.V14.WikiAuditLog.AuditEvent))
    | PromoteContributorToTrustedResponse Evergreen.V14.Wiki.Slug (Result Evergreen.V14.WikiAdminUsers.PromoteContributorError ())
    | DemoteTrustedToContributorResponse Evergreen.V14.Wiki.Slug (Result Evergreen.V14.WikiAdminUsers.DemoteTrustedError ())
    | GrantWikiAdminResponse Evergreen.V14.Wiki.Slug (Result Evergreen.V14.WikiAdminUsers.GrantTrustedToAdminError ())
    | RevokeWikiAdminResponse Evergreen.V14.Wiki.Slug (Result Evergreen.V14.WikiAdminUsers.RevokeAdminError ())
    | SubmissionDetailsResponse Evergreen.V14.Wiki.Slug String (Result Evergreen.V14.Submission.DetailsError Evergreen.V14.Submission.ContributorView)
    | RegisterContributorResponse Evergreen.V14.Wiki.Slug (Result Evergreen.V14.ContributorAccount.RegisterContributorError Evergreen.V14.WikiRole.WikiRole)
    | LoginContributorResponse Evergreen.V14.Wiki.Slug (Result Evergreen.V14.ContributorAccount.LoginContributorError Evergreen.V14.WikiRole.WikiRole)
    | LogoutContributorResponse Evergreen.V14.Wiki.Slug
    | SubmitNewPageResponse Evergreen.V14.Wiki.Slug (Result Evergreen.V14.Submission.SubmitNewPageError Evergreen.V14.Submission.NewPageSubmitSuccess)
    | SubmitPageEditResponse Evergreen.V14.Wiki.Slug (Result Evergreen.V14.Submission.SubmitPageEditError Evergreen.V14.Submission.EditSubmitSuccess)
    | RequestPublishedPageDeletionResponse Evergreen.V14.Wiki.Slug (Result Evergreen.V14.Submission.RequestPublishedPageDeletionError Evergreen.V14.Submission.Id)
    | DeletePublishedPageImmediatelyResponse Evergreen.V14.Wiki.Slug (Result Evergreen.V14.Submission.DeletePublishedPageImmediatelyError ())
    | SaveNewPageDraftResponse Evergreen.V14.Wiki.Slug (Result Evergreen.V14.Submission.SaveNewPageDraftError Evergreen.V14.Submission.Id)
    | SavePageEditDraftResponse Evergreen.V14.Wiki.Slug (Result Evergreen.V14.Submission.SavePageEditDraftError Evergreen.V14.Submission.Id)
    | SavePageDeleteDraftResponse Evergreen.V14.Wiki.Slug (Result Evergreen.V14.Submission.SavePageDeleteDraftError Evergreen.V14.Submission.Id)
    | SubmitDraftForReviewResponse Evergreen.V14.Wiki.Slug String (Result Evergreen.V14.Submission.SubmitDraftForReviewError ())
    | WithdrawSubmissionResponse Evergreen.V14.Wiki.Slug String (Result Evergreen.V14.Submission.WithdrawSubmissionError ())
    | DeleteMySubmissionResponse Evergreen.V14.Wiki.Slug String (Result Evergreen.V14.Submission.DeleteMySubmissionError ())
    | ApproveSubmissionResponse Evergreen.V14.Wiki.Slug String (Result Evergreen.V14.Submission.ApproveSubmissionError ())
    | RejectSubmissionResponse Evergreen.V14.Wiki.Slug String (Result Evergreen.V14.Submission.RejectSubmissionError ())
    | RequestSubmissionChangesResponse Evergreen.V14.Wiki.Slug String (Result Evergreen.V14.Submission.RequestChangesSubmissionError ())
    | HostAdminLoginResponse (Result Evergreen.V14.HostAdmin.LoginError ())
    | HostAdminWikiListResponse (Result Evergreen.V14.HostAdmin.ProtectedError (List Evergreen.V14.Wiki.CatalogEntry))
    | HostAuditLogResponse Evergreen.V14.WikiAuditLog.HostAuditLogFilter (Result Evergreen.V14.HostAdmin.ProtectedError (List Evergreen.V14.WikiAuditLog.ScopedAuditEvent))
    | CreateHostedWikiResponse (Result Evergreen.V14.HostAdmin.CreateHostedWikiError Evergreen.V14.Wiki.CatalogEntry)
    | HostWikiDetailResponse Evergreen.V14.Wiki.Slug (Result Evergreen.V14.HostAdmin.HostWikiDetailError Evergreen.V14.Wiki.CatalogEntry)
    | UpdateHostedWikiMetadataResponse Evergreen.V14.Wiki.Slug (Result Evergreen.V14.HostAdmin.UpdateHostedWikiMetadataError Evergreen.V14.Wiki.CatalogEntry)
    | DeactivateHostedWikiResponse Evergreen.V14.Wiki.Slug (Result Evergreen.V14.HostAdmin.WikiLifecycleError Evergreen.V14.Wiki.CatalogEntry)
    | ReactivateHostedWikiResponse Evergreen.V14.Wiki.Slug (Result Evergreen.V14.HostAdmin.WikiLifecycleError Evergreen.V14.Wiki.CatalogEntry)
    | DeleteHostedWikiResponse Evergreen.V14.Wiki.Slug (Result Evergreen.V14.HostAdmin.DeleteHostedWikiError ())
    | HostAdminDataExportResponse (Result Evergreen.V14.HostAdmin.DataExportError String)
    | HostAdminDataImportResponse (Result Evergreen.V14.HostAdmin.DataImportError ())
    | HostAdminWikiDataExportResponse Evergreen.V14.Wiki.Slug (Result Evergreen.V14.HostAdmin.WikiDataExportError String)
    | HostAdminWikiDataImportResponse Evergreen.V14.Wiki.Slug (Result Evergreen.V14.HostAdmin.WikiDataImportError ())
    | HostAdminWikiDataImportAutoResponse (Result Evergreen.V14.HostAdmin.WikiDataImportError Evergreen.V14.Wiki.Slug)

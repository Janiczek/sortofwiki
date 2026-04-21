module Evergreen.V3.Types exposing (..)

import Dict
import Effect.Browser
import Effect.Browser.Navigation
import Effect.File
import Effect.Lamdera
import Evergreen.V3.ColorTheme
import Evergreen.V3.ContributorAccount
import Evergreen.V3.ContributorWikiSession
import Evergreen.V3.HostAdmin
import Evergreen.V3.Page
import Evergreen.V3.Route
import Evergreen.V3.Store
import Evergreen.V3.Submission
import Evergreen.V3.SubmissionReviewDetail
import Evergreen.V3.Wiki
import Evergreen.V3.WikiAdminUsers
import Evergreen.V3.WikiAuditLog
import Evergreen.V3.WikiContributors
import Evergreen.V3.WikiRole
import Evergreen.V3.WikiUser
import RemoteData
import Set
import Time
import Url


type alias RegisterDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V3.ContributorAccount.RegisterContributorError ())
    }


type alias LoginDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V3.ContributorAccount.LoginContributorError ())
    }


type alias NewPageSubmitDraft =
    { pageSlug : String
    , pageSlugLockedFromQuery : Bool
    , markdownBody : String
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V3.Submission.SubmitNewPageError Evergreen.V3.Submission.NewPageSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V3.Submission.SaveNewPageDraftError Evergreen.V3.Submission.Id)
    }


type alias PageEditSubmitDraft =
    { markdownBody : String
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V3.Submission.SubmitPageEditError Evergreen.V3.Submission.EditSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V3.Submission.SavePageEditDraftError Evergreen.V3.Submission.Id)
    }


type alias PageDeleteSubmitDraft =
    { reasonText : String
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V3.Submission.PageDeleteFormError Evergreen.V3.Submission.PageDeleteFormSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V3.Submission.SavePageDeleteDraftError Evergreen.V3.Submission.Id)
    }


type alias ReviewApproveDraft =
    { inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V3.Submission.ApproveSubmissionError ())
    }


type ReviewDecision
    = ReviewDecisionApprove
    | ReviewDecisionRequestChanges
    | ReviewDecisionReject


type alias ReviewRejectDraft =
    { reasonText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V3.Submission.RejectSubmissionError ())
    }


type alias ReviewRequestChangesDraft =
    { guidanceText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V3.Submission.RequestChangesSubmissionError ())
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
    , lastResult : Maybe (Result Evergreen.V3.HostAdmin.LoginError ())
    }


type alias HostAdminCreateWikiDraft =
    { slug : String
    , name : String
    , initialAdminUsername : String
    , initialAdminPassword : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V3.HostAdmin.CreateHostedWikiError Evergreen.V3.Wiki.CatalogEntry)
    }


type alias HostAdminWikiDetailDraft =
    { wikiSlug : Evergreen.V3.Wiki.Slug
    , load : RemoteData.RemoteData () (Result Evergreen.V3.HostAdmin.HostWikiDetailError Evergreen.V3.Wiki.CatalogEntry)
    , slugDraft : String
    , nameDraft : String
    , summaryDraft : String
    , saveInFlight : Bool
    , lastSaveResult : Maybe (Result Evergreen.V3.HostAdmin.UpdateHostedWikiMetadataError ())
    , lifecycleInFlight : Bool
    , lastLifecycleResult : Maybe (Result Evergreen.V3.HostAdmin.WikiLifecycleError ())
    , deleteConfirmDraft : String
    , deleteInFlight : Bool
    , lastDeleteResult : Maybe (Result Evergreen.V3.HostAdmin.DeleteHostedWikiError ())
    }


type alias FrontendModel =
    { key : Effect.Browser.Navigation.Key
    , colorThemePreference : Evergreen.V3.ColorTheme.ColorThemePreference
    , systemColorTheme : Evergreen.V3.ColorTheme.ColorTheme
    , route : Evergreen.V3.Route.Route
    , navigationFragment : Maybe String
    , store : Evergreen.V3.Store.Store
    , contributorWikiSessions : Dict.Dict Evergreen.V3.Wiki.Slug Evergreen.V3.ContributorWikiSession.ContributorWikiSession
    , registerDraft : RegisterDraft
    , loginDraft : LoginDraft
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
    , wikiAdminAuditFilterSelectedKindTags : List Evergreen.V3.WikiAuditLog.AuditEventKindFilterTag
    , wikiAdminAuditAppliedFilter : Evergreen.V3.WikiAuditLog.AuditLogFilter
    , hostAdminAuditFilterWikiDraft : String
    , hostAdminAuditFilterActorDraft : String
    , hostAdminAuditFilterPageDraft : String
    , hostAdminAuditFilterSelectedKindTags : List Evergreen.V3.WikiAuditLog.AuditEventKindFilterTag
    , hostAdminAuditAppliedFilter : Evergreen.V3.WikiAuditLog.HostAuditLogFilter
    , hostAdminAuditLog : RemoteData.RemoteData () (Result Evergreen.V3.HostAdmin.ProtectedError (List Evergreen.V3.WikiAuditLog.ScopedAuditEvent))
    , hostAdminLoginDraft : HostAdminLoginDraft
    , hostAdminCreateWikiDraft : HostAdminCreateWikiDraft
    , hostAdminWikiDetailDraft : HostAdminWikiDetailDraft
    , hostAdminWikis : RemoteData.RemoteData () (Result Evergreen.V3.HostAdmin.ProtectedError (List Evergreen.V3.Wiki.CatalogEntry))
    , hostAdminSessionAuthenticated : Bool
    , hostAdminExportInFlight : Bool
    , hostAdminImportInFlight : Bool
    , hostAdminBackupNotice : Maybe String
    , hostAdminWikiExportInFlightSlug : Maybe Evergreen.V3.Wiki.Slug
    , hostAdminWikiImportInFlightSlug : Maybe Evergreen.V3.Wiki.Slug
    , hostAdminWikiImportPendingSlug : Maybe Evergreen.V3.Wiki.Slug
    , hostAdminWikisNotice : Maybe String
    }


type alias BackendModel =
    { wikis : Dict.Dict Evergreen.V3.Wiki.Slug Evergreen.V3.Wiki.Wiki
    , contributors : Evergreen.V3.WikiContributors.Registry
    , contributorSessions : Evergreen.V3.WikiUser.SessionTable
    , hostSessions : Set.Set String
    , submissions : Dict.Dict String Evergreen.V3.Submission.Submission
    , nextSubmissionCounter : Int
    , wikiAuditEvents : Dict.Dict Evergreen.V3.Wiki.Slug (List Evergreen.V3.WikiAuditLog.AuditEvent)
    }


type FrontendMsg
    = UrlClicked Effect.Browser.UrlRequest
    | UrlChanged Url.Url
    | UrlFragmentScrollDone
    | ColorThemeToggled
    | ColorThemeFromJs (Maybe Evergreen.V3.ColorTheme.Incoming)
    | RegisterFormUsernameChanged String
    | RegisterFormPasswordChanged String
    | RegisterFormSubmitted
    | LoginFormUsernameChanged String
    | LoginFormPasswordChanged String
    | LoginFormSubmitted
    | ContributorLogoutWiki Evergreen.V3.Wiki.Slug
    | NewPageSubmitMarkdownChanged String
    | NewPageSubmitSlugChanged String
    | NewPageSubmitFormSubmitted
    | PageEditSubmitMarkdownChanged String
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
    | WikiAdminAuditFilterTypeTagToggled Evergreen.V3.WikiAuditLog.AuditEventKindFilterTag Bool
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
    | HostAdminAuditFilterTypeTagToggled Evergreen.V3.WikiAuditLog.AuditEventKindFilterTag Bool
    | HostAdminDataExportClicked
    | HostAdminDataImportPickRequested
    | HostAdminDataImportFileSelected Effect.File.File
    | HostAdminDataImportFileRead (Result () String)
    | HostAdminWikisDataImportPickRequested
    | HostAdminWikisDataImportFileSelected Effect.File.File
    | HostAdminWikisDataImportFileRead (Result () String)
    | HostAdminWikiDataExportClicked Evergreen.V3.Wiki.Slug
    | HostAdminWikiDataImportPickRequested Evergreen.V3.Wiki.Slug
    | HostAdminWikiDataImportFileSelected Effect.File.File
    | HostAdminWikiDataImportFileRead Evergreen.V3.Wiki.Slug (Result () String)


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
    | RequestWikiFrontendDetails Evergreen.V3.Wiki.Slug
    | RequestPageFrontendDetails Evergreen.V3.Wiki.Slug Evergreen.V3.Page.Slug
    | RequestMyPendingSubmissions Evergreen.V3.Wiki.Slug
    | RequestReviewQueue Evergreen.V3.Wiki.Slug
    | RequestReviewSubmissionDetail Evergreen.V3.Wiki.Slug String
    | RequestWikiUsers Evergreen.V3.Wiki.Slug
    | RequestWikiAuditLog Evergreen.V3.Wiki.Slug Evergreen.V3.WikiAuditLog.AuditLogFilter
    | PromoteContributorToTrusted Evergreen.V3.Wiki.Slug String
    | DemoteTrustedToContributor Evergreen.V3.Wiki.Slug String
    | GrantWikiAdmin Evergreen.V3.Wiki.Slug String
    | RevokeWikiAdmin Evergreen.V3.Wiki.Slug String
    | RequestSubmissionDetails Evergreen.V3.Wiki.Slug String
    | RegisterContributor Evergreen.V3.Wiki.Slug RegisterContributorPayload
    | LoginContributor Evergreen.V3.Wiki.Slug LoginContributorPayload
    | LogoutContributor Evergreen.V3.Wiki.Slug
    | SubmitNewPage Evergreen.V3.Wiki.Slug SubmitNewPagePayload
    | SubmitPageEdit Evergreen.V3.Wiki.Slug Evergreen.V3.Page.Slug String
    | RequestPublishedPageDeletion Evergreen.V3.Wiki.Slug Evergreen.V3.Page.Slug String
    | DeletePublishedPageImmediately Evergreen.V3.Wiki.Slug Evergreen.V3.Page.Slug String
    | SaveNewPageDraft
        Evergreen.V3.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , rawPageSlug : String
        , rawMarkdown : String
        }
    | SavePageEditDraft
        Evergreen.V3.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V3.Page.Slug
        , rawMarkdown : String
        }
    | SavePageDeleteDraft
        Evergreen.V3.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V3.Page.Slug
        , rawReason : String
        }
    | SubmitDraftForReview Evergreen.V3.Wiki.Slug String
    | WithdrawSubmission Evergreen.V3.Wiki.Slug String
    | DeleteMySubmission Evergreen.V3.Wiki.Slug String
    | ApproveSubmission Evergreen.V3.Wiki.Slug String
    | RejectSubmission Evergreen.V3.Wiki.Slug RejectSubmissionPayload
    | RequestSubmissionChanges Evergreen.V3.Wiki.Slug RequestSubmissionChangesPayload
    | HostAdminLogin String
    | RequestHostWikiList
    | RequestHostAuditLog Evergreen.V3.WikiAuditLog.HostAuditLogFilter
    | RequestHostWikiDetail Evergreen.V3.Wiki.Slug
    | CreateHostedWiki CreateHostedWikiPayload
    | UpdateHostedWikiMetadata Evergreen.V3.Wiki.Slug UpdateHostedWikiMetadataPayload
    | DeactivateHostedWiki Evergreen.V3.Wiki.Slug
    | ReactivateHostedWiki Evergreen.V3.Wiki.Slug
    | DeleteHostedWiki Evergreen.V3.Wiki.Slug String
    | RequestHostAdminDataExport
    | ImportHostAdminDataSnapshot String
    | RequestHostAdminWikiDataExport Evergreen.V3.Wiki.Slug
    | ImportHostAdminWikiDataSnapshot Evergreen.V3.Wiki.Slug String
    | ImportHostAdminWikiDataSnapshotAuto String


type BackendMsg
    = ToBackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Time.Posix


type ToFrontend
    = WikiCatalogResponse (Dict.Dict Evergreen.V3.Wiki.Slug Evergreen.V3.Wiki.CatalogEntry)
    | WikiFrontendDetailsResponse Evergreen.V3.Wiki.Slug (Maybe Evergreen.V3.Wiki.FrontendDetails)
    | PageFrontendDetailsResponse Evergreen.V3.Wiki.Slug Evergreen.V3.Page.Slug (Maybe Evergreen.V3.Page.FrontendDetails)
    | MyPendingSubmissionsResponse Evergreen.V3.Wiki.Slug (Result Evergreen.V3.Submission.MyPendingSubmissionsError (List Evergreen.V3.Submission.MyPendingSubmissionListItem))
    | ReviewQueueResponse Evergreen.V3.Wiki.Slug (Result Evergreen.V3.Submission.ReviewQueueError (List Evergreen.V3.Submission.ReviewQueueItem))
    | ReviewSubmissionDetailResponse Evergreen.V3.Wiki.Slug String (Result Evergreen.V3.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V3.SubmissionReviewDetail.SubmissionReviewDetail)
    | WikiUsersResponse Evergreen.V3.Wiki.Slug (Result Evergreen.V3.WikiAdminUsers.Error (List Evergreen.V3.WikiAdminUsers.ListedUser))
    | WikiAuditLogResponse Evergreen.V3.Wiki.Slug Evergreen.V3.WikiAuditLog.AuditLogFilter (Result Evergreen.V3.WikiAuditLog.Error (List Evergreen.V3.WikiAuditLog.AuditEvent))
    | PromoteContributorToTrustedResponse Evergreen.V3.Wiki.Slug (Result Evergreen.V3.WikiAdminUsers.PromoteContributorError ())
    | DemoteTrustedToContributorResponse Evergreen.V3.Wiki.Slug (Result Evergreen.V3.WikiAdminUsers.DemoteTrustedError ())
    | GrantWikiAdminResponse Evergreen.V3.Wiki.Slug (Result Evergreen.V3.WikiAdminUsers.GrantTrustedToAdminError ())
    | RevokeWikiAdminResponse Evergreen.V3.Wiki.Slug (Result Evergreen.V3.WikiAdminUsers.RevokeAdminError ())
    | SubmissionDetailsResponse Evergreen.V3.Wiki.Slug String (Result Evergreen.V3.Submission.DetailsError Evergreen.V3.Submission.ContributorView)
    | RegisterContributorResponse Evergreen.V3.Wiki.Slug (Result Evergreen.V3.ContributorAccount.RegisterContributorError Evergreen.V3.WikiRole.WikiRole)
    | LoginContributorResponse Evergreen.V3.Wiki.Slug (Result Evergreen.V3.ContributorAccount.LoginContributorError Evergreen.V3.WikiRole.WikiRole)
    | LogoutContributorResponse Evergreen.V3.Wiki.Slug
    | SubmitNewPageResponse Evergreen.V3.Wiki.Slug (Result Evergreen.V3.Submission.SubmitNewPageError Evergreen.V3.Submission.NewPageSubmitSuccess)
    | SubmitPageEditResponse Evergreen.V3.Wiki.Slug (Result Evergreen.V3.Submission.SubmitPageEditError Evergreen.V3.Submission.EditSubmitSuccess)
    | RequestPublishedPageDeletionResponse Evergreen.V3.Wiki.Slug (Result Evergreen.V3.Submission.RequestPublishedPageDeletionError Evergreen.V3.Submission.Id)
    | DeletePublishedPageImmediatelyResponse Evergreen.V3.Wiki.Slug (Result Evergreen.V3.Submission.DeletePublishedPageImmediatelyError ())
    | SaveNewPageDraftResponse Evergreen.V3.Wiki.Slug (Result Evergreen.V3.Submission.SaveNewPageDraftError Evergreen.V3.Submission.Id)
    | SavePageEditDraftResponse Evergreen.V3.Wiki.Slug (Result Evergreen.V3.Submission.SavePageEditDraftError Evergreen.V3.Submission.Id)
    | SavePageDeleteDraftResponse Evergreen.V3.Wiki.Slug (Result Evergreen.V3.Submission.SavePageDeleteDraftError Evergreen.V3.Submission.Id)
    | SubmitDraftForReviewResponse Evergreen.V3.Wiki.Slug String (Result Evergreen.V3.Submission.SubmitDraftForReviewError ())
    | WithdrawSubmissionResponse Evergreen.V3.Wiki.Slug String (Result Evergreen.V3.Submission.WithdrawSubmissionError ())
    | DeleteMySubmissionResponse Evergreen.V3.Wiki.Slug String (Result Evergreen.V3.Submission.DeleteMySubmissionError ())
    | ApproveSubmissionResponse Evergreen.V3.Wiki.Slug String (Result Evergreen.V3.Submission.ApproveSubmissionError ())
    | RejectSubmissionResponse Evergreen.V3.Wiki.Slug String (Result Evergreen.V3.Submission.RejectSubmissionError ())
    | RequestSubmissionChangesResponse Evergreen.V3.Wiki.Slug String (Result Evergreen.V3.Submission.RequestChangesSubmissionError ())
    | HostAdminLoginResponse (Result Evergreen.V3.HostAdmin.LoginError ())
    | HostAdminWikiListResponse (Result Evergreen.V3.HostAdmin.ProtectedError (List Evergreen.V3.Wiki.CatalogEntry))
    | HostAuditLogResponse Evergreen.V3.WikiAuditLog.HostAuditLogFilter (Result Evergreen.V3.HostAdmin.ProtectedError (List Evergreen.V3.WikiAuditLog.ScopedAuditEvent))
    | CreateHostedWikiResponse (Result Evergreen.V3.HostAdmin.CreateHostedWikiError Evergreen.V3.Wiki.CatalogEntry)
    | HostWikiDetailResponse Evergreen.V3.Wiki.Slug (Result Evergreen.V3.HostAdmin.HostWikiDetailError Evergreen.V3.Wiki.CatalogEntry)
    | UpdateHostedWikiMetadataResponse Evergreen.V3.Wiki.Slug (Result Evergreen.V3.HostAdmin.UpdateHostedWikiMetadataError Evergreen.V3.Wiki.CatalogEntry)
    | DeactivateHostedWikiResponse Evergreen.V3.Wiki.Slug (Result Evergreen.V3.HostAdmin.WikiLifecycleError Evergreen.V3.Wiki.CatalogEntry)
    | ReactivateHostedWikiResponse Evergreen.V3.Wiki.Slug (Result Evergreen.V3.HostAdmin.WikiLifecycleError Evergreen.V3.Wiki.CatalogEntry)
    | DeleteHostedWikiResponse Evergreen.V3.Wiki.Slug (Result Evergreen.V3.HostAdmin.DeleteHostedWikiError ())
    | HostAdminDataExportResponse (Result Evergreen.V3.HostAdmin.DataExportError String)
    | HostAdminDataImportResponse (Result Evergreen.V3.HostAdmin.DataImportError ())
    | HostAdminWikiDataExportResponse Evergreen.V3.Wiki.Slug (Result Evergreen.V3.HostAdmin.WikiDataExportError String)
    | HostAdminWikiDataImportResponse Evergreen.V3.Wiki.Slug (Result Evergreen.V3.HostAdmin.WikiDataImportError ())
    | HostAdminWikiDataImportAutoResponse (Result Evergreen.V3.HostAdmin.WikiDataImportError Evergreen.V3.Wiki.Slug)

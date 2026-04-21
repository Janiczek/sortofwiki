module Evergreen.V1.Types exposing (..)

import Dict
import Effect.Browser
import Effect.Browser.Navigation
import Effect.File
import Effect.Lamdera
import Evergreen.V1.ColorTheme
import Evergreen.V1.ContributorAccount
import Evergreen.V1.ContributorWikiSession
import Evergreen.V1.HostAdmin
import Evergreen.V1.Page
import Evergreen.V1.Route
import Evergreen.V1.Store
import Evergreen.V1.Submission
import Evergreen.V1.SubmissionReviewDetail
import Evergreen.V1.Wiki
import Evergreen.V1.WikiAdminUsers
import Evergreen.V1.WikiAuditLog
import Evergreen.V1.WikiContributors
import Evergreen.V1.WikiRole
import Evergreen.V1.WikiUser
import RemoteData
import Set
import Time
import Url


type alias RegisterDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V1.ContributorAccount.RegisterContributorError ())
    }


type alias LoginDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V1.ContributorAccount.LoginContributorError ())
    }


type alias NewPageSubmitDraft =
    { pageSlug : String
    , pageSlugLockedFromQuery : Bool
    , markdownBody : String
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V1.Submission.SubmitNewPageError Evergreen.V1.Submission.NewPageSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V1.Submission.SaveNewPageDraftError Evergreen.V1.Submission.Id)
    }


type alias PageEditSubmitDraft =
    { markdownBody : String
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V1.Submission.SubmitPageEditError Evergreen.V1.Submission.EditSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V1.Submission.SavePageEditDraftError Evergreen.V1.Submission.Id)
    }


type alias PageDeleteSubmitDraft =
    { reasonText : String
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V1.Submission.PageDeleteFormError Evergreen.V1.Submission.PageDeleteFormSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V1.Submission.SavePageDeleteDraftError Evergreen.V1.Submission.Id)
    }


type alias ReviewApproveDraft =
    { inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V1.Submission.ApproveSubmissionError ())
    }


type ReviewDecision
    = ReviewDecisionApprove
    | ReviewDecisionRequestChanges
    | ReviewDecisionReject


type alias ReviewRejectDraft =
    { reasonText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V1.Submission.RejectSubmissionError ())
    }


type alias ReviewRequestChangesDraft =
    { guidanceText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V1.Submission.RequestChangesSubmissionError ())
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
    , lastResult : Maybe (Result Evergreen.V1.HostAdmin.LoginError ())
    }


type alias HostAdminCreateWikiDraft =
    { slug : String
    , name : String
    , initialAdminUsername : String
    , initialAdminPassword : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V1.HostAdmin.CreateHostedWikiError Evergreen.V1.Wiki.CatalogEntry)
    }


type alias HostAdminWikiDetailDraft =
    { wikiSlug : Evergreen.V1.Wiki.Slug
    , load : RemoteData.RemoteData () (Result Evergreen.V1.HostAdmin.HostWikiDetailError Evergreen.V1.Wiki.CatalogEntry)
    , slugDraft : String
    , nameDraft : String
    , summaryDraft : String
    , saveInFlight : Bool
    , lastSaveResult : Maybe (Result Evergreen.V1.HostAdmin.UpdateHostedWikiMetadataError ())
    , lifecycleInFlight : Bool
    , lastLifecycleResult : Maybe (Result Evergreen.V1.HostAdmin.WikiLifecycleError ())
    , deleteConfirmDraft : String
    , deleteInFlight : Bool
    , lastDeleteResult : Maybe (Result Evergreen.V1.HostAdmin.DeleteHostedWikiError ())
    }


type alias FrontendModel =
    { key : Effect.Browser.Navigation.Key
    , colorThemePreference : Evergreen.V1.ColorTheme.ColorThemePreference
    , systemColorTheme : Evergreen.V1.ColorTheme.ColorTheme
    , route : Evergreen.V1.Route.Route
    , navigationFragment : Maybe String
    , store : Evergreen.V1.Store.Store
    , contributorWikiSessions : Dict.Dict Evergreen.V1.Wiki.Slug Evergreen.V1.ContributorWikiSession.ContributorWikiSession
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
    , wikiAdminAuditFilterSelectedKindTags : List Evergreen.V1.WikiAuditLog.AuditEventKindFilterTag
    , wikiAdminAuditAppliedFilter : Evergreen.V1.WikiAuditLog.AuditLogFilter
    , hostAdminAuditFilterWikiDraft : String
    , hostAdminAuditFilterActorDraft : String
    , hostAdminAuditFilterPageDraft : String
    , hostAdminAuditFilterSelectedKindTags : List Evergreen.V1.WikiAuditLog.AuditEventKindFilterTag
    , hostAdminAuditAppliedFilter : Evergreen.V1.WikiAuditLog.HostAuditLogFilter
    , hostAdminAuditLog : RemoteData.RemoteData () (Result Evergreen.V1.HostAdmin.ProtectedError (List Evergreen.V1.WikiAuditLog.ScopedAuditEvent))
    , hostAdminLoginDraft : HostAdminLoginDraft
    , hostAdminCreateWikiDraft : HostAdminCreateWikiDraft
    , hostAdminWikiDetailDraft : HostAdminWikiDetailDraft
    , hostAdminWikis : RemoteData.RemoteData () (Result Evergreen.V1.HostAdmin.ProtectedError (List Evergreen.V1.Wiki.CatalogEntry))
    , hostAdminSessionAuthenticated : Bool
    , hostAdminExportInFlight : Bool
    , hostAdminImportInFlight : Bool
    , hostAdminBackupNotice : Maybe String
    , hostAdminWikiExportInFlightSlug : Maybe Evergreen.V1.Wiki.Slug
    , hostAdminWikiImportInFlightSlug : Maybe Evergreen.V1.Wiki.Slug
    , hostAdminWikiImportPendingSlug : Maybe Evergreen.V1.Wiki.Slug
    , hostAdminWikisNotice : Maybe String
    }


type alias BackendModel =
    { wikis : Dict.Dict Evergreen.V1.Wiki.Slug Evergreen.V1.Wiki.Wiki
    , contributors : Evergreen.V1.WikiContributors.Registry
    , contributorSessions : Evergreen.V1.WikiUser.SessionTable
    , hostSessions : Set.Set String
    , submissions : Dict.Dict String Evergreen.V1.Submission.Submission
    , nextSubmissionCounter : Int
    , wikiAuditEvents : Dict.Dict Evergreen.V1.Wiki.Slug (List Evergreen.V1.WikiAuditLog.AuditEvent)
    }


type FrontendMsg
    = UrlClicked Effect.Browser.UrlRequest
    | UrlChanged Url.Url
    | UrlFragmentScrollDone
    | ColorThemeToggled
    | ColorThemeFromJs (Maybe Evergreen.V1.ColorTheme.Incoming)
    | RegisterFormUsernameChanged String
    | RegisterFormPasswordChanged String
    | RegisterFormSubmitted
    | LoginFormUsernameChanged String
    | LoginFormPasswordChanged String
    | LoginFormSubmitted
    | ContributorLogoutWiki Evergreen.V1.Wiki.Slug
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
    | WikiAdminAuditFilterTypeTagToggled Evergreen.V1.WikiAuditLog.AuditEventKindFilterTag Bool
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
    | HostAdminAuditFilterTypeTagToggled Evergreen.V1.WikiAuditLog.AuditEventKindFilterTag Bool
    | HostAdminDataExportClicked
    | HostAdminDataImportPickRequested
    | HostAdminDataImportFileSelected Effect.File.File
    | HostAdminDataImportFileRead (Result () String)
    | HostAdminWikiDataExportClicked Evergreen.V1.Wiki.Slug
    | HostAdminWikiDataImportPickRequested Evergreen.V1.Wiki.Slug
    | HostAdminWikiDataImportFileSelected Effect.File.File
    | HostAdminWikiDataImportFileRead Evergreen.V1.Wiki.Slug (Result () String)


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
    | RequestWikiFrontendDetails Evergreen.V1.Wiki.Slug
    | RequestPageFrontendDetails Evergreen.V1.Wiki.Slug Evergreen.V1.Page.Slug
    | RequestMyPendingSubmissions Evergreen.V1.Wiki.Slug
    | RequestReviewQueue Evergreen.V1.Wiki.Slug
    | RequestReviewSubmissionDetail Evergreen.V1.Wiki.Slug String
    | RequestWikiUsers Evergreen.V1.Wiki.Slug
    | RequestWikiAuditLog Evergreen.V1.Wiki.Slug Evergreen.V1.WikiAuditLog.AuditLogFilter
    | PromoteContributorToTrusted Evergreen.V1.Wiki.Slug String
    | DemoteTrustedToContributor Evergreen.V1.Wiki.Slug String
    | GrantWikiAdmin Evergreen.V1.Wiki.Slug String
    | RevokeWikiAdmin Evergreen.V1.Wiki.Slug String
    | RequestSubmissionDetails Evergreen.V1.Wiki.Slug String
    | RegisterContributor Evergreen.V1.Wiki.Slug RegisterContributorPayload
    | LoginContributor Evergreen.V1.Wiki.Slug LoginContributorPayload
    | LogoutContributor Evergreen.V1.Wiki.Slug
    | SubmitNewPage Evergreen.V1.Wiki.Slug SubmitNewPagePayload
    | SubmitPageEdit Evergreen.V1.Wiki.Slug Evergreen.V1.Page.Slug String
    | RequestPublishedPageDeletion Evergreen.V1.Wiki.Slug Evergreen.V1.Page.Slug String
    | DeletePublishedPageImmediately Evergreen.V1.Wiki.Slug Evergreen.V1.Page.Slug String
    | SaveNewPageDraft
        Evergreen.V1.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , rawPageSlug : String
        , rawMarkdown : String
        }
    | SavePageEditDraft
        Evergreen.V1.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V1.Page.Slug
        , rawMarkdown : String
        }
    | SavePageDeleteDraft
        Evergreen.V1.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V1.Page.Slug
        , rawReason : String
        }
    | SubmitDraftForReview Evergreen.V1.Wiki.Slug String
    | WithdrawSubmission Evergreen.V1.Wiki.Slug String
    | DeleteMySubmission Evergreen.V1.Wiki.Slug String
    | ApproveSubmission Evergreen.V1.Wiki.Slug String
    | RejectSubmission Evergreen.V1.Wiki.Slug RejectSubmissionPayload
    | RequestSubmissionChanges Evergreen.V1.Wiki.Slug RequestSubmissionChangesPayload
    | HostAdminLogin String
    | RequestHostWikiList
    | RequestHostAuditLog Evergreen.V1.WikiAuditLog.HostAuditLogFilter
    | RequestHostWikiDetail Evergreen.V1.Wiki.Slug
    | CreateHostedWiki CreateHostedWikiPayload
    | UpdateHostedWikiMetadata Evergreen.V1.Wiki.Slug UpdateHostedWikiMetadataPayload
    | DeactivateHostedWiki Evergreen.V1.Wiki.Slug
    | ReactivateHostedWiki Evergreen.V1.Wiki.Slug
    | DeleteHostedWiki Evergreen.V1.Wiki.Slug String
    | RequestHostAdminDataExport
    | ImportHostAdminDataSnapshot String
    | RequestHostAdminWikiDataExport Evergreen.V1.Wiki.Slug
    | ImportHostAdminWikiDataSnapshot Evergreen.V1.Wiki.Slug String
    | ImportHostAdminWikiDataSnapshotAuto String


type BackendMsg
    = ToBackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Time.Posix


type ToFrontend
    = WikiCatalogResponse (Dict.Dict Evergreen.V1.Wiki.Slug Evergreen.V1.Wiki.CatalogEntry)
    | WikiFrontendDetailsResponse Evergreen.V1.Wiki.Slug (Maybe Evergreen.V1.Wiki.FrontendDetails)
    | PageFrontendDetailsResponse Evergreen.V1.Wiki.Slug Evergreen.V1.Page.Slug (Maybe Evergreen.V1.Page.FrontendDetails)
    | MyPendingSubmissionsResponse Evergreen.V1.Wiki.Slug (Result Evergreen.V1.Submission.MyPendingSubmissionsError (List Evergreen.V1.Submission.MyPendingSubmissionListItem))
    | ReviewQueueResponse Evergreen.V1.Wiki.Slug (Result Evergreen.V1.Submission.ReviewQueueError (List Evergreen.V1.Submission.ReviewQueueItem))
    | ReviewSubmissionDetailResponse Evergreen.V1.Wiki.Slug String (Result Evergreen.V1.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V1.SubmissionReviewDetail.SubmissionReviewDetail)
    | WikiUsersResponse Evergreen.V1.Wiki.Slug (Result Evergreen.V1.WikiAdminUsers.Error (List Evergreen.V1.WikiAdminUsers.ListedUser))
    | WikiAuditLogResponse Evergreen.V1.Wiki.Slug Evergreen.V1.WikiAuditLog.AuditLogFilter (Result Evergreen.V1.WikiAuditLog.Error (List Evergreen.V1.WikiAuditLog.AuditEvent))
    | PromoteContributorToTrustedResponse Evergreen.V1.Wiki.Slug (Result Evergreen.V1.WikiAdminUsers.PromoteContributorError ())
    | DemoteTrustedToContributorResponse Evergreen.V1.Wiki.Slug (Result Evergreen.V1.WikiAdminUsers.DemoteTrustedError ())
    | GrantWikiAdminResponse Evergreen.V1.Wiki.Slug (Result Evergreen.V1.WikiAdminUsers.GrantTrustedToAdminError ())
    | RevokeWikiAdminResponse Evergreen.V1.Wiki.Slug (Result Evergreen.V1.WikiAdminUsers.RevokeAdminError ())
    | SubmissionDetailsResponse Evergreen.V1.Wiki.Slug String (Result Evergreen.V1.Submission.DetailsError Evergreen.V1.Submission.ContributorView)
    | RegisterContributorResponse Evergreen.V1.Wiki.Slug (Result Evergreen.V1.ContributorAccount.RegisterContributorError Evergreen.V1.WikiRole.WikiRole)
    | LoginContributorResponse Evergreen.V1.Wiki.Slug (Result Evergreen.V1.ContributorAccount.LoginContributorError Evergreen.V1.WikiRole.WikiRole)
    | LogoutContributorResponse Evergreen.V1.Wiki.Slug
    | SubmitNewPageResponse Evergreen.V1.Wiki.Slug (Result Evergreen.V1.Submission.SubmitNewPageError Evergreen.V1.Submission.NewPageSubmitSuccess)
    | SubmitPageEditResponse Evergreen.V1.Wiki.Slug (Result Evergreen.V1.Submission.SubmitPageEditError Evergreen.V1.Submission.EditSubmitSuccess)
    | RequestPublishedPageDeletionResponse Evergreen.V1.Wiki.Slug (Result Evergreen.V1.Submission.RequestPublishedPageDeletionError Evergreen.V1.Submission.Id)
    | DeletePublishedPageImmediatelyResponse Evergreen.V1.Wiki.Slug (Result Evergreen.V1.Submission.DeletePublishedPageImmediatelyError ())
    | SaveNewPageDraftResponse Evergreen.V1.Wiki.Slug (Result Evergreen.V1.Submission.SaveNewPageDraftError Evergreen.V1.Submission.Id)
    | SavePageEditDraftResponse Evergreen.V1.Wiki.Slug (Result Evergreen.V1.Submission.SavePageEditDraftError Evergreen.V1.Submission.Id)
    | SavePageDeleteDraftResponse Evergreen.V1.Wiki.Slug (Result Evergreen.V1.Submission.SavePageDeleteDraftError Evergreen.V1.Submission.Id)
    | SubmitDraftForReviewResponse Evergreen.V1.Wiki.Slug String (Result Evergreen.V1.Submission.SubmitDraftForReviewError ())
    | WithdrawSubmissionResponse Evergreen.V1.Wiki.Slug String (Result Evergreen.V1.Submission.WithdrawSubmissionError ())
    | DeleteMySubmissionResponse Evergreen.V1.Wiki.Slug String (Result Evergreen.V1.Submission.DeleteMySubmissionError ())
    | ApproveSubmissionResponse Evergreen.V1.Wiki.Slug String (Result Evergreen.V1.Submission.ApproveSubmissionError ())
    | RejectSubmissionResponse Evergreen.V1.Wiki.Slug String (Result Evergreen.V1.Submission.RejectSubmissionError ())
    | RequestSubmissionChangesResponse Evergreen.V1.Wiki.Slug String (Result Evergreen.V1.Submission.RequestChangesSubmissionError ())
    | HostAdminLoginResponse (Result Evergreen.V1.HostAdmin.LoginError ())
    | HostAdminWikiListResponse (Result Evergreen.V1.HostAdmin.ProtectedError (List Evergreen.V1.Wiki.CatalogEntry))
    | HostAuditLogResponse Evergreen.V1.WikiAuditLog.HostAuditLogFilter (Result Evergreen.V1.HostAdmin.ProtectedError (List Evergreen.V1.WikiAuditLog.ScopedAuditEvent))
    | CreateHostedWikiResponse (Result Evergreen.V1.HostAdmin.CreateHostedWikiError Evergreen.V1.Wiki.CatalogEntry)
    | HostWikiDetailResponse Evergreen.V1.Wiki.Slug (Result Evergreen.V1.HostAdmin.HostWikiDetailError Evergreen.V1.Wiki.CatalogEntry)
    | UpdateHostedWikiMetadataResponse Evergreen.V1.Wiki.Slug (Result Evergreen.V1.HostAdmin.UpdateHostedWikiMetadataError Evergreen.V1.Wiki.CatalogEntry)
    | DeactivateHostedWikiResponse Evergreen.V1.Wiki.Slug (Result Evergreen.V1.HostAdmin.WikiLifecycleError Evergreen.V1.Wiki.CatalogEntry)
    | ReactivateHostedWikiResponse Evergreen.V1.Wiki.Slug (Result Evergreen.V1.HostAdmin.WikiLifecycleError Evergreen.V1.Wiki.CatalogEntry)
    | DeleteHostedWikiResponse Evergreen.V1.Wiki.Slug (Result Evergreen.V1.HostAdmin.DeleteHostedWikiError ())
    | HostAdminDataExportResponse (Result Evergreen.V1.HostAdmin.DataExportError String)
    | HostAdminDataImportResponse (Result Evergreen.V1.HostAdmin.DataImportError ())
    | HostAdminWikiDataExportResponse Evergreen.V1.Wiki.Slug (Result Evergreen.V1.HostAdmin.WikiDataExportError String)
    | HostAdminWikiDataImportResponse Evergreen.V1.Wiki.Slug (Result Evergreen.V1.HostAdmin.WikiDataImportError ())
    | HostAdminWikiDataImportAutoResponse (Result Evergreen.V1.HostAdmin.WikiDataImportError Evergreen.V1.Wiki.Slug)

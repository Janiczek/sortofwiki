module Evergreen.V2.Types exposing (..)

import Dict
import Effect.Browser
import Effect.Browser.Navigation
import Effect.File
import Effect.Lamdera
import Evergreen.V2.ColorTheme
import Evergreen.V2.ContributorAccount
import Evergreen.V2.ContributorWikiSession
import Evergreen.V2.HostAdmin
import Evergreen.V2.Page
import Evergreen.V2.Route
import Evergreen.V2.Store
import Evergreen.V2.Submission
import Evergreen.V2.SubmissionReviewDetail
import Evergreen.V2.Wiki
import Evergreen.V2.WikiAdminUsers
import Evergreen.V2.WikiAuditLog
import Evergreen.V2.WikiContributors
import Evergreen.V2.WikiRole
import Evergreen.V2.WikiUser
import RemoteData
import Set
import Time
import Url


type alias RegisterDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V2.ContributorAccount.RegisterContributorError ())
    }


type alias LoginDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V2.ContributorAccount.LoginContributorError ())
    }


type alias NewPageSubmitDraft =
    { pageSlug : String
    , pageSlugLockedFromQuery : Bool
    , markdownBody : String
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V2.Submission.SubmitNewPageError Evergreen.V2.Submission.NewPageSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V2.Submission.SaveNewPageDraftError Evergreen.V2.Submission.Id)
    }


type alias PageEditSubmitDraft =
    { markdownBody : String
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V2.Submission.SubmitPageEditError Evergreen.V2.Submission.EditSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V2.Submission.SavePageEditDraftError Evergreen.V2.Submission.Id)
    }


type alias PageDeleteSubmitDraft =
    { reasonText : String
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V2.Submission.PageDeleteFormError Evergreen.V2.Submission.PageDeleteFormSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V2.Submission.SavePageDeleteDraftError Evergreen.V2.Submission.Id)
    }


type alias ReviewApproveDraft =
    { inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V2.Submission.ApproveSubmissionError ())
    }


type ReviewDecision
    = ReviewDecisionApprove
    | ReviewDecisionRequestChanges
    | ReviewDecisionReject


type alias ReviewRejectDraft =
    { reasonText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V2.Submission.RejectSubmissionError ())
    }


type alias ReviewRequestChangesDraft =
    { guidanceText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V2.Submission.RequestChangesSubmissionError ())
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
    , lastResult : Maybe (Result Evergreen.V2.HostAdmin.LoginError ())
    }


type alias HostAdminCreateWikiDraft =
    { slug : String
    , name : String
    , initialAdminUsername : String
    , initialAdminPassword : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V2.HostAdmin.CreateHostedWikiError Evergreen.V2.Wiki.CatalogEntry)
    }


type alias HostAdminWikiDetailDraft =
    { wikiSlug : Evergreen.V2.Wiki.Slug
    , load : RemoteData.RemoteData () (Result Evergreen.V2.HostAdmin.HostWikiDetailError Evergreen.V2.Wiki.CatalogEntry)
    , slugDraft : String
    , nameDraft : String
    , summaryDraft : String
    , saveInFlight : Bool
    , lastSaveResult : Maybe (Result Evergreen.V2.HostAdmin.UpdateHostedWikiMetadataError ())
    , lifecycleInFlight : Bool
    , lastLifecycleResult : Maybe (Result Evergreen.V2.HostAdmin.WikiLifecycleError ())
    , deleteConfirmDraft : String
    , deleteInFlight : Bool
    , lastDeleteResult : Maybe (Result Evergreen.V2.HostAdmin.DeleteHostedWikiError ())
    }


type alias FrontendModel =
    { key : Effect.Browser.Navigation.Key
    , colorThemePreference : Evergreen.V2.ColorTheme.ColorThemePreference
    , systemColorTheme : Evergreen.V2.ColorTheme.ColorTheme
    , route : Evergreen.V2.Route.Route
    , navigationFragment : Maybe String
    , store : Evergreen.V2.Store.Store
    , contributorWikiSessions : Dict.Dict Evergreen.V2.Wiki.Slug Evergreen.V2.ContributorWikiSession.ContributorWikiSession
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
    , wikiAdminAuditFilterSelectedKindTags : List Evergreen.V2.WikiAuditLog.AuditEventKindFilterTag
    , wikiAdminAuditAppliedFilter : Evergreen.V2.WikiAuditLog.AuditLogFilter
    , hostAdminAuditFilterWikiDraft : String
    , hostAdminAuditFilterActorDraft : String
    , hostAdminAuditFilterPageDraft : String
    , hostAdminAuditFilterSelectedKindTags : List Evergreen.V2.WikiAuditLog.AuditEventKindFilterTag
    , hostAdminAuditAppliedFilter : Evergreen.V2.WikiAuditLog.HostAuditLogFilter
    , hostAdminAuditLog : RemoteData.RemoteData () (Result Evergreen.V2.HostAdmin.ProtectedError (List Evergreen.V2.WikiAuditLog.ScopedAuditEvent))
    , hostAdminLoginDraft : HostAdminLoginDraft
    , hostAdminCreateWikiDraft : HostAdminCreateWikiDraft
    , hostAdminWikiDetailDraft : HostAdminWikiDetailDraft
    , hostAdminWikis : RemoteData.RemoteData () (Result Evergreen.V2.HostAdmin.ProtectedError (List Evergreen.V2.Wiki.CatalogEntry))
    , hostAdminSessionAuthenticated : Bool
    , hostAdminExportInFlight : Bool
    , hostAdminImportInFlight : Bool
    , hostAdminBackupNotice : Maybe String
    , hostAdminWikiExportInFlightSlug : Maybe Evergreen.V2.Wiki.Slug
    , hostAdminWikiImportInFlightSlug : Maybe Evergreen.V2.Wiki.Slug
    , hostAdminWikiImportPendingSlug : Maybe Evergreen.V2.Wiki.Slug
    , hostAdminWikisNotice : Maybe String
    }


type alias BackendModel =
    { wikis : Dict.Dict Evergreen.V2.Wiki.Slug Evergreen.V2.Wiki.Wiki
    , contributors : Evergreen.V2.WikiContributors.Registry
    , contributorSessions : Evergreen.V2.WikiUser.SessionTable
    , hostSessions : Set.Set String
    , submissions : Dict.Dict String Evergreen.V2.Submission.Submission
    , nextSubmissionCounter : Int
    , wikiAuditEvents : Dict.Dict Evergreen.V2.Wiki.Slug (List Evergreen.V2.WikiAuditLog.AuditEvent)
    }


type FrontendMsg
    = UrlClicked Effect.Browser.UrlRequest
    | UrlChanged Url.Url
    | UrlFragmentScrollDone
    | ColorThemeToggled
    | ColorThemeFromJs (Maybe Evergreen.V2.ColorTheme.Incoming)
    | RegisterFormUsernameChanged String
    | RegisterFormPasswordChanged String
    | RegisterFormSubmitted
    | LoginFormUsernameChanged String
    | LoginFormPasswordChanged String
    | LoginFormSubmitted
    | ContributorLogoutWiki Evergreen.V2.Wiki.Slug
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
    | WikiAdminAuditFilterTypeTagToggled Evergreen.V2.WikiAuditLog.AuditEventKindFilterTag Bool
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
    | HostAdminAuditFilterTypeTagToggled Evergreen.V2.WikiAuditLog.AuditEventKindFilterTag Bool
    | HostAdminDataExportClicked
    | HostAdminDataImportPickRequested
    | HostAdminDataImportFileSelected Effect.File.File
    | HostAdminDataImportFileRead (Result () String)
    | HostAdminWikisDataImportPickRequested
    | HostAdminWikisDataImportFileSelected Effect.File.File
    | HostAdminWikisDataImportFileRead (Result () String)
    | HostAdminWikiDataExportClicked Evergreen.V2.Wiki.Slug
    | HostAdminWikiDataImportPickRequested Evergreen.V2.Wiki.Slug
    | HostAdminWikiDataImportFileSelected Effect.File.File
    | HostAdminWikiDataImportFileRead Evergreen.V2.Wiki.Slug (Result () String)


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
    | RequestWikiFrontendDetails Evergreen.V2.Wiki.Slug
    | RequestPageFrontendDetails Evergreen.V2.Wiki.Slug Evergreen.V2.Page.Slug
    | RequestMyPendingSubmissions Evergreen.V2.Wiki.Slug
    | RequestReviewQueue Evergreen.V2.Wiki.Slug
    | RequestReviewSubmissionDetail Evergreen.V2.Wiki.Slug String
    | RequestWikiUsers Evergreen.V2.Wiki.Slug
    | RequestWikiAuditLog Evergreen.V2.Wiki.Slug Evergreen.V2.WikiAuditLog.AuditLogFilter
    | PromoteContributorToTrusted Evergreen.V2.Wiki.Slug String
    | DemoteTrustedToContributor Evergreen.V2.Wiki.Slug String
    | GrantWikiAdmin Evergreen.V2.Wiki.Slug String
    | RevokeWikiAdmin Evergreen.V2.Wiki.Slug String
    | RequestSubmissionDetails Evergreen.V2.Wiki.Slug String
    | RegisterContributor Evergreen.V2.Wiki.Slug RegisterContributorPayload
    | LoginContributor Evergreen.V2.Wiki.Slug LoginContributorPayload
    | LogoutContributor Evergreen.V2.Wiki.Slug
    | SubmitNewPage Evergreen.V2.Wiki.Slug SubmitNewPagePayload
    | SubmitPageEdit Evergreen.V2.Wiki.Slug Evergreen.V2.Page.Slug String
    | RequestPublishedPageDeletion Evergreen.V2.Wiki.Slug Evergreen.V2.Page.Slug String
    | DeletePublishedPageImmediately Evergreen.V2.Wiki.Slug Evergreen.V2.Page.Slug String
    | SaveNewPageDraft
        Evergreen.V2.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , rawPageSlug : String
        , rawMarkdown : String
        }
    | SavePageEditDraft
        Evergreen.V2.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V2.Page.Slug
        , rawMarkdown : String
        }
    | SavePageDeleteDraft
        Evergreen.V2.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V2.Page.Slug
        , rawReason : String
        }
    | SubmitDraftForReview Evergreen.V2.Wiki.Slug String
    | WithdrawSubmission Evergreen.V2.Wiki.Slug String
    | DeleteMySubmission Evergreen.V2.Wiki.Slug String
    | ApproveSubmission Evergreen.V2.Wiki.Slug String
    | RejectSubmission Evergreen.V2.Wiki.Slug RejectSubmissionPayload
    | RequestSubmissionChanges Evergreen.V2.Wiki.Slug RequestSubmissionChangesPayload
    | HostAdminLogin String
    | RequestHostWikiList
    | RequestHostAuditLog Evergreen.V2.WikiAuditLog.HostAuditLogFilter
    | RequestHostWikiDetail Evergreen.V2.Wiki.Slug
    | CreateHostedWiki CreateHostedWikiPayload
    | UpdateHostedWikiMetadata Evergreen.V2.Wiki.Slug UpdateHostedWikiMetadataPayload
    | DeactivateHostedWiki Evergreen.V2.Wiki.Slug
    | ReactivateHostedWiki Evergreen.V2.Wiki.Slug
    | DeleteHostedWiki Evergreen.V2.Wiki.Slug String
    | RequestHostAdminDataExport
    | ImportHostAdminDataSnapshot String
    | RequestHostAdminWikiDataExport Evergreen.V2.Wiki.Slug
    | ImportHostAdminWikiDataSnapshot Evergreen.V2.Wiki.Slug String
    | ImportHostAdminWikiDataSnapshotAuto String


type BackendMsg
    = ToBackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Time.Posix


type ToFrontend
    = WikiCatalogResponse (Dict.Dict Evergreen.V2.Wiki.Slug Evergreen.V2.Wiki.CatalogEntry)
    | WikiFrontendDetailsResponse Evergreen.V2.Wiki.Slug (Maybe Evergreen.V2.Wiki.FrontendDetails)
    | PageFrontendDetailsResponse Evergreen.V2.Wiki.Slug Evergreen.V2.Page.Slug (Maybe Evergreen.V2.Page.FrontendDetails)
    | MyPendingSubmissionsResponse Evergreen.V2.Wiki.Slug (Result Evergreen.V2.Submission.MyPendingSubmissionsError (List Evergreen.V2.Submission.MyPendingSubmissionListItem))
    | ReviewQueueResponse Evergreen.V2.Wiki.Slug (Result Evergreen.V2.Submission.ReviewQueueError (List Evergreen.V2.Submission.ReviewQueueItem))
    | ReviewSubmissionDetailResponse Evergreen.V2.Wiki.Slug String (Result Evergreen.V2.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V2.SubmissionReviewDetail.SubmissionReviewDetail)
    | WikiUsersResponse Evergreen.V2.Wiki.Slug (Result Evergreen.V2.WikiAdminUsers.Error (List Evergreen.V2.WikiAdminUsers.ListedUser))
    | WikiAuditLogResponse Evergreen.V2.Wiki.Slug Evergreen.V2.WikiAuditLog.AuditLogFilter (Result Evergreen.V2.WikiAuditLog.Error (List Evergreen.V2.WikiAuditLog.AuditEvent))
    | PromoteContributorToTrustedResponse Evergreen.V2.Wiki.Slug (Result Evergreen.V2.WikiAdminUsers.PromoteContributorError ())
    | DemoteTrustedToContributorResponse Evergreen.V2.Wiki.Slug (Result Evergreen.V2.WikiAdminUsers.DemoteTrustedError ())
    | GrantWikiAdminResponse Evergreen.V2.Wiki.Slug (Result Evergreen.V2.WikiAdminUsers.GrantTrustedToAdminError ())
    | RevokeWikiAdminResponse Evergreen.V2.Wiki.Slug (Result Evergreen.V2.WikiAdminUsers.RevokeAdminError ())
    | SubmissionDetailsResponse Evergreen.V2.Wiki.Slug String (Result Evergreen.V2.Submission.DetailsError Evergreen.V2.Submission.ContributorView)
    | RegisterContributorResponse Evergreen.V2.Wiki.Slug (Result Evergreen.V2.ContributorAccount.RegisterContributorError Evergreen.V2.WikiRole.WikiRole)
    | LoginContributorResponse Evergreen.V2.Wiki.Slug (Result Evergreen.V2.ContributorAccount.LoginContributorError Evergreen.V2.WikiRole.WikiRole)
    | LogoutContributorResponse Evergreen.V2.Wiki.Slug
    | SubmitNewPageResponse Evergreen.V2.Wiki.Slug (Result Evergreen.V2.Submission.SubmitNewPageError Evergreen.V2.Submission.NewPageSubmitSuccess)
    | SubmitPageEditResponse Evergreen.V2.Wiki.Slug (Result Evergreen.V2.Submission.SubmitPageEditError Evergreen.V2.Submission.EditSubmitSuccess)
    | RequestPublishedPageDeletionResponse Evergreen.V2.Wiki.Slug (Result Evergreen.V2.Submission.RequestPublishedPageDeletionError Evergreen.V2.Submission.Id)
    | DeletePublishedPageImmediatelyResponse Evergreen.V2.Wiki.Slug (Result Evergreen.V2.Submission.DeletePublishedPageImmediatelyError ())
    | SaveNewPageDraftResponse Evergreen.V2.Wiki.Slug (Result Evergreen.V2.Submission.SaveNewPageDraftError Evergreen.V2.Submission.Id)
    | SavePageEditDraftResponse Evergreen.V2.Wiki.Slug (Result Evergreen.V2.Submission.SavePageEditDraftError Evergreen.V2.Submission.Id)
    | SavePageDeleteDraftResponse Evergreen.V2.Wiki.Slug (Result Evergreen.V2.Submission.SavePageDeleteDraftError Evergreen.V2.Submission.Id)
    | SubmitDraftForReviewResponse Evergreen.V2.Wiki.Slug String (Result Evergreen.V2.Submission.SubmitDraftForReviewError ())
    | WithdrawSubmissionResponse Evergreen.V2.Wiki.Slug String (Result Evergreen.V2.Submission.WithdrawSubmissionError ())
    | DeleteMySubmissionResponse Evergreen.V2.Wiki.Slug String (Result Evergreen.V2.Submission.DeleteMySubmissionError ())
    | ApproveSubmissionResponse Evergreen.V2.Wiki.Slug String (Result Evergreen.V2.Submission.ApproveSubmissionError ())
    | RejectSubmissionResponse Evergreen.V2.Wiki.Slug String (Result Evergreen.V2.Submission.RejectSubmissionError ())
    | RequestSubmissionChangesResponse Evergreen.V2.Wiki.Slug String (Result Evergreen.V2.Submission.RequestChangesSubmissionError ())
    | HostAdminLoginResponse (Result Evergreen.V2.HostAdmin.LoginError ())
    | HostAdminWikiListResponse (Result Evergreen.V2.HostAdmin.ProtectedError (List Evergreen.V2.Wiki.CatalogEntry))
    | HostAuditLogResponse Evergreen.V2.WikiAuditLog.HostAuditLogFilter (Result Evergreen.V2.HostAdmin.ProtectedError (List Evergreen.V2.WikiAuditLog.ScopedAuditEvent))
    | CreateHostedWikiResponse (Result Evergreen.V2.HostAdmin.CreateHostedWikiError Evergreen.V2.Wiki.CatalogEntry)
    | HostWikiDetailResponse Evergreen.V2.Wiki.Slug (Result Evergreen.V2.HostAdmin.HostWikiDetailError Evergreen.V2.Wiki.CatalogEntry)
    | UpdateHostedWikiMetadataResponse Evergreen.V2.Wiki.Slug (Result Evergreen.V2.HostAdmin.UpdateHostedWikiMetadataError Evergreen.V2.Wiki.CatalogEntry)
    | DeactivateHostedWikiResponse Evergreen.V2.Wiki.Slug (Result Evergreen.V2.HostAdmin.WikiLifecycleError Evergreen.V2.Wiki.CatalogEntry)
    | ReactivateHostedWikiResponse Evergreen.V2.Wiki.Slug (Result Evergreen.V2.HostAdmin.WikiLifecycleError Evergreen.V2.Wiki.CatalogEntry)
    | DeleteHostedWikiResponse Evergreen.V2.Wiki.Slug (Result Evergreen.V2.HostAdmin.DeleteHostedWikiError ())
    | HostAdminDataExportResponse (Result Evergreen.V2.HostAdmin.DataExportError String)
    | HostAdminDataImportResponse (Result Evergreen.V2.HostAdmin.DataImportError ())
    | HostAdminWikiDataExportResponse Evergreen.V2.Wiki.Slug (Result Evergreen.V2.HostAdmin.WikiDataExportError String)
    | HostAdminWikiDataImportResponse Evergreen.V2.Wiki.Slug (Result Evergreen.V2.HostAdmin.WikiDataImportError ())
    | HostAdminWikiDataImportAutoResponse (Result Evergreen.V2.HostAdmin.WikiDataImportError Evergreen.V2.Wiki.Slug)

module Evergreen.V4.Types exposing (..)

import Dict
import Effect.Browser
import Effect.Browser.Navigation
import Effect.File
import Effect.Lamdera
import Evergreen.V4.ColorTheme
import Evergreen.V4.ContributorAccount
import Evergreen.V4.ContributorWikiSession
import Evergreen.V4.HostAdmin
import Evergreen.V4.Page
import Evergreen.V4.Route
import Evergreen.V4.Store
import Evergreen.V4.Submission
import Evergreen.V4.SubmissionReviewDetail
import Evergreen.V4.Wiki
import Evergreen.V4.WikiAdminUsers
import Evergreen.V4.WikiAuditLog
import Evergreen.V4.WikiContributors
import Evergreen.V4.WikiRole
import Evergreen.V4.WikiUser
import RemoteData
import Set
import Time
import Url


type alias RegisterDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V4.ContributorAccount.RegisterContributorError ())
    }


type alias LoginDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V4.ContributorAccount.LoginContributorError ())
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
    , lastResult : Maybe (Result Evergreen.V4.Submission.SubmitNewPageError Evergreen.V4.Submission.NewPageSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V4.Submission.SaveNewPageDraftError Evergreen.V4.Submission.Id)
    }


type alias PageEditSubmitDraft =
    { markdownBody : String
    , tagsInput : String
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V4.Submission.SubmitPageEditError Evergreen.V4.Submission.EditSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V4.Submission.SavePageEditDraftError Evergreen.V4.Submission.Id)
    }


type alias PageDeleteSubmitDraft =
    { reasonText : String
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V4.Submission.PageDeleteFormError Evergreen.V4.Submission.PageDeleteFormSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V4.Submission.SavePageDeleteDraftError Evergreen.V4.Submission.Id)
    }


type alias ReviewApproveDraft =
    { inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V4.Submission.ApproveSubmissionError ())
    }


type ReviewDecision
    = ReviewDecisionApprove
    | ReviewDecisionRequestChanges
    | ReviewDecisionReject


type alias ReviewRejectDraft =
    { reasonText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V4.Submission.RejectSubmissionError ())
    }


type alias ReviewRequestChangesDraft =
    { guidanceText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V4.Submission.RequestChangesSubmissionError ())
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
    , lastResult : Maybe (Result Evergreen.V4.HostAdmin.LoginError ())
    }


type alias HostAdminCreateWikiDraft =
    { slug : String
    , name : String
    , initialAdminUsername : String
    , initialAdminPassword : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V4.HostAdmin.CreateHostedWikiError Evergreen.V4.Wiki.CatalogEntry)
    }


type alias HostAdminWikiDetailDraft =
    { wikiSlug : Evergreen.V4.Wiki.Slug
    , load : RemoteData.RemoteData () (Result Evergreen.V4.HostAdmin.HostWikiDetailError Evergreen.V4.Wiki.CatalogEntry)
    , slugDraft : String
    , nameDraft : String
    , summaryDraft : String
    , saveInFlight : Bool
    , lastSaveResult : Maybe (Result Evergreen.V4.HostAdmin.UpdateHostedWikiMetadataError ())
    , lifecycleInFlight : Bool
    , lastLifecycleResult : Maybe (Result Evergreen.V4.HostAdmin.WikiLifecycleError ())
    , deleteConfirmDraft : String
    , deleteInFlight : Bool
    , lastDeleteResult : Maybe (Result Evergreen.V4.HostAdmin.DeleteHostedWikiError ())
    }


type alias FrontendModel =
    { key : Effect.Browser.Navigation.Key
    , colorThemePreference : Evergreen.V4.ColorTheme.ColorThemePreference
    , systemColorTheme : Evergreen.V4.ColorTheme.ColorTheme
    , route : Evergreen.V4.Route.Route
    , navigationFragment : Maybe String
    , store : Evergreen.V4.Store.Store
    , contributorWikiSessions : Dict.Dict Evergreen.V4.Wiki.Slug Evergreen.V4.ContributorWikiSession.ContributorWikiSession
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
    , wikiAdminAuditFilterSelectedKindTags : List Evergreen.V4.WikiAuditLog.AuditEventKindFilterTag
    , wikiAdminAuditAppliedFilter : Evergreen.V4.WikiAuditLog.AuditLogFilter
    , hostAdminAuditFilterWikiDraft : String
    , hostAdminAuditFilterActorDraft : String
    , hostAdminAuditFilterPageDraft : String
    , hostAdminAuditFilterSelectedKindTags : List Evergreen.V4.WikiAuditLog.AuditEventKindFilterTag
    , hostAdminAuditAppliedFilter : Evergreen.V4.WikiAuditLog.HostAuditLogFilter
    , hostAdminAuditLog : RemoteData.RemoteData () (Result Evergreen.V4.HostAdmin.ProtectedError (List Evergreen.V4.WikiAuditLog.ScopedAuditEvent))
    , hostAdminLoginDraft : HostAdminLoginDraft
    , hostAdminCreateWikiDraft : HostAdminCreateWikiDraft
    , hostAdminWikiDetailDraft : HostAdminWikiDetailDraft
    , hostAdminWikis : RemoteData.RemoteData () (Result Evergreen.V4.HostAdmin.ProtectedError (List Evergreen.V4.Wiki.CatalogEntry))
    , hostAdminSessionAuthenticated : Bool
    , hostAdminExportInFlight : Bool
    , hostAdminImportInFlight : Bool
    , hostAdminBackupNotice : Maybe String
    , hostAdminWikiExportInFlightSlug : Maybe Evergreen.V4.Wiki.Slug
    , hostAdminWikiImportInFlightSlug : Maybe Evergreen.V4.Wiki.Slug
    , hostAdminWikiImportPendingSlug : Maybe Evergreen.V4.Wiki.Slug
    , hostAdminWikisNotice : Maybe String
    }


type alias BackendModel =
    { wikis : Dict.Dict Evergreen.V4.Wiki.Slug Evergreen.V4.Wiki.Wiki
    , contributors : Evergreen.V4.WikiContributors.Registry
    , contributorSessions : Evergreen.V4.WikiUser.SessionTable
    , hostSessions : Set.Set String
    , submissions : Dict.Dict String Evergreen.V4.Submission.Submission
    , nextSubmissionCounter : Int
    , wikiAuditEvents : Dict.Dict Evergreen.V4.Wiki.Slug (List Evergreen.V4.WikiAuditLog.AuditEvent)
    }


type FrontendMsg
    = UrlClicked Effect.Browser.UrlRequest
    | UrlChanged Url.Url
    | UrlFragmentScrollDone
    | ColorThemeToggled
    | ColorThemeFromJs (Maybe Evergreen.V4.ColorTheme.Incoming)
    | RegisterFormUsernameChanged String
    | RegisterFormPasswordChanged String
    | RegisterFormSubmitted
    | LoginFormUsernameChanged String
    | LoginFormPasswordChanged String
    | LoginFormSubmitted
    | ContributorLogoutWiki Evergreen.V4.Wiki.Slug
    | NewPageSubmitMarkdownChanged String
    | NewPageSubmitSlugChanged String
    | NewPageSubmitTagsChanged String
    | NewPageSubmitFormSubmitted
    | PageEditSubmitMarkdownChanged String
    | PageEditSubmitTagsChanged String
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
    | WikiAdminAuditFilterTypeTagToggled Evergreen.V4.WikiAuditLog.AuditEventKindFilterTag Bool
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
    | HostAdminAuditFilterTypeTagToggled Evergreen.V4.WikiAuditLog.AuditEventKindFilterTag Bool
    | HostAdminDataExportClicked
    | HostAdminDataImportPickRequested
    | HostAdminDataImportFileSelected Effect.File.File
    | HostAdminDataImportFileRead (Result () String)
    | HostAdminWikisDataImportPickRequested
    | HostAdminWikisDataImportFileSelected Effect.File.File
    | HostAdminWikisDataImportFileRead (Result () String)
    | HostAdminWikiDataExportClicked Evergreen.V4.Wiki.Slug
    | HostAdminWikiDataImportPickRequested Evergreen.V4.Wiki.Slug
    | HostAdminWikiDataImportFileSelected Effect.File.File
    | HostAdminWikiDataImportFileRead Evergreen.V4.Wiki.Slug (Result () String)


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
    | RequestWikiFrontendDetails Evergreen.V4.Wiki.Slug
    | RequestPageFrontendDetails Evergreen.V4.Wiki.Slug Evergreen.V4.Page.Slug
    | RequestMyPendingSubmissions Evergreen.V4.Wiki.Slug
    | RequestReviewQueue Evergreen.V4.Wiki.Slug
    | RequestReviewSubmissionDetail Evergreen.V4.Wiki.Slug String
    | RequestWikiUsers Evergreen.V4.Wiki.Slug
    | RequestWikiAuditLog Evergreen.V4.Wiki.Slug Evergreen.V4.WikiAuditLog.AuditLogFilter
    | PromoteContributorToTrusted Evergreen.V4.Wiki.Slug String
    | DemoteTrustedToContributor Evergreen.V4.Wiki.Slug String
    | GrantWikiAdmin Evergreen.V4.Wiki.Slug String
    | RevokeWikiAdmin Evergreen.V4.Wiki.Slug String
    | RequestSubmissionDetails Evergreen.V4.Wiki.Slug String
    | RegisterContributor Evergreen.V4.Wiki.Slug RegisterContributorPayload
    | LoginContributor Evergreen.V4.Wiki.Slug LoginContributorPayload
    | LogoutContributor Evergreen.V4.Wiki.Slug
    | SubmitNewPage Evergreen.V4.Wiki.Slug SubmitNewPagePayload
    | SubmitPageEdit Evergreen.V4.Wiki.Slug Evergreen.V4.Page.Slug String String
    | RequestPublishedPageDeletion Evergreen.V4.Wiki.Slug Evergreen.V4.Page.Slug String
    | DeletePublishedPageImmediately Evergreen.V4.Wiki.Slug Evergreen.V4.Page.Slug String
    | SaveNewPageDraft
        Evergreen.V4.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , rawPageSlug : String
        , rawMarkdown : String
        , rawTags : String
        }
    | SavePageEditDraft
        Evergreen.V4.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V4.Page.Slug
        , rawMarkdown : String
        , rawTags : String
        }
    | SavePageDeleteDraft
        Evergreen.V4.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V4.Page.Slug
        , rawReason : String
        }
    | SubmitDraftForReview Evergreen.V4.Wiki.Slug String
    | WithdrawSubmission Evergreen.V4.Wiki.Slug String
    | DeleteMySubmission Evergreen.V4.Wiki.Slug String
    | ApproveSubmission Evergreen.V4.Wiki.Slug String
    | RejectSubmission Evergreen.V4.Wiki.Slug RejectSubmissionPayload
    | RequestSubmissionChanges Evergreen.V4.Wiki.Slug RequestSubmissionChangesPayload
    | HostAdminLogin String
    | RequestHostWikiList
    | RequestHostAuditLog Evergreen.V4.WikiAuditLog.HostAuditLogFilter
    | RequestHostWikiDetail Evergreen.V4.Wiki.Slug
    | CreateHostedWiki CreateHostedWikiPayload
    | UpdateHostedWikiMetadata Evergreen.V4.Wiki.Slug UpdateHostedWikiMetadataPayload
    | DeactivateHostedWiki Evergreen.V4.Wiki.Slug
    | ReactivateHostedWiki Evergreen.V4.Wiki.Slug
    | DeleteHostedWiki Evergreen.V4.Wiki.Slug String
    | RequestHostAdminDataExport
    | ImportHostAdminDataSnapshot String
    | RequestHostAdminWikiDataExport Evergreen.V4.Wiki.Slug
    | ImportHostAdminWikiDataSnapshot Evergreen.V4.Wiki.Slug String
    | ImportHostAdminWikiDataSnapshotAuto String


type BackendMsg
    = ToBackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Time.Posix


type ToFrontend
    = WikiCatalogResponse (Dict.Dict Evergreen.V4.Wiki.Slug Evergreen.V4.Wiki.CatalogEntry)
    | WikiFrontendDetailsResponse Evergreen.V4.Wiki.Slug (Maybe Evergreen.V4.Wiki.FrontendDetails)
    | PageFrontendDetailsResponse Evergreen.V4.Wiki.Slug Evergreen.V4.Page.Slug (Maybe Evergreen.V4.Page.FrontendDetails)
    | MyPendingSubmissionsResponse Evergreen.V4.Wiki.Slug (Result Evergreen.V4.Submission.MyPendingSubmissionsError (List Evergreen.V4.Submission.MyPendingSubmissionListItem))
    | ReviewQueueResponse Evergreen.V4.Wiki.Slug (Result Evergreen.V4.Submission.ReviewQueueError (List Evergreen.V4.Submission.ReviewQueueItem))
    | ReviewSubmissionDetailResponse Evergreen.V4.Wiki.Slug String (Result Evergreen.V4.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V4.SubmissionReviewDetail.SubmissionReviewDetail)
    | WikiUsersResponse Evergreen.V4.Wiki.Slug (Result Evergreen.V4.WikiAdminUsers.Error (List Evergreen.V4.WikiAdminUsers.ListedUser))
    | WikiAuditLogResponse Evergreen.V4.Wiki.Slug Evergreen.V4.WikiAuditLog.AuditLogFilter (Result Evergreen.V4.WikiAuditLog.Error (List Evergreen.V4.WikiAuditLog.AuditEvent))
    | PromoteContributorToTrustedResponse Evergreen.V4.Wiki.Slug (Result Evergreen.V4.WikiAdminUsers.PromoteContributorError ())
    | DemoteTrustedToContributorResponse Evergreen.V4.Wiki.Slug (Result Evergreen.V4.WikiAdminUsers.DemoteTrustedError ())
    | GrantWikiAdminResponse Evergreen.V4.Wiki.Slug (Result Evergreen.V4.WikiAdminUsers.GrantTrustedToAdminError ())
    | RevokeWikiAdminResponse Evergreen.V4.Wiki.Slug (Result Evergreen.V4.WikiAdminUsers.RevokeAdminError ())
    | SubmissionDetailsResponse Evergreen.V4.Wiki.Slug String (Result Evergreen.V4.Submission.DetailsError Evergreen.V4.Submission.ContributorView)
    | RegisterContributorResponse Evergreen.V4.Wiki.Slug (Result Evergreen.V4.ContributorAccount.RegisterContributorError Evergreen.V4.WikiRole.WikiRole)
    | LoginContributorResponse Evergreen.V4.Wiki.Slug (Result Evergreen.V4.ContributorAccount.LoginContributorError Evergreen.V4.WikiRole.WikiRole)
    | LogoutContributorResponse Evergreen.V4.Wiki.Slug
    | SubmitNewPageResponse Evergreen.V4.Wiki.Slug (Result Evergreen.V4.Submission.SubmitNewPageError Evergreen.V4.Submission.NewPageSubmitSuccess)
    | SubmitPageEditResponse Evergreen.V4.Wiki.Slug (Result Evergreen.V4.Submission.SubmitPageEditError Evergreen.V4.Submission.EditSubmitSuccess)
    | RequestPublishedPageDeletionResponse Evergreen.V4.Wiki.Slug (Result Evergreen.V4.Submission.RequestPublishedPageDeletionError Evergreen.V4.Submission.Id)
    | DeletePublishedPageImmediatelyResponse Evergreen.V4.Wiki.Slug (Result Evergreen.V4.Submission.DeletePublishedPageImmediatelyError ())
    | SaveNewPageDraftResponse Evergreen.V4.Wiki.Slug (Result Evergreen.V4.Submission.SaveNewPageDraftError Evergreen.V4.Submission.Id)
    | SavePageEditDraftResponse Evergreen.V4.Wiki.Slug (Result Evergreen.V4.Submission.SavePageEditDraftError Evergreen.V4.Submission.Id)
    | SavePageDeleteDraftResponse Evergreen.V4.Wiki.Slug (Result Evergreen.V4.Submission.SavePageDeleteDraftError Evergreen.V4.Submission.Id)
    | SubmitDraftForReviewResponse Evergreen.V4.Wiki.Slug String (Result Evergreen.V4.Submission.SubmitDraftForReviewError ())
    | WithdrawSubmissionResponse Evergreen.V4.Wiki.Slug String (Result Evergreen.V4.Submission.WithdrawSubmissionError ())
    | DeleteMySubmissionResponse Evergreen.V4.Wiki.Slug String (Result Evergreen.V4.Submission.DeleteMySubmissionError ())
    | ApproveSubmissionResponse Evergreen.V4.Wiki.Slug String (Result Evergreen.V4.Submission.ApproveSubmissionError ())
    | RejectSubmissionResponse Evergreen.V4.Wiki.Slug String (Result Evergreen.V4.Submission.RejectSubmissionError ())
    | RequestSubmissionChangesResponse Evergreen.V4.Wiki.Slug String (Result Evergreen.V4.Submission.RequestChangesSubmissionError ())
    | HostAdminLoginResponse (Result Evergreen.V4.HostAdmin.LoginError ())
    | HostAdminWikiListResponse (Result Evergreen.V4.HostAdmin.ProtectedError (List Evergreen.V4.Wiki.CatalogEntry))
    | HostAuditLogResponse Evergreen.V4.WikiAuditLog.HostAuditLogFilter (Result Evergreen.V4.HostAdmin.ProtectedError (List Evergreen.V4.WikiAuditLog.ScopedAuditEvent))
    | CreateHostedWikiResponse (Result Evergreen.V4.HostAdmin.CreateHostedWikiError Evergreen.V4.Wiki.CatalogEntry)
    | HostWikiDetailResponse Evergreen.V4.Wiki.Slug (Result Evergreen.V4.HostAdmin.HostWikiDetailError Evergreen.V4.Wiki.CatalogEntry)
    | UpdateHostedWikiMetadataResponse Evergreen.V4.Wiki.Slug (Result Evergreen.V4.HostAdmin.UpdateHostedWikiMetadataError Evergreen.V4.Wiki.CatalogEntry)
    | DeactivateHostedWikiResponse Evergreen.V4.Wiki.Slug (Result Evergreen.V4.HostAdmin.WikiLifecycleError Evergreen.V4.Wiki.CatalogEntry)
    | ReactivateHostedWikiResponse Evergreen.V4.Wiki.Slug (Result Evergreen.V4.HostAdmin.WikiLifecycleError Evergreen.V4.Wiki.CatalogEntry)
    | DeleteHostedWikiResponse Evergreen.V4.Wiki.Slug (Result Evergreen.V4.HostAdmin.DeleteHostedWikiError ())
    | HostAdminDataExportResponse (Result Evergreen.V4.HostAdmin.DataExportError String)
    | HostAdminDataImportResponse (Result Evergreen.V4.HostAdmin.DataImportError ())
    | HostAdminWikiDataExportResponse Evergreen.V4.Wiki.Slug (Result Evergreen.V4.HostAdmin.WikiDataExportError String)
    | HostAdminWikiDataImportResponse Evergreen.V4.Wiki.Slug (Result Evergreen.V4.HostAdmin.WikiDataImportError ())
    | HostAdminWikiDataImportAutoResponse (Result Evergreen.V4.HostAdmin.WikiDataImportError Evergreen.V4.Wiki.Slug)

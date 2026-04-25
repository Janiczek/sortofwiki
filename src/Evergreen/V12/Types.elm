module Evergreen.V12.Types exposing (..)

import Dict
import Effect.Browser
import Effect.Browser.Navigation
import Effect.File
import Effect.Lamdera
import Evergreen.V12.ColorTheme
import Evergreen.V12.ContributorAccount
import Evergreen.V12.ContributorWikiSession
import Evergreen.V12.HostAdmin
import Evergreen.V12.Page
import Evergreen.V12.PendingReviewCount
import Evergreen.V12.Route
import Evergreen.V12.Store
import Evergreen.V12.Submission
import Evergreen.V12.SubmissionReviewDetail
import Evergreen.V12.Wiki
import Evergreen.V12.WikiAdminUsers
import Evergreen.V12.WikiAuditLog
import Evergreen.V12.WikiContributors
import Evergreen.V12.WikiFrontendSubscription
import Evergreen.V12.WikiRole
import Evergreen.V12.WikiUser
import RemoteData
import Set
import Time
import Url


type alias RegisterDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V12.ContributorAccount.RegisterContributorError ())
    }


type alias LoginDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V12.ContributorAccount.LoginContributorError ())
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
    , lastResult : Maybe (Result Evergreen.V12.Submission.SubmitNewPageError Evergreen.V12.Submission.NewPageSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V12.Submission.SaveNewPageDraftError Evergreen.V12.Submission.Id)
    }


type alias PageEditSubmitDraft =
    { markdownBody : String
    , tagsInput : String
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V12.Submission.SubmitPageEditError Evergreen.V12.Submission.EditSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V12.Submission.SavePageEditDraftError Evergreen.V12.Submission.Id)
    }


type alias PageDeleteSubmitDraft =
    { reasonText : String
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V12.Submission.PageDeleteFormError Evergreen.V12.Submission.PageDeleteFormSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V12.Submission.SavePageDeleteDraftError Evergreen.V12.Submission.Id)
    }


type alias ReviewApproveDraft =
    { inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V12.Submission.ApproveSubmissionError ())
    }


type ReviewDecision
    = ReviewDecisionApprove
    | ReviewDecisionRequestChanges
    | ReviewDecisionReject


type alias ReviewRejectDraft =
    { reasonText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V12.Submission.RejectSubmissionError ())
    }


type alias ReviewRequestChangesDraft =
    { guidanceText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V12.Submission.RequestChangesSubmissionError ())
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
    , lastResult : Maybe (Result Evergreen.V12.HostAdmin.LoginError ())
    }


type alias HostAdminCreateWikiDraft =
    { slug : String
    , name : String
    , initialAdminUsername : String
    , initialAdminPassword : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V12.HostAdmin.CreateHostedWikiError Evergreen.V12.Wiki.CatalogEntry)
    }


type alias HostAdminWikiDetailDraft =
    { wikiSlug : Evergreen.V12.Wiki.Slug
    , load : RemoteData.RemoteData () (Result Evergreen.V12.HostAdmin.HostWikiDetailError Evergreen.V12.Wiki.CatalogEntry)
    , slugDraft : String
    , nameDraft : String
    , summaryDraft : String
    , saveInFlight : Bool
    , lastSaveResult : Maybe (Result Evergreen.V12.HostAdmin.UpdateHostedWikiMetadataError ())
    , lifecycleInFlight : Bool
    , lastLifecycleResult : Maybe (Result Evergreen.V12.HostAdmin.WikiLifecycleError ())
    , deleteConfirmDraft : String
    , deleteInFlight : Bool
    , lastDeleteResult : Maybe (Result Evergreen.V12.HostAdmin.DeleteHostedWikiError ())
    }


type alias FrontendModel =
    { key : Effect.Browser.Navigation.Key
    , colorThemePreference : Evergreen.V12.ColorTheme.ColorThemePreference
    , systemColorTheme : Evergreen.V12.ColorTheme.ColorTheme
    , route : Evergreen.V12.Route.Route
    , navigationFragment : Maybe String
    , store : Evergreen.V12.Store.Store
    , contributorWikiSessions : Dict.Dict Evergreen.V12.Wiki.Slug Evergreen.V12.ContributorWikiSession.ContributorWikiSession
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
    , wikiAdminAuditFilterSelectedKindTags : List Evergreen.V12.WikiAuditLog.AuditEventKindFilterTag
    , wikiAdminAuditAppliedFilter : Evergreen.V12.WikiAuditLog.AuditLogFilter
    , hostAdminAuditFilterWikiDraft : String
    , hostAdminAuditFilterActorDraft : String
    , hostAdminAuditFilterPageDraft : String
    , hostAdminAuditFilterSelectedKindTags : List Evergreen.V12.WikiAuditLog.AuditEventKindFilterTag
    , hostAdminAuditAppliedFilter : Evergreen.V12.WikiAuditLog.HostAuditLogFilter
    , hostAdminAuditLog : RemoteData.RemoteData () (Result Evergreen.V12.HostAdmin.ProtectedError (List Evergreen.V12.WikiAuditLog.ScopedAuditEvent))
    , hostAdminLoginDraft : HostAdminLoginDraft
    , hostAdminCreateWikiDraft : HostAdminCreateWikiDraft
    , hostAdminWikiDetailDraft : HostAdminWikiDetailDraft
    , hostAdminWikis : RemoteData.RemoteData () (Result Evergreen.V12.HostAdmin.ProtectedError (List Evergreen.V12.Wiki.CatalogEntry))
    , hostAdminSessionAuthenticated : Bool
    , hostAdminExportInFlight : Bool
    , hostAdminImportInFlight : Bool
    , hostAdminBackupNotice : Maybe String
    , hostAdminWikiExportInFlightSlug : Maybe Evergreen.V12.Wiki.Slug
    , hostAdminWikiImportInFlightSlug : Maybe Evergreen.V12.Wiki.Slug
    , hostAdminWikiImportPendingSlug : Maybe Evergreen.V12.Wiki.Slug
    , hostAdminWikisNotice : Maybe String
    }


type alias BackendModel =
    { wikis : Dict.Dict Evergreen.V12.Wiki.Slug Evergreen.V12.Wiki.Wiki
    , contributors : Evergreen.V12.WikiContributors.Registry
    , contributorSessions : Evergreen.V12.WikiUser.SessionTable
    , hostSessions : Set.Set String
    , submissions : Dict.Dict String Evergreen.V12.Submission.Submission
    , nextSubmissionCounter : Int
    , wikiAuditEvents : Dict.Dict Evergreen.V12.Wiki.Slug (List Evergreen.V12.WikiAuditLog.AuditEvent)
    , pendingReviewCounts : Dict.Dict Evergreen.V12.Wiki.Slug Int
    , pendingReviewClients : Evergreen.V12.PendingReviewCount.PendingReviewClientSets
    , wikiFrontendClients : Evergreen.V12.WikiFrontendSubscription.WikiFrontendClientSets
    }


type FrontendMsg
    = UrlClicked Effect.Browser.UrlRequest
    | UrlChanged Url.Url
    | UrlFragmentScrollDone
    | ColorThemeToggled
    | ColorThemeFromJs (Maybe Evergreen.V12.ColorTheme.Incoming)
    | RegisterFormUsernameChanged String
    | RegisterFormPasswordChanged String
    | RegisterFormSubmitted
    | LoginFormUsernameChanged String
    | LoginFormPasswordChanged String
    | LoginFormSubmitted
    | ContributorLogoutWiki Evergreen.V12.Wiki.Slug
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
    | WikiAdminAuditFilterTypeTagToggled Evergreen.V12.WikiAuditLog.AuditEventKindFilterTag Bool
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
    | HostAdminAuditFilterTypeTagToggled Evergreen.V12.WikiAuditLog.AuditEventKindFilterTag Bool
    | HostAdminDataExportClicked
    | HostAdminDataImportPickRequested
    | HostAdminDataImportFileSelected Effect.File.File
    | HostAdminDataImportFileRead (Result () String)
    | HostAdminWikisDataImportPickRequested
    | HostAdminWikisDataImportFileSelected Effect.File.File
    | HostAdminWikisDataImportFileRead (Result () String)
    | HostAdminWikiDataExportClicked Evergreen.V12.Wiki.Slug
    | HostAdminWikiDataImportPickRequested Evergreen.V12.Wiki.Slug
    | HostAdminWikiDataImportFileSelected Effect.File.File
    | HostAdminWikiDataImportFileRead Evergreen.V12.Wiki.Slug (Result () String)


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
    | RequestWikiFrontendDetails Evergreen.V12.Wiki.Slug
    | RequestPageFrontendDetails Evergreen.V12.Wiki.Slug Evergreen.V12.Page.Slug
    | RequestMyPendingSubmissions Evergreen.V12.Wiki.Slug
    | RequestReviewQueue Evergreen.V12.Wiki.Slug
    | RequestReviewSubmissionDetail Evergreen.V12.Wiki.Slug String
    | RequestWikiUsers Evergreen.V12.Wiki.Slug
    | RequestWikiAuditLog Evergreen.V12.Wiki.Slug Evergreen.V12.WikiAuditLog.AuditLogFilter
    | PromoteContributorToTrusted Evergreen.V12.Wiki.Slug String
    | DemoteTrustedToContributor Evergreen.V12.Wiki.Slug String
    | GrantWikiAdmin Evergreen.V12.Wiki.Slug String
    | RevokeWikiAdmin Evergreen.V12.Wiki.Slug String
    | RequestSubmissionDetails Evergreen.V12.Wiki.Slug String
    | RegisterContributor Evergreen.V12.Wiki.Slug RegisterContributorPayload
    | LoginContributor Evergreen.V12.Wiki.Slug LoginContributorPayload
    | LogoutContributor Evergreen.V12.Wiki.Slug
    | SubmitNewPage Evergreen.V12.Wiki.Slug SubmitNewPagePayload
    | SubmitPageEdit Evergreen.V12.Wiki.Slug Evergreen.V12.Page.Slug String String
    | RequestPublishedPageDeletion Evergreen.V12.Wiki.Slug Evergreen.V12.Page.Slug String
    | DeletePublishedPageImmediately Evergreen.V12.Wiki.Slug Evergreen.V12.Page.Slug String
    | SaveNewPageDraft
        Evergreen.V12.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , rawPageSlug : String
        , rawMarkdown : String
        , rawTags : String
        }
    | SavePageEditDraft
        Evergreen.V12.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V12.Page.Slug
        , rawMarkdown : String
        , rawTags : String
        }
    | SavePageDeleteDraft
        Evergreen.V12.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V12.Page.Slug
        , rawReason : String
        }
    | SubmitDraftForReview Evergreen.V12.Wiki.Slug String
    | WithdrawSubmission Evergreen.V12.Wiki.Slug String
    | DeleteMySubmission Evergreen.V12.Wiki.Slug String
    | ApproveSubmission Evergreen.V12.Wiki.Slug String
    | RejectSubmission Evergreen.V12.Wiki.Slug RejectSubmissionPayload
    | RequestSubmissionChanges Evergreen.V12.Wiki.Slug RequestSubmissionChangesPayload
    | HostAdminLogin String
    | RequestHostWikiList
    | RequestHostAuditLog Evergreen.V12.WikiAuditLog.HostAuditLogFilter
    | RequestHostWikiDetail Evergreen.V12.Wiki.Slug
    | CreateHostedWiki CreateHostedWikiPayload
    | UpdateHostedWikiMetadata Evergreen.V12.Wiki.Slug UpdateHostedWikiMetadataPayload
    | DeactivateHostedWiki Evergreen.V12.Wiki.Slug
    | ReactivateHostedWiki Evergreen.V12.Wiki.Slug
    | DeleteHostedWiki Evergreen.V12.Wiki.Slug String
    | RequestHostAdminDataExport
    | ImportHostAdminDataSnapshot String
    | RequestHostAdminWikiDataExport Evergreen.V12.Wiki.Slug
    | ImportHostAdminWikiDataSnapshot Evergreen.V12.Wiki.Slug String
    | ImportHostAdminWikiDataSnapshotAuto String


type BackendMsg
    = ToBackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Time.Posix


type ToFrontend
    = WikiCatalogResponse (Dict.Dict Evergreen.V12.Wiki.Slug Evergreen.V12.Wiki.CatalogEntry)
    | PendingReviewCountUpdated Evergreen.V12.Wiki.Slug Int
    | WikiFrontendDetailsResponse Evergreen.V12.Wiki.Slug (Maybe Evergreen.V12.Wiki.FrontendDetails)
    | PageFrontendDetailsResponse Evergreen.V12.Wiki.Slug Evergreen.V12.Page.Slug (Maybe Evergreen.V12.Page.FrontendDetails)
    | MyPendingSubmissionsResponse Evergreen.V12.Wiki.Slug (Result Evergreen.V12.Submission.MyPendingSubmissionsError (List Evergreen.V12.Submission.MyPendingSubmissionListItem))
    | ReviewQueueResponse Evergreen.V12.Wiki.Slug (Result Evergreen.V12.Submission.ReviewQueueError (List Evergreen.V12.Submission.ReviewQueueItem))
    | ReviewSubmissionDetailResponse Evergreen.V12.Wiki.Slug String (Result Evergreen.V12.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V12.SubmissionReviewDetail.SubmissionReviewDetail)
    | WikiUsersResponse Evergreen.V12.Wiki.Slug (Result Evergreen.V12.WikiAdminUsers.Error (List Evergreen.V12.WikiAdminUsers.ListedUser))
    | WikiAuditLogResponse Evergreen.V12.Wiki.Slug Evergreen.V12.WikiAuditLog.AuditLogFilter (Result Evergreen.V12.WikiAuditLog.Error (List Evergreen.V12.WikiAuditLog.AuditEvent))
    | PromoteContributorToTrustedResponse Evergreen.V12.Wiki.Slug (Result Evergreen.V12.WikiAdminUsers.PromoteContributorError ())
    | DemoteTrustedToContributorResponse Evergreen.V12.Wiki.Slug (Result Evergreen.V12.WikiAdminUsers.DemoteTrustedError ())
    | GrantWikiAdminResponse Evergreen.V12.Wiki.Slug (Result Evergreen.V12.WikiAdminUsers.GrantTrustedToAdminError ())
    | RevokeWikiAdminResponse Evergreen.V12.Wiki.Slug (Result Evergreen.V12.WikiAdminUsers.RevokeAdminError ())
    | SubmissionDetailsResponse Evergreen.V12.Wiki.Slug String (Result Evergreen.V12.Submission.DetailsError Evergreen.V12.Submission.ContributorView)
    | RegisterContributorResponse Evergreen.V12.Wiki.Slug (Result Evergreen.V12.ContributorAccount.RegisterContributorError Evergreen.V12.WikiRole.WikiRole)
    | LoginContributorResponse Evergreen.V12.Wiki.Slug (Result Evergreen.V12.ContributorAccount.LoginContributorError Evergreen.V12.WikiRole.WikiRole)
    | LogoutContributorResponse Evergreen.V12.Wiki.Slug
    | SubmitNewPageResponse Evergreen.V12.Wiki.Slug (Result Evergreen.V12.Submission.SubmitNewPageError Evergreen.V12.Submission.NewPageSubmitSuccess)
    | SubmitPageEditResponse Evergreen.V12.Wiki.Slug (Result Evergreen.V12.Submission.SubmitPageEditError Evergreen.V12.Submission.EditSubmitSuccess)
    | RequestPublishedPageDeletionResponse Evergreen.V12.Wiki.Slug (Result Evergreen.V12.Submission.RequestPublishedPageDeletionError Evergreen.V12.Submission.Id)
    | DeletePublishedPageImmediatelyResponse Evergreen.V12.Wiki.Slug (Result Evergreen.V12.Submission.DeletePublishedPageImmediatelyError ())
    | SaveNewPageDraftResponse Evergreen.V12.Wiki.Slug (Result Evergreen.V12.Submission.SaveNewPageDraftError Evergreen.V12.Submission.Id)
    | SavePageEditDraftResponse Evergreen.V12.Wiki.Slug (Result Evergreen.V12.Submission.SavePageEditDraftError Evergreen.V12.Submission.Id)
    | SavePageDeleteDraftResponse Evergreen.V12.Wiki.Slug (Result Evergreen.V12.Submission.SavePageDeleteDraftError Evergreen.V12.Submission.Id)
    | SubmitDraftForReviewResponse Evergreen.V12.Wiki.Slug String (Result Evergreen.V12.Submission.SubmitDraftForReviewError ())
    | WithdrawSubmissionResponse Evergreen.V12.Wiki.Slug String (Result Evergreen.V12.Submission.WithdrawSubmissionError ())
    | DeleteMySubmissionResponse Evergreen.V12.Wiki.Slug String (Result Evergreen.V12.Submission.DeleteMySubmissionError ())
    | ApproveSubmissionResponse Evergreen.V12.Wiki.Slug String (Result Evergreen.V12.Submission.ApproveSubmissionError ())
    | RejectSubmissionResponse Evergreen.V12.Wiki.Slug String (Result Evergreen.V12.Submission.RejectSubmissionError ())
    | RequestSubmissionChangesResponse Evergreen.V12.Wiki.Slug String (Result Evergreen.V12.Submission.RequestChangesSubmissionError ())
    | HostAdminLoginResponse (Result Evergreen.V12.HostAdmin.LoginError ())
    | HostAdminWikiListResponse (Result Evergreen.V12.HostAdmin.ProtectedError (List Evergreen.V12.Wiki.CatalogEntry))
    | HostAuditLogResponse Evergreen.V12.WikiAuditLog.HostAuditLogFilter (Result Evergreen.V12.HostAdmin.ProtectedError (List Evergreen.V12.WikiAuditLog.ScopedAuditEvent))
    | CreateHostedWikiResponse (Result Evergreen.V12.HostAdmin.CreateHostedWikiError Evergreen.V12.Wiki.CatalogEntry)
    | HostWikiDetailResponse Evergreen.V12.Wiki.Slug (Result Evergreen.V12.HostAdmin.HostWikiDetailError Evergreen.V12.Wiki.CatalogEntry)
    | UpdateHostedWikiMetadataResponse Evergreen.V12.Wiki.Slug (Result Evergreen.V12.HostAdmin.UpdateHostedWikiMetadataError Evergreen.V12.Wiki.CatalogEntry)
    | DeactivateHostedWikiResponse Evergreen.V12.Wiki.Slug (Result Evergreen.V12.HostAdmin.WikiLifecycleError Evergreen.V12.Wiki.CatalogEntry)
    | ReactivateHostedWikiResponse Evergreen.V12.Wiki.Slug (Result Evergreen.V12.HostAdmin.WikiLifecycleError Evergreen.V12.Wiki.CatalogEntry)
    | DeleteHostedWikiResponse Evergreen.V12.Wiki.Slug (Result Evergreen.V12.HostAdmin.DeleteHostedWikiError ())
    | HostAdminDataExportResponse (Result Evergreen.V12.HostAdmin.DataExportError String)
    | HostAdminDataImportResponse (Result Evergreen.V12.HostAdmin.DataImportError ())
    | HostAdminWikiDataExportResponse Evergreen.V12.Wiki.Slug (Result Evergreen.V12.HostAdmin.WikiDataExportError String)
    | HostAdminWikiDataImportResponse Evergreen.V12.Wiki.Slug (Result Evergreen.V12.HostAdmin.WikiDataImportError ())
    | HostAdminWikiDataImportAutoResponse (Result Evergreen.V12.HostAdmin.WikiDataImportError Evergreen.V12.Wiki.Slug)

module Evergreen.V5.Types exposing (..)

import Dict
import Effect.Browser
import Effect.Browser.Navigation
import Effect.File
import Effect.Lamdera
import Evergreen.V5.ColorTheme
import Evergreen.V5.ContributorAccount
import Evergreen.V5.ContributorWikiSession
import Evergreen.V5.HostAdmin
import Evergreen.V5.Page
import Evergreen.V5.PendingReviewCount
import Evergreen.V5.Route
import Evergreen.V5.Store
import Evergreen.V5.Submission
import Evergreen.V5.SubmissionReviewDetail
import Evergreen.V5.Wiki
import Evergreen.V5.WikiAdminUsers
import Evergreen.V5.WikiAuditLog
import Evergreen.V5.WikiContributors
import Evergreen.V5.WikiFrontendSubscription
import Evergreen.V5.WikiRole
import Evergreen.V5.WikiUser
import RemoteData
import Set
import Time
import Url


type alias RegisterDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V5.ContributorAccount.RegisterContributorError ())
    }


type alias LoginDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V5.ContributorAccount.LoginContributorError ())
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
    , lastResult : Maybe (Result Evergreen.V5.Submission.SubmitNewPageError Evergreen.V5.Submission.NewPageSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V5.Submission.SaveNewPageDraftError Evergreen.V5.Submission.Id)
    }


type alias PageEditSubmitDraft =
    { markdownBody : String
    , tagsInput : String
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V5.Submission.SubmitPageEditError Evergreen.V5.Submission.EditSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V5.Submission.SavePageEditDraftError Evergreen.V5.Submission.Id)
    }


type alias PageDeleteSubmitDraft =
    { reasonText : String
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V5.Submission.PageDeleteFormError Evergreen.V5.Submission.PageDeleteFormSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V5.Submission.SavePageDeleteDraftError Evergreen.V5.Submission.Id)
    }


type alias ReviewApproveDraft =
    { inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V5.Submission.ApproveSubmissionError ())
    }


type ReviewDecision
    = ReviewDecisionApprove
    | ReviewDecisionRequestChanges
    | ReviewDecisionReject


type alias ReviewRejectDraft =
    { reasonText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V5.Submission.RejectSubmissionError ())
    }


type alias ReviewRequestChangesDraft =
    { guidanceText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V5.Submission.RequestChangesSubmissionError ())
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
    , lastResult : Maybe (Result Evergreen.V5.HostAdmin.LoginError ())
    }


type alias HostAdminCreateWikiDraft =
    { slug : String
    , name : String
    , initialAdminUsername : String
    , initialAdminPassword : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V5.HostAdmin.CreateHostedWikiError Evergreen.V5.Wiki.CatalogEntry)
    }


type alias HostAdminWikiDetailDraft =
    { wikiSlug : Evergreen.V5.Wiki.Slug
    , load : RemoteData.RemoteData () (Result Evergreen.V5.HostAdmin.HostWikiDetailError Evergreen.V5.Wiki.CatalogEntry)
    , slugDraft : String
    , nameDraft : String
    , summaryDraft : String
    , saveInFlight : Bool
    , lastSaveResult : Maybe (Result Evergreen.V5.HostAdmin.UpdateHostedWikiMetadataError ())
    , lifecycleInFlight : Bool
    , lastLifecycleResult : Maybe (Result Evergreen.V5.HostAdmin.WikiLifecycleError ())
    , deleteConfirmDraft : String
    , deleteInFlight : Bool
    , lastDeleteResult : Maybe (Result Evergreen.V5.HostAdmin.DeleteHostedWikiError ())
    }


type alias FrontendModel =
    { key : Effect.Browser.Navigation.Key
    , colorThemePreference : Evergreen.V5.ColorTheme.ColorThemePreference
    , systemColorTheme : Evergreen.V5.ColorTheme.ColorTheme
    , route : Evergreen.V5.Route.Route
    , navigationFragment : Maybe String
    , store : Evergreen.V5.Store.Store
    , contributorWikiSessions : Dict.Dict Evergreen.V5.Wiki.Slug Evergreen.V5.ContributorWikiSession.ContributorWikiSession
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
    , wikiAdminAuditFilterSelectedKindTags : List Evergreen.V5.WikiAuditLog.AuditEventKindFilterTag
    , wikiAdminAuditAppliedFilter : Evergreen.V5.WikiAuditLog.AuditLogFilter
    , hostAdminAuditFilterWikiDraft : String
    , hostAdminAuditFilterActorDraft : String
    , hostAdminAuditFilterPageDraft : String
    , hostAdminAuditFilterSelectedKindTags : List Evergreen.V5.WikiAuditLog.AuditEventKindFilterTag
    , hostAdminAuditAppliedFilter : Evergreen.V5.WikiAuditLog.HostAuditLogFilter
    , hostAdminAuditLog : RemoteData.RemoteData () (Result Evergreen.V5.HostAdmin.ProtectedError (List Evergreen.V5.WikiAuditLog.ScopedAuditEvent))
    , hostAdminLoginDraft : HostAdminLoginDraft
    , hostAdminCreateWikiDraft : HostAdminCreateWikiDraft
    , hostAdminWikiDetailDraft : HostAdminWikiDetailDraft
    , hostAdminWikis : RemoteData.RemoteData () (Result Evergreen.V5.HostAdmin.ProtectedError (List Evergreen.V5.Wiki.CatalogEntry))
    , hostAdminSessionAuthenticated : Bool
    , hostAdminExportInFlight : Bool
    , hostAdminImportInFlight : Bool
    , hostAdminBackupNotice : Maybe String
    , hostAdminWikiExportInFlightSlug : Maybe Evergreen.V5.Wiki.Slug
    , hostAdminWikiImportInFlightSlug : Maybe Evergreen.V5.Wiki.Slug
    , hostAdminWikiImportPendingSlug : Maybe Evergreen.V5.Wiki.Slug
    , hostAdminWikisNotice : Maybe String
    }


type alias BackendModel =
    { wikis : Dict.Dict Evergreen.V5.Wiki.Slug Evergreen.V5.Wiki.Wiki
    , contributors : Evergreen.V5.WikiContributors.Registry
    , contributorSessions : Evergreen.V5.WikiUser.SessionTable
    , hostSessions : Set.Set String
    , submissions : Dict.Dict String Evergreen.V5.Submission.Submission
    , nextSubmissionCounter : Int
    , wikiAuditEvents : Dict.Dict Evergreen.V5.Wiki.Slug (List Evergreen.V5.WikiAuditLog.AuditEvent)
    , pendingReviewCounts : Dict.Dict Evergreen.V5.Wiki.Slug Int
    , pendingReviewClients : Evergreen.V5.PendingReviewCount.PendingReviewClientSets
    , wikiFrontendClients : Evergreen.V5.WikiFrontendSubscription.WikiFrontendClientSets
    }


type FrontendMsg
    = UrlClicked Effect.Browser.UrlRequest
    | UrlChanged Url.Url
    | UrlFragmentScrollDone
    | ColorThemeToggled
    | ColorThemeFromJs (Maybe Evergreen.V5.ColorTheme.Incoming)
    | RegisterFormUsernameChanged String
    | RegisterFormPasswordChanged String
    | RegisterFormSubmitted
    | LoginFormUsernameChanged String
    | LoginFormPasswordChanged String
    | LoginFormSubmitted
    | ContributorLogoutWiki Evergreen.V5.Wiki.Slug
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
    | WikiAdminAuditFilterTypeTagToggled Evergreen.V5.WikiAuditLog.AuditEventKindFilterTag Bool
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
    | HostAdminAuditFilterTypeTagToggled Evergreen.V5.WikiAuditLog.AuditEventKindFilterTag Bool
    | HostAdminDataExportClicked
    | HostAdminDataImportPickRequested
    | HostAdminDataImportFileSelected Effect.File.File
    | HostAdminDataImportFileRead (Result () String)
    | HostAdminWikisDataImportPickRequested
    | HostAdminWikisDataImportFileSelected Effect.File.File
    | HostAdminWikisDataImportFileRead (Result () String)
    | HostAdminWikiDataExportClicked Evergreen.V5.Wiki.Slug
    | HostAdminWikiDataImportPickRequested Evergreen.V5.Wiki.Slug
    | HostAdminWikiDataImportFileSelected Effect.File.File
    | HostAdminWikiDataImportFileRead Evergreen.V5.Wiki.Slug (Result () String)


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
    | RequestWikiFrontendDetails Evergreen.V5.Wiki.Slug
    | RequestPageFrontendDetails Evergreen.V5.Wiki.Slug Evergreen.V5.Page.Slug
    | RequestMyPendingSubmissions Evergreen.V5.Wiki.Slug
    | RequestReviewQueue Evergreen.V5.Wiki.Slug
    | RequestReviewSubmissionDetail Evergreen.V5.Wiki.Slug String
    | RequestWikiUsers Evergreen.V5.Wiki.Slug
    | RequestWikiAuditLog Evergreen.V5.Wiki.Slug Evergreen.V5.WikiAuditLog.AuditLogFilter
    | PromoteContributorToTrusted Evergreen.V5.Wiki.Slug String
    | DemoteTrustedToContributor Evergreen.V5.Wiki.Slug String
    | GrantWikiAdmin Evergreen.V5.Wiki.Slug String
    | RevokeWikiAdmin Evergreen.V5.Wiki.Slug String
    | RequestSubmissionDetails Evergreen.V5.Wiki.Slug String
    | RegisterContributor Evergreen.V5.Wiki.Slug RegisterContributorPayload
    | LoginContributor Evergreen.V5.Wiki.Slug LoginContributorPayload
    | LogoutContributor Evergreen.V5.Wiki.Slug
    | SubmitNewPage Evergreen.V5.Wiki.Slug SubmitNewPagePayload
    | SubmitPageEdit Evergreen.V5.Wiki.Slug Evergreen.V5.Page.Slug String String
    | RequestPublishedPageDeletion Evergreen.V5.Wiki.Slug Evergreen.V5.Page.Slug String
    | DeletePublishedPageImmediately Evergreen.V5.Wiki.Slug Evergreen.V5.Page.Slug String
    | SaveNewPageDraft
        Evergreen.V5.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , rawPageSlug : String
        , rawMarkdown : String
        , rawTags : String
        }
    | SavePageEditDraft
        Evergreen.V5.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V5.Page.Slug
        , rawMarkdown : String
        , rawTags : String
        }
    | SavePageDeleteDraft
        Evergreen.V5.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V5.Page.Slug
        , rawReason : String
        }
    | SubmitDraftForReview Evergreen.V5.Wiki.Slug String
    | WithdrawSubmission Evergreen.V5.Wiki.Slug String
    | DeleteMySubmission Evergreen.V5.Wiki.Slug String
    | ApproveSubmission Evergreen.V5.Wiki.Slug String
    | RejectSubmission Evergreen.V5.Wiki.Slug RejectSubmissionPayload
    | RequestSubmissionChanges Evergreen.V5.Wiki.Slug RequestSubmissionChangesPayload
    | HostAdminLogin String
    | RequestHostWikiList
    | RequestHostAuditLog Evergreen.V5.WikiAuditLog.HostAuditLogFilter
    | RequestHostWikiDetail Evergreen.V5.Wiki.Slug
    | CreateHostedWiki CreateHostedWikiPayload
    | UpdateHostedWikiMetadata Evergreen.V5.Wiki.Slug UpdateHostedWikiMetadataPayload
    | DeactivateHostedWiki Evergreen.V5.Wiki.Slug
    | ReactivateHostedWiki Evergreen.V5.Wiki.Slug
    | DeleteHostedWiki Evergreen.V5.Wiki.Slug String
    | RequestHostAdminDataExport
    | ImportHostAdminDataSnapshot String
    | RequestHostAdminWikiDataExport Evergreen.V5.Wiki.Slug
    | ImportHostAdminWikiDataSnapshot Evergreen.V5.Wiki.Slug String
    | ImportHostAdminWikiDataSnapshotAuto String


type BackendMsg
    = ToBackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Time.Posix


type ToFrontend
    = WikiCatalogResponse (Dict.Dict Evergreen.V5.Wiki.Slug Evergreen.V5.Wiki.CatalogEntry)
    | PendingReviewCountUpdated Evergreen.V5.Wiki.Slug Int
    | WikiFrontendDetailsResponse Evergreen.V5.Wiki.Slug (Maybe Evergreen.V5.Wiki.FrontendDetails)
    | PageFrontendDetailsResponse Evergreen.V5.Wiki.Slug Evergreen.V5.Page.Slug (Maybe Evergreen.V5.Page.FrontendDetails)
    | MyPendingSubmissionsResponse Evergreen.V5.Wiki.Slug (Result Evergreen.V5.Submission.MyPendingSubmissionsError (List Evergreen.V5.Submission.MyPendingSubmissionListItem))
    | ReviewQueueResponse Evergreen.V5.Wiki.Slug (Result Evergreen.V5.Submission.ReviewQueueError (List Evergreen.V5.Submission.ReviewQueueItem))
    | ReviewSubmissionDetailResponse Evergreen.V5.Wiki.Slug String (Result Evergreen.V5.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V5.SubmissionReviewDetail.SubmissionReviewDetail)
    | WikiUsersResponse Evergreen.V5.Wiki.Slug (Result Evergreen.V5.WikiAdminUsers.Error (List Evergreen.V5.WikiAdminUsers.ListedUser))
    | WikiAuditLogResponse Evergreen.V5.Wiki.Slug Evergreen.V5.WikiAuditLog.AuditLogFilter (Result Evergreen.V5.WikiAuditLog.Error (List Evergreen.V5.WikiAuditLog.AuditEvent))
    | PromoteContributorToTrustedResponse Evergreen.V5.Wiki.Slug (Result Evergreen.V5.WikiAdminUsers.PromoteContributorError ())
    | DemoteTrustedToContributorResponse Evergreen.V5.Wiki.Slug (Result Evergreen.V5.WikiAdminUsers.DemoteTrustedError ())
    | GrantWikiAdminResponse Evergreen.V5.Wiki.Slug (Result Evergreen.V5.WikiAdminUsers.GrantTrustedToAdminError ())
    | RevokeWikiAdminResponse Evergreen.V5.Wiki.Slug (Result Evergreen.V5.WikiAdminUsers.RevokeAdminError ())
    | SubmissionDetailsResponse Evergreen.V5.Wiki.Slug String (Result Evergreen.V5.Submission.DetailsError Evergreen.V5.Submission.ContributorView)
    | RegisterContributorResponse Evergreen.V5.Wiki.Slug (Result Evergreen.V5.ContributorAccount.RegisterContributorError Evergreen.V5.WikiRole.WikiRole)
    | LoginContributorResponse Evergreen.V5.Wiki.Slug (Result Evergreen.V5.ContributorAccount.LoginContributorError Evergreen.V5.WikiRole.WikiRole)
    | LogoutContributorResponse Evergreen.V5.Wiki.Slug
    | SubmitNewPageResponse Evergreen.V5.Wiki.Slug (Result Evergreen.V5.Submission.SubmitNewPageError Evergreen.V5.Submission.NewPageSubmitSuccess)
    | SubmitPageEditResponse Evergreen.V5.Wiki.Slug (Result Evergreen.V5.Submission.SubmitPageEditError Evergreen.V5.Submission.EditSubmitSuccess)
    | RequestPublishedPageDeletionResponse Evergreen.V5.Wiki.Slug (Result Evergreen.V5.Submission.RequestPublishedPageDeletionError Evergreen.V5.Submission.Id)
    | DeletePublishedPageImmediatelyResponse Evergreen.V5.Wiki.Slug (Result Evergreen.V5.Submission.DeletePublishedPageImmediatelyError ())
    | SaveNewPageDraftResponse Evergreen.V5.Wiki.Slug (Result Evergreen.V5.Submission.SaveNewPageDraftError Evergreen.V5.Submission.Id)
    | SavePageEditDraftResponse Evergreen.V5.Wiki.Slug (Result Evergreen.V5.Submission.SavePageEditDraftError Evergreen.V5.Submission.Id)
    | SavePageDeleteDraftResponse Evergreen.V5.Wiki.Slug (Result Evergreen.V5.Submission.SavePageDeleteDraftError Evergreen.V5.Submission.Id)
    | SubmitDraftForReviewResponse Evergreen.V5.Wiki.Slug String (Result Evergreen.V5.Submission.SubmitDraftForReviewError ())
    | WithdrawSubmissionResponse Evergreen.V5.Wiki.Slug String (Result Evergreen.V5.Submission.WithdrawSubmissionError ())
    | DeleteMySubmissionResponse Evergreen.V5.Wiki.Slug String (Result Evergreen.V5.Submission.DeleteMySubmissionError ())
    | ApproveSubmissionResponse Evergreen.V5.Wiki.Slug String (Result Evergreen.V5.Submission.ApproveSubmissionError ())
    | RejectSubmissionResponse Evergreen.V5.Wiki.Slug String (Result Evergreen.V5.Submission.RejectSubmissionError ())
    | RequestSubmissionChangesResponse Evergreen.V5.Wiki.Slug String (Result Evergreen.V5.Submission.RequestChangesSubmissionError ())
    | HostAdminLoginResponse (Result Evergreen.V5.HostAdmin.LoginError ())
    | HostAdminWikiListResponse (Result Evergreen.V5.HostAdmin.ProtectedError (List Evergreen.V5.Wiki.CatalogEntry))
    | HostAuditLogResponse Evergreen.V5.WikiAuditLog.HostAuditLogFilter (Result Evergreen.V5.HostAdmin.ProtectedError (List Evergreen.V5.WikiAuditLog.ScopedAuditEvent))
    | CreateHostedWikiResponse (Result Evergreen.V5.HostAdmin.CreateHostedWikiError Evergreen.V5.Wiki.CatalogEntry)
    | HostWikiDetailResponse Evergreen.V5.Wiki.Slug (Result Evergreen.V5.HostAdmin.HostWikiDetailError Evergreen.V5.Wiki.CatalogEntry)
    | UpdateHostedWikiMetadataResponse Evergreen.V5.Wiki.Slug (Result Evergreen.V5.HostAdmin.UpdateHostedWikiMetadataError Evergreen.V5.Wiki.CatalogEntry)
    | DeactivateHostedWikiResponse Evergreen.V5.Wiki.Slug (Result Evergreen.V5.HostAdmin.WikiLifecycleError Evergreen.V5.Wiki.CatalogEntry)
    | ReactivateHostedWikiResponse Evergreen.V5.Wiki.Slug (Result Evergreen.V5.HostAdmin.WikiLifecycleError Evergreen.V5.Wiki.CatalogEntry)
    | DeleteHostedWikiResponse Evergreen.V5.Wiki.Slug (Result Evergreen.V5.HostAdmin.DeleteHostedWikiError ())
    | HostAdminDataExportResponse (Result Evergreen.V5.HostAdmin.DataExportError String)
    | HostAdminDataImportResponse (Result Evergreen.V5.HostAdmin.DataImportError ())
    | HostAdminWikiDataExportResponse Evergreen.V5.Wiki.Slug (Result Evergreen.V5.HostAdmin.WikiDataExportError String)
    | HostAdminWikiDataImportResponse Evergreen.V5.Wiki.Slug (Result Evergreen.V5.HostAdmin.WikiDataImportError ())
    | HostAdminWikiDataImportAutoResponse (Result Evergreen.V5.HostAdmin.WikiDataImportError Evergreen.V5.Wiki.Slug)

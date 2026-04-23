module Evergreen.V11.Types exposing (..)

import Dict
import Effect.Browser
import Effect.Browser.Navigation
import Effect.File
import Effect.Lamdera
import Evergreen.V11.ColorTheme
import Evergreen.V11.ContributorAccount
import Evergreen.V11.ContributorWikiSession
import Evergreen.V11.HostAdmin
import Evergreen.V11.Page
import Evergreen.V11.PendingReviewCount
import Evergreen.V11.Route
import Evergreen.V11.Store
import Evergreen.V11.Submission
import Evergreen.V11.SubmissionReviewDetail
import Evergreen.V11.Wiki
import Evergreen.V11.WikiAdminUsers
import Evergreen.V11.WikiAuditLog
import Evergreen.V11.WikiContributors
import Evergreen.V11.WikiFrontendSubscription
import Evergreen.V11.WikiRole
import Evergreen.V11.WikiUser
import RemoteData
import Set
import Time
import Url


type alias RegisterDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V11.ContributorAccount.RegisterContributorError ())
    }


type alias LoginDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V11.ContributorAccount.LoginContributorError ())
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
    , lastResult : Maybe (Result Evergreen.V11.Submission.SubmitNewPageError Evergreen.V11.Submission.NewPageSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V11.Submission.SaveNewPageDraftError Evergreen.V11.Submission.Id)
    }


type alias PageEditSubmitDraft =
    { markdownBody : String
    , tagsInput : String
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V11.Submission.SubmitPageEditError Evergreen.V11.Submission.EditSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V11.Submission.SavePageEditDraftError Evergreen.V11.Submission.Id)
    }


type alias PageDeleteSubmitDraft =
    { reasonText : String
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V11.Submission.PageDeleteFormError Evergreen.V11.Submission.PageDeleteFormSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V11.Submission.SavePageDeleteDraftError Evergreen.V11.Submission.Id)
    }


type alias ReviewApproveDraft =
    { inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V11.Submission.ApproveSubmissionError ())
    }


type ReviewDecision
    = ReviewDecisionApprove
    | ReviewDecisionRequestChanges
    | ReviewDecisionReject


type alias ReviewRejectDraft =
    { reasonText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V11.Submission.RejectSubmissionError ())
    }


type alias ReviewRequestChangesDraft =
    { guidanceText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V11.Submission.RequestChangesSubmissionError ())
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
    , lastResult : Maybe (Result Evergreen.V11.HostAdmin.LoginError ())
    }


type alias HostAdminCreateWikiDraft =
    { slug : String
    , name : String
    , initialAdminUsername : String
    , initialAdminPassword : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V11.HostAdmin.CreateHostedWikiError Evergreen.V11.Wiki.CatalogEntry)
    }


type alias HostAdminWikiDetailDraft =
    { wikiSlug : Evergreen.V11.Wiki.Slug
    , load : RemoteData.RemoteData () (Result Evergreen.V11.HostAdmin.HostWikiDetailError Evergreen.V11.Wiki.CatalogEntry)
    , slugDraft : String
    , nameDraft : String
    , summaryDraft : String
    , saveInFlight : Bool
    , lastSaveResult : Maybe (Result Evergreen.V11.HostAdmin.UpdateHostedWikiMetadataError ())
    , lifecycleInFlight : Bool
    , lastLifecycleResult : Maybe (Result Evergreen.V11.HostAdmin.WikiLifecycleError ())
    , deleteConfirmDraft : String
    , deleteInFlight : Bool
    , lastDeleteResult : Maybe (Result Evergreen.V11.HostAdmin.DeleteHostedWikiError ())
    }


type alias FrontendModel =
    { key : Effect.Browser.Navigation.Key
    , colorThemePreference : Evergreen.V11.ColorTheme.ColorThemePreference
    , systemColorTheme : Evergreen.V11.ColorTheme.ColorTheme
    , route : Evergreen.V11.Route.Route
    , navigationFragment : Maybe String
    , store : Evergreen.V11.Store.Store
    , contributorWikiSessions : Dict.Dict Evergreen.V11.Wiki.Slug Evergreen.V11.ContributorWikiSession.ContributorWikiSession
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
    , wikiAdminAuditFilterSelectedKindTags : List Evergreen.V11.WikiAuditLog.AuditEventKindFilterTag
    , wikiAdminAuditAppliedFilter : Evergreen.V11.WikiAuditLog.AuditLogFilter
    , hostAdminAuditFilterWikiDraft : String
    , hostAdminAuditFilterActorDraft : String
    , hostAdminAuditFilterPageDraft : String
    , hostAdminAuditFilterSelectedKindTags : List Evergreen.V11.WikiAuditLog.AuditEventKindFilterTag
    , hostAdminAuditAppliedFilter : Evergreen.V11.WikiAuditLog.HostAuditLogFilter
    , hostAdminAuditLog : RemoteData.RemoteData () (Result Evergreen.V11.HostAdmin.ProtectedError (List Evergreen.V11.WikiAuditLog.ScopedAuditEvent))
    , hostAdminLoginDraft : HostAdminLoginDraft
    , hostAdminCreateWikiDraft : HostAdminCreateWikiDraft
    , hostAdminWikiDetailDraft : HostAdminWikiDetailDraft
    , hostAdminWikis : RemoteData.RemoteData () (Result Evergreen.V11.HostAdmin.ProtectedError (List Evergreen.V11.Wiki.CatalogEntry))
    , hostAdminSessionAuthenticated : Bool
    , hostAdminExportInFlight : Bool
    , hostAdminImportInFlight : Bool
    , hostAdminBackupNotice : Maybe String
    , hostAdminWikiExportInFlightSlug : Maybe Evergreen.V11.Wiki.Slug
    , hostAdminWikiImportInFlightSlug : Maybe Evergreen.V11.Wiki.Slug
    , hostAdminWikiImportPendingSlug : Maybe Evergreen.V11.Wiki.Slug
    , hostAdminWikisNotice : Maybe String
    }


type alias BackendModel =
    { wikis : Dict.Dict Evergreen.V11.Wiki.Slug Evergreen.V11.Wiki.Wiki
    , contributors : Evergreen.V11.WikiContributors.Registry
    , contributorSessions : Evergreen.V11.WikiUser.SessionTable
    , hostSessions : Set.Set String
    , submissions : Dict.Dict String Evergreen.V11.Submission.Submission
    , nextSubmissionCounter : Int
    , wikiAuditEvents : Dict.Dict Evergreen.V11.Wiki.Slug (List Evergreen.V11.WikiAuditLog.AuditEvent)
    , pendingReviewCounts : Dict.Dict Evergreen.V11.Wiki.Slug Int
    , pendingReviewClients : Evergreen.V11.PendingReviewCount.PendingReviewClientSets
    , wikiFrontendClients : Evergreen.V11.WikiFrontendSubscription.WikiFrontendClientSets
    }


type FrontendMsg
    = UrlClicked Effect.Browser.UrlRequest
    | UrlChanged Url.Url
    | UrlFragmentScrollDone
    | ColorThemeToggled
    | ColorThemeFromJs (Maybe Evergreen.V11.ColorTheme.Incoming)
    | RegisterFormUsernameChanged String
    | RegisterFormPasswordChanged String
    | RegisterFormSubmitted
    | LoginFormUsernameChanged String
    | LoginFormPasswordChanged String
    | LoginFormSubmitted
    | ContributorLogoutWiki Evergreen.V11.Wiki.Slug
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
    | WikiAdminAuditFilterTypeTagToggled Evergreen.V11.WikiAuditLog.AuditEventKindFilterTag Bool
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
    | HostAdminAuditFilterTypeTagToggled Evergreen.V11.WikiAuditLog.AuditEventKindFilterTag Bool
    | HostAdminDataExportClicked
    | HostAdminDataImportPickRequested
    | HostAdminDataImportFileSelected Effect.File.File
    | HostAdminDataImportFileRead (Result () String)
    | HostAdminWikisDataImportPickRequested
    | HostAdminWikisDataImportFileSelected Effect.File.File
    | HostAdminWikisDataImportFileRead (Result () String)
    | HostAdminWikiDataExportClicked Evergreen.V11.Wiki.Slug
    | HostAdminWikiDataImportPickRequested Evergreen.V11.Wiki.Slug
    | HostAdminWikiDataImportFileSelected Effect.File.File
    | HostAdminWikiDataImportFileRead Evergreen.V11.Wiki.Slug (Result () String)


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
    | RequestWikiFrontendDetails Evergreen.V11.Wiki.Slug
    | RequestPageFrontendDetails Evergreen.V11.Wiki.Slug Evergreen.V11.Page.Slug
    | RequestMyPendingSubmissions Evergreen.V11.Wiki.Slug
    | RequestReviewQueue Evergreen.V11.Wiki.Slug
    | RequestReviewSubmissionDetail Evergreen.V11.Wiki.Slug String
    | RequestWikiUsers Evergreen.V11.Wiki.Slug
    | RequestWikiAuditLog Evergreen.V11.Wiki.Slug Evergreen.V11.WikiAuditLog.AuditLogFilter
    | PromoteContributorToTrusted Evergreen.V11.Wiki.Slug String
    | DemoteTrustedToContributor Evergreen.V11.Wiki.Slug String
    | GrantWikiAdmin Evergreen.V11.Wiki.Slug String
    | RevokeWikiAdmin Evergreen.V11.Wiki.Slug String
    | RequestSubmissionDetails Evergreen.V11.Wiki.Slug String
    | RegisterContributor Evergreen.V11.Wiki.Slug RegisterContributorPayload
    | LoginContributor Evergreen.V11.Wiki.Slug LoginContributorPayload
    | LogoutContributor Evergreen.V11.Wiki.Slug
    | SubmitNewPage Evergreen.V11.Wiki.Slug SubmitNewPagePayload
    | SubmitPageEdit Evergreen.V11.Wiki.Slug Evergreen.V11.Page.Slug String String
    | RequestPublishedPageDeletion Evergreen.V11.Wiki.Slug Evergreen.V11.Page.Slug String
    | DeletePublishedPageImmediately Evergreen.V11.Wiki.Slug Evergreen.V11.Page.Slug String
    | SaveNewPageDraft
        Evergreen.V11.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , rawPageSlug : String
        , rawMarkdown : String
        , rawTags : String
        }
    | SavePageEditDraft
        Evergreen.V11.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V11.Page.Slug
        , rawMarkdown : String
        , rawTags : String
        }
    | SavePageDeleteDraft
        Evergreen.V11.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V11.Page.Slug
        , rawReason : String
        }
    | SubmitDraftForReview Evergreen.V11.Wiki.Slug String
    | WithdrawSubmission Evergreen.V11.Wiki.Slug String
    | DeleteMySubmission Evergreen.V11.Wiki.Slug String
    | ApproveSubmission Evergreen.V11.Wiki.Slug String
    | RejectSubmission Evergreen.V11.Wiki.Slug RejectSubmissionPayload
    | RequestSubmissionChanges Evergreen.V11.Wiki.Slug RequestSubmissionChangesPayload
    | HostAdminLogin String
    | RequestHostWikiList
    | RequestHostAuditLog Evergreen.V11.WikiAuditLog.HostAuditLogFilter
    | RequestHostWikiDetail Evergreen.V11.Wiki.Slug
    | CreateHostedWiki CreateHostedWikiPayload
    | UpdateHostedWikiMetadata Evergreen.V11.Wiki.Slug UpdateHostedWikiMetadataPayload
    | DeactivateHostedWiki Evergreen.V11.Wiki.Slug
    | ReactivateHostedWiki Evergreen.V11.Wiki.Slug
    | DeleteHostedWiki Evergreen.V11.Wiki.Slug String
    | RequestHostAdminDataExport
    | ImportHostAdminDataSnapshot String
    | RequestHostAdminWikiDataExport Evergreen.V11.Wiki.Slug
    | ImportHostAdminWikiDataSnapshot Evergreen.V11.Wiki.Slug String
    | ImportHostAdminWikiDataSnapshotAuto String


type BackendMsg
    = ToBackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Time.Posix


type ToFrontend
    = WikiCatalogResponse (Dict.Dict Evergreen.V11.Wiki.Slug Evergreen.V11.Wiki.CatalogEntry)
    | PendingReviewCountUpdated Evergreen.V11.Wiki.Slug Int
    | WikiFrontendDetailsResponse Evergreen.V11.Wiki.Slug (Maybe Evergreen.V11.Wiki.FrontendDetails)
    | PageFrontendDetailsResponse Evergreen.V11.Wiki.Slug Evergreen.V11.Page.Slug (Maybe Evergreen.V11.Page.FrontendDetails)
    | MyPendingSubmissionsResponse Evergreen.V11.Wiki.Slug (Result Evergreen.V11.Submission.MyPendingSubmissionsError (List Evergreen.V11.Submission.MyPendingSubmissionListItem))
    | ReviewQueueResponse Evergreen.V11.Wiki.Slug (Result Evergreen.V11.Submission.ReviewQueueError (List Evergreen.V11.Submission.ReviewQueueItem))
    | ReviewSubmissionDetailResponse Evergreen.V11.Wiki.Slug String (Result Evergreen.V11.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V11.SubmissionReviewDetail.SubmissionReviewDetail)
    | WikiUsersResponse Evergreen.V11.Wiki.Slug (Result Evergreen.V11.WikiAdminUsers.Error (List Evergreen.V11.WikiAdminUsers.ListedUser))
    | WikiAuditLogResponse Evergreen.V11.Wiki.Slug Evergreen.V11.WikiAuditLog.AuditLogFilter (Result Evergreen.V11.WikiAuditLog.Error (List Evergreen.V11.WikiAuditLog.AuditEvent))
    | PromoteContributorToTrustedResponse Evergreen.V11.Wiki.Slug (Result Evergreen.V11.WikiAdminUsers.PromoteContributorError ())
    | DemoteTrustedToContributorResponse Evergreen.V11.Wiki.Slug (Result Evergreen.V11.WikiAdminUsers.DemoteTrustedError ())
    | GrantWikiAdminResponse Evergreen.V11.Wiki.Slug (Result Evergreen.V11.WikiAdminUsers.GrantTrustedToAdminError ())
    | RevokeWikiAdminResponse Evergreen.V11.Wiki.Slug (Result Evergreen.V11.WikiAdminUsers.RevokeAdminError ())
    | SubmissionDetailsResponse Evergreen.V11.Wiki.Slug String (Result Evergreen.V11.Submission.DetailsError Evergreen.V11.Submission.ContributorView)
    | RegisterContributorResponse Evergreen.V11.Wiki.Slug (Result Evergreen.V11.ContributorAccount.RegisterContributorError Evergreen.V11.WikiRole.WikiRole)
    | LoginContributorResponse Evergreen.V11.Wiki.Slug (Result Evergreen.V11.ContributorAccount.LoginContributorError Evergreen.V11.WikiRole.WikiRole)
    | LogoutContributorResponse Evergreen.V11.Wiki.Slug
    | SubmitNewPageResponse Evergreen.V11.Wiki.Slug (Result Evergreen.V11.Submission.SubmitNewPageError Evergreen.V11.Submission.NewPageSubmitSuccess)
    | SubmitPageEditResponse Evergreen.V11.Wiki.Slug (Result Evergreen.V11.Submission.SubmitPageEditError Evergreen.V11.Submission.EditSubmitSuccess)
    | RequestPublishedPageDeletionResponse Evergreen.V11.Wiki.Slug (Result Evergreen.V11.Submission.RequestPublishedPageDeletionError Evergreen.V11.Submission.Id)
    | DeletePublishedPageImmediatelyResponse Evergreen.V11.Wiki.Slug (Result Evergreen.V11.Submission.DeletePublishedPageImmediatelyError ())
    | SaveNewPageDraftResponse Evergreen.V11.Wiki.Slug (Result Evergreen.V11.Submission.SaveNewPageDraftError Evergreen.V11.Submission.Id)
    | SavePageEditDraftResponse Evergreen.V11.Wiki.Slug (Result Evergreen.V11.Submission.SavePageEditDraftError Evergreen.V11.Submission.Id)
    | SavePageDeleteDraftResponse Evergreen.V11.Wiki.Slug (Result Evergreen.V11.Submission.SavePageDeleteDraftError Evergreen.V11.Submission.Id)
    | SubmitDraftForReviewResponse Evergreen.V11.Wiki.Slug String (Result Evergreen.V11.Submission.SubmitDraftForReviewError ())
    | WithdrawSubmissionResponse Evergreen.V11.Wiki.Slug String (Result Evergreen.V11.Submission.WithdrawSubmissionError ())
    | DeleteMySubmissionResponse Evergreen.V11.Wiki.Slug String (Result Evergreen.V11.Submission.DeleteMySubmissionError ())
    | ApproveSubmissionResponse Evergreen.V11.Wiki.Slug String (Result Evergreen.V11.Submission.ApproveSubmissionError ())
    | RejectSubmissionResponse Evergreen.V11.Wiki.Slug String (Result Evergreen.V11.Submission.RejectSubmissionError ())
    | RequestSubmissionChangesResponse Evergreen.V11.Wiki.Slug String (Result Evergreen.V11.Submission.RequestChangesSubmissionError ())
    | HostAdminLoginResponse (Result Evergreen.V11.HostAdmin.LoginError ())
    | HostAdminWikiListResponse (Result Evergreen.V11.HostAdmin.ProtectedError (List Evergreen.V11.Wiki.CatalogEntry))
    | HostAuditLogResponse Evergreen.V11.WikiAuditLog.HostAuditLogFilter (Result Evergreen.V11.HostAdmin.ProtectedError (List Evergreen.V11.WikiAuditLog.ScopedAuditEvent))
    | CreateHostedWikiResponse (Result Evergreen.V11.HostAdmin.CreateHostedWikiError Evergreen.V11.Wiki.CatalogEntry)
    | HostWikiDetailResponse Evergreen.V11.Wiki.Slug (Result Evergreen.V11.HostAdmin.HostWikiDetailError Evergreen.V11.Wiki.CatalogEntry)
    | UpdateHostedWikiMetadataResponse Evergreen.V11.Wiki.Slug (Result Evergreen.V11.HostAdmin.UpdateHostedWikiMetadataError Evergreen.V11.Wiki.CatalogEntry)
    | DeactivateHostedWikiResponse Evergreen.V11.Wiki.Slug (Result Evergreen.V11.HostAdmin.WikiLifecycleError Evergreen.V11.Wiki.CatalogEntry)
    | ReactivateHostedWikiResponse Evergreen.V11.Wiki.Slug (Result Evergreen.V11.HostAdmin.WikiLifecycleError Evergreen.V11.Wiki.CatalogEntry)
    | DeleteHostedWikiResponse Evergreen.V11.Wiki.Slug (Result Evergreen.V11.HostAdmin.DeleteHostedWikiError ())
    | HostAdminDataExportResponse (Result Evergreen.V11.HostAdmin.DataExportError String)
    | HostAdminDataImportResponse (Result Evergreen.V11.HostAdmin.DataImportError ())
    | HostAdminWikiDataExportResponse Evergreen.V11.Wiki.Slug (Result Evergreen.V11.HostAdmin.WikiDataExportError String)
    | HostAdminWikiDataImportResponse Evergreen.V11.Wiki.Slug (Result Evergreen.V11.HostAdmin.WikiDataImportError ())
    | HostAdminWikiDataImportAutoResponse (Result Evergreen.V11.HostAdmin.WikiDataImportError Evergreen.V11.Wiki.Slug)

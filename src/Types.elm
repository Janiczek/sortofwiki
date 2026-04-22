module Types exposing
    ( BackendModel
    , BackendMsg(..)
    , CreateHostedWikiPayload
    , FrontendModel
    , FrontendMsg(..)
    , HostAdminCreateWikiDraft
    , HostAdminLoginDraft
    , HostAdminWikiDetailDraft
    , LoginContributorPayload
    , LoginDraft
    , NewPageSubmitDraft
    , PageDeleteSubmitDraft
    , PageEditSubmitDraft
    , RegisterContributorPayload
    , RegisterDraft
    , RejectSubmissionPayload
    , RequestSubmissionChangesPayload
    , ReviewApproveDraft
    , ReviewDecision(..)
    , ReviewRejectDraft
    , ReviewRequestChangesDraft
    , SubmissionDetailEditDraft
    , SubmitNewPagePayload
    , ToBackend(..)
    , ToFrontend(..)
    , UpdateHostedWikiMetadataPayload
    , emptySubmissionDetailEditDraft
    )

import ColorTheme exposing (ColorTheme, ColorThemePreference)
import ContributorAccount
import ContributorWikiSession exposing (ContributorWikiSession)
import Dict exposing (Dict)
import Effect.Browser
import Effect.Browser.Navigation
import Effect.File
import Effect.Lamdera exposing (ClientId, SessionId)
import HostAdmin
import Page
import RemoteData exposing (RemoteData)
import Route exposing (Route)
import Set exposing (Set)
import Store exposing (Store)
import Submission
import SubmissionReviewDetail
import Time
import Url exposing (Url)
import Wiki exposing (Wiki)
import WikiAdminUsers
import WikiAuditLog
import WikiContributors
import WikiRole
import WikiUser


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


type ToBackend
    = RequestWikiCatalog
    | RequestWikiFrontendDetails Wiki.Slug
    | RequestPageFrontendDetails Wiki.Slug Page.Slug
    | RequestMyPendingSubmissions Wiki.Slug
    | RequestReviewQueue Wiki.Slug
    | RequestReviewSubmissionDetail Wiki.Slug String
    | RequestWikiUsers Wiki.Slug
    | RequestWikiAuditLog Wiki.Slug WikiAuditLog.AuditLogFilter
    | PromoteContributorToTrusted Wiki.Slug String
    | DemoteTrustedToContributor Wiki.Slug String
    | GrantWikiAdmin Wiki.Slug String
    | RevokeWikiAdmin Wiki.Slug String
    | RequestSubmissionDetails Wiki.Slug String
    | RegisterContributor Wiki.Slug RegisterContributorPayload
    | LoginContributor Wiki.Slug LoginContributorPayload
    | LogoutContributor Wiki.Slug
    | SubmitNewPage Wiki.Slug SubmitNewPagePayload
    | SubmitPageEdit Wiki.Slug Page.Slug String String
    | RequestPublishedPageDeletion Wiki.Slug Page.Slug String
    | DeletePublishedPageImmediately Wiki.Slug Page.Slug String
    | SaveNewPageDraft Wiki.Slug { maybeSubmissionId : Maybe String, rawPageSlug : String, rawMarkdown : String, rawTags : String }
    | SavePageEditDraft Wiki.Slug { maybeSubmissionId : Maybe String, pageSlug : Page.Slug, rawMarkdown : String, rawTags : String }
    | SavePageDeleteDraft Wiki.Slug { maybeSubmissionId : Maybe String, pageSlug : Page.Slug, rawReason : String }
    | SubmitDraftForReview Wiki.Slug String
    | WithdrawSubmission Wiki.Slug String
    | DeleteMySubmission Wiki.Slug String
    | ApproveSubmission Wiki.Slug String
    | RejectSubmission Wiki.Slug RejectSubmissionPayload
    | RequestSubmissionChanges Wiki.Slug RequestSubmissionChangesPayload
    | HostAdminLogin String
    | RequestHostWikiList
    | RequestHostAuditLog WikiAuditLog.HostAuditLogFilter
    | RequestHostWikiDetail Wiki.Slug
    | CreateHostedWiki CreateHostedWikiPayload
    | UpdateHostedWikiMetadata Wiki.Slug UpdateHostedWikiMetadataPayload
    | DeactivateHostedWiki Wiki.Slug
    | ReactivateHostedWiki Wiki.Slug
    | DeleteHostedWiki Wiki.Slug String
    | RequestHostAdminDataExport
    | ImportHostAdminDataSnapshot String
    | RequestHostAdminWikiDataExport Wiki.Slug
    | ImportHostAdminWikiDataSnapshot Wiki.Slug String
    | ImportHostAdminWikiDataSnapshotAuto String


type ToFrontend
    = WikiCatalogResponse (Dict Wiki.Slug Wiki.CatalogEntry)
    | WikiFrontendDetailsResponse Wiki.Slug (Maybe Wiki.FrontendDetails)
    | PageFrontendDetailsResponse Wiki.Slug Page.Slug (Maybe Page.FrontendDetails)
    | MyPendingSubmissionsResponse Wiki.Slug (Result Submission.MyPendingSubmissionsError (List Submission.MyPendingSubmissionListItem))
    | ReviewQueueResponse Wiki.Slug (Result Submission.ReviewQueueError (List Submission.ReviewQueueItem))
    | ReviewSubmissionDetailResponse Wiki.Slug String (Result SubmissionReviewDetail.ReviewSubmissionDetailError SubmissionReviewDetail.SubmissionReviewDetail)
    | WikiUsersResponse Wiki.Slug (Result WikiAdminUsers.Error (List WikiAdminUsers.ListedUser))
    | WikiAuditLogResponse Wiki.Slug WikiAuditLog.AuditLogFilter (Result WikiAuditLog.Error (List WikiAuditLog.AuditEvent))
    | PromoteContributorToTrustedResponse Wiki.Slug (Result WikiAdminUsers.PromoteContributorError ())
    | DemoteTrustedToContributorResponse Wiki.Slug (Result WikiAdminUsers.DemoteTrustedError ())
    | GrantWikiAdminResponse Wiki.Slug (Result WikiAdminUsers.GrantTrustedToAdminError ())
    | RevokeWikiAdminResponse Wiki.Slug (Result WikiAdminUsers.RevokeAdminError ())
    | SubmissionDetailsResponse Wiki.Slug String (Result Submission.DetailsError Submission.ContributorView)
    | RegisterContributorResponse Wiki.Slug (Result ContributorAccount.RegisterContributorError WikiRole.WikiRole)
    | LoginContributorResponse Wiki.Slug (Result ContributorAccount.LoginContributorError WikiRole.WikiRole)
    | LogoutContributorResponse Wiki.Slug
    | SubmitNewPageResponse Wiki.Slug (Result Submission.SubmitNewPageError Submission.NewPageSubmitSuccess)
    | SubmitPageEditResponse Wiki.Slug (Result Submission.SubmitPageEditError Submission.EditSubmitSuccess)
    | RequestPublishedPageDeletionResponse Wiki.Slug (Result Submission.RequestPublishedPageDeletionError Submission.Id)
    | DeletePublishedPageImmediatelyResponse Wiki.Slug (Result Submission.DeletePublishedPageImmediatelyError ())
    | SaveNewPageDraftResponse Wiki.Slug (Result Submission.SaveNewPageDraftError Submission.Id)
    | SavePageEditDraftResponse Wiki.Slug (Result Submission.SavePageEditDraftError Submission.Id)
    | SavePageDeleteDraftResponse Wiki.Slug (Result Submission.SavePageDeleteDraftError Submission.Id)
    | SubmitDraftForReviewResponse Wiki.Slug String (Result Submission.SubmitDraftForReviewError ())
    | WithdrawSubmissionResponse Wiki.Slug String (Result Submission.WithdrawSubmissionError ())
    | DeleteMySubmissionResponse Wiki.Slug String (Result Submission.DeleteMySubmissionError ())
    | ApproveSubmissionResponse Wiki.Slug String (Result Submission.ApproveSubmissionError ())
    | RejectSubmissionResponse Wiki.Slug String (Result Submission.RejectSubmissionError ())
    | RequestSubmissionChangesResponse Wiki.Slug String (Result Submission.RequestChangesSubmissionError ())
    | HostAdminLoginResponse (Result HostAdmin.LoginError ())
    | HostAdminWikiListResponse (Result HostAdmin.ProtectedError (List Wiki.CatalogEntry))
    | HostAuditLogResponse WikiAuditLog.HostAuditLogFilter (Result HostAdmin.ProtectedError (List WikiAuditLog.ScopedAuditEvent))
    | CreateHostedWikiResponse (Result HostAdmin.CreateHostedWikiError Wiki.CatalogEntry)
    | HostWikiDetailResponse Wiki.Slug (Result HostAdmin.HostWikiDetailError Wiki.CatalogEntry)
    | UpdateHostedWikiMetadataResponse Wiki.Slug (Result HostAdmin.UpdateHostedWikiMetadataError Wiki.CatalogEntry)
    | DeactivateHostedWikiResponse Wiki.Slug (Result HostAdmin.WikiLifecycleError Wiki.CatalogEntry)
    | ReactivateHostedWikiResponse Wiki.Slug (Result HostAdmin.WikiLifecycleError Wiki.CatalogEntry)
    | DeleteHostedWikiResponse Wiki.Slug (Result HostAdmin.DeleteHostedWikiError ())
    | HostAdminDataExportResponse (Result HostAdmin.DataExportError String)
    | HostAdminDataImportResponse (Result HostAdmin.DataImportError ())
    | HostAdminWikiDataExportResponse Wiki.Slug (Result HostAdmin.WikiDataExportError String)
    | HostAdminWikiDataImportResponse Wiki.Slug (Result HostAdmin.WikiDataImportError ())
    | HostAdminWikiDataImportAutoResponse (Result HostAdmin.WikiDataImportError Wiki.Slug)


type alias BackendModel =
    { wikis : Dict Wiki.Slug Wiki
    , contributors : WikiContributors.Registry
    , contributorSessions : WikiUser.SessionTable
    , hostSessions : Set String
    , submissions : Dict String Submission.Submission
    , nextSubmissionCounter : Int
    , wikiAuditEvents : Dict Wiki.Slug (List WikiAuditLog.AuditEvent)
    }


type BackendMsg
    = ToBackendGotTime SessionId ClientId ToBackend Time.Posix


type alias RegisterDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result ContributorAccount.RegisterContributorError ())
    }


type alias LoginDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result ContributorAccount.LoginContributorError ())
    }


type alias HostAdminLoginDraft =
    { password : String
    , inFlight : Bool
    , lastResult : Maybe (Result HostAdmin.LoginError ())
    }


type alias HostAdminCreateWikiDraft =
    { slug : String
    , name : String
    , initialAdminUsername : String
    , initialAdminPassword : String
    , inFlight : Bool
    , lastResult : Maybe (Result HostAdmin.CreateHostedWikiError Wiki.CatalogEntry)
    }


type alias HostAdminWikiDetailDraft =
    { wikiSlug : Wiki.Slug
    , load : RemoteData () (Result HostAdmin.HostWikiDetailError Wiki.CatalogEntry)
    , slugDraft : String
    , nameDraft : String
    , summaryDraft : String
    , saveInFlight : Bool
    , lastSaveResult : Maybe (Result HostAdmin.UpdateHostedWikiMetadataError ())
    , lifecycleInFlight : Bool
    , lastLifecycleResult : Maybe (Result HostAdmin.WikiLifecycleError ())
    , deleteConfirmDraft : String
    , deleteInFlight : Bool
    , lastDeleteResult : Maybe (Result HostAdmin.DeleteHostedWikiError ())
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
    , lastResult : Maybe (Result Submission.SubmitNewPageError Submission.NewPageSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Submission.SaveNewPageDraftError Submission.Id)
    }


type alias PageEditSubmitDraft =
    { markdownBody : String
    , tagsInput : String
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Submission.SubmitPageEditError Submission.EditSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Submission.SavePageEditDraftError Submission.Id)
    }


type alias PageDeleteSubmitDraft =
    { reasonText : String
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Submission.PageDeleteFormError Submission.PageDeleteFormSuccess)
    , lastSaveDraftResult : Maybe (Result Submission.SavePageDeleteDraftError Submission.Id)
    }


type alias ReviewApproveDraft =
    { inFlight : Bool
    , lastResult : Maybe (Result Submission.ApproveSubmissionError ())
    }


{-| Selected moderation outcome on the review detail form (approve, request changes, or reject).
-}
type ReviewDecision
    = ReviewDecisionApprove
    | ReviewDecisionRequestChanges
    | ReviewDecisionReject


type alias ReviewRejectDraft =
    { reasonText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Submission.RejectSubmissionError ())
    }


type alias ReviewRequestChangesDraft =
    { guidanceText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Submission.RequestChangesSubmissionError ())
    }


{-| Local editor state on contributor submission detail (draft edits + action in-flight).
-}
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


emptySubmissionDetailEditDraft : SubmissionDetailEditDraft
emptySubmissionDetailEditDraft =
    { markdownBody = ""
    , newPageSlug = ""
    , saveDraftInFlight = False
    , submitForReviewInFlight = False
    , withdrawInFlight = False
    , deleteInFlight = False
    , pendingSubmitAfterSave = False
    , lastError = Nothing
    }


type alias FrontendModel =
    { key : Effect.Browser.Navigation.Key
    , colorThemePreference : ColorThemePreference
    , systemColorTheme : ColorTheme
    , route : Route
    , navigationFragment : Maybe String
    , store : Store
    , contributorWikiSessions : Dict Wiki.Slug ContributorWikiSession
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
    , wikiAdminAuditFilterSelectedKindTags : List WikiAuditLog.AuditEventKindFilterTag
    , wikiAdminAuditAppliedFilter : WikiAuditLog.AuditLogFilter
    , hostAdminAuditFilterWikiDraft : String
    , hostAdminAuditFilterActorDraft : String
    , hostAdminAuditFilterPageDraft : String
    , hostAdminAuditFilterSelectedKindTags : List WikiAuditLog.AuditEventKindFilterTag
    , hostAdminAuditAppliedFilter : WikiAuditLog.HostAuditLogFilter
    , hostAdminAuditLog : RemoteData () (Result HostAdmin.ProtectedError (List WikiAuditLog.ScopedAuditEvent))
    , hostAdminLoginDraft : HostAdminLoginDraft
    , hostAdminCreateWikiDraft : HostAdminCreateWikiDraft
    , hostAdminWikiDetailDraft : HostAdminWikiDetailDraft
    , hostAdminWikis : RemoteData () (Result HostAdmin.ProtectedError (List Wiki.CatalogEntry))
    , hostAdminSessionAuthenticated : Bool
    , hostAdminExportInFlight : Bool
    , hostAdminImportInFlight : Bool
    , hostAdminBackupNotice : Maybe String
    , hostAdminWikiExportInFlightSlug : Maybe Wiki.Slug
    , hostAdminWikiImportInFlightSlug : Maybe Wiki.Slug
    , hostAdminWikiImportPendingSlug : Maybe Wiki.Slug
    , hostAdminWikisNotice : Maybe String
    }


type FrontendMsg
    = UrlClicked Effect.Browser.UrlRequest
    | UrlChanged Url
    | UrlFragmentScrollDone
    | ColorThemeToggled
    | ColorThemeFromJs (Maybe ColorTheme.Incoming)
    | RegisterFormUsernameChanged String
    | RegisterFormPasswordChanged String
    | RegisterFormSubmitted
    | LoginFormUsernameChanged String
    | LoginFormPasswordChanged String
    | LoginFormSubmitted
    | ContributorLogoutWiki Wiki.Slug
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
    | WikiAdminAuditFilterTypeTagToggled WikiAuditLog.AuditEventKindFilterTag Bool
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
    | HostAdminAuditFilterTypeTagToggled WikiAuditLog.AuditEventKindFilterTag Bool
    | HostAdminDataExportClicked
    | HostAdminDataImportPickRequested
    | HostAdminDataImportFileSelected Effect.File.File
    | HostAdminDataImportFileRead (Result () String)
    | HostAdminWikisDataImportPickRequested
    | HostAdminWikisDataImportFileSelected Effect.File.File
    | HostAdminWikisDataImportFileRead (Result () String)
    | HostAdminWikiDataExportClicked Wiki.Slug
    | HostAdminWikiDataImportPickRequested Wiki.Slug
    | HostAdminWikiDataImportFileSelected Effect.File.File
    | HostAdminWikiDataImportFileRead Wiki.Slug (Result () String)

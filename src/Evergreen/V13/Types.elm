module Evergreen.V13.Types exposing (..)

import Dict
import Effect.Browser
import Effect.Browser.Navigation
import Effect.File
import Effect.Lamdera
import Evergreen.V13.ColorTheme
import Evergreen.V13.ContributorAccount
import Evergreen.V13.ContributorWikiSession
import Evergreen.V13.HostAdmin
import Evergreen.V13.Page
import Evergreen.V13.PendingReviewCount
import Evergreen.V13.Route
import Evergreen.V13.Store
import Evergreen.V13.Submission
import Evergreen.V13.SubmissionReviewDetail
import Evergreen.V13.Wiki
import Evergreen.V13.WikiAdminUsers
import Evergreen.V13.WikiAuditLog
import Evergreen.V13.WikiContributors
import Evergreen.V13.WikiFrontendSubscription
import Evergreen.V13.WikiRole
import Evergreen.V13.WikiUser
import RemoteData
import Set
import Time
import Url


type alias RegisterDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V13.ContributorAccount.RegisterContributorError ())
    }


type alias LoginDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V13.ContributorAccount.LoginContributorError ())
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
    , lastResult : Maybe (Result Evergreen.V13.Submission.SubmitNewPageError Evergreen.V13.Submission.NewPageSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V13.Submission.SaveNewPageDraftError Evergreen.V13.Submission.Id)
    }


type alias PageEditSubmitDraft =
    { markdownBody : String
    , tagsInput : String
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V13.Submission.SubmitPageEditError Evergreen.V13.Submission.EditSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V13.Submission.SavePageEditDraftError Evergreen.V13.Submission.Id)
    }


type alias PageDeleteSubmitDraft =
    { reasonText : String
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V13.Submission.PageDeleteFormError Evergreen.V13.Submission.PageDeleteFormSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V13.Submission.SavePageDeleteDraftError Evergreen.V13.Submission.Id)
    }


type alias ReviewApproveDraft =
    { inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V13.Submission.ApproveSubmissionError ())
    }


type ReviewDecision
    = ReviewDecisionApprove
    | ReviewDecisionRequestChanges
    | ReviewDecisionReject


type alias ReviewRejectDraft =
    { reasonText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V13.Submission.RejectSubmissionError ())
    }


type alias ReviewRequestChangesDraft =
    { guidanceText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V13.Submission.RequestChangesSubmissionError ())
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
    , lastResult : Maybe (Result Evergreen.V13.HostAdmin.LoginError ())
    }


type alias HostAdminCreateWikiDraft =
    { slug : String
    , name : String
    , initialAdminUsername : String
    , initialAdminPassword : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V13.HostAdmin.CreateHostedWikiError Evergreen.V13.Wiki.CatalogEntry)
    }


type alias HostAdminWikiDetailDraft =
    { wikiSlug : Evergreen.V13.Wiki.Slug
    , load : RemoteData.RemoteData () (Result Evergreen.V13.HostAdmin.HostWikiDetailError Evergreen.V13.Wiki.CatalogEntry)
    , slugDraft : String
    , nameDraft : String
    , summaryDraft : String
    , saveInFlight : Bool
    , lastSaveResult : Maybe (Result Evergreen.V13.HostAdmin.UpdateHostedWikiMetadataError ())
    , lifecycleInFlight : Bool
    , lastLifecycleResult : Maybe (Result Evergreen.V13.HostAdmin.WikiLifecycleError ())
    , deleteConfirmDraft : String
    , deleteInFlight : Bool
    , lastDeleteResult : Maybe (Result Evergreen.V13.HostAdmin.DeleteHostedWikiError ())
    }


type alias FrontendModel =
    { key : Effect.Browser.Navigation.Key
    , colorThemePreference : Evergreen.V13.ColorTheme.ColorThemePreference
    , systemColorTheme : Evergreen.V13.ColorTheme.ColorTheme
    , route : Evergreen.V13.Route.Route
    , navigationFragment : Maybe String
    , store : Evergreen.V13.Store.Store
    , contributorWikiSessions : Dict.Dict Evergreen.V13.Wiki.Slug Evergreen.V13.ContributorWikiSession.ContributorWikiSession
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
    , wikiAdminAuditFilterSelectedKindTags : List Evergreen.V13.WikiAuditLog.AuditEventKindFilterTag
    , wikiAdminAuditAppliedFilter : Evergreen.V13.WikiAuditLog.AuditLogFilter
    , hostAdminAuditFilterWikiDraft : String
    , hostAdminAuditFilterActorDraft : String
    , hostAdminAuditFilterPageDraft : String
    , hostAdminAuditFilterSelectedKindTags : List Evergreen.V13.WikiAuditLog.AuditEventKindFilterTag
    , hostAdminAuditAppliedFilter : Evergreen.V13.WikiAuditLog.HostAuditLogFilter
    , hostAdminAuditLog : RemoteData.RemoteData () (Result Evergreen.V13.HostAdmin.ProtectedError (List Evergreen.V13.WikiAuditLog.ScopedAuditEvent))
    , hostAdminLoginDraft : HostAdminLoginDraft
    , hostAdminCreateWikiDraft : HostAdminCreateWikiDraft
    , hostAdminWikiDetailDraft : HostAdminWikiDetailDraft
    , hostAdminWikis : RemoteData.RemoteData () (Result Evergreen.V13.HostAdmin.ProtectedError (List Evergreen.V13.Wiki.CatalogEntry))
    , hostAdminSessionAuthenticated : Bool
    , hostAdminExportInFlight : Bool
    , hostAdminImportInFlight : Bool
    , hostAdminBackupNotice : Maybe String
    , hostAdminWikiExportInFlightSlug : Maybe Evergreen.V13.Wiki.Slug
    , hostAdminWikiImportInFlightSlug : Maybe Evergreen.V13.Wiki.Slug
    , hostAdminWikiImportPendingSlug : Maybe Evergreen.V13.Wiki.Slug
    , hostAdminWikisNotice : Maybe String
    }


type alias BackendModel =
    { wikis : Dict.Dict Evergreen.V13.Wiki.Slug Evergreen.V13.Wiki.Wiki
    , contributors : Evergreen.V13.WikiContributors.Registry
    , contributorSessions : Evergreen.V13.WikiUser.SessionTable
    , hostSessions : Set.Set String
    , submissions : Dict.Dict String Evergreen.V13.Submission.Submission
    , nextSubmissionCounter : Int
    , wikiAuditEvents : Dict.Dict Evergreen.V13.Wiki.Slug (List Evergreen.V13.WikiAuditLog.AuditEvent)
    , pendingReviewCounts : Dict.Dict Evergreen.V13.Wiki.Slug Int
    , pendingReviewClients : Evergreen.V13.PendingReviewCount.PendingReviewClientSets
    , wikiFrontendClients : Evergreen.V13.WikiFrontendSubscription.WikiFrontendClientSets
    }


type FrontendMsg
    = UrlClicked Effect.Browser.UrlRequest
    | UrlChanged Url.Url
    | UrlFragmentScrollDone
    | ColorThemeToggled
    | ColorThemeFromJs (Maybe Evergreen.V13.ColorTheme.Incoming)
    | RegisterFormUsernameChanged String
    | RegisterFormPasswordChanged String
    | RegisterFormSubmitted
    | LoginFormUsernameChanged String
    | LoginFormPasswordChanged String
    | LoginFormSubmitted
    | HeaderSearchQueryChanged String
    | HeaderSearchSubmitted
    | WikiSearchPageQueryChanged String
    | ContributorLogoutWiki Evergreen.V13.Wiki.Slug
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
    | WikiAdminAuditFilterTypeTagToggled Evergreen.V13.WikiAuditLog.AuditEventKindFilterTag Bool
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
    | HostAdminAuditFilterTypeTagToggled Evergreen.V13.WikiAuditLog.AuditEventKindFilterTag Bool
    | HostAdminDataExportClicked
    | HostAdminDataImportPickRequested
    | HostAdminDataImportFileSelected Effect.File.File
    | HostAdminDataImportFileRead (Result () String)
    | HostAdminWikisDataImportPickRequested
    | HostAdminWikisDataImportFileSelected Effect.File.File
    | HostAdminWikisDataImportFileRead (Result () String)
    | HostAdminWikiDataExportClicked Evergreen.V13.Wiki.Slug
    | HostAdminWikiDataImportPickRequested Evergreen.V13.Wiki.Slug
    | HostAdminWikiDataImportFileSelected Effect.File.File
    | HostAdminWikiDataImportFileRead Evergreen.V13.Wiki.Slug (Result () String)


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
    | RequestWikiFrontendDetails Evergreen.V13.Wiki.Slug
    | RequestPageFrontendDetails Evergreen.V13.Wiki.Slug Evergreen.V13.Page.Slug
    | RequestMyPendingSubmissions Evergreen.V13.Wiki.Slug
    | RequestReviewQueue Evergreen.V13.Wiki.Slug
    | RequestReviewSubmissionDetail Evergreen.V13.Wiki.Slug String
    | RequestWikiUsers Evergreen.V13.Wiki.Slug
    | RequestWikiAuditLog Evergreen.V13.Wiki.Slug Evergreen.V13.WikiAuditLog.AuditLogFilter
    | PromoteContributorToTrusted Evergreen.V13.Wiki.Slug String
    | DemoteTrustedToContributor Evergreen.V13.Wiki.Slug String
    | GrantWikiAdmin Evergreen.V13.Wiki.Slug String
    | RevokeWikiAdmin Evergreen.V13.Wiki.Slug String
    | RequestSubmissionDetails Evergreen.V13.Wiki.Slug String
    | RegisterContributor Evergreen.V13.Wiki.Slug RegisterContributorPayload
    | LoginContributor Evergreen.V13.Wiki.Slug LoginContributorPayload
    | LogoutContributor Evergreen.V13.Wiki.Slug
    | SubmitNewPage Evergreen.V13.Wiki.Slug SubmitNewPagePayload
    | SubmitPageEdit Evergreen.V13.Wiki.Slug Evergreen.V13.Page.Slug String String
    | RequestPublishedPageDeletion Evergreen.V13.Wiki.Slug Evergreen.V13.Page.Slug String
    | DeletePublishedPageImmediately Evergreen.V13.Wiki.Slug Evergreen.V13.Page.Slug String
    | SaveNewPageDraft
        Evergreen.V13.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , rawPageSlug : String
        , rawMarkdown : String
        , rawTags : String
        }
    | SavePageEditDraft
        Evergreen.V13.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V13.Page.Slug
        , rawMarkdown : String
        , rawTags : String
        }
    | SavePageDeleteDraft
        Evergreen.V13.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V13.Page.Slug
        , rawReason : String
        }
    | SubmitDraftForReview Evergreen.V13.Wiki.Slug String
    | WithdrawSubmission Evergreen.V13.Wiki.Slug String
    | DeleteMySubmission Evergreen.V13.Wiki.Slug String
    | ApproveSubmission Evergreen.V13.Wiki.Slug String
    | RejectSubmission Evergreen.V13.Wiki.Slug RejectSubmissionPayload
    | RequestSubmissionChanges Evergreen.V13.Wiki.Slug RequestSubmissionChangesPayload
    | HostAdminLogin String
    | RequestHostWikiList
    | RequestHostAuditLog Evergreen.V13.WikiAuditLog.HostAuditLogFilter
    | RequestHostWikiDetail Evergreen.V13.Wiki.Slug
    | CreateHostedWiki CreateHostedWikiPayload
    | UpdateHostedWikiMetadata Evergreen.V13.Wiki.Slug UpdateHostedWikiMetadataPayload
    | DeactivateHostedWiki Evergreen.V13.Wiki.Slug
    | ReactivateHostedWiki Evergreen.V13.Wiki.Slug
    | DeleteHostedWiki Evergreen.V13.Wiki.Slug String
    | RequestHostAdminDataExport
    | ImportHostAdminDataSnapshot String
    | RequestHostAdminWikiDataExport Evergreen.V13.Wiki.Slug
    | ImportHostAdminWikiDataSnapshot Evergreen.V13.Wiki.Slug String
    | ImportHostAdminWikiDataSnapshotAuto String


type BackendMsg
    = ToBackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Time.Posix


type ToFrontend
    = WikiCatalogResponse (Dict.Dict Evergreen.V13.Wiki.Slug Evergreen.V13.Wiki.CatalogEntry)
    | PendingReviewCountUpdated Evergreen.V13.Wiki.Slug Int
    | WikiFrontendDetailsResponse Evergreen.V13.Wiki.Slug (Maybe Evergreen.V13.Wiki.FrontendDetails)
    | PageFrontendDetailsResponse Evergreen.V13.Wiki.Slug Evergreen.V13.Page.Slug (Maybe Evergreen.V13.Page.FrontendDetails)
    | MyPendingSubmissionsResponse Evergreen.V13.Wiki.Slug (Result Evergreen.V13.Submission.MyPendingSubmissionsError (List Evergreen.V13.Submission.MyPendingSubmissionListItem))
    | ReviewQueueResponse Evergreen.V13.Wiki.Slug (Result Evergreen.V13.Submission.ReviewQueueError (List Evergreen.V13.Submission.ReviewQueueItem))
    | ReviewSubmissionDetailResponse Evergreen.V13.Wiki.Slug String (Result Evergreen.V13.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V13.SubmissionReviewDetail.SubmissionReviewDetail)
    | WikiUsersResponse Evergreen.V13.Wiki.Slug (Result Evergreen.V13.WikiAdminUsers.Error (List Evergreen.V13.WikiAdminUsers.ListedUser))
    | WikiAuditLogResponse Evergreen.V13.Wiki.Slug Evergreen.V13.WikiAuditLog.AuditLogFilter (Result Evergreen.V13.WikiAuditLog.Error (List Evergreen.V13.WikiAuditLog.AuditEvent))
    | PromoteContributorToTrustedResponse Evergreen.V13.Wiki.Slug (Result Evergreen.V13.WikiAdminUsers.PromoteContributorError ())
    | DemoteTrustedToContributorResponse Evergreen.V13.Wiki.Slug (Result Evergreen.V13.WikiAdminUsers.DemoteTrustedError ())
    | GrantWikiAdminResponse Evergreen.V13.Wiki.Slug (Result Evergreen.V13.WikiAdminUsers.GrantTrustedToAdminError ())
    | RevokeWikiAdminResponse Evergreen.V13.Wiki.Slug (Result Evergreen.V13.WikiAdminUsers.RevokeAdminError ())
    | SubmissionDetailsResponse Evergreen.V13.Wiki.Slug String (Result Evergreen.V13.Submission.DetailsError Evergreen.V13.Submission.ContributorView)
    | RegisterContributorResponse Evergreen.V13.Wiki.Slug (Result Evergreen.V13.ContributorAccount.RegisterContributorError Evergreen.V13.WikiRole.WikiRole)
    | LoginContributorResponse Evergreen.V13.Wiki.Slug (Result Evergreen.V13.ContributorAccount.LoginContributorError Evergreen.V13.WikiRole.WikiRole)
    | LogoutContributorResponse Evergreen.V13.Wiki.Slug
    | SubmitNewPageResponse Evergreen.V13.Wiki.Slug (Result Evergreen.V13.Submission.SubmitNewPageError Evergreen.V13.Submission.NewPageSubmitSuccess)
    | SubmitPageEditResponse Evergreen.V13.Wiki.Slug (Result Evergreen.V13.Submission.SubmitPageEditError Evergreen.V13.Submission.EditSubmitSuccess)
    | RequestPublishedPageDeletionResponse Evergreen.V13.Wiki.Slug (Result Evergreen.V13.Submission.RequestPublishedPageDeletionError Evergreen.V13.Submission.Id)
    | DeletePublishedPageImmediatelyResponse Evergreen.V13.Wiki.Slug (Result Evergreen.V13.Submission.DeletePublishedPageImmediatelyError ())
    | SaveNewPageDraftResponse Evergreen.V13.Wiki.Slug (Result Evergreen.V13.Submission.SaveNewPageDraftError Evergreen.V13.Submission.Id)
    | SavePageEditDraftResponse Evergreen.V13.Wiki.Slug (Result Evergreen.V13.Submission.SavePageEditDraftError Evergreen.V13.Submission.Id)
    | SavePageDeleteDraftResponse Evergreen.V13.Wiki.Slug (Result Evergreen.V13.Submission.SavePageDeleteDraftError Evergreen.V13.Submission.Id)
    | SubmitDraftForReviewResponse Evergreen.V13.Wiki.Slug String (Result Evergreen.V13.Submission.SubmitDraftForReviewError ())
    | WithdrawSubmissionResponse Evergreen.V13.Wiki.Slug String (Result Evergreen.V13.Submission.WithdrawSubmissionError ())
    | DeleteMySubmissionResponse Evergreen.V13.Wiki.Slug String (Result Evergreen.V13.Submission.DeleteMySubmissionError ())
    | ApproveSubmissionResponse Evergreen.V13.Wiki.Slug String (Result Evergreen.V13.Submission.ApproveSubmissionError ())
    | RejectSubmissionResponse Evergreen.V13.Wiki.Slug String (Result Evergreen.V13.Submission.RejectSubmissionError ())
    | RequestSubmissionChangesResponse Evergreen.V13.Wiki.Slug String (Result Evergreen.V13.Submission.RequestChangesSubmissionError ())
    | HostAdminLoginResponse (Result Evergreen.V13.HostAdmin.LoginError ())
    | HostAdminWikiListResponse (Result Evergreen.V13.HostAdmin.ProtectedError (List Evergreen.V13.Wiki.CatalogEntry))
    | HostAuditLogResponse Evergreen.V13.WikiAuditLog.HostAuditLogFilter (Result Evergreen.V13.HostAdmin.ProtectedError (List Evergreen.V13.WikiAuditLog.ScopedAuditEvent))
    | CreateHostedWikiResponse (Result Evergreen.V13.HostAdmin.CreateHostedWikiError Evergreen.V13.Wiki.CatalogEntry)
    | HostWikiDetailResponse Evergreen.V13.Wiki.Slug (Result Evergreen.V13.HostAdmin.HostWikiDetailError Evergreen.V13.Wiki.CatalogEntry)
    | UpdateHostedWikiMetadataResponse Evergreen.V13.Wiki.Slug (Result Evergreen.V13.HostAdmin.UpdateHostedWikiMetadataError Evergreen.V13.Wiki.CatalogEntry)
    | DeactivateHostedWikiResponse Evergreen.V13.Wiki.Slug (Result Evergreen.V13.HostAdmin.WikiLifecycleError Evergreen.V13.Wiki.CatalogEntry)
    | ReactivateHostedWikiResponse Evergreen.V13.Wiki.Slug (Result Evergreen.V13.HostAdmin.WikiLifecycleError Evergreen.V13.Wiki.CatalogEntry)
    | DeleteHostedWikiResponse Evergreen.V13.Wiki.Slug (Result Evergreen.V13.HostAdmin.DeleteHostedWikiError ())
    | HostAdminDataExportResponse (Result Evergreen.V13.HostAdmin.DataExportError String)
    | HostAdminDataImportResponse (Result Evergreen.V13.HostAdmin.DataImportError ())
    | HostAdminWikiDataExportResponse Evergreen.V13.Wiki.Slug (Result Evergreen.V13.HostAdmin.WikiDataExportError String)
    | HostAdminWikiDataImportResponse Evergreen.V13.Wiki.Slug (Result Evergreen.V13.HostAdmin.WikiDataImportError ())
    | HostAdminWikiDataImportAutoResponse (Result Evergreen.V13.HostAdmin.WikiDataImportError Evergreen.V13.Wiki.Slug)

module Evergreen.V17.Types exposing (..)

import Dict
import Effect.Browser
import Effect.Browser.Navigation
import Effect.File
import Effect.Lamdera
import Evergreen.V17.ColorTheme
import Evergreen.V17.ContributorAccount
import Evergreen.V17.ContributorWikiSession
import Evergreen.V17.HostAdmin
import Evergreen.V17.Page
import Evergreen.V17.PendingReviewCount
import Evergreen.V17.Route
import Evergreen.V17.Store
import Evergreen.V17.Submission
import Evergreen.V17.SubmissionReviewDetail
import Evergreen.V17.Wiki
import Evergreen.V17.WikiAdminUsers
import Evergreen.V17.WikiAuditLog
import Evergreen.V17.WikiContributors
import Evergreen.V17.WikiFrontendSubscription
import Evergreen.V17.WikiMarkdownEditorPane
import Evergreen.V17.WikiRole
import Evergreen.V17.WikiSearch
import Evergreen.V17.WikiUser
import RemoteData
import Set
import Time
import Url


type alias RegisterDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V17.ContributorAccount.RegisterContributorError ())
    }


type alias LoginDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V17.ContributorAccount.LoginContributorError ())
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
    , lastResult : Maybe (Result Evergreen.V17.Submission.SubmitNewPageError Evergreen.V17.Submission.NewPageSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V17.Submission.SaveNewPageDraftError Evergreen.V17.Submission.Id)
    }


type alias PageEditSubmitDraft =
    { markdownBody : String
    , tagsInput : String
    , publishedRowCollapsed : Bool
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V17.Submission.SubmitPageEditError Evergreen.V17.Submission.EditSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V17.Submission.SavePageEditDraftError Evergreen.V17.Submission.Id)
    }


type alias PageDeleteSubmitDraft =
    { reasonText : String
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V17.Submission.PageDeleteFormError Evergreen.V17.Submission.PageDeleteFormSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V17.Submission.SavePageDeleteDraftError Evergreen.V17.Submission.Id)
    }


type alias ReviewApproveDraft =
    { inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V17.Submission.ApproveSubmissionError ())
    }


type ReviewDecision
    = ReviewDecisionApprove
    | ReviewDecisionRequestChanges
    | ReviewDecisionReject


type alias ReviewRejectDraft =
    { reasonText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V17.Submission.RejectSubmissionError ())
    }


type alias ReviewRequestChangesDraft =
    { guidanceText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V17.Submission.RequestChangesSubmissionError ())
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
    , lastResult : Maybe (Result Evergreen.V17.HostAdmin.LoginError ())
    }


type alias HostAdminCreateWikiDraft =
    { slug : String
    , name : String
    , initialAdminUsername : String
    , initialAdminPassword : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V17.HostAdmin.CreateHostedWikiError Evergreen.V17.Wiki.CatalogEntry)
    }


type alias HostAdminWikiDetailDraft =
    { wikiSlug : Evergreen.V17.Wiki.Slug
    , load : RemoteData.RemoteData () (Result Evergreen.V17.HostAdmin.HostWikiDetailError Evergreen.V17.Wiki.CatalogEntry)
    , slugDraft : String
    , nameDraft : String
    , summaryDraft : String
    , saveInFlight : Bool
    , lastSaveResult : Maybe (Result Evergreen.V17.HostAdmin.UpdateHostedWikiMetadataError ())
    , lifecycleInFlight : Bool
    , lastLifecycleResult : Maybe (Result Evergreen.V17.HostAdmin.WikiLifecycleError ())
    , deleteConfirmDraft : String
    , deleteInFlight : Bool
    , lastDeleteResult : Maybe (Result Evergreen.V17.HostAdmin.DeleteHostedWikiError ())
    }


type alias FrontendModel =
    { key : Effect.Browser.Navigation.Key
    , colorThemePreference : Evergreen.V17.ColorTheme.ColorThemePreference
    , systemColorTheme : Evergreen.V17.ColorTheme.ColorTheme
    , route : Evergreen.V17.Route.Route
    , navigationFragment : Maybe String
    , store : Evergreen.V17.Store.Store
    , contributorWikiSessions : Dict.Dict Evergreen.V17.Wiki.Slug Evergreen.V17.ContributorWikiSession.ContributorWikiSession
    , registerDraft : RegisterDraft
    , loginDraft : LoginDraft
    , headerSearchQuery : String
    , headerSearchResults : List Evergreen.V17.WikiSearch.ResultItem
    , headerSearchPending : Maybe ( Evergreen.V17.Wiki.Slug, String )
    , wikiSearchPageQuery : String
    , wikiSearchPageResults : List Evergreen.V17.WikiSearch.ResultItem
    , wikiSearchPagePending : Maybe ( Evergreen.V17.Wiki.Slug, String )
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
    , wikiAdminAuditFilterSelectedKindTags : List Evergreen.V17.WikiAuditLog.AuditEventKindFilterTag
    , wikiAdminAuditAppliedFilter : Evergreen.V17.WikiAuditLog.AuditLogFilter
    , hostAdminAuditFilterWikiDraft : String
    , hostAdminAuditFilterActorDraft : String
    , hostAdminAuditFilterPageDraft : String
    , hostAdminAuditFilterSelectedKindTags : List Evergreen.V17.WikiAuditLog.AuditEventKindFilterTag
    , hostAdminAuditAppliedFilter : Evergreen.V17.WikiAuditLog.HostAuditLogFilter
    , hostAdminAuditLog : RemoteData.RemoteData () (Result Evergreen.V17.HostAdmin.ProtectedError (List Evergreen.V17.WikiAuditLog.ScopedAuditEvent))
    , hostAdminLoginDraft : HostAdminLoginDraft
    , hostAdminCreateWikiDraft : HostAdminCreateWikiDraft
    , hostAdminWikiDetailDraft : HostAdminWikiDetailDraft
    , hostAdminWikis : RemoteData.RemoteData () (Result Evergreen.V17.HostAdmin.ProtectedError (List Evergreen.V17.Wiki.CatalogEntry))
    , hostAdminSessionAuthenticated : Bool
    , hostAdminExportInFlight : Bool
    , hostAdminImportInFlight : Bool
    , hostAdminBackupNotice : Maybe String
    , hostAdminWikiExportInFlightSlug : Maybe Evergreen.V17.Wiki.Slug
    , hostAdminWikiImportInFlightSlug : Maybe Evergreen.V17.Wiki.Slug
    , hostAdminWikiImportPendingSlug : Maybe Evergreen.V17.Wiki.Slug
    , hostAdminWikisNotice : Maybe String
    , sideNavOpen : Bool
    , wikiMarkdownEditorPane : Evergreen.V17.WikiMarkdownEditorPane.WikiMarkdownEditorPane
    }


type alias BackendModel =
    { wikis : Dict.Dict Evergreen.V17.Wiki.Slug Evergreen.V17.Wiki.Wiki
    , contributors : Evergreen.V17.WikiContributors.Registry
    , contributorSessions : Evergreen.V17.WikiUser.SessionTable
    , hostSessions : Set.Set String
    , submissions : Dict.Dict String Evergreen.V17.Submission.Submission
    , nextSubmissionCounter : Int
    , wikiAuditEvents : Dict.Dict Evergreen.V17.Wiki.Slug (List Evergreen.V17.WikiAuditLog.AuditEvent)
    , pendingReviewCounts : Dict.Dict Evergreen.V17.Wiki.Slug Int
    , pendingReviewClients : Evergreen.V17.PendingReviewCount.PendingReviewClientSets
    , wikiFrontendClients : Evergreen.V17.WikiFrontendSubscription.WikiFrontendClientSets
    , wikiSearchIndexes : Dict.Dict Evergreen.V17.Wiki.Slug Evergreen.V17.WikiSearch.PrefixIndex
    }


type FrontendMsg
    = UrlClicked Effect.Browser.UrlRequest
    | UrlChanged Url.Url
    | UrlFragmentScrollDone
    | ColorThemeToggled
    | ColorThemeFromJs (Maybe Evergreen.V17.ColorTheme.Incoming)
    | RegisterFormUsernameChanged String
    | RegisterFormPasswordChanged String
    | RegisterFormSubmitted
    | LoginFormUsernameChanged String
    | LoginFormPasswordChanged String
    | LoginFormSubmitted
    | HeaderSearchQueryChanged String
    | HeaderSearchTimeoutReached Evergreen.V17.Wiki.Slug String
    | HeaderSearchSubmitted
    | WikiSearchPageQueryChanged String
    | WikiSearchPageTimeoutReached Evergreen.V17.Wiki.Slug String
    | ContributorLogoutWiki Evergreen.V17.Wiki.Slug
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
    | WikiAdminAuditFilterTypeTagToggled Evergreen.V17.WikiAuditLog.AuditEventKindFilterTag Bool
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
    | HostAdminAuditFilterTypeTagToggled Evergreen.V17.WikiAuditLog.AuditEventKindFilterTag Bool
    | HostAdminDataExportClicked
    | HostAdminDataImportPickRequested
    | HostAdminDataImportFileSelected Effect.File.File
    | HostAdminDataImportFileRead (Result () String)
    | HostAdminWikisDataImportPickRequested
    | HostAdminWikisDataImportFileSelected Effect.File.File
    | HostAdminWikisDataImportFileRead (Result () String)
    | HostAdminWikiDataExportClicked Evergreen.V17.Wiki.Slug
    | HostAdminWikiDataImportPickRequested Evergreen.V17.Wiki.Slug
    | HostAdminWikiDataImportFileSelected Effect.File.File
    | HostAdminWikiDataImportFileRead Evergreen.V17.Wiki.Slug (Result () String)
    | SideNavOpened
    | SideNavClosed
    | WikiMarkdownEditorPaneSelected Evergreen.V17.WikiMarkdownEditorPane.WikiMarkdownEditorPane


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
    | RequestWikiFrontendDetails Evergreen.V17.Wiki.Slug
    | RequestPageFrontendDetails Evergreen.V17.Wiki.Slug Evergreen.V17.Page.Slug
    | RequestWikiSearch Evergreen.V17.Wiki.Slug String
    | RequestMyPendingSubmissions Evergreen.V17.Wiki.Slug
    | RequestReviewQueue Evergreen.V17.Wiki.Slug
    | RequestReviewSubmissionDetail Evergreen.V17.Wiki.Slug String
    | RequestWikiUsers Evergreen.V17.Wiki.Slug
    | RequestWikiAuditLog Evergreen.V17.Wiki.Slug Evergreen.V17.WikiAuditLog.AuditLogFilter
    | PromoteContributorToTrusted Evergreen.V17.Wiki.Slug String
    | DemoteTrustedToContributor Evergreen.V17.Wiki.Slug String
    | GrantWikiAdmin Evergreen.V17.Wiki.Slug String
    | RevokeWikiAdmin Evergreen.V17.Wiki.Slug String
    | RequestSubmissionDetails Evergreen.V17.Wiki.Slug String
    | RegisterContributor Evergreen.V17.Wiki.Slug RegisterContributorPayload
    | LoginContributor Evergreen.V17.Wiki.Slug LoginContributorPayload
    | LogoutContributor Evergreen.V17.Wiki.Slug
    | SubmitNewPage Evergreen.V17.Wiki.Slug SubmitNewPagePayload
    | SubmitPageEdit Evergreen.V17.Wiki.Slug Evergreen.V17.Page.Slug String String
    | RequestPublishedPageDeletion Evergreen.V17.Wiki.Slug Evergreen.V17.Page.Slug String
    | DeletePublishedPageImmediately Evergreen.V17.Wiki.Slug Evergreen.V17.Page.Slug String
    | SaveNewPageDraft
        Evergreen.V17.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , rawPageSlug : String
        , rawMarkdown : String
        , rawTags : String
        }
    | SavePageEditDraft
        Evergreen.V17.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V17.Page.Slug
        , rawMarkdown : String
        , rawTags : String
        }
    | SavePageDeleteDraft
        Evergreen.V17.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V17.Page.Slug
        , rawReason : String
        }
    | SubmitDraftForReview Evergreen.V17.Wiki.Slug String
    | WithdrawSubmission Evergreen.V17.Wiki.Slug String
    | DeleteMySubmission Evergreen.V17.Wiki.Slug String
    | ApproveSubmission Evergreen.V17.Wiki.Slug String
    | RejectSubmission Evergreen.V17.Wiki.Slug RejectSubmissionPayload
    | RequestSubmissionChanges Evergreen.V17.Wiki.Slug RequestSubmissionChangesPayload
    | HostAdminLogin String
    | RequestHostWikiList
    | RequestHostAuditLog Evergreen.V17.WikiAuditLog.HostAuditLogFilter
    | RequestHostWikiDetail Evergreen.V17.Wiki.Slug
    | CreateHostedWiki CreateHostedWikiPayload
    | UpdateHostedWikiMetadata Evergreen.V17.Wiki.Slug UpdateHostedWikiMetadataPayload
    | DeactivateHostedWiki Evergreen.V17.Wiki.Slug
    | ReactivateHostedWiki Evergreen.V17.Wiki.Slug
    | DeleteHostedWiki Evergreen.V17.Wiki.Slug String
    | RequestHostAdminDataExport
    | ImportHostAdminDataSnapshot String
    | RequestHostAdminWikiDataExport Evergreen.V17.Wiki.Slug
    | ImportHostAdminWikiDataSnapshot Evergreen.V17.Wiki.Slug String
    | ImportHostAdminWikiDataSnapshotAuto String


type BackendMsg
    = ToBackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Time.Posix


type ToFrontend
    = WikiCatalogResponse (Dict.Dict Evergreen.V17.Wiki.Slug Evergreen.V17.Wiki.CatalogEntry)
    | PendingReviewCountUpdated Evergreen.V17.Wiki.Slug Int
    | WikiFrontendDetailsResponse Evergreen.V17.Wiki.Slug (Maybe Evergreen.V17.Wiki.FrontendDetails)
    | PageFrontendDetailsResponse Evergreen.V17.Wiki.Slug Evergreen.V17.Page.Slug (Maybe Evergreen.V17.Page.FrontendDetails)
    | WikiSearchResponse Evergreen.V17.Wiki.Slug String (List Evergreen.V17.WikiSearch.ResultItem)
    | MyPendingSubmissionsResponse Evergreen.V17.Wiki.Slug (Result Evergreen.V17.Submission.MyPendingSubmissionsError (List Evergreen.V17.Submission.MyPendingSubmissionListItem))
    | ReviewQueueResponse Evergreen.V17.Wiki.Slug (Result Evergreen.V17.Submission.ReviewQueueError (List Evergreen.V17.Submission.ReviewQueueItem))
    | ReviewSubmissionDetailResponse Evergreen.V17.Wiki.Slug String (Result Evergreen.V17.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V17.SubmissionReviewDetail.SubmissionReviewDetail)
    | WikiUsersResponse Evergreen.V17.Wiki.Slug (Result Evergreen.V17.WikiAdminUsers.Error (List Evergreen.V17.WikiAdminUsers.ListedUser))
    | WikiAuditLogResponse Evergreen.V17.Wiki.Slug Evergreen.V17.WikiAuditLog.AuditLogFilter (Result Evergreen.V17.WikiAuditLog.Error (List Evergreen.V17.WikiAuditLog.AuditEvent))
    | PromoteContributorToTrustedResponse Evergreen.V17.Wiki.Slug (Result Evergreen.V17.WikiAdminUsers.PromoteContributorError ())
    | DemoteTrustedToContributorResponse Evergreen.V17.Wiki.Slug (Result Evergreen.V17.WikiAdminUsers.DemoteTrustedError ())
    | GrantWikiAdminResponse Evergreen.V17.Wiki.Slug (Result Evergreen.V17.WikiAdminUsers.GrantTrustedToAdminError ())
    | RevokeWikiAdminResponse Evergreen.V17.Wiki.Slug (Result Evergreen.V17.WikiAdminUsers.RevokeAdminError ())
    | SubmissionDetailsResponse Evergreen.V17.Wiki.Slug String (Result Evergreen.V17.Submission.DetailsError Evergreen.V17.Submission.ContributorView)
    | RegisterContributorResponse Evergreen.V17.Wiki.Slug (Result Evergreen.V17.ContributorAccount.RegisterContributorError Evergreen.V17.WikiRole.WikiRole)
    | LoginContributorResponse Evergreen.V17.Wiki.Slug (Result Evergreen.V17.ContributorAccount.LoginContributorError Evergreen.V17.WikiRole.WikiRole)
    | LogoutContributorResponse Evergreen.V17.Wiki.Slug
    | SubmitNewPageResponse Evergreen.V17.Wiki.Slug (Result Evergreen.V17.Submission.SubmitNewPageError Evergreen.V17.Submission.NewPageSubmitSuccess)
    | SubmitPageEditResponse Evergreen.V17.Wiki.Slug (Result Evergreen.V17.Submission.SubmitPageEditError Evergreen.V17.Submission.EditSubmitSuccess)
    | RequestPublishedPageDeletionResponse Evergreen.V17.Wiki.Slug (Result Evergreen.V17.Submission.RequestPublishedPageDeletionError Evergreen.V17.Submission.Id)
    | DeletePublishedPageImmediatelyResponse Evergreen.V17.Wiki.Slug (Result Evergreen.V17.Submission.DeletePublishedPageImmediatelyError ())
    | SaveNewPageDraftResponse Evergreen.V17.Wiki.Slug (Result Evergreen.V17.Submission.SaveNewPageDraftError Evergreen.V17.Submission.Id)
    | SavePageEditDraftResponse Evergreen.V17.Wiki.Slug (Result Evergreen.V17.Submission.SavePageEditDraftError Evergreen.V17.Submission.Id)
    | SavePageDeleteDraftResponse Evergreen.V17.Wiki.Slug (Result Evergreen.V17.Submission.SavePageDeleteDraftError Evergreen.V17.Submission.Id)
    | SubmitDraftForReviewResponse Evergreen.V17.Wiki.Slug String (Result Evergreen.V17.Submission.SubmitDraftForReviewError ())
    | WithdrawSubmissionResponse Evergreen.V17.Wiki.Slug String (Result Evergreen.V17.Submission.WithdrawSubmissionError ())
    | DeleteMySubmissionResponse Evergreen.V17.Wiki.Slug String (Result Evergreen.V17.Submission.DeleteMySubmissionError ())
    | ApproveSubmissionResponse Evergreen.V17.Wiki.Slug String (Result Evergreen.V17.Submission.ApproveSubmissionError ())
    | RejectSubmissionResponse Evergreen.V17.Wiki.Slug String (Result Evergreen.V17.Submission.RejectSubmissionError ())
    | RequestSubmissionChangesResponse Evergreen.V17.Wiki.Slug String (Result Evergreen.V17.Submission.RequestChangesSubmissionError ())
    | HostAdminLoginResponse (Result Evergreen.V17.HostAdmin.LoginError ())
    | HostAdminWikiListResponse (Result Evergreen.V17.HostAdmin.ProtectedError (List Evergreen.V17.Wiki.CatalogEntry))
    | HostAuditLogResponse Evergreen.V17.WikiAuditLog.HostAuditLogFilter (Result Evergreen.V17.HostAdmin.ProtectedError (List Evergreen.V17.WikiAuditLog.ScopedAuditEvent))
    | CreateHostedWikiResponse (Result Evergreen.V17.HostAdmin.CreateHostedWikiError Evergreen.V17.Wiki.CatalogEntry)
    | HostWikiDetailResponse Evergreen.V17.Wiki.Slug (Result Evergreen.V17.HostAdmin.HostWikiDetailError Evergreen.V17.Wiki.CatalogEntry)
    | UpdateHostedWikiMetadataResponse Evergreen.V17.Wiki.Slug (Result Evergreen.V17.HostAdmin.UpdateHostedWikiMetadataError Evergreen.V17.Wiki.CatalogEntry)
    | DeactivateHostedWikiResponse Evergreen.V17.Wiki.Slug (Result Evergreen.V17.HostAdmin.WikiLifecycleError Evergreen.V17.Wiki.CatalogEntry)
    | ReactivateHostedWikiResponse Evergreen.V17.Wiki.Slug (Result Evergreen.V17.HostAdmin.WikiLifecycleError Evergreen.V17.Wiki.CatalogEntry)
    | DeleteHostedWikiResponse Evergreen.V17.Wiki.Slug (Result Evergreen.V17.HostAdmin.DeleteHostedWikiError ())
    | HostAdminDataExportResponse (Result Evergreen.V17.HostAdmin.DataExportError String)
    | HostAdminDataImportResponse (Result Evergreen.V17.HostAdmin.DataImportError ())
    | HostAdminWikiDataExportResponse Evergreen.V17.Wiki.Slug (Result Evergreen.V17.HostAdmin.WikiDataExportError String)
    | HostAdminWikiDataImportResponse Evergreen.V17.Wiki.Slug (Result Evergreen.V17.HostAdmin.WikiDataImportError ())
    | HostAdminWikiDataImportAutoResponse (Result Evergreen.V17.HostAdmin.WikiDataImportError Evergreen.V17.Wiki.Slug)

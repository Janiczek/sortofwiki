module Evergreen.V16.Types exposing (..)

import Dict
import Effect.Browser
import Effect.Browser.Navigation
import Effect.File
import Effect.Lamdera
import Evergreen.V16.ColorTheme
import Evergreen.V16.ContributorAccount
import Evergreen.V16.ContributorWikiSession
import Evergreen.V16.HostAdmin
import Evergreen.V16.Page
import Evergreen.V16.PendingReviewCount
import Evergreen.V16.Route
import Evergreen.V16.Store
import Evergreen.V16.Submission
import Evergreen.V16.SubmissionReviewDetail
import Evergreen.V16.Wiki
import Evergreen.V16.WikiAdminUsers
import Evergreen.V16.WikiAuditLog
import Evergreen.V16.WikiContributors
import Evergreen.V16.WikiFrontendSubscription
import Evergreen.V16.WikiMarkdownEditorPane
import Evergreen.V16.WikiRole
import Evergreen.V16.WikiSearch
import Evergreen.V16.WikiUser
import RemoteData
import Set
import Time
import Url


type alias RegisterDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V16.ContributorAccount.RegisterContributorError ())
    }


type alias LoginDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V16.ContributorAccount.LoginContributorError ())
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
    , lastResult : Maybe (Result Evergreen.V16.Submission.SubmitNewPageError Evergreen.V16.Submission.NewPageSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V16.Submission.SaveNewPageDraftError Evergreen.V16.Submission.Id)
    }


type alias PageEditSubmitDraft =
    { markdownBody : String
    , tagsInput : String
    , publishedRowCollapsed : Bool
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V16.Submission.SubmitPageEditError Evergreen.V16.Submission.EditSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V16.Submission.SavePageEditDraftError Evergreen.V16.Submission.Id)
    }


type alias PageDeleteSubmitDraft =
    { reasonText : String
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V16.Submission.PageDeleteFormError Evergreen.V16.Submission.PageDeleteFormSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V16.Submission.SavePageDeleteDraftError Evergreen.V16.Submission.Id)
    }


type alias ReviewApproveDraft =
    { inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V16.Submission.ApproveSubmissionError ())
    }


type ReviewDecision
    = ReviewDecisionApprove
    | ReviewDecisionRequestChanges
    | ReviewDecisionReject


type alias ReviewRejectDraft =
    { reasonText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V16.Submission.RejectSubmissionError ())
    }


type alias ReviewRequestChangesDraft =
    { guidanceText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V16.Submission.RequestChangesSubmissionError ())
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
    , lastResult : Maybe (Result Evergreen.V16.HostAdmin.LoginError ())
    }


type alias HostAdminCreateWikiDraft =
    { slug : String
    , name : String
    , initialAdminUsername : String
    , initialAdminPassword : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V16.HostAdmin.CreateHostedWikiError Evergreen.V16.Wiki.CatalogEntry)
    }


type alias HostAdminWikiDetailDraft =
    { wikiSlug : Evergreen.V16.Wiki.Slug
    , load : RemoteData.RemoteData () (Result Evergreen.V16.HostAdmin.HostWikiDetailError Evergreen.V16.Wiki.CatalogEntry)
    , slugDraft : String
    , nameDraft : String
    , summaryDraft : String
    , saveInFlight : Bool
    , lastSaveResult : Maybe (Result Evergreen.V16.HostAdmin.UpdateHostedWikiMetadataError ())
    , lifecycleInFlight : Bool
    , lastLifecycleResult : Maybe (Result Evergreen.V16.HostAdmin.WikiLifecycleError ())
    , deleteConfirmDraft : String
    , deleteInFlight : Bool
    , lastDeleteResult : Maybe (Result Evergreen.V16.HostAdmin.DeleteHostedWikiError ())
    }


type alias FrontendModel =
    { key : Effect.Browser.Navigation.Key
    , colorThemePreference : Evergreen.V16.ColorTheme.ColorThemePreference
    , systemColorTheme : Evergreen.V16.ColorTheme.ColorTheme
    , route : Evergreen.V16.Route.Route
    , navigationFragment : Maybe String
    , store : Evergreen.V16.Store.Store
    , contributorWikiSessions : Dict.Dict Evergreen.V16.Wiki.Slug Evergreen.V16.ContributorWikiSession.ContributorWikiSession
    , registerDraft : RegisterDraft
    , loginDraft : LoginDraft
    , headerSearchQuery : String
    , headerSearchResults : List Evergreen.V16.WikiSearch.ResultItem
    , headerSearchPending : Maybe ( Evergreen.V16.Wiki.Slug, String )
    , wikiSearchPageQuery : String
    , wikiSearchPageResults : List Evergreen.V16.WikiSearch.ResultItem
    , wikiSearchPagePending : Maybe ( Evergreen.V16.Wiki.Slug, String )
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
    , wikiAdminAuditFilterSelectedKindTags : List Evergreen.V16.WikiAuditLog.AuditEventKindFilterTag
    , wikiAdminAuditAppliedFilter : Evergreen.V16.WikiAuditLog.AuditLogFilter
    , hostAdminAuditFilterWikiDraft : String
    , hostAdminAuditFilterActorDraft : String
    , hostAdminAuditFilterPageDraft : String
    , hostAdminAuditFilterSelectedKindTags : List Evergreen.V16.WikiAuditLog.AuditEventKindFilterTag
    , hostAdminAuditAppliedFilter : Evergreen.V16.WikiAuditLog.HostAuditLogFilter
    , hostAdminAuditLog : RemoteData.RemoteData () (Result Evergreen.V16.HostAdmin.ProtectedError (List Evergreen.V16.WikiAuditLog.ScopedAuditEvent))
    , hostAdminLoginDraft : HostAdminLoginDraft
    , hostAdminCreateWikiDraft : HostAdminCreateWikiDraft
    , hostAdminWikiDetailDraft : HostAdminWikiDetailDraft
    , hostAdminWikis : RemoteData.RemoteData () (Result Evergreen.V16.HostAdmin.ProtectedError (List Evergreen.V16.Wiki.CatalogEntry))
    , hostAdminSessionAuthenticated : Bool
    , hostAdminExportInFlight : Bool
    , hostAdminImportInFlight : Bool
    , hostAdminBackupNotice : Maybe String
    , hostAdminWikiExportInFlightSlug : Maybe Evergreen.V16.Wiki.Slug
    , hostAdminWikiImportInFlightSlug : Maybe Evergreen.V16.Wiki.Slug
    , hostAdminWikiImportPendingSlug : Maybe Evergreen.V16.Wiki.Slug
    , hostAdminWikisNotice : Maybe String
    , sideNavOpen : Bool
    , wikiMarkdownEditorPane : Evergreen.V16.WikiMarkdownEditorPane.WikiMarkdownEditorPane
    }


type alias BackendModel =
    { wikis : Dict.Dict Evergreen.V16.Wiki.Slug Evergreen.V16.Wiki.Wiki
    , contributors : Evergreen.V16.WikiContributors.Registry
    , contributorSessions : Evergreen.V16.WikiUser.SessionTable
    , hostSessions : Set.Set String
    , submissions : Dict.Dict String Evergreen.V16.Submission.Submission
    , nextSubmissionCounter : Int
    , wikiAuditEvents : Dict.Dict Evergreen.V16.Wiki.Slug (List Evergreen.V16.WikiAuditLog.AuditEvent)
    , pendingReviewCounts : Dict.Dict Evergreen.V16.Wiki.Slug Int
    , pendingReviewClients : Evergreen.V16.PendingReviewCount.PendingReviewClientSets
    , wikiFrontendClients : Evergreen.V16.WikiFrontendSubscription.WikiFrontendClientSets
    , wikiSearchIndexes : Dict.Dict Evergreen.V16.Wiki.Slug Evergreen.V16.WikiSearch.PrefixIndex
    }


type FrontendMsg
    = UrlClicked Effect.Browser.UrlRequest
    | UrlChanged Url.Url
    | UrlFragmentScrollDone
    | ColorThemeToggled
    | ColorThemeFromJs (Maybe Evergreen.V16.ColorTheme.Incoming)
    | RegisterFormUsernameChanged String
    | RegisterFormPasswordChanged String
    | RegisterFormSubmitted
    | LoginFormUsernameChanged String
    | LoginFormPasswordChanged String
    | LoginFormSubmitted
    | HeaderSearchQueryChanged String
    | HeaderSearchTimeoutReached Evergreen.V16.Wiki.Slug String
    | HeaderSearchSubmitted
    | WikiSearchPageQueryChanged String
    | WikiSearchPageTimeoutReached Evergreen.V16.Wiki.Slug String
    | ContributorLogoutWiki Evergreen.V16.Wiki.Slug
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
    | WikiAdminAuditFilterTypeTagToggled Evergreen.V16.WikiAuditLog.AuditEventKindFilterTag Bool
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
    | HostAdminAuditFilterTypeTagToggled Evergreen.V16.WikiAuditLog.AuditEventKindFilterTag Bool
    | HostAdminDataExportClicked
    | HostAdminDataImportPickRequested
    | HostAdminDataImportFileSelected Effect.File.File
    | HostAdminDataImportFileRead (Result () String)
    | HostAdminWikisDataImportPickRequested
    | HostAdminWikisDataImportFileSelected Effect.File.File
    | HostAdminWikisDataImportFileRead (Result () String)
    | HostAdminWikiDataExportClicked Evergreen.V16.Wiki.Slug
    | HostAdminWikiDataImportPickRequested Evergreen.V16.Wiki.Slug
    | HostAdminWikiDataImportFileSelected Effect.File.File
    | HostAdminWikiDataImportFileRead Evergreen.V16.Wiki.Slug (Result () String)
    | SideNavOpened
    | SideNavClosed
    | WikiMarkdownEditorPaneSelected Evergreen.V16.WikiMarkdownEditorPane.WikiMarkdownEditorPane


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
    | RequestWikiFrontendDetails Evergreen.V16.Wiki.Slug
    | RequestPageFrontendDetails Evergreen.V16.Wiki.Slug Evergreen.V16.Page.Slug
    | RequestWikiSearch Evergreen.V16.Wiki.Slug String
    | RequestMyPendingSubmissions Evergreen.V16.Wiki.Slug
    | RequestReviewQueue Evergreen.V16.Wiki.Slug
    | RequestReviewSubmissionDetail Evergreen.V16.Wiki.Slug String
    | RequestWikiUsers Evergreen.V16.Wiki.Slug
    | RequestWikiAuditLog Evergreen.V16.Wiki.Slug Evergreen.V16.WikiAuditLog.AuditLogFilter
    | PromoteContributorToTrusted Evergreen.V16.Wiki.Slug String
    | DemoteTrustedToContributor Evergreen.V16.Wiki.Slug String
    | GrantWikiAdmin Evergreen.V16.Wiki.Slug String
    | RevokeWikiAdmin Evergreen.V16.Wiki.Slug String
    | RequestSubmissionDetails Evergreen.V16.Wiki.Slug String
    | RegisterContributor Evergreen.V16.Wiki.Slug RegisterContributorPayload
    | LoginContributor Evergreen.V16.Wiki.Slug LoginContributorPayload
    | LogoutContributor Evergreen.V16.Wiki.Slug
    | SubmitNewPage Evergreen.V16.Wiki.Slug SubmitNewPagePayload
    | SubmitPageEdit Evergreen.V16.Wiki.Slug Evergreen.V16.Page.Slug String String
    | RequestPublishedPageDeletion Evergreen.V16.Wiki.Slug Evergreen.V16.Page.Slug String
    | DeletePublishedPageImmediately Evergreen.V16.Wiki.Slug Evergreen.V16.Page.Slug String
    | SaveNewPageDraft
        Evergreen.V16.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , rawPageSlug : String
        , rawMarkdown : String
        , rawTags : String
        }
    | SavePageEditDraft
        Evergreen.V16.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V16.Page.Slug
        , rawMarkdown : String
        , rawTags : String
        }
    | SavePageDeleteDraft
        Evergreen.V16.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V16.Page.Slug
        , rawReason : String
        }
    | SubmitDraftForReview Evergreen.V16.Wiki.Slug String
    | WithdrawSubmission Evergreen.V16.Wiki.Slug String
    | DeleteMySubmission Evergreen.V16.Wiki.Slug String
    | ApproveSubmission Evergreen.V16.Wiki.Slug String
    | RejectSubmission Evergreen.V16.Wiki.Slug RejectSubmissionPayload
    | RequestSubmissionChanges Evergreen.V16.Wiki.Slug RequestSubmissionChangesPayload
    | HostAdminLogin String
    | RequestHostWikiList
    | RequestHostAuditLog Evergreen.V16.WikiAuditLog.HostAuditLogFilter
    | RequestHostWikiDetail Evergreen.V16.Wiki.Slug
    | CreateHostedWiki CreateHostedWikiPayload
    | UpdateHostedWikiMetadata Evergreen.V16.Wiki.Slug UpdateHostedWikiMetadataPayload
    | DeactivateHostedWiki Evergreen.V16.Wiki.Slug
    | ReactivateHostedWiki Evergreen.V16.Wiki.Slug
    | DeleteHostedWiki Evergreen.V16.Wiki.Slug String
    | RequestHostAdminDataExport
    | ImportHostAdminDataSnapshot String
    | RequestHostAdminWikiDataExport Evergreen.V16.Wiki.Slug
    | ImportHostAdminWikiDataSnapshot Evergreen.V16.Wiki.Slug String
    | ImportHostAdminWikiDataSnapshotAuto String


type BackendMsg
    = ToBackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Time.Posix


type ToFrontend
    = WikiCatalogResponse (Dict.Dict Evergreen.V16.Wiki.Slug Evergreen.V16.Wiki.CatalogEntry)
    | PendingReviewCountUpdated Evergreen.V16.Wiki.Slug Int
    | WikiFrontendDetailsResponse Evergreen.V16.Wiki.Slug (Maybe Evergreen.V16.Wiki.FrontendDetails)
    | PageFrontendDetailsResponse Evergreen.V16.Wiki.Slug Evergreen.V16.Page.Slug (Maybe Evergreen.V16.Page.FrontendDetails)
    | WikiSearchResponse Evergreen.V16.Wiki.Slug String (List Evergreen.V16.WikiSearch.ResultItem)
    | MyPendingSubmissionsResponse Evergreen.V16.Wiki.Slug (Result Evergreen.V16.Submission.MyPendingSubmissionsError (List Evergreen.V16.Submission.MyPendingSubmissionListItem))
    | ReviewQueueResponse Evergreen.V16.Wiki.Slug (Result Evergreen.V16.Submission.ReviewQueueError (List Evergreen.V16.Submission.ReviewQueueItem))
    | ReviewSubmissionDetailResponse Evergreen.V16.Wiki.Slug String (Result Evergreen.V16.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V16.SubmissionReviewDetail.SubmissionReviewDetail)
    | WikiUsersResponse Evergreen.V16.Wiki.Slug (Result Evergreen.V16.WikiAdminUsers.Error (List Evergreen.V16.WikiAdminUsers.ListedUser))
    | WikiAuditLogResponse Evergreen.V16.Wiki.Slug Evergreen.V16.WikiAuditLog.AuditLogFilter (Result Evergreen.V16.WikiAuditLog.Error (List Evergreen.V16.WikiAuditLog.AuditEvent))
    | PromoteContributorToTrustedResponse Evergreen.V16.Wiki.Slug (Result Evergreen.V16.WikiAdminUsers.PromoteContributorError ())
    | DemoteTrustedToContributorResponse Evergreen.V16.Wiki.Slug (Result Evergreen.V16.WikiAdminUsers.DemoteTrustedError ())
    | GrantWikiAdminResponse Evergreen.V16.Wiki.Slug (Result Evergreen.V16.WikiAdminUsers.GrantTrustedToAdminError ())
    | RevokeWikiAdminResponse Evergreen.V16.Wiki.Slug (Result Evergreen.V16.WikiAdminUsers.RevokeAdminError ())
    | SubmissionDetailsResponse Evergreen.V16.Wiki.Slug String (Result Evergreen.V16.Submission.DetailsError Evergreen.V16.Submission.ContributorView)
    | RegisterContributorResponse Evergreen.V16.Wiki.Slug (Result Evergreen.V16.ContributorAccount.RegisterContributorError Evergreen.V16.WikiRole.WikiRole)
    | LoginContributorResponse Evergreen.V16.Wiki.Slug (Result Evergreen.V16.ContributorAccount.LoginContributorError Evergreen.V16.WikiRole.WikiRole)
    | LogoutContributorResponse Evergreen.V16.Wiki.Slug
    | SubmitNewPageResponse Evergreen.V16.Wiki.Slug (Result Evergreen.V16.Submission.SubmitNewPageError Evergreen.V16.Submission.NewPageSubmitSuccess)
    | SubmitPageEditResponse Evergreen.V16.Wiki.Slug (Result Evergreen.V16.Submission.SubmitPageEditError Evergreen.V16.Submission.EditSubmitSuccess)
    | RequestPublishedPageDeletionResponse Evergreen.V16.Wiki.Slug (Result Evergreen.V16.Submission.RequestPublishedPageDeletionError Evergreen.V16.Submission.Id)
    | DeletePublishedPageImmediatelyResponse Evergreen.V16.Wiki.Slug (Result Evergreen.V16.Submission.DeletePublishedPageImmediatelyError ())
    | SaveNewPageDraftResponse Evergreen.V16.Wiki.Slug (Result Evergreen.V16.Submission.SaveNewPageDraftError Evergreen.V16.Submission.Id)
    | SavePageEditDraftResponse Evergreen.V16.Wiki.Slug (Result Evergreen.V16.Submission.SavePageEditDraftError Evergreen.V16.Submission.Id)
    | SavePageDeleteDraftResponse Evergreen.V16.Wiki.Slug (Result Evergreen.V16.Submission.SavePageDeleteDraftError Evergreen.V16.Submission.Id)
    | SubmitDraftForReviewResponse Evergreen.V16.Wiki.Slug String (Result Evergreen.V16.Submission.SubmitDraftForReviewError ())
    | WithdrawSubmissionResponse Evergreen.V16.Wiki.Slug String (Result Evergreen.V16.Submission.WithdrawSubmissionError ())
    | DeleteMySubmissionResponse Evergreen.V16.Wiki.Slug String (Result Evergreen.V16.Submission.DeleteMySubmissionError ())
    | ApproveSubmissionResponse Evergreen.V16.Wiki.Slug String (Result Evergreen.V16.Submission.ApproveSubmissionError ())
    | RejectSubmissionResponse Evergreen.V16.Wiki.Slug String (Result Evergreen.V16.Submission.RejectSubmissionError ())
    | RequestSubmissionChangesResponse Evergreen.V16.Wiki.Slug String (Result Evergreen.V16.Submission.RequestChangesSubmissionError ())
    | HostAdminLoginResponse (Result Evergreen.V16.HostAdmin.LoginError ())
    | HostAdminWikiListResponse (Result Evergreen.V16.HostAdmin.ProtectedError (List Evergreen.V16.Wiki.CatalogEntry))
    | HostAuditLogResponse Evergreen.V16.WikiAuditLog.HostAuditLogFilter (Result Evergreen.V16.HostAdmin.ProtectedError (List Evergreen.V16.WikiAuditLog.ScopedAuditEvent))
    | CreateHostedWikiResponse (Result Evergreen.V16.HostAdmin.CreateHostedWikiError Evergreen.V16.Wiki.CatalogEntry)
    | HostWikiDetailResponse Evergreen.V16.Wiki.Slug (Result Evergreen.V16.HostAdmin.HostWikiDetailError Evergreen.V16.Wiki.CatalogEntry)
    | UpdateHostedWikiMetadataResponse Evergreen.V16.Wiki.Slug (Result Evergreen.V16.HostAdmin.UpdateHostedWikiMetadataError Evergreen.V16.Wiki.CatalogEntry)
    | DeactivateHostedWikiResponse Evergreen.V16.Wiki.Slug (Result Evergreen.V16.HostAdmin.WikiLifecycleError Evergreen.V16.Wiki.CatalogEntry)
    | ReactivateHostedWikiResponse Evergreen.V16.Wiki.Slug (Result Evergreen.V16.HostAdmin.WikiLifecycleError Evergreen.V16.Wiki.CatalogEntry)
    | DeleteHostedWikiResponse Evergreen.V16.Wiki.Slug (Result Evergreen.V16.HostAdmin.DeleteHostedWikiError ())
    | HostAdminDataExportResponse (Result Evergreen.V16.HostAdmin.DataExportError String)
    | HostAdminDataImportResponse (Result Evergreen.V16.HostAdmin.DataImportError ())
    | HostAdminWikiDataExportResponse Evergreen.V16.Wiki.Slug (Result Evergreen.V16.HostAdmin.WikiDataExportError String)
    | HostAdminWikiDataImportResponse Evergreen.V16.Wiki.Slug (Result Evergreen.V16.HostAdmin.WikiDataImportError ())
    | HostAdminWikiDataImportAutoResponse (Result Evergreen.V16.HostAdmin.WikiDataImportError Evergreen.V16.Wiki.Slug)

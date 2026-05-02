module Evergreen.V20.Types exposing (..)

import Dict
import Effect.Browser
import Effect.Browser.Navigation
import Effect.File
import Effect.Lamdera
import Evergreen.V20.ColorTheme
import Evergreen.V20.ContributorAccount
import Evergreen.V20.ContributorWikiSession
import Evergreen.V20.HostAdmin
import Evergreen.V20.Page
import Evergreen.V20.PendingReviewCount
import Evergreen.V20.Route
import Evergreen.V20.Store
import Evergreen.V20.Submission
import Evergreen.V20.SubmissionReviewDetail
import Evergreen.V20.Wiki
import Evergreen.V20.WikiAdminUsers
import Evergreen.V20.WikiAuditLog
import Evergreen.V20.WikiContributors
import Evergreen.V20.WikiFrontendSubscription
import Evergreen.V20.WikiMarkdownEditorPane
import Evergreen.V20.WikiRole
import Evergreen.V20.WikiSearch
import Evergreen.V20.WikiTodos
import Evergreen.V20.WikiUser
import RemoteData
import Set
import Time
import Url


type alias RegisterDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V20.ContributorAccount.RegisterContributorError ())
    }


type alias LoginDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V20.ContributorAccount.LoginContributorError ())
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
    , lastResult : Maybe (Result Evergreen.V20.Submission.SubmitNewPageError Evergreen.V20.Submission.NewPageSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V20.Submission.SaveNewPageDraftError Evergreen.V20.Submission.Id)
    }


type alias PageEditSubmitDraft =
    { markdownBody : String
    , tagsInput : String
    , publishedRowCollapsed : Bool
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V20.Submission.SubmitPageEditError Evergreen.V20.Submission.EditSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V20.Submission.SavePageEditDraftError Evergreen.V20.Submission.Id)
    }


type alias PageDeleteSubmitDraft =
    { reasonText : String
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V20.Submission.PageDeleteFormError Evergreen.V20.Submission.PageDeleteFormSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V20.Submission.SavePageDeleteDraftError Evergreen.V20.Submission.Id)
    }


type alias ReviewApproveDraft =
    { inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V20.Submission.ApproveSubmissionError ())
    }


type ReviewDecision
    = ReviewDecisionApprove
    | ReviewDecisionRequestChanges
    | ReviewDecisionReject


type alias ReviewRejectDraft =
    { reasonText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V20.Submission.RejectSubmissionError ())
    }


type alias ReviewRequestChangesDraft =
    { guidanceText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V20.Submission.RequestChangesSubmissionError ())
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
    , lastResult : Maybe (Result Evergreen.V20.HostAdmin.LoginError ())
    }


type alias HostAdminCreateWikiDraft =
    { slug : String
    , name : String
    , initialAdminUsername : String
    , initialAdminPassword : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V20.HostAdmin.CreateHostedWikiError Evergreen.V20.Wiki.CatalogEntry)
    }


type alias HostAdminWikiDetailDraft =
    { wikiSlug : Evergreen.V20.Wiki.Slug
    , load : RemoteData.RemoteData () (Result Evergreen.V20.HostAdmin.HostWikiDetailError Evergreen.V20.Wiki.CatalogEntry)
    , slugDraft : String
    , nameDraft : String
    , summaryDraft : String
    , saveInFlight : Bool
    , lastSaveResult : Maybe (Result Evergreen.V20.HostAdmin.UpdateHostedWikiMetadataError ())
    , lifecycleInFlight : Bool
    , lastLifecycleResult : Maybe (Result Evergreen.V20.HostAdmin.WikiLifecycleError ())
    , deleteConfirmDraft : String
    , deleteInFlight : Bool
    , lastDeleteResult : Maybe (Result Evergreen.V20.HostAdmin.DeleteHostedWikiError ())
    }


type alias FrontendModel =
    { key : Effect.Browser.Navigation.Key
    , colorThemePreference : Evergreen.V20.ColorTheme.ColorThemePreference
    , systemColorTheme : Evergreen.V20.ColorTheme.ColorTheme
    , route : Evergreen.V20.Route.Route
    , navigationFragment : Maybe String
    , store : Evergreen.V20.Store.Store
    , contributorWikiSessions : Dict.Dict Evergreen.V20.Wiki.Slug Evergreen.V20.ContributorWikiSession.ContributorWikiSession
    , registerDraft : RegisterDraft
    , loginDraft : LoginDraft
    , headerSearchQuery : String
    , headerSearchResults : List Evergreen.V20.WikiSearch.ResultItem
    , headerSearchPending : Maybe ( Evergreen.V20.Wiki.Slug, String )
    , wikiSearchPageQuery : String
    , wikiSearchPageResults : List Evergreen.V20.WikiSearch.ResultItem
    , wikiSearchPagePending : Maybe ( Evergreen.V20.Wiki.Slug, String )
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
    , wikiAdminAuditFilterSelectedKindTags : List Evergreen.V20.WikiAuditLog.AuditEventKindFilterTag
    , wikiAdminAuditAppliedFilter : Evergreen.V20.WikiAuditLog.AuditLogFilter
    , hostAdminAuditFilterWikiDraft : String
    , hostAdminAuditFilterActorDraft : String
    , hostAdminAuditFilterPageDraft : String
    , hostAdminAuditFilterSelectedKindTags : List Evergreen.V20.WikiAuditLog.AuditEventKindFilterTag
    , hostAdminAuditAppliedFilter : Evergreen.V20.WikiAuditLog.HostAuditLogFilter
    , hostAdminAuditLog : RemoteData.RemoteData () (Result Evergreen.V20.HostAdmin.ProtectedError (List Evergreen.V20.WikiAuditLog.ScopedAuditEvent))
    , hostAdminLoginDraft : HostAdminLoginDraft
    , hostAdminCreateWikiDraft : HostAdminCreateWikiDraft
    , hostAdminWikiDetailDraft : HostAdminWikiDetailDraft
    , hostAdminWikis : RemoteData.RemoteData () (Result Evergreen.V20.HostAdmin.ProtectedError (List Evergreen.V20.Wiki.CatalogEntry))
    , hostAdminSessionAuthenticated : Bool
    , hostAdminExportInFlight : Bool
    , hostAdminImportInFlight : Bool
    , hostAdminBackupNotice : Maybe String
    , hostAdminWikiExportInFlightSlug : Maybe Evergreen.V20.Wiki.Slug
    , hostAdminWikiImportInFlightSlug : Maybe Evergreen.V20.Wiki.Slug
    , hostAdminWikiImportPendingSlug : Maybe Evergreen.V20.Wiki.Slug
    , hostAdminWikisNotice : Maybe String
    , sideNavOpen : Bool
    , wikiMarkdownEditorPane : Evergreen.V20.WikiMarkdownEditorPane.WikiMarkdownEditorPane
    }


type alias BackendModel =
    { wikis : Dict.Dict Evergreen.V20.Wiki.Slug Evergreen.V20.Wiki.Wiki
    , contributors : Evergreen.V20.WikiContributors.Registry
    , contributorSessions : Evergreen.V20.WikiUser.SessionTable
    , hostSessions : Set.Set String
    , submissions : Dict.Dict String Evergreen.V20.Submission.Submission
    , nextSubmissionCounter : Int
    , wikiAuditEvents : Dict.Dict Evergreen.V20.Wiki.Slug (List Evergreen.V20.WikiAuditLog.AuditEvent)
    , pendingReviewCounts : Dict.Dict Evergreen.V20.Wiki.Slug Int
    , pendingReviewClients : Evergreen.V20.PendingReviewCount.PendingReviewClientSets
    , wikiFrontendClients : Evergreen.V20.WikiFrontendSubscription.WikiFrontendClientSets
    , wikiSearchIndexes : Dict.Dict Evergreen.V20.Wiki.Slug Evergreen.V20.WikiSearch.PrefixIndex
    , wikiTodosCaches : Dict.Dict Evergreen.V20.Wiki.Slug (List Evergreen.V20.WikiTodos.TableRow)
    }


type FrontendMsg
    = UrlClicked Effect.Browser.UrlRequest
    | UrlChanged Url.Url
    | UrlFragmentScrollDone
    | ColorThemeToggled
    | ColorThemeFromJs (Maybe Evergreen.V20.ColorTheme.Incoming)
    | RegisterFormUsernameChanged String
    | RegisterFormPasswordChanged String
    | RegisterFormSubmitted
    | LoginFormUsernameChanged String
    | LoginFormPasswordChanged String
    | LoginFormSubmitted
    | HeaderSearchQueryChanged String
    | HeaderSearchTimeoutReached Evergreen.V20.Wiki.Slug String
    | HeaderSearchSubmitted
    | WikiSearchPageQueryChanged String
    | WikiSearchPageTimeoutReached Evergreen.V20.Wiki.Slug String
    | ContributorLogoutWiki Evergreen.V20.Wiki.Slug
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
    | WikiAdminAuditFilterTypeTagToggled Evergreen.V20.WikiAuditLog.AuditEventKindFilterTag Bool
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
    | HostAdminAuditFilterTypeTagToggled Evergreen.V20.WikiAuditLog.AuditEventKindFilterTag Bool
    | HostAdminDataExportClicked
    | HostAdminDataImportPickRequested
    | HostAdminDataImportFileSelected Effect.File.File
    | HostAdminDataImportFileRead (Result () String)
    | HostAdminWikisDataImportPickRequested
    | HostAdminWikisDataImportFileSelected Effect.File.File
    | HostAdminWikisDataImportFileRead (Result () String)
    | HostAdminWikiDataExportClicked Evergreen.V20.Wiki.Slug
    | HostAdminWikiDataImportPickRequested Evergreen.V20.Wiki.Slug
    | HostAdminWikiDataImportFileSelected Effect.File.File
    | HostAdminWikiDataImportFileRead Evergreen.V20.Wiki.Slug (Result () String)
    | SideNavOpened
    | SideNavClosed
    | WikiMarkdownEditorPaneSelected Evergreen.V20.WikiMarkdownEditorPane.WikiMarkdownEditorPane


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
    | RequestWikiFrontendDetails Evergreen.V20.Wiki.Slug
    | RequestWikiTodos Evergreen.V20.Wiki.Slug
    | RequestPageFrontendDetails Evergreen.V20.Wiki.Slug Evergreen.V20.Page.Slug
    | RequestWikiSearch Evergreen.V20.Wiki.Slug String
    | RequestMyPendingSubmissions Evergreen.V20.Wiki.Slug
    | RequestReviewQueue Evergreen.V20.Wiki.Slug
    | RequestReviewSubmissionDetail Evergreen.V20.Wiki.Slug String
    | RequestWikiUsers Evergreen.V20.Wiki.Slug
    | RequestWikiAuditLog Evergreen.V20.Wiki.Slug Evergreen.V20.WikiAuditLog.AuditLogFilter
    | PromoteContributorToTrusted Evergreen.V20.Wiki.Slug String
    | DemoteTrustedToContributor Evergreen.V20.Wiki.Slug String
    | GrantWikiAdmin Evergreen.V20.Wiki.Slug String
    | RevokeWikiAdmin Evergreen.V20.Wiki.Slug String
    | RequestSubmissionDetails Evergreen.V20.Wiki.Slug String
    | RegisterContributor Evergreen.V20.Wiki.Slug RegisterContributorPayload
    | LoginContributor Evergreen.V20.Wiki.Slug LoginContributorPayload
    | LogoutContributor Evergreen.V20.Wiki.Slug
    | SubmitNewPage Evergreen.V20.Wiki.Slug SubmitNewPagePayload
    | SubmitPageEdit Evergreen.V20.Wiki.Slug Evergreen.V20.Page.Slug String String
    | RequestPublishedPageDeletion Evergreen.V20.Wiki.Slug Evergreen.V20.Page.Slug String
    | DeletePublishedPageImmediately Evergreen.V20.Wiki.Slug Evergreen.V20.Page.Slug String
    | SaveNewPageDraft
        Evergreen.V20.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , rawPageSlug : String
        , rawMarkdown : String
        , rawTags : String
        }
    | SavePageEditDraft
        Evergreen.V20.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V20.Page.Slug
        , rawMarkdown : String
        , rawTags : String
        }
    | SavePageDeleteDraft
        Evergreen.V20.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V20.Page.Slug
        , rawReason : String
        }
    | SubmitDraftForReview Evergreen.V20.Wiki.Slug String
    | WithdrawSubmission Evergreen.V20.Wiki.Slug String
    | DeleteMySubmission Evergreen.V20.Wiki.Slug String
    | ApproveSubmission Evergreen.V20.Wiki.Slug String
    | RejectSubmission Evergreen.V20.Wiki.Slug RejectSubmissionPayload
    | RequestSubmissionChanges Evergreen.V20.Wiki.Slug RequestSubmissionChangesPayload
    | HostAdminLogin String
    | RequestHostWikiList
    | RequestHostAuditLog Evergreen.V20.WikiAuditLog.HostAuditLogFilter
    | RequestHostWikiDetail Evergreen.V20.Wiki.Slug
    | CreateHostedWiki CreateHostedWikiPayload
    | UpdateHostedWikiMetadata Evergreen.V20.Wiki.Slug UpdateHostedWikiMetadataPayload
    | DeactivateHostedWiki Evergreen.V20.Wiki.Slug
    | ReactivateHostedWiki Evergreen.V20.Wiki.Slug
    | DeleteHostedWiki Evergreen.V20.Wiki.Slug String
    | RequestHostAdminDataExport
    | ImportHostAdminDataSnapshot String
    | RequestHostAdminWikiDataExport Evergreen.V20.Wiki.Slug
    | ImportHostAdminWikiDataSnapshot Evergreen.V20.Wiki.Slug String
    | ImportHostAdminWikiDataSnapshotAuto String


type BackendMsg
    = ToBackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Time.Posix


type ToFrontend
    = WikiCatalogResponse (Dict.Dict Evergreen.V20.Wiki.Slug Evergreen.V20.Wiki.CatalogEntry)
    | PendingReviewCountUpdated Evergreen.V20.Wiki.Slug Int
    | WikiFrontendDetailsResponse Evergreen.V20.Wiki.Slug (Maybe Evergreen.V20.Wiki.FrontendDetails)
    | WikiTodosResponse Evergreen.V20.Wiki.Slug (Result () (List Evergreen.V20.WikiTodos.TableRow))
    | PageFrontendDetailsResponse Evergreen.V20.Wiki.Slug Evergreen.V20.Page.Slug (Maybe Evergreen.V20.Page.FrontendDetails)
    | WikiSearchResponse Evergreen.V20.Wiki.Slug String (List Evergreen.V20.WikiSearch.ResultItem)
    | MyPendingSubmissionsResponse Evergreen.V20.Wiki.Slug (Result Evergreen.V20.Submission.MyPendingSubmissionsError (List Evergreen.V20.Submission.MyPendingSubmissionListItem))
    | ReviewQueueResponse Evergreen.V20.Wiki.Slug (Result Evergreen.V20.Submission.ReviewQueueError (List Evergreen.V20.Submission.ReviewQueueItem))
    | ReviewSubmissionDetailResponse Evergreen.V20.Wiki.Slug String (Result Evergreen.V20.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V20.SubmissionReviewDetail.SubmissionReviewDetail)
    | WikiUsersResponse Evergreen.V20.Wiki.Slug (Result Evergreen.V20.WikiAdminUsers.Error (List Evergreen.V20.WikiAdminUsers.ListedUser))
    | WikiAuditLogResponse Evergreen.V20.Wiki.Slug Evergreen.V20.WikiAuditLog.AuditLogFilter (Result Evergreen.V20.WikiAuditLog.Error (List Evergreen.V20.WikiAuditLog.AuditEvent))
    | PromoteContributorToTrustedResponse Evergreen.V20.Wiki.Slug (Result Evergreen.V20.WikiAdminUsers.PromoteContributorError ())
    | DemoteTrustedToContributorResponse Evergreen.V20.Wiki.Slug (Result Evergreen.V20.WikiAdminUsers.DemoteTrustedError ())
    | GrantWikiAdminResponse Evergreen.V20.Wiki.Slug (Result Evergreen.V20.WikiAdminUsers.GrantTrustedToAdminError ())
    | RevokeWikiAdminResponse Evergreen.V20.Wiki.Slug (Result Evergreen.V20.WikiAdminUsers.RevokeAdminError ())
    | SubmissionDetailsResponse Evergreen.V20.Wiki.Slug String (Result Evergreen.V20.Submission.DetailsError Evergreen.V20.Submission.ContributorView)
    | RegisterContributorResponse Evergreen.V20.Wiki.Slug (Result Evergreen.V20.ContributorAccount.RegisterContributorError Evergreen.V20.WikiRole.WikiRole)
    | LoginContributorResponse Evergreen.V20.Wiki.Slug (Result Evergreen.V20.ContributorAccount.LoginContributorError Evergreen.V20.WikiRole.WikiRole)
    | LogoutContributorResponse Evergreen.V20.Wiki.Slug
    | SubmitNewPageResponse Evergreen.V20.Wiki.Slug (Result Evergreen.V20.Submission.SubmitNewPageError Evergreen.V20.Submission.NewPageSubmitSuccess)
    | SubmitPageEditResponse Evergreen.V20.Wiki.Slug (Result Evergreen.V20.Submission.SubmitPageEditError Evergreen.V20.Submission.EditSubmitSuccess)
    | RequestPublishedPageDeletionResponse Evergreen.V20.Wiki.Slug (Result Evergreen.V20.Submission.RequestPublishedPageDeletionError Evergreen.V20.Submission.Id)
    | DeletePublishedPageImmediatelyResponse Evergreen.V20.Wiki.Slug (Result Evergreen.V20.Submission.DeletePublishedPageImmediatelyError ())
    | SaveNewPageDraftResponse Evergreen.V20.Wiki.Slug (Result Evergreen.V20.Submission.SaveNewPageDraftError Evergreen.V20.Submission.Id)
    | SavePageEditDraftResponse Evergreen.V20.Wiki.Slug (Result Evergreen.V20.Submission.SavePageEditDraftError Evergreen.V20.Submission.Id)
    | SavePageDeleteDraftResponse Evergreen.V20.Wiki.Slug (Result Evergreen.V20.Submission.SavePageDeleteDraftError Evergreen.V20.Submission.Id)
    | SubmitDraftForReviewResponse Evergreen.V20.Wiki.Slug String (Result Evergreen.V20.Submission.SubmitDraftForReviewError ())
    | WithdrawSubmissionResponse Evergreen.V20.Wiki.Slug String (Result Evergreen.V20.Submission.WithdrawSubmissionError ())
    | DeleteMySubmissionResponse Evergreen.V20.Wiki.Slug String (Result Evergreen.V20.Submission.DeleteMySubmissionError ())
    | ApproveSubmissionResponse Evergreen.V20.Wiki.Slug String (Result Evergreen.V20.Submission.ApproveSubmissionError ())
    | RejectSubmissionResponse Evergreen.V20.Wiki.Slug String (Result Evergreen.V20.Submission.RejectSubmissionError ())
    | RequestSubmissionChangesResponse Evergreen.V20.Wiki.Slug String (Result Evergreen.V20.Submission.RequestChangesSubmissionError ())
    | HostAdminLoginResponse (Result Evergreen.V20.HostAdmin.LoginError ())
    | HostAdminWikiListResponse (Result Evergreen.V20.HostAdmin.ProtectedError (List Evergreen.V20.Wiki.CatalogEntry))
    | HostAuditLogResponse Evergreen.V20.WikiAuditLog.HostAuditLogFilter (Result Evergreen.V20.HostAdmin.ProtectedError (List Evergreen.V20.WikiAuditLog.ScopedAuditEvent))
    | CreateHostedWikiResponse (Result Evergreen.V20.HostAdmin.CreateHostedWikiError Evergreen.V20.Wiki.CatalogEntry)
    | HostWikiDetailResponse Evergreen.V20.Wiki.Slug (Result Evergreen.V20.HostAdmin.HostWikiDetailError Evergreen.V20.Wiki.CatalogEntry)
    | UpdateHostedWikiMetadataResponse Evergreen.V20.Wiki.Slug (Result Evergreen.V20.HostAdmin.UpdateHostedWikiMetadataError Evergreen.V20.Wiki.CatalogEntry)
    | DeactivateHostedWikiResponse Evergreen.V20.Wiki.Slug (Result Evergreen.V20.HostAdmin.WikiLifecycleError Evergreen.V20.Wiki.CatalogEntry)
    | ReactivateHostedWikiResponse Evergreen.V20.Wiki.Slug (Result Evergreen.V20.HostAdmin.WikiLifecycleError Evergreen.V20.Wiki.CatalogEntry)
    | DeleteHostedWikiResponse Evergreen.V20.Wiki.Slug (Result Evergreen.V20.HostAdmin.DeleteHostedWikiError ())
    | HostAdminDataExportResponse (Result Evergreen.V20.HostAdmin.DataExportError String)
    | HostAdminDataImportResponse (Result Evergreen.V20.HostAdmin.DataImportError ())
    | HostAdminWikiDataExportResponse Evergreen.V20.Wiki.Slug (Result Evergreen.V20.HostAdmin.WikiDataExportError String)
    | HostAdminWikiDataImportResponse Evergreen.V20.Wiki.Slug (Result Evergreen.V20.HostAdmin.WikiDataImportError ())
    | HostAdminWikiDataImportAutoResponse (Result Evergreen.V20.HostAdmin.WikiDataImportError Evergreen.V20.Wiki.Slug)

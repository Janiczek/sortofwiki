module Evergreen.V26.Types exposing (..)

import Dict
import Effect.Browser
import Effect.Browser.Navigation
import Effect.File
import Effect.Lamdera
import Evergreen.V26.ColorTheme
import Evergreen.V26.ContributorAccount
import Evergreen.V26.ContributorWikiSession
import Evergreen.V26.HostAdmin
import Evergreen.V26.Page
import Evergreen.V26.PendingReviewCount
import Evergreen.V26.Route
import Evergreen.V26.Store
import Evergreen.V26.Submission
import Evergreen.V26.SubmissionReviewDetail
import Evergreen.V26.Wiki
import Evergreen.V26.WikiAdminUsers
import Evergreen.V26.WikiAuditLog
import Evergreen.V26.WikiContributors
import Evergreen.V26.WikiFrontendSubscription
import Evergreen.V26.WikiMarkdownEditorPane
import Evergreen.V26.WikiRole
import Evergreen.V26.WikiSearch
import Evergreen.V26.WikiTodos
import Evergreen.V26.WikiUser
import RemoteData
import Set
import Time
import Url


type alias RegisterDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V26.ContributorAccount.RegisterContributorError ())
    }


type alias LoginDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V26.ContributorAccount.LoginContributorError ())
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
    , lastResult : Maybe (Result Evergreen.V26.Submission.SubmitNewPageError Evergreen.V26.Submission.NewPageSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V26.Submission.SaveNewPageDraftError Evergreen.V26.Submission.Id)
    }


type alias PageEditSubmitDraft =
    { markdownBody : String
    , tagsInput : String
    , publishedRowCollapsed : Bool
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V26.Submission.SubmitPageEditError Evergreen.V26.Submission.EditSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V26.Submission.SavePageEditDraftError Evergreen.V26.Submission.Id)
    }


type alias PageDeleteSubmitDraft =
    { reasonText : String
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V26.Submission.PageDeleteFormError Evergreen.V26.Submission.PageDeleteFormSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V26.Submission.SavePageDeleteDraftError Evergreen.V26.Submission.Id)
    }


type alias ReviewApproveDraft =
    { inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V26.Submission.ApproveSubmissionError ())
    }


type ReviewDecision
    = ReviewDecisionApprove
    | ReviewDecisionRequestChanges
    | ReviewDecisionReject


type alias ReviewRejectDraft =
    { reasonText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V26.Submission.RejectSubmissionError ())
    }


type alias ReviewRequestChangesDraft =
    { guidanceText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V26.Submission.RequestChangesSubmissionError ())
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
    , lastResult : Maybe (Result Evergreen.V26.HostAdmin.LoginError ())
    }


type alias HostAdminCreateWikiDraft =
    { slug : String
    , name : String
    , initialAdminUsername : String
    , initialAdminPassword : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V26.HostAdmin.CreateHostedWikiError Evergreen.V26.Wiki.CatalogEntry)
    }


type alias HostAdminWikiDetailDraft =
    { wikiSlug : Evergreen.V26.Wiki.Slug
    , load : RemoteData.RemoteData () (Result Evergreen.V26.HostAdmin.HostWikiDetailError Evergreen.V26.Wiki.CatalogEntry)
    , slugDraft : String
    , nameDraft : String
    , summaryDraft : String
    , saveInFlight : Bool
    , lastSaveResult : Maybe (Result Evergreen.V26.HostAdmin.UpdateHostedWikiMetadataError ())
    , lifecycleInFlight : Bool
    , lastLifecycleResult : Maybe (Result Evergreen.V26.HostAdmin.WikiLifecycleError ())
    , deleteConfirmDraft : String
    , deleteInFlight : Bool
    , lastDeleteResult : Maybe (Result Evergreen.V26.HostAdmin.DeleteHostedWikiError ())
    }


type alias FrontendModel =
    { key : Effect.Browser.Navigation.Key
    , colorThemePreference : Evergreen.V26.ColorTheme.ColorThemePreference
    , systemColorTheme : Evergreen.V26.ColorTheme.ColorTheme
    , currentUrl : Url.Url
    , route : Evergreen.V26.Route.Route
    , navigationFragment : Maybe String
    , store : Evergreen.V26.Store.Store
    , contributorWikiSessions : Dict.Dict Evergreen.V26.Wiki.Slug Evergreen.V26.ContributorWikiSession.ContributorWikiSession
    , registerDraft : RegisterDraft
    , loginDraft : LoginDraft
    , headerSearchQuery : String
    , headerSearchResults : List Evergreen.V26.WikiSearch.ResultItem
    , headerSearchPending : Maybe ( Evergreen.V26.Wiki.Slug, String )
    , wikiSearchPageQuery : String
    , wikiSearchPageResults : List Evergreen.V26.WikiSearch.ResultItem
    , wikiSearchPagePending : Maybe ( Evergreen.V26.Wiki.Slug, String )
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
    , wikiAdminAuditFilterSelectedKindTags : List Evergreen.V26.WikiAuditLog.AuditEventKindFilterTag
    , wikiAdminAuditAppliedFilter : Evergreen.V26.WikiAuditLog.AuditLogFilter
    , hostAdminAuditFilterWikiDraft : String
    , hostAdminAuditFilterActorDraft : String
    , hostAdminAuditFilterPageDraft : String
    , hostAdminAuditFilterSelectedKindTags : List Evergreen.V26.WikiAuditLog.AuditEventKindFilterTag
    , hostAdminAuditAppliedFilter : Evergreen.V26.WikiAuditLog.HostAuditLogFilter
    , hostAdminAuditLog : RemoteData.RemoteData () (Result Evergreen.V26.HostAdmin.ProtectedError (List Evergreen.V26.WikiAuditLog.ScopedAuditEvent))
    , hostAdminLoginDraft : HostAdminLoginDraft
    , hostAdminCreateWikiDraft : HostAdminCreateWikiDraft
    , hostAdminWikiDetailDraft : HostAdminWikiDetailDraft
    , hostAdminWikis : RemoteData.RemoteData () (Result Evergreen.V26.HostAdmin.ProtectedError (List Evergreen.V26.Wiki.CatalogEntry))
    , hostAdminSessionAuthenticated : Bool
    , hostAdminExportInFlight : Bool
    , hostAdminImportInFlight : Bool
    , hostAdminBackupNotice : Maybe String
    , hostAdminWikiExportInFlightSlug : Maybe Evergreen.V26.Wiki.Slug
    , hostAdminWikiImportInFlightSlug : Maybe Evergreen.V26.Wiki.Slug
    , hostAdminWikiImportPendingSlug : Maybe Evergreen.V26.Wiki.Slug
    , hostAdminWikisNotice : Maybe String
    , sideNavOpen : Bool
    , wikiPageMobileRightRailCollapsed : Bool
    , wikiMarkdownEditorPane : Evergreen.V26.WikiMarkdownEditorPane.WikiMarkdownEditorPane
    }


type alias BackendModel =
    { wikis : Dict.Dict Evergreen.V26.Wiki.Slug Evergreen.V26.Wiki.Wiki
    , contributors : Evergreen.V26.WikiContributors.Registry
    , contributorSessions : Evergreen.V26.WikiUser.SessionTable
    , hostSessions : Set.Set String
    , submissions : Dict.Dict String Evergreen.V26.Submission.Submission
    , nextSubmissionCounter : Int
    , wikiAuditEvents : Dict.Dict Evergreen.V26.Wiki.Slug (List Evergreen.V26.WikiAuditLog.AuditEvent)
    , pendingReviewCounts : Dict.Dict Evergreen.V26.Wiki.Slug Int
    , pendingReviewClients : Evergreen.V26.PendingReviewCount.PendingReviewClientSets
    , wikiFrontendClients : Evergreen.V26.WikiFrontendSubscription.WikiFrontendClientSets
    , wikiSearchIndexes : Dict.Dict Evergreen.V26.Wiki.Slug Evergreen.V26.WikiSearch.PrefixIndex
    , wikiTodosCaches : Dict.Dict Evergreen.V26.Wiki.Slug (List Evergreen.V26.WikiTodos.TableRow)
    }


type FrontendMsg
    = UrlClicked Effect.Browser.UrlRequest
    | UrlChanged Url.Url
    | UrlFragmentScrollDone
    | ColorThemeToggled
    | ColorThemeFromJs (Maybe Evergreen.V26.ColorTheme.Incoming)
    | RegisterFormUsernameChanged String
    | RegisterFormPasswordChanged String
    | RegisterFormSubmitted
    | LoginFormUsernameChanged String
    | LoginFormPasswordChanged String
    | LoginFormSubmitted
    | HeaderSearchQueryChanged String
    | HeaderSearchTimeoutReached Evergreen.V26.Wiki.Slug String
    | HeaderSearchSubmitted
    | WikiSearchPageQueryChanged String
    | WikiSearchPageTimeoutReached Evergreen.V26.Wiki.Slug String
    | ContributorLogoutWiki Evergreen.V26.Wiki.Slug
    | NewPageSubmitMarkdownChanged String
    | NewPageSubmitSlugChanged String
    | NewPageSubmitTagsChanged String
    | NewPageSubmitFormSubmitted
    | PageEditSubmitMarkdownChanged String
    | PageEditSubmitTagsChanged String
    | PageEditPublishedRowToggled
    | WikiPageMobileRightRailToggled
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
    | WikiAdminAuditFilterTypeTagToggled Evergreen.V26.WikiAuditLog.AuditEventKindFilterTag Bool
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
    | HostAdminAuditFilterTypeTagToggled Evergreen.V26.WikiAuditLog.AuditEventKindFilterTag Bool
    | HostAdminDataExportClicked
    | HostAdminDataImportPickRequested
    | HostAdminDataImportFileSelected Effect.File.File
    | HostAdminDataImportFileRead (Result () String)
    | HostAdminWikisDataImportPickRequested
    | HostAdminWikisDataImportFileSelected Effect.File.File
    | HostAdminWikisDataImportFileRead (Result () String)
    | HostAdminWikiDataExportClicked Evergreen.V26.Wiki.Slug
    | HostAdminWikiDataImportPickRequested Evergreen.V26.Wiki.Slug
    | HostAdminWikiDataImportFileSelected Effect.File.File
    | HostAdminWikiDataImportFileRead Evergreen.V26.Wiki.Slug (Result () String)
    | SideNavOpened
    | SideNavClosed
    | WikiMarkdownEditorPaneSelected Evergreen.V26.WikiMarkdownEditorPane.WikiMarkdownEditorPane


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
    | RequestWikiFrontendDetails Evergreen.V26.Wiki.Slug
    | RequestWikiTodos Evergreen.V26.Wiki.Slug
    | RequestPageFrontendDetails Evergreen.V26.Wiki.Slug Evergreen.V26.Page.Slug
    | RequestWikiSearch Evergreen.V26.Wiki.Slug String
    | RequestMyPendingSubmissions Evergreen.V26.Wiki.Slug
    | RequestReviewQueue Evergreen.V26.Wiki.Slug
    | RequestReviewSubmissionDetail Evergreen.V26.Wiki.Slug String
    | RequestWikiUsers Evergreen.V26.Wiki.Slug
    | RequestWikiAuditLog Evergreen.V26.Wiki.Slug Evergreen.V26.WikiAuditLog.AuditLogFilter
    | PromoteContributorToTrusted Evergreen.V26.Wiki.Slug String
    | DemoteTrustedToContributor Evergreen.V26.Wiki.Slug String
    | GrantWikiAdmin Evergreen.V26.Wiki.Slug String
    | RevokeWikiAdmin Evergreen.V26.Wiki.Slug String
    | RequestSubmissionDetails Evergreen.V26.Wiki.Slug String
    | RegisterContributor Evergreen.V26.Wiki.Slug RegisterContributorPayload
    | LoginContributor Evergreen.V26.Wiki.Slug LoginContributorPayload
    | LogoutContributor Evergreen.V26.Wiki.Slug
    | SubmitNewPage Evergreen.V26.Wiki.Slug SubmitNewPagePayload
    | SubmitPageEdit Evergreen.V26.Wiki.Slug Evergreen.V26.Page.Slug String String
    | RequestPublishedPageDeletion Evergreen.V26.Wiki.Slug Evergreen.V26.Page.Slug String
    | DeletePublishedPageImmediately Evergreen.V26.Wiki.Slug Evergreen.V26.Page.Slug String
    | SaveNewPageDraft
        Evergreen.V26.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , rawPageSlug : String
        , rawMarkdown : String
        , rawTags : String
        }
    | SavePageEditDraft
        Evergreen.V26.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V26.Page.Slug
        , rawMarkdown : String
        , rawTags : String
        }
    | SavePageDeleteDraft
        Evergreen.V26.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V26.Page.Slug
        , rawReason : String
        }
    | SubmitDraftForReview Evergreen.V26.Wiki.Slug String
    | WithdrawSubmission Evergreen.V26.Wiki.Slug String
    | DeleteMySubmission Evergreen.V26.Wiki.Slug String
    | ApproveSubmission Evergreen.V26.Wiki.Slug String
    | RejectSubmission Evergreen.V26.Wiki.Slug RejectSubmissionPayload
    | RequestSubmissionChanges Evergreen.V26.Wiki.Slug RequestSubmissionChangesPayload
    | HostAdminLogin String
    | RequestHostWikiList
    | RequestHostAuditLog Evergreen.V26.WikiAuditLog.HostAuditLogFilter
    | RequestHostWikiDetail Evergreen.V26.Wiki.Slug
    | CreateHostedWiki CreateHostedWikiPayload
    | UpdateHostedWikiMetadata Evergreen.V26.Wiki.Slug UpdateHostedWikiMetadataPayload
    | DeactivateHostedWiki Evergreen.V26.Wiki.Slug
    | ReactivateHostedWiki Evergreen.V26.Wiki.Slug
    | DeleteHostedWiki Evergreen.V26.Wiki.Slug String
    | RequestHostAdminDataExport
    | ImportHostAdminDataSnapshot String
    | RequestHostAdminWikiDataExport Evergreen.V26.Wiki.Slug
    | ImportHostAdminWikiDataSnapshot Evergreen.V26.Wiki.Slug String
    | ImportHostAdminWikiDataSnapshotAuto String


type BackendMsg
    = ToBackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Time.Posix


type ToFrontend
    = WikiCatalogResponse (Dict.Dict Evergreen.V26.Wiki.Slug Evergreen.V26.Wiki.CatalogEntry)
    | PendingReviewCountUpdated Evergreen.V26.Wiki.Slug Int
    | WikiFrontendDetailsResponse Evergreen.V26.Wiki.Slug (Maybe Evergreen.V26.Wiki.FrontendDetails)
    | WikiTodosResponse Evergreen.V26.Wiki.Slug (Result () (List Evergreen.V26.WikiTodos.TableRow))
    | PageFrontendDetailsResponse Evergreen.V26.Wiki.Slug Evergreen.V26.Page.Slug (Maybe Evergreen.V26.Page.FrontendDetails)
    | WikiSearchResponse Evergreen.V26.Wiki.Slug String (List Evergreen.V26.WikiSearch.ResultItem)
    | MyPendingSubmissionsResponse Evergreen.V26.Wiki.Slug (Result Evergreen.V26.Submission.MyPendingSubmissionsError (List Evergreen.V26.Submission.MyPendingSubmissionListItem))
    | ReviewQueueResponse Evergreen.V26.Wiki.Slug (Result Evergreen.V26.Submission.ReviewQueueError (List Evergreen.V26.Submission.ReviewQueueItem))
    | ReviewSubmissionDetailResponse Evergreen.V26.Wiki.Slug String (Result Evergreen.V26.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V26.SubmissionReviewDetail.SubmissionReviewDetail)
    | WikiUsersResponse Evergreen.V26.Wiki.Slug (Result Evergreen.V26.WikiAdminUsers.Error (List Evergreen.V26.WikiAdminUsers.ListedUser))
    | WikiAuditLogResponse Evergreen.V26.Wiki.Slug Evergreen.V26.WikiAuditLog.AuditLogFilter (Result Evergreen.V26.WikiAuditLog.Error (List Evergreen.V26.WikiAuditLog.AuditEvent))
    | PromoteContributorToTrustedResponse Evergreen.V26.Wiki.Slug (Result Evergreen.V26.WikiAdminUsers.PromoteContributorError ())
    | DemoteTrustedToContributorResponse Evergreen.V26.Wiki.Slug (Result Evergreen.V26.WikiAdminUsers.DemoteTrustedError ())
    | GrantWikiAdminResponse Evergreen.V26.Wiki.Slug (Result Evergreen.V26.WikiAdminUsers.GrantTrustedToAdminError ())
    | RevokeWikiAdminResponse Evergreen.V26.Wiki.Slug (Result Evergreen.V26.WikiAdminUsers.RevokeAdminError ())
    | SubmissionDetailsResponse Evergreen.V26.Wiki.Slug String (Result Evergreen.V26.Submission.DetailsError Evergreen.V26.Submission.ContributorView)
    | RegisterContributorResponse Evergreen.V26.Wiki.Slug (Result Evergreen.V26.ContributorAccount.RegisterContributorError Evergreen.V26.WikiRole.WikiRole)
    | LoginContributorResponse Evergreen.V26.Wiki.Slug (Result Evergreen.V26.ContributorAccount.LoginContributorError Evergreen.V26.WikiRole.WikiRole)
    | LogoutContributorResponse Evergreen.V26.Wiki.Slug
    | SubmitNewPageResponse Evergreen.V26.Wiki.Slug (Result Evergreen.V26.Submission.SubmitNewPageError Evergreen.V26.Submission.NewPageSubmitSuccess)
    | SubmitPageEditResponse Evergreen.V26.Wiki.Slug (Result Evergreen.V26.Submission.SubmitPageEditError Evergreen.V26.Submission.EditSubmitSuccess)
    | RequestPublishedPageDeletionResponse Evergreen.V26.Wiki.Slug (Result Evergreen.V26.Submission.RequestPublishedPageDeletionError Evergreen.V26.Submission.Id)
    | DeletePublishedPageImmediatelyResponse Evergreen.V26.Wiki.Slug (Result Evergreen.V26.Submission.DeletePublishedPageImmediatelyError ())
    | SaveNewPageDraftResponse Evergreen.V26.Wiki.Slug (Result Evergreen.V26.Submission.SaveNewPageDraftError Evergreen.V26.Submission.Id)
    | SavePageEditDraftResponse Evergreen.V26.Wiki.Slug (Result Evergreen.V26.Submission.SavePageEditDraftError Evergreen.V26.Submission.Id)
    | SavePageDeleteDraftResponse Evergreen.V26.Wiki.Slug (Result Evergreen.V26.Submission.SavePageDeleteDraftError Evergreen.V26.Submission.Id)
    | SubmitDraftForReviewResponse Evergreen.V26.Wiki.Slug String (Result Evergreen.V26.Submission.SubmitDraftForReviewError ())
    | WithdrawSubmissionResponse Evergreen.V26.Wiki.Slug String (Result Evergreen.V26.Submission.WithdrawSubmissionError ())
    | DeleteMySubmissionResponse Evergreen.V26.Wiki.Slug String (Result Evergreen.V26.Submission.DeleteMySubmissionError ())
    | ApproveSubmissionResponse Evergreen.V26.Wiki.Slug String (Result Evergreen.V26.Submission.ApproveSubmissionError ())
    | RejectSubmissionResponse Evergreen.V26.Wiki.Slug String (Result Evergreen.V26.Submission.RejectSubmissionError ())
    | RequestSubmissionChangesResponse Evergreen.V26.Wiki.Slug String (Result Evergreen.V26.Submission.RequestChangesSubmissionError ())
    | HostAdminLoginResponse (Result Evergreen.V26.HostAdmin.LoginError ())
    | HostAdminWikiListResponse (Result Evergreen.V26.HostAdmin.ProtectedError (List Evergreen.V26.Wiki.CatalogEntry))
    | HostAuditLogResponse Evergreen.V26.WikiAuditLog.HostAuditLogFilter (Result Evergreen.V26.HostAdmin.ProtectedError (List Evergreen.V26.WikiAuditLog.ScopedAuditEvent))
    | CreateHostedWikiResponse (Result Evergreen.V26.HostAdmin.CreateHostedWikiError Evergreen.V26.Wiki.CatalogEntry)
    | HostWikiDetailResponse Evergreen.V26.Wiki.Slug (Result Evergreen.V26.HostAdmin.HostWikiDetailError Evergreen.V26.Wiki.CatalogEntry)
    | UpdateHostedWikiMetadataResponse Evergreen.V26.Wiki.Slug (Result Evergreen.V26.HostAdmin.UpdateHostedWikiMetadataError Evergreen.V26.Wiki.CatalogEntry)
    | DeactivateHostedWikiResponse Evergreen.V26.Wiki.Slug (Result Evergreen.V26.HostAdmin.WikiLifecycleError Evergreen.V26.Wiki.CatalogEntry)
    | ReactivateHostedWikiResponse Evergreen.V26.Wiki.Slug (Result Evergreen.V26.HostAdmin.WikiLifecycleError Evergreen.V26.Wiki.CatalogEntry)
    | DeleteHostedWikiResponse Evergreen.V26.Wiki.Slug (Result Evergreen.V26.HostAdmin.DeleteHostedWikiError ())
    | HostAdminDataExportResponse (Result Evergreen.V26.HostAdmin.DataExportError String)
    | HostAdminDataImportResponse (Result Evergreen.V26.HostAdmin.DataImportError ())
    | HostAdminWikiDataExportResponse Evergreen.V26.Wiki.Slug (Result Evergreen.V26.HostAdmin.WikiDataExportError String)
    | HostAdminWikiDataImportResponse Evergreen.V26.Wiki.Slug (Result Evergreen.V26.HostAdmin.WikiDataImportError ())
    | HostAdminWikiDataImportAutoResponse (Result Evergreen.V26.HostAdmin.WikiDataImportError Evergreen.V26.Wiki.Slug)

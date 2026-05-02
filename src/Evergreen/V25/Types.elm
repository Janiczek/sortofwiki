module Evergreen.V25.Types exposing (..)

import Dict
import Effect.Browser
import Effect.Browser.Navigation
import Effect.File
import Effect.Lamdera
import Evergreen.V25.ColorTheme
import Evergreen.V25.ContributorAccount
import Evergreen.V25.ContributorWikiSession
import Evergreen.V25.HostAdmin
import Evergreen.V25.Page
import Evergreen.V25.PendingReviewCount
import Evergreen.V25.Route
import Evergreen.V25.Store
import Evergreen.V25.Submission
import Evergreen.V25.SubmissionReviewDetail
import Evergreen.V25.Wiki
import Evergreen.V25.WikiAdminUsers
import Evergreen.V25.WikiAuditLog
import Evergreen.V25.WikiContributors
import Evergreen.V25.WikiFrontendSubscription
import Evergreen.V25.WikiMarkdownEditorPane
import Evergreen.V25.WikiRole
import Evergreen.V25.WikiSearch
import Evergreen.V25.WikiTodos
import Evergreen.V25.WikiUser
import RemoteData
import Set
import Time
import Url


type alias RegisterDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V25.ContributorAccount.RegisterContributorError ())
    }


type alias LoginDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V25.ContributorAccount.LoginContributorError ())
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
    , lastResult : Maybe (Result Evergreen.V25.Submission.SubmitNewPageError Evergreen.V25.Submission.NewPageSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V25.Submission.SaveNewPageDraftError Evergreen.V25.Submission.Id)
    }


type alias PageEditSubmitDraft =
    { markdownBody : String
    , tagsInput : String
    , publishedRowCollapsed : Bool
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V25.Submission.SubmitPageEditError Evergreen.V25.Submission.EditSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V25.Submission.SavePageEditDraftError Evergreen.V25.Submission.Id)
    }


type alias PageDeleteSubmitDraft =
    { reasonText : String
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V25.Submission.PageDeleteFormError Evergreen.V25.Submission.PageDeleteFormSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V25.Submission.SavePageDeleteDraftError Evergreen.V25.Submission.Id)
    }


type alias ReviewApproveDraft =
    { inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V25.Submission.ApproveSubmissionError ())
    }


type ReviewDecision
    = ReviewDecisionApprove
    | ReviewDecisionRequestChanges
    | ReviewDecisionReject


type alias ReviewRejectDraft =
    { reasonText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V25.Submission.RejectSubmissionError ())
    }


type alias ReviewRequestChangesDraft =
    { guidanceText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V25.Submission.RequestChangesSubmissionError ())
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
    , lastResult : Maybe (Result Evergreen.V25.HostAdmin.LoginError ())
    }


type alias HostAdminCreateWikiDraft =
    { slug : String
    , name : String
    , initialAdminUsername : String
    , initialAdminPassword : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V25.HostAdmin.CreateHostedWikiError Evergreen.V25.Wiki.CatalogEntry)
    }


type alias HostAdminWikiDetailDraft =
    { wikiSlug : Evergreen.V25.Wiki.Slug
    , load : RemoteData.RemoteData () (Result Evergreen.V25.HostAdmin.HostWikiDetailError Evergreen.V25.Wiki.CatalogEntry)
    , slugDraft : String
    , nameDraft : String
    , summaryDraft : String
    , saveInFlight : Bool
    , lastSaveResult : Maybe (Result Evergreen.V25.HostAdmin.UpdateHostedWikiMetadataError ())
    , lifecycleInFlight : Bool
    , lastLifecycleResult : Maybe (Result Evergreen.V25.HostAdmin.WikiLifecycleError ())
    , deleteConfirmDraft : String
    , deleteInFlight : Bool
    , lastDeleteResult : Maybe (Result Evergreen.V25.HostAdmin.DeleteHostedWikiError ())
    }


type alias FrontendModel =
    { key : Effect.Browser.Navigation.Key
    , colorThemePreference : Evergreen.V25.ColorTheme.ColorThemePreference
    , systemColorTheme : Evergreen.V25.ColorTheme.ColorTheme
    , route : Evergreen.V25.Route.Route
    , navigationFragment : Maybe String
    , store : Evergreen.V25.Store.Store
    , contributorWikiSessions : Dict.Dict Evergreen.V25.Wiki.Slug Evergreen.V25.ContributorWikiSession.ContributorWikiSession
    , registerDraft : RegisterDraft
    , loginDraft : LoginDraft
    , headerSearchQuery : String
    , headerSearchResults : List Evergreen.V25.WikiSearch.ResultItem
    , headerSearchPending : Maybe ( Evergreen.V25.Wiki.Slug, String )
    , wikiSearchPageQuery : String
    , wikiSearchPageResults : List Evergreen.V25.WikiSearch.ResultItem
    , wikiSearchPagePending : Maybe ( Evergreen.V25.Wiki.Slug, String )
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
    , wikiAdminAuditFilterSelectedKindTags : List Evergreen.V25.WikiAuditLog.AuditEventKindFilterTag
    , wikiAdminAuditAppliedFilter : Evergreen.V25.WikiAuditLog.AuditLogFilter
    , hostAdminAuditFilterWikiDraft : String
    , hostAdminAuditFilterActorDraft : String
    , hostAdminAuditFilterPageDraft : String
    , hostAdminAuditFilterSelectedKindTags : List Evergreen.V25.WikiAuditLog.AuditEventKindFilterTag
    , hostAdminAuditAppliedFilter : Evergreen.V25.WikiAuditLog.HostAuditLogFilter
    , hostAdminAuditLog : RemoteData.RemoteData () (Result Evergreen.V25.HostAdmin.ProtectedError (List Evergreen.V25.WikiAuditLog.ScopedAuditEvent))
    , hostAdminLoginDraft : HostAdminLoginDraft
    , hostAdminCreateWikiDraft : HostAdminCreateWikiDraft
    , hostAdminWikiDetailDraft : HostAdminWikiDetailDraft
    , hostAdminWikis : RemoteData.RemoteData () (Result Evergreen.V25.HostAdmin.ProtectedError (List Evergreen.V25.Wiki.CatalogEntry))
    , hostAdminSessionAuthenticated : Bool
    , hostAdminExportInFlight : Bool
    , hostAdminImportInFlight : Bool
    , hostAdminBackupNotice : Maybe String
    , hostAdminWikiExportInFlightSlug : Maybe Evergreen.V25.Wiki.Slug
    , hostAdminWikiImportInFlightSlug : Maybe Evergreen.V25.Wiki.Slug
    , hostAdminWikiImportPendingSlug : Maybe Evergreen.V25.Wiki.Slug
    , hostAdminWikisNotice : Maybe String
    , sideNavOpen : Bool
    , wikiPageMobileRightRailCollapsed : Bool
    , wikiMarkdownEditorPane : Evergreen.V25.WikiMarkdownEditorPane.WikiMarkdownEditorPane
    }


type alias BackendModel =
    { wikis : Dict.Dict Evergreen.V25.Wiki.Slug Evergreen.V25.Wiki.Wiki
    , contributors : Evergreen.V25.WikiContributors.Registry
    , contributorSessions : Evergreen.V25.WikiUser.SessionTable
    , hostSessions : Set.Set String
    , submissions : Dict.Dict String Evergreen.V25.Submission.Submission
    , nextSubmissionCounter : Int
    , wikiAuditEvents : Dict.Dict Evergreen.V25.Wiki.Slug (List Evergreen.V25.WikiAuditLog.AuditEvent)
    , pendingReviewCounts : Dict.Dict Evergreen.V25.Wiki.Slug Int
    , pendingReviewClients : Evergreen.V25.PendingReviewCount.PendingReviewClientSets
    , wikiFrontendClients : Evergreen.V25.WikiFrontendSubscription.WikiFrontendClientSets
    , wikiSearchIndexes : Dict.Dict Evergreen.V25.Wiki.Slug Evergreen.V25.WikiSearch.PrefixIndex
    , wikiTodosCaches : Dict.Dict Evergreen.V25.Wiki.Slug (List Evergreen.V25.WikiTodos.TableRow)
    }


type FrontendMsg
    = UrlClicked Effect.Browser.UrlRequest
    | UrlChanged Url.Url
    | UrlFragmentScrollDone
    | ColorThemeToggled
    | ColorThemeFromJs (Maybe Evergreen.V25.ColorTheme.Incoming)
    | RegisterFormUsernameChanged String
    | RegisterFormPasswordChanged String
    | RegisterFormSubmitted
    | LoginFormUsernameChanged String
    | LoginFormPasswordChanged String
    | LoginFormSubmitted
    | HeaderSearchQueryChanged String
    | HeaderSearchTimeoutReached Evergreen.V25.Wiki.Slug String
    | HeaderSearchSubmitted
    | WikiSearchPageQueryChanged String
    | WikiSearchPageTimeoutReached Evergreen.V25.Wiki.Slug String
    | ContributorLogoutWiki Evergreen.V25.Wiki.Slug
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
    | WikiAdminAuditFilterTypeTagToggled Evergreen.V25.WikiAuditLog.AuditEventKindFilterTag Bool
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
    | HostAdminAuditFilterTypeTagToggled Evergreen.V25.WikiAuditLog.AuditEventKindFilterTag Bool
    | HostAdminDataExportClicked
    | HostAdminDataImportPickRequested
    | HostAdminDataImportFileSelected Effect.File.File
    | HostAdminDataImportFileRead (Result () String)
    | HostAdminWikisDataImportPickRequested
    | HostAdminWikisDataImportFileSelected Effect.File.File
    | HostAdminWikisDataImportFileRead (Result () String)
    | HostAdminWikiDataExportClicked Evergreen.V25.Wiki.Slug
    | HostAdminWikiDataImportPickRequested Evergreen.V25.Wiki.Slug
    | HostAdminWikiDataImportFileSelected Effect.File.File
    | HostAdminWikiDataImportFileRead Evergreen.V25.Wiki.Slug (Result () String)
    | SideNavOpened
    | SideNavClosed
    | WikiMarkdownEditorPaneSelected Evergreen.V25.WikiMarkdownEditorPane.WikiMarkdownEditorPane


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
    | RequestWikiFrontendDetails Evergreen.V25.Wiki.Slug
    | RequestWikiTodos Evergreen.V25.Wiki.Slug
    | RequestPageFrontendDetails Evergreen.V25.Wiki.Slug Evergreen.V25.Page.Slug
    | RequestWikiSearch Evergreen.V25.Wiki.Slug String
    | RequestMyPendingSubmissions Evergreen.V25.Wiki.Slug
    | RequestReviewQueue Evergreen.V25.Wiki.Slug
    | RequestReviewSubmissionDetail Evergreen.V25.Wiki.Slug String
    | RequestWikiUsers Evergreen.V25.Wiki.Slug
    | RequestWikiAuditLog Evergreen.V25.Wiki.Slug Evergreen.V25.WikiAuditLog.AuditLogFilter
    | PromoteContributorToTrusted Evergreen.V25.Wiki.Slug String
    | DemoteTrustedToContributor Evergreen.V25.Wiki.Slug String
    | GrantWikiAdmin Evergreen.V25.Wiki.Slug String
    | RevokeWikiAdmin Evergreen.V25.Wiki.Slug String
    | RequestSubmissionDetails Evergreen.V25.Wiki.Slug String
    | RegisterContributor Evergreen.V25.Wiki.Slug RegisterContributorPayload
    | LoginContributor Evergreen.V25.Wiki.Slug LoginContributorPayload
    | LogoutContributor Evergreen.V25.Wiki.Slug
    | SubmitNewPage Evergreen.V25.Wiki.Slug SubmitNewPagePayload
    | SubmitPageEdit Evergreen.V25.Wiki.Slug Evergreen.V25.Page.Slug String String
    | RequestPublishedPageDeletion Evergreen.V25.Wiki.Slug Evergreen.V25.Page.Slug String
    | DeletePublishedPageImmediately Evergreen.V25.Wiki.Slug Evergreen.V25.Page.Slug String
    | SaveNewPageDraft
        Evergreen.V25.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , rawPageSlug : String
        , rawMarkdown : String
        , rawTags : String
        }
    | SavePageEditDraft
        Evergreen.V25.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V25.Page.Slug
        , rawMarkdown : String
        , rawTags : String
        }
    | SavePageDeleteDraft
        Evergreen.V25.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V25.Page.Slug
        , rawReason : String
        }
    | SubmitDraftForReview Evergreen.V25.Wiki.Slug String
    | WithdrawSubmission Evergreen.V25.Wiki.Slug String
    | DeleteMySubmission Evergreen.V25.Wiki.Slug String
    | ApproveSubmission Evergreen.V25.Wiki.Slug String
    | RejectSubmission Evergreen.V25.Wiki.Slug RejectSubmissionPayload
    | RequestSubmissionChanges Evergreen.V25.Wiki.Slug RequestSubmissionChangesPayload
    | HostAdminLogin String
    | RequestHostWikiList
    | RequestHostAuditLog Evergreen.V25.WikiAuditLog.HostAuditLogFilter
    | RequestHostWikiDetail Evergreen.V25.Wiki.Slug
    | CreateHostedWiki CreateHostedWikiPayload
    | UpdateHostedWikiMetadata Evergreen.V25.Wiki.Slug UpdateHostedWikiMetadataPayload
    | DeactivateHostedWiki Evergreen.V25.Wiki.Slug
    | ReactivateHostedWiki Evergreen.V25.Wiki.Slug
    | DeleteHostedWiki Evergreen.V25.Wiki.Slug String
    | RequestHostAdminDataExport
    | ImportHostAdminDataSnapshot String
    | RequestHostAdminWikiDataExport Evergreen.V25.Wiki.Slug
    | ImportHostAdminWikiDataSnapshot Evergreen.V25.Wiki.Slug String
    | ImportHostAdminWikiDataSnapshotAuto String


type BackendMsg
    = ToBackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Time.Posix


type ToFrontend
    = WikiCatalogResponse (Dict.Dict Evergreen.V25.Wiki.Slug Evergreen.V25.Wiki.CatalogEntry)
    | PendingReviewCountUpdated Evergreen.V25.Wiki.Slug Int
    | WikiFrontendDetailsResponse Evergreen.V25.Wiki.Slug (Maybe Evergreen.V25.Wiki.FrontendDetails)
    | WikiTodosResponse Evergreen.V25.Wiki.Slug (Result () (List Evergreen.V25.WikiTodos.TableRow))
    | PageFrontendDetailsResponse Evergreen.V25.Wiki.Slug Evergreen.V25.Page.Slug (Maybe Evergreen.V25.Page.FrontendDetails)
    | WikiSearchResponse Evergreen.V25.Wiki.Slug String (List Evergreen.V25.WikiSearch.ResultItem)
    | MyPendingSubmissionsResponse Evergreen.V25.Wiki.Slug (Result Evergreen.V25.Submission.MyPendingSubmissionsError (List Evergreen.V25.Submission.MyPendingSubmissionListItem))
    | ReviewQueueResponse Evergreen.V25.Wiki.Slug (Result Evergreen.V25.Submission.ReviewQueueError (List Evergreen.V25.Submission.ReviewQueueItem))
    | ReviewSubmissionDetailResponse Evergreen.V25.Wiki.Slug String (Result Evergreen.V25.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V25.SubmissionReviewDetail.SubmissionReviewDetail)
    | WikiUsersResponse Evergreen.V25.Wiki.Slug (Result Evergreen.V25.WikiAdminUsers.Error (List Evergreen.V25.WikiAdminUsers.ListedUser))
    | WikiAuditLogResponse Evergreen.V25.Wiki.Slug Evergreen.V25.WikiAuditLog.AuditLogFilter (Result Evergreen.V25.WikiAuditLog.Error (List Evergreen.V25.WikiAuditLog.AuditEvent))
    | PromoteContributorToTrustedResponse Evergreen.V25.Wiki.Slug (Result Evergreen.V25.WikiAdminUsers.PromoteContributorError ())
    | DemoteTrustedToContributorResponse Evergreen.V25.Wiki.Slug (Result Evergreen.V25.WikiAdminUsers.DemoteTrustedError ())
    | GrantWikiAdminResponse Evergreen.V25.Wiki.Slug (Result Evergreen.V25.WikiAdminUsers.GrantTrustedToAdminError ())
    | RevokeWikiAdminResponse Evergreen.V25.Wiki.Slug (Result Evergreen.V25.WikiAdminUsers.RevokeAdminError ())
    | SubmissionDetailsResponse Evergreen.V25.Wiki.Slug String (Result Evergreen.V25.Submission.DetailsError Evergreen.V25.Submission.ContributorView)
    | RegisterContributorResponse Evergreen.V25.Wiki.Slug (Result Evergreen.V25.ContributorAccount.RegisterContributorError Evergreen.V25.WikiRole.WikiRole)
    | LoginContributorResponse Evergreen.V25.Wiki.Slug (Result Evergreen.V25.ContributorAccount.LoginContributorError Evergreen.V25.WikiRole.WikiRole)
    | LogoutContributorResponse Evergreen.V25.Wiki.Slug
    | SubmitNewPageResponse Evergreen.V25.Wiki.Slug (Result Evergreen.V25.Submission.SubmitNewPageError Evergreen.V25.Submission.NewPageSubmitSuccess)
    | SubmitPageEditResponse Evergreen.V25.Wiki.Slug (Result Evergreen.V25.Submission.SubmitPageEditError Evergreen.V25.Submission.EditSubmitSuccess)
    | RequestPublishedPageDeletionResponse Evergreen.V25.Wiki.Slug (Result Evergreen.V25.Submission.RequestPublishedPageDeletionError Evergreen.V25.Submission.Id)
    | DeletePublishedPageImmediatelyResponse Evergreen.V25.Wiki.Slug (Result Evergreen.V25.Submission.DeletePublishedPageImmediatelyError ())
    | SaveNewPageDraftResponse Evergreen.V25.Wiki.Slug (Result Evergreen.V25.Submission.SaveNewPageDraftError Evergreen.V25.Submission.Id)
    | SavePageEditDraftResponse Evergreen.V25.Wiki.Slug (Result Evergreen.V25.Submission.SavePageEditDraftError Evergreen.V25.Submission.Id)
    | SavePageDeleteDraftResponse Evergreen.V25.Wiki.Slug (Result Evergreen.V25.Submission.SavePageDeleteDraftError Evergreen.V25.Submission.Id)
    | SubmitDraftForReviewResponse Evergreen.V25.Wiki.Slug String (Result Evergreen.V25.Submission.SubmitDraftForReviewError ())
    | WithdrawSubmissionResponse Evergreen.V25.Wiki.Slug String (Result Evergreen.V25.Submission.WithdrawSubmissionError ())
    | DeleteMySubmissionResponse Evergreen.V25.Wiki.Slug String (Result Evergreen.V25.Submission.DeleteMySubmissionError ())
    | ApproveSubmissionResponse Evergreen.V25.Wiki.Slug String (Result Evergreen.V25.Submission.ApproveSubmissionError ())
    | RejectSubmissionResponse Evergreen.V25.Wiki.Slug String (Result Evergreen.V25.Submission.RejectSubmissionError ())
    | RequestSubmissionChangesResponse Evergreen.V25.Wiki.Slug String (Result Evergreen.V25.Submission.RequestChangesSubmissionError ())
    | HostAdminLoginResponse (Result Evergreen.V25.HostAdmin.LoginError ())
    | HostAdminWikiListResponse (Result Evergreen.V25.HostAdmin.ProtectedError (List Evergreen.V25.Wiki.CatalogEntry))
    | HostAuditLogResponse Evergreen.V25.WikiAuditLog.HostAuditLogFilter (Result Evergreen.V25.HostAdmin.ProtectedError (List Evergreen.V25.WikiAuditLog.ScopedAuditEvent))
    | CreateHostedWikiResponse (Result Evergreen.V25.HostAdmin.CreateHostedWikiError Evergreen.V25.Wiki.CatalogEntry)
    | HostWikiDetailResponse Evergreen.V25.Wiki.Slug (Result Evergreen.V25.HostAdmin.HostWikiDetailError Evergreen.V25.Wiki.CatalogEntry)
    | UpdateHostedWikiMetadataResponse Evergreen.V25.Wiki.Slug (Result Evergreen.V25.HostAdmin.UpdateHostedWikiMetadataError Evergreen.V25.Wiki.CatalogEntry)
    | DeactivateHostedWikiResponse Evergreen.V25.Wiki.Slug (Result Evergreen.V25.HostAdmin.WikiLifecycleError Evergreen.V25.Wiki.CatalogEntry)
    | ReactivateHostedWikiResponse Evergreen.V25.Wiki.Slug (Result Evergreen.V25.HostAdmin.WikiLifecycleError Evergreen.V25.Wiki.CatalogEntry)
    | DeleteHostedWikiResponse Evergreen.V25.Wiki.Slug (Result Evergreen.V25.HostAdmin.DeleteHostedWikiError ())
    | HostAdminDataExportResponse (Result Evergreen.V25.HostAdmin.DataExportError String)
    | HostAdminDataImportResponse (Result Evergreen.V25.HostAdmin.DataImportError ())
    | HostAdminWikiDataExportResponse Evergreen.V25.Wiki.Slug (Result Evergreen.V25.HostAdmin.WikiDataExportError String)
    | HostAdminWikiDataImportResponse Evergreen.V25.Wiki.Slug (Result Evergreen.V25.HostAdmin.WikiDataImportError ())
    | HostAdminWikiDataImportAutoResponse (Result Evergreen.V25.HostAdmin.WikiDataImportError Evergreen.V25.Wiki.Slug)

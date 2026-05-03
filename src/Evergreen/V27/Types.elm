module Evergreen.V27.Types exposing (..)

import Dict
import Effect.Browser
import Effect.Browser.Navigation
import Effect.File
import Effect.Lamdera
import Evergreen.V27.CacheVersion
import Evergreen.V27.ColorTheme
import Evergreen.V27.ContributorAccount
import Evergreen.V27.ContributorWikiSession
import Evergreen.V27.HostAdmin
import Evergreen.V27.Page
import Evergreen.V27.PendingReviewCount
import Evergreen.V27.Route
import Evergreen.V27.Store
import Evergreen.V27.Submission
import Evergreen.V27.SubmissionReviewDetail
import Evergreen.V27.Wiki
import Evergreen.V27.WikiAdminUsers
import Evergreen.V27.WikiAuditLog
import Evergreen.V27.WikiContributors
import Evergreen.V27.WikiFrontendSubscription
import Evergreen.V27.WikiMarkdownEditorPane
import Evergreen.V27.WikiRole
import Evergreen.V27.WikiSearch
import Evergreen.V27.WikiStats
import Evergreen.V27.WikiTodos
import Evergreen.V27.WikiUser
import RemoteData
import Set
import Time
import Url


type alias RegisterDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V27.ContributorAccount.RegisterContributorError ())
    }


type alias LoginDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V27.ContributorAccount.LoginContributorError ())
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
    , lastResult : Maybe (Result Evergreen.V27.Submission.SubmitNewPageError Evergreen.V27.Submission.NewPageSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V27.Submission.SaveNewPageDraftError Evergreen.V27.Submission.Id)
    }


type alias PageEditSubmitDraft =
    { markdownBody : String
    , tagsInput : String
    , publishedRowCollapsed : Bool
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V27.Submission.SubmitPageEditError Evergreen.V27.Submission.EditSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V27.Submission.SavePageEditDraftError Evergreen.V27.Submission.Id)
    }


type alias PageDeleteSubmitDraft =
    { reasonText : String
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V27.Submission.PageDeleteFormError Evergreen.V27.Submission.PageDeleteFormSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V27.Submission.SavePageDeleteDraftError Evergreen.V27.Submission.Id)
    }


type alias ReviewApproveDraft =
    { inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V27.Submission.ApproveSubmissionError ())
    }


type ReviewDecision
    = ReviewDecisionApprove
    | ReviewDecisionRequestChanges
    | ReviewDecisionReject


type alias ReviewRejectDraft =
    { reasonText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V27.Submission.RejectSubmissionError ())
    }


type alias ReviewRequestChangesDraft =
    { guidanceText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V27.Submission.RequestChangesSubmissionError ())
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
    , lastResult : Maybe (Result Evergreen.V27.HostAdmin.LoginError ())
    }


type alias HostAdminCreateWikiDraft =
    { slug : String
    , name : String
    , initialAdminUsername : String
    , initialAdminPassword : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V27.HostAdmin.CreateHostedWikiError Evergreen.V27.Wiki.CatalogEntry)
    }


type alias HostAdminWikiDetailDraft =
    { wikiSlug : Evergreen.V27.Wiki.Slug
    , load : RemoteData.RemoteData () (Result Evergreen.V27.HostAdmin.HostWikiDetailError Evergreen.V27.Wiki.CatalogEntry)
    , slugDraft : String
    , nameDraft : String
    , summaryDraft : String
    , saveInFlight : Bool
    , lastSaveResult : Maybe (Result Evergreen.V27.HostAdmin.UpdateHostedWikiMetadataError ())
    , lifecycleInFlight : Bool
    , lastLifecycleResult : Maybe (Result Evergreen.V27.HostAdmin.WikiLifecycleError ())
    , deleteConfirmDraft : String
    , deleteInFlight : Bool
    , lastDeleteResult : Maybe (Result Evergreen.V27.HostAdmin.DeleteHostedWikiError ())
    }


type alias FrontendModel =
    { key : Effect.Browser.Navigation.Key
    , colorThemePreference : Evergreen.V27.ColorTheme.ColorThemePreference
    , systemColorTheme : Evergreen.V27.ColorTheme.ColorTheme
    , currentUrl : Url.Url
    , route : Evergreen.V27.Route.Route
    , navigationFragment : Maybe String
    , store : Evergreen.V27.Store.Store
    , contributorWikiSessions : Dict.Dict Evergreen.V27.Wiki.Slug Evergreen.V27.ContributorWikiSession.ContributorWikiSession
    , registerDraft : RegisterDraft
    , loginDraft : LoginDraft
    , headerSearchQuery : String
    , headerSearchResults : List Evergreen.V27.WikiSearch.ResultItem
    , headerSearchPending : Maybe ( Evergreen.V27.Wiki.Slug, String )
    , wikiSearchPageQuery : String
    , wikiSearchPageResults : List Evergreen.V27.WikiSearch.ResultItem
    , wikiSearchPagePending : Maybe ( Evergreen.V27.Wiki.Slug, String )
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
    , wikiAdminAuditFilterSelectedKindTags : List Evergreen.V27.WikiAuditLog.AuditEventKindFilterTag
    , wikiAdminAuditAppliedFilter : Evergreen.V27.WikiAuditLog.AuditLogFilter
    , hostAdminAuditFilterWikiDraft : String
    , hostAdminAuditFilterActorDraft : String
    , hostAdminAuditFilterPageDraft : String
    , hostAdminAuditFilterSelectedKindTags : List Evergreen.V27.WikiAuditLog.AuditEventKindFilterTag
    , hostAdminAuditAppliedFilter : Evergreen.V27.WikiAuditLog.HostAuditLogFilter
    , hostAdminAuditLog : RemoteData.RemoteData () (Result Evergreen.V27.HostAdmin.ProtectedError (List Evergreen.V27.WikiAuditLog.ScopedAuditEvent))
    , hostAdminLoginDraft : HostAdminLoginDraft
    , hostAdminCreateWikiDraft : HostAdminCreateWikiDraft
    , hostAdminWikiDetailDraft : HostAdminWikiDetailDraft
    , hostAdminWikis : RemoteData.RemoteData () (Result Evergreen.V27.HostAdmin.ProtectedError (List Evergreen.V27.Wiki.CatalogEntry))
    , hostAdminSessionAuthenticated : Bool
    , hostAdminExportInFlight : Bool
    , hostAdminImportInFlight : Bool
    , hostAdminBackupNotice : Maybe String
    , hostAdminWikiExportInFlightSlug : Maybe Evergreen.V27.Wiki.Slug
    , hostAdminWikiImportInFlightSlug : Maybe Evergreen.V27.Wiki.Slug
    , hostAdminWikiImportPendingSlug : Maybe Evergreen.V27.Wiki.Slug
    , hostAdminWikisNotice : Maybe String
    , sideNavOpen : Bool
    , wikiPageMobileRightRailCollapsed : Bool
    , wikiMarkdownEditorPane : Evergreen.V27.WikiMarkdownEditorPane.WikiMarkdownEditorPane
    , wikiStatsDailyActivityHover :
        Maybe
            { metric : String
            , day : String
            , count : Int
            }
    }


type alias WikiStatsPartitions =
    { fromWiki : Evergreen.V27.WikiStats.FromWiki
    , fromAudit : Evergreen.V27.WikiStats.FromAudit
    , fromViews : Evergreen.V27.WikiStats.FromViews
    }


type alias BackendModel =
    { wikis : Dict.Dict Evergreen.V27.Wiki.Slug Evergreen.V27.Wiki.Wiki
    , contributors : Evergreen.V27.WikiContributors.Registry
    , contributorSessions : Evergreen.V27.WikiUser.SessionTable
    , hostSessions : Set.Set String
    , submissions : Dict.Dict String Evergreen.V27.Submission.Submission
    , nextSubmissionCounter : Int
    , wikiAuditEvents : Dict.Dict Evergreen.V27.Wiki.Slug (List Evergreen.V27.WikiAuditLog.AuditEvent)
    , wikiAuditVersions : Dict.Dict Evergreen.V27.Wiki.Slug Int
    , pendingReviewCounts : Dict.Dict Evergreen.V27.Wiki.Slug Int
    , pendingReviewClients : Evergreen.V27.PendingReviewCount.PendingReviewClientSets
    , wikiFrontendClients : Evergreen.V27.WikiFrontendSubscription.WikiFrontendClientSets
    , wikiSearchIndexes : Dict.Dict Evergreen.V27.Wiki.Slug Evergreen.V27.WikiSearch.PrefixIndex
    , wikiTodosCaches : Dict.Dict Evergreen.V27.Wiki.Slug (List Evergreen.V27.WikiTodos.TableRow)
    , pageViewCounts : Dict.Dict Evergreen.V27.Wiki.Slug (Dict.Dict Evergreen.V27.Page.Slug Int)
    , wikiViewsVersions : Dict.Dict Evergreen.V27.Wiki.Slug Int
    , wikiStatsCache : Dict.Dict Evergreen.V27.Wiki.Slug WikiStatsPartitions
    }


type FrontendMsg
    = UrlClicked Effect.Browser.UrlRequest
    | UrlChanged Url.Url
    | UrlFragmentScrollDone
    | ColorThemeToggled
    | ColorThemeFromJs (Maybe Evergreen.V27.ColorTheme.Incoming)
    | RegisterFormUsernameChanged String
    | RegisterFormPasswordChanged String
    | RegisterFormSubmitted
    | LoginFormUsernameChanged String
    | LoginFormPasswordChanged String
    | LoginFormSubmitted
    | HeaderSearchQueryChanged String
    | HeaderSearchTimeoutReached Evergreen.V27.Wiki.Slug String
    | HeaderSearchSubmitted
    | WikiSearchPageQueryChanged String
    | WikiSearchPageTimeoutReached Evergreen.V27.Wiki.Slug String
    | ContributorLogoutWiki Evergreen.V27.Wiki.Slug
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
    | WikiAdminAuditFilterTypeTagToggled Evergreen.V27.WikiAuditLog.AuditEventKindFilterTag Bool
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
    | HostAdminAuditFilterTypeTagToggled Evergreen.V27.WikiAuditLog.AuditEventKindFilterTag Bool
    | HostAdminDataExportClicked
    | HostAdminDataImportPickRequested
    | HostAdminDataImportFileSelected Effect.File.File
    | HostAdminDataImportFileRead (Result () String)
    | HostAdminWikisDataImportPickRequested
    | HostAdminWikisDataImportFileSelected Effect.File.File
    | HostAdminWikisDataImportFileRead (Result () String)
    | HostAdminWikiDataExportClicked Evergreen.V27.Wiki.Slug
    | HostAdminWikiDataImportPickRequested Evergreen.V27.Wiki.Slug
    | HostAdminWikiDataImportFileSelected Effect.File.File
    | HostAdminWikiDataImportFileRead Evergreen.V27.Wiki.Slug (Result () String)
    | SideNavOpened
    | SideNavClosed
    | WikiMarkdownEditorPaneSelected Evergreen.V27.WikiMarkdownEditorPane.WikiMarkdownEditorPane
    | WikiStatsDailyActivityHoverChanged
        (Maybe
            { metric : String
            , day : String
            , count : Int
            }
        )


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
    | RequestWikiStats Evergreen.V27.Wiki.Slug (Maybe Evergreen.V27.CacheVersion.Versions)
    | RequestWikiFrontendDetails Evergreen.V27.Wiki.Slug
    | RequestWikiTodos Evergreen.V27.Wiki.Slug (Maybe Int)
    | RequestPageFrontendDetails Evergreen.V27.Wiki.Slug Evergreen.V27.Page.Slug
    | RequestWikiSearch Evergreen.V27.Wiki.Slug String
    | RequestMyPendingSubmissions Evergreen.V27.Wiki.Slug
    | RequestReviewQueue Evergreen.V27.Wiki.Slug
    | RequestReviewSubmissionDetail Evergreen.V27.Wiki.Slug String
    | RequestWikiUsers Evergreen.V27.Wiki.Slug
    | RequestWikiAuditLog Evergreen.V27.Wiki.Slug Evergreen.V27.WikiAuditLog.AuditLogFilter (Maybe Int)
    | PromoteContributorToTrusted Evergreen.V27.Wiki.Slug String
    | DemoteTrustedToContributor Evergreen.V27.Wiki.Slug String
    | GrantWikiAdmin Evergreen.V27.Wiki.Slug String
    | RevokeWikiAdmin Evergreen.V27.Wiki.Slug String
    | RequestSubmissionDetails Evergreen.V27.Wiki.Slug String
    | RegisterContributor Evergreen.V27.Wiki.Slug RegisterContributorPayload
    | LoginContributor Evergreen.V27.Wiki.Slug LoginContributorPayload
    | LogoutContributor Evergreen.V27.Wiki.Slug
    | SubmitNewPage Evergreen.V27.Wiki.Slug SubmitNewPagePayload
    | SubmitPageEdit Evergreen.V27.Wiki.Slug Evergreen.V27.Page.Slug String String
    | RequestPublishedPageDeletion Evergreen.V27.Wiki.Slug Evergreen.V27.Page.Slug String
    | DeletePublishedPageImmediately Evergreen.V27.Wiki.Slug Evergreen.V27.Page.Slug String
    | SaveNewPageDraft
        Evergreen.V27.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , rawPageSlug : String
        , rawMarkdown : String
        , rawTags : String
        }
    | SavePageEditDraft
        Evergreen.V27.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V27.Page.Slug
        , rawMarkdown : String
        , rawTags : String
        }
    | SavePageDeleteDraft
        Evergreen.V27.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V27.Page.Slug
        , rawReason : String
        }
    | SubmitDraftForReview Evergreen.V27.Wiki.Slug String
    | WithdrawSubmission Evergreen.V27.Wiki.Slug String
    | DeleteMySubmission Evergreen.V27.Wiki.Slug String
    | ApproveSubmission Evergreen.V27.Wiki.Slug String
    | RejectSubmission Evergreen.V27.Wiki.Slug RejectSubmissionPayload
    | RequestSubmissionChanges Evergreen.V27.Wiki.Slug RequestSubmissionChangesPayload
    | HostAdminLogin String
    | RequestHostWikiList
    | RequestHostAuditLog Evergreen.V27.WikiAuditLog.HostAuditLogFilter
    | RequestHostWikiDetail Evergreen.V27.Wiki.Slug
    | CreateHostedWiki CreateHostedWikiPayload
    | UpdateHostedWikiMetadata Evergreen.V27.Wiki.Slug UpdateHostedWikiMetadataPayload
    | DeactivateHostedWiki Evergreen.V27.Wiki.Slug
    | ReactivateHostedWiki Evergreen.V27.Wiki.Slug
    | DeleteHostedWiki Evergreen.V27.Wiki.Slug String
    | RequestHostAdminDataExport
    | ImportHostAdminDataSnapshot String
    | RequestHostAdminWikiDataExport Evergreen.V27.Wiki.Slug
    | ImportHostAdminWikiDataSnapshot Evergreen.V27.Wiki.Slug String
    | ImportHostAdminWikiDataSnapshotAuto String


type BackendMsg
    = ToBackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Time.Posix


type ToFrontend
    = WikiCatalogResponse (Dict.Dict Evergreen.V27.Wiki.Slug Evergreen.V27.Wiki.CatalogEntry)
    | WikiStatsResponse Evergreen.V27.Wiki.Slug Evergreen.V27.CacheVersion.Versions (Maybe Evergreen.V27.WikiStats.Summary)
    | WikiStatsUnchanged
    | WikiCacheInvalidated Evergreen.V27.Wiki.Slug Evergreen.V27.CacheVersion.Versions
    | WikiSlugRenamed Evergreen.V27.Wiki.Slug Evergreen.V27.Wiki.Slug
    | PendingReviewCountUpdated Evergreen.V27.Wiki.Slug Int
    | WikiFrontendDetailsResponse Evergreen.V27.Wiki.Slug (Maybe Evergreen.V27.Wiki.FrontendDetails)
    | WikiTodosResponse Evergreen.V27.Wiki.Slug Int (Result () (List Evergreen.V27.WikiTodos.TableRow))
    | WikiTodosUnchanged
    | PageFrontendDetailsResponse Evergreen.V27.Wiki.Slug Evergreen.V27.Page.Slug (Maybe Evergreen.V27.Page.FrontendDetails)
    | WikiSearchResponse Evergreen.V27.Wiki.Slug String (List Evergreen.V27.WikiSearch.ResultItem)
    | MyPendingSubmissionsResponse Evergreen.V27.Wiki.Slug (Result Evergreen.V27.Submission.MyPendingSubmissionsError (List Evergreen.V27.Submission.MyPendingSubmissionListItem))
    | ReviewQueueResponse Evergreen.V27.Wiki.Slug (Result Evergreen.V27.Submission.ReviewQueueError (List Evergreen.V27.Submission.ReviewQueueItem))
    | ReviewSubmissionDetailResponse Evergreen.V27.Wiki.Slug String (Result Evergreen.V27.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V27.SubmissionReviewDetail.SubmissionReviewDetail)
    | WikiUsersResponse Evergreen.V27.Wiki.Slug (Result Evergreen.V27.WikiAdminUsers.Error (List Evergreen.V27.WikiAdminUsers.ListedUser))
    | WikiAuditLogResponse Evergreen.V27.Wiki.Slug Evergreen.V27.WikiAuditLog.AuditLogFilter Int (Result Evergreen.V27.WikiAuditLog.Error (List Evergreen.V27.WikiAuditLog.AuditEvent))
    | WikiAuditLogUnchanged Evergreen.V27.Wiki.Slug
    | PromoteContributorToTrustedResponse Evergreen.V27.Wiki.Slug (Result Evergreen.V27.WikiAdminUsers.PromoteContributorError ())
    | DemoteTrustedToContributorResponse Evergreen.V27.Wiki.Slug (Result Evergreen.V27.WikiAdminUsers.DemoteTrustedError ())
    | GrantWikiAdminResponse Evergreen.V27.Wiki.Slug (Result Evergreen.V27.WikiAdminUsers.GrantTrustedToAdminError ())
    | RevokeWikiAdminResponse Evergreen.V27.Wiki.Slug (Result Evergreen.V27.WikiAdminUsers.RevokeAdminError ())
    | SubmissionDetailsResponse Evergreen.V27.Wiki.Slug String (Result Evergreen.V27.Submission.DetailsError Evergreen.V27.Submission.ContributorView)
    | RegisterContributorResponse Evergreen.V27.Wiki.Slug (Result Evergreen.V27.ContributorAccount.RegisterContributorError Evergreen.V27.WikiRole.WikiRole)
    | LoginContributorResponse Evergreen.V27.Wiki.Slug (Result Evergreen.V27.ContributorAccount.LoginContributorError Evergreen.V27.WikiRole.WikiRole)
    | LogoutContributorResponse Evergreen.V27.Wiki.Slug
    | SubmitNewPageResponse Evergreen.V27.Wiki.Slug (Result Evergreen.V27.Submission.SubmitNewPageError Evergreen.V27.Submission.NewPageSubmitSuccess)
    | SubmitPageEditResponse Evergreen.V27.Wiki.Slug (Result Evergreen.V27.Submission.SubmitPageEditError Evergreen.V27.Submission.EditSubmitSuccess)
    | RequestPublishedPageDeletionResponse Evergreen.V27.Wiki.Slug (Result Evergreen.V27.Submission.RequestPublishedPageDeletionError Evergreen.V27.Submission.Id)
    | DeletePublishedPageImmediatelyResponse Evergreen.V27.Wiki.Slug (Result Evergreen.V27.Submission.DeletePublishedPageImmediatelyError ())
    | SaveNewPageDraftResponse Evergreen.V27.Wiki.Slug (Result Evergreen.V27.Submission.SaveNewPageDraftError Evergreen.V27.Submission.Id)
    | SavePageEditDraftResponse Evergreen.V27.Wiki.Slug (Result Evergreen.V27.Submission.SavePageEditDraftError Evergreen.V27.Submission.Id)
    | SavePageDeleteDraftResponse Evergreen.V27.Wiki.Slug (Result Evergreen.V27.Submission.SavePageDeleteDraftError Evergreen.V27.Submission.Id)
    | SubmitDraftForReviewResponse Evergreen.V27.Wiki.Slug String (Result Evergreen.V27.Submission.SubmitDraftForReviewError ())
    | WithdrawSubmissionResponse Evergreen.V27.Wiki.Slug String (Result Evergreen.V27.Submission.WithdrawSubmissionError ())
    | DeleteMySubmissionResponse Evergreen.V27.Wiki.Slug String (Result Evergreen.V27.Submission.DeleteMySubmissionError ())
    | ApproveSubmissionResponse Evergreen.V27.Wiki.Slug String (Result Evergreen.V27.Submission.ApproveSubmissionError ())
    | RejectSubmissionResponse Evergreen.V27.Wiki.Slug String (Result Evergreen.V27.Submission.RejectSubmissionError ())
    | RequestSubmissionChangesResponse Evergreen.V27.Wiki.Slug String (Result Evergreen.V27.Submission.RequestChangesSubmissionError ())
    | HostAdminLoginResponse (Result Evergreen.V27.HostAdmin.LoginError ())
    | HostAdminWikiListResponse (Result Evergreen.V27.HostAdmin.ProtectedError (List Evergreen.V27.Wiki.CatalogEntry))
    | HostAuditLogResponse Evergreen.V27.WikiAuditLog.HostAuditLogFilter (Result Evergreen.V27.HostAdmin.ProtectedError (List Evergreen.V27.WikiAuditLog.ScopedAuditEvent))
    | CreateHostedWikiResponse (Result Evergreen.V27.HostAdmin.CreateHostedWikiError Evergreen.V27.Wiki.CatalogEntry)
    | HostWikiDetailResponse Evergreen.V27.Wiki.Slug (Result Evergreen.V27.HostAdmin.HostWikiDetailError Evergreen.V27.Wiki.CatalogEntry)
    | UpdateHostedWikiMetadataResponse Evergreen.V27.Wiki.Slug (Result Evergreen.V27.HostAdmin.UpdateHostedWikiMetadataError Evergreen.V27.Wiki.CatalogEntry)
    | DeactivateHostedWikiResponse Evergreen.V27.Wiki.Slug (Result Evergreen.V27.HostAdmin.WikiLifecycleError Evergreen.V27.Wiki.CatalogEntry)
    | ReactivateHostedWikiResponse Evergreen.V27.Wiki.Slug (Result Evergreen.V27.HostAdmin.WikiLifecycleError Evergreen.V27.Wiki.CatalogEntry)
    | DeleteHostedWikiResponse Evergreen.V27.Wiki.Slug (Result Evergreen.V27.HostAdmin.DeleteHostedWikiError ())
    | HostAdminDataExportResponse (Result Evergreen.V27.HostAdmin.DataExportError String)
    | HostAdminDataImportResponse (Result Evergreen.V27.HostAdmin.DataImportError ())
    | HostAdminWikiDataExportResponse Evergreen.V27.Wiki.Slug (Result Evergreen.V27.HostAdmin.WikiDataExportError String)
    | HostAdminWikiDataImportResponse Evergreen.V27.Wiki.Slug (Result Evergreen.V27.HostAdmin.WikiDataImportError ())
    | HostAdminWikiDataImportAutoResponse (Result Evergreen.V27.HostAdmin.WikiDataImportError Evergreen.V27.Wiki.Slug)

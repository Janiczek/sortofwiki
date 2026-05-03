module Evergreen.V28.Types exposing (..)

import Dict
import Effect.Browser
import Effect.Browser.Navigation
import Effect.File
import Effect.Lamdera
import Evergreen.V28.CacheVersion
import Evergreen.V28.ColorTheme
import Evergreen.V28.ContributorAccount
import Evergreen.V28.ContributorWikiSession
import Evergreen.V28.HostAdmin
import Evergreen.V28.Page
import Evergreen.V28.PendingReviewCount
import Evergreen.V28.Route
import Evergreen.V28.Store
import Evergreen.V28.Submission
import Evergreen.V28.SubmissionReviewDetail
import Evergreen.V28.Wiki
import Evergreen.V28.WikiAdminUsers
import Evergreen.V28.WikiAuditLog
import Evergreen.V28.WikiContributors
import Evergreen.V28.WikiFrontendSubscription
import Evergreen.V28.WikiMarkdownEditorPane
import Evergreen.V28.WikiRole
import Evergreen.V28.WikiSearch
import Evergreen.V28.WikiStats
import Evergreen.V28.WikiTodos
import Evergreen.V28.WikiUser
import RemoteData
import Set
import Time
import Url


type alias RegisterDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V28.ContributorAccount.RegisterContributorError ())
    }


type alias LoginDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V28.ContributorAccount.LoginContributorError ())
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
    , lastResult : Maybe (Result Evergreen.V28.Submission.SubmitNewPageError Evergreen.V28.Submission.NewPageSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V28.Submission.SaveNewPageDraftError Evergreen.V28.Submission.Id)
    }


type alias PageEditSubmitDraft =
    { markdownBody : String
    , tagsInput : String
    , publishedRowCollapsed : Bool
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V28.Submission.SubmitPageEditError Evergreen.V28.Submission.EditSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V28.Submission.SavePageEditDraftError Evergreen.V28.Submission.Id)
    }


type alias PageDeleteSubmitDraft =
    { reasonText : String
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V28.Submission.PageDeleteFormError Evergreen.V28.Submission.PageDeleteFormSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V28.Submission.SavePageDeleteDraftError Evergreen.V28.Submission.Id)
    }


type alias ReviewApproveDraft =
    { inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V28.Submission.ApproveSubmissionError ())
    }


type ReviewDecision
    = ReviewDecisionApprove
    | ReviewDecisionRequestChanges
    | ReviewDecisionReject


type alias ReviewRejectDraft =
    { reasonText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V28.Submission.RejectSubmissionError ())
    }


type alias ReviewRequestChangesDraft =
    { guidanceText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V28.Submission.RequestChangesSubmissionError ())
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
    , lastResult : Maybe (Result Evergreen.V28.HostAdmin.LoginError ())
    }


type alias HostAdminCreateWikiDraft =
    { slug : String
    , name : String
    , initialAdminUsername : String
    , initialAdminPassword : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V28.HostAdmin.CreateHostedWikiError Evergreen.V28.Wiki.CatalogEntry)
    }


type alias HostAdminWikiDetailDraft =
    { wikiSlug : Evergreen.V28.Wiki.Slug
    , load : RemoteData.RemoteData () (Result Evergreen.V28.HostAdmin.HostWikiDetailError Evergreen.V28.Wiki.CatalogEntry)
    , slugDraft : String
    , nameDraft : String
    , summaryDraft : String
    , saveInFlight : Bool
    , lastSaveResult : Maybe (Result Evergreen.V28.HostAdmin.UpdateHostedWikiMetadataError ())
    , lifecycleInFlight : Bool
    , lastLifecycleResult : Maybe (Result Evergreen.V28.HostAdmin.WikiLifecycleError ())
    , deleteConfirmDraft : String
    , deleteInFlight : Bool
    , lastDeleteResult : Maybe (Result Evergreen.V28.HostAdmin.DeleteHostedWikiError ())
    }


type alias FrontendModel =
    { key : Effect.Browser.Navigation.Key
    , colorThemePreference : Evergreen.V28.ColorTheme.ColorThemePreference
    , systemColorTheme : Evergreen.V28.ColorTheme.ColorTheme
    , currentUrl : Url.Url
    , route : Evergreen.V28.Route.Route
    , navigationFragment : Maybe String
    , store : Evergreen.V28.Store.Store
    , contributorWikiSessions : Dict.Dict Evergreen.V28.Wiki.Slug Evergreen.V28.ContributorWikiSession.ContributorWikiSession
    , registerDraft : RegisterDraft
    , loginDraft : LoginDraft
    , headerSearchQuery : String
    , headerSearchResults : List Evergreen.V28.WikiSearch.ResultItem
    , headerSearchPending : Maybe ( Evergreen.V28.Wiki.Slug, String )
    , wikiSearchPageQuery : String
    , wikiSearchPageResults : List Evergreen.V28.WikiSearch.ResultItem
    , wikiSearchPagePending : Maybe ( Evergreen.V28.Wiki.Slug, String )
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
    , wikiAdminAuditFilterSelectedKindTags : List Evergreen.V28.WikiAuditLog.AuditEventKindFilterTag
    , wikiAdminAuditAppliedFilter : Evergreen.V28.WikiAuditLog.AuditLogFilter
    , hostAdminAuditFilterWikiDraft : String
    , hostAdminAuditFilterActorDraft : String
    , hostAdminAuditFilterPageDraft : String
    , hostAdminAuditFilterSelectedKindTags : List Evergreen.V28.WikiAuditLog.AuditEventKindFilterTag
    , hostAdminAuditAppliedFilter : Evergreen.V28.WikiAuditLog.HostAuditLogFilter
    , hostAdminAuditLog : RemoteData.RemoteData () (Result Evergreen.V28.HostAdmin.ProtectedError (List Evergreen.V28.WikiAuditLog.ScopedAuditEventSummary))
    , auditTrustedPublishDiffByKey : Dict.Dict Evergreen.V28.WikiAuditLog.AuditDiffCacheKey (RemoteData.RemoteData () (Result Evergreen.V28.WikiAuditLog.EventDiffError Evergreen.V28.WikiAuditLog.TrustedPublishAuditDiff))
    , hostAdminLoginDraft : HostAdminLoginDraft
    , hostAdminCreateWikiDraft : HostAdminCreateWikiDraft
    , hostAdminWikiDetailDraft : HostAdminWikiDetailDraft
    , hostAdminWikis : RemoteData.RemoteData () (Result Evergreen.V28.HostAdmin.ProtectedError (List Evergreen.V28.Wiki.CatalogEntry))
    , hostAdminSessionAuthenticated : Bool
    , hostAdminExportInFlight : Bool
    , hostAdminImportInFlight : Bool
    , hostAdminBackupNotice : Maybe String
    , hostAdminWikiExportInFlightSlug : Maybe Evergreen.V28.Wiki.Slug
    , hostAdminWikiImportInFlightSlug : Maybe Evergreen.V28.Wiki.Slug
    , hostAdminWikiImportPendingSlug : Maybe Evergreen.V28.Wiki.Slug
    , hostAdminWikisNotice : Maybe String
    , sideNavOpen : Bool
    , wikiPageMobileRightRailCollapsed : Bool
    , wikiMarkdownEditorPane : Evergreen.V28.WikiMarkdownEditorPane.WikiMarkdownEditorPane
    , wikiStatsDailyActivityHover :
        Maybe
            { metric : String
            , day : String
            , count : Int
            }
    }


type alias WikiStatsPartitions =
    { fromWiki : Evergreen.V28.WikiStats.FromWiki
    , fromAudit : Evergreen.V28.WikiStats.FromAudit
    , fromViews : Evergreen.V28.WikiStats.FromViews
    }


type alias BackendModel =
    { wikis : Dict.Dict Evergreen.V28.Wiki.Slug Evergreen.V28.Wiki.Wiki
    , contributors : Evergreen.V28.WikiContributors.Registry
    , contributorSessions : Evergreen.V28.WikiUser.SessionTable
    , hostSessions : Set.Set String
    , submissions : Dict.Dict String Evergreen.V28.Submission.Submission
    , nextSubmissionCounter : Int
    , wikiAuditEvents : Dict.Dict Evergreen.V28.Wiki.Slug (List Evergreen.V28.WikiAuditLog.AuditEvent)
    , wikiAuditVersions : Dict.Dict Evergreen.V28.Wiki.Slug Int
    , pendingReviewCounts : Dict.Dict Evergreen.V28.Wiki.Slug Int
    , pendingReviewClients : Evergreen.V28.PendingReviewCount.PendingReviewClientSets
    , wikiFrontendClients : Evergreen.V28.WikiFrontendSubscription.WikiFrontendClientSets
    , wikiSearchIndexes : Dict.Dict Evergreen.V28.Wiki.Slug Evergreen.V28.WikiSearch.PrefixIndex
    , wikiTodosCaches : Dict.Dict Evergreen.V28.Wiki.Slug (List Evergreen.V28.WikiTodos.TableRow)
    , pageViewCounts : Dict.Dict Evergreen.V28.Wiki.Slug (Dict.Dict Evergreen.V28.Page.Slug Int)
    , wikiViewsVersions : Dict.Dict Evergreen.V28.Wiki.Slug Int
    , wikiStatsCache : Dict.Dict Evergreen.V28.Wiki.Slug WikiStatsPartitions
    }


type FrontendMsg
    = UrlClicked Effect.Browser.UrlRequest
    | UrlChanged Url.Url
    | UrlFragmentScrollDone
    | ColorThemeToggled
    | ColorThemeFromJs (Maybe Evergreen.V28.ColorTheme.Incoming)
    | RegisterFormUsernameChanged String
    | RegisterFormPasswordChanged String
    | RegisterFormSubmitted
    | LoginFormUsernameChanged String
    | LoginFormPasswordChanged String
    | LoginFormSubmitted
    | HeaderSearchQueryChanged String
    | HeaderSearchTimeoutReached Evergreen.V28.Wiki.Slug String
    | HeaderSearchSubmitted
    | WikiSearchPageQueryChanged String
    | WikiSearchPageTimeoutReached Evergreen.V28.Wiki.Slug String
    | ContributorLogoutWiki Evergreen.V28.Wiki.Slug
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
    | WikiAdminAuditFilterTypeTagToggled Evergreen.V28.WikiAuditLog.AuditEventKindFilterTag Bool
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
    | HostAdminAuditFilterTypeTagToggled Evergreen.V28.WikiAuditLog.AuditEventKindFilterTag Bool
    | HostAdminDataExportClicked
    | HostAdminDataImportPickRequested
    | HostAdminDataImportFileSelected Effect.File.File
    | HostAdminDataImportFileRead (Result () String)
    | HostAdminWikisDataImportPickRequested
    | HostAdminWikisDataImportFileSelected Effect.File.File
    | HostAdminWikisDataImportFileRead (Result () String)
    | HostAdminWikiDataExportClicked Evergreen.V28.Wiki.Slug
    | HostAdminWikiDataImportPickRequested Evergreen.V28.Wiki.Slug
    | HostAdminWikiDataImportFileSelected Effect.File.File
    | HostAdminWikiDataImportFileRead Evergreen.V28.Wiki.Slug (Result () String)
    | SideNavOpened
    | SideNavClosed
    | WikiMarkdownEditorPaneSelected Evergreen.V28.WikiMarkdownEditorPane.WikiMarkdownEditorPane
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
    | RequestWikiStats Evergreen.V28.Wiki.Slug (Maybe Evergreen.V28.CacheVersion.Versions)
    | RequestWikiFrontendDetails Evergreen.V28.Wiki.Slug
    | RequestWikiTodos Evergreen.V28.Wiki.Slug (Maybe Int)
    | RequestPageFrontendDetails Evergreen.V28.Wiki.Slug Evergreen.V28.Page.Slug
    | RequestWikiSearch Evergreen.V28.Wiki.Slug String
    | RequestMyPendingSubmissions Evergreen.V28.Wiki.Slug
    | RequestReviewQueue Evergreen.V28.Wiki.Slug
    | RequestReviewSubmissionDetail Evergreen.V28.Wiki.Slug String
    | RequestWikiUsers Evergreen.V28.Wiki.Slug
    | RequestWikiAuditLog Evergreen.V28.Wiki.Slug Evergreen.V28.WikiAuditLog.AuditLogFilter (Maybe Int)
    | RequestWikiAuditEventDiff Evergreen.V28.Wiki.Slug Evergreen.V28.WikiAuditLog.AuditLogFilter Int
    | PromoteContributorToTrusted Evergreen.V28.Wiki.Slug String
    | DemoteTrustedToContributor Evergreen.V28.Wiki.Slug String
    | GrantWikiAdmin Evergreen.V28.Wiki.Slug String
    | RevokeWikiAdmin Evergreen.V28.Wiki.Slug String
    | RequestSubmissionDetails Evergreen.V28.Wiki.Slug String
    | RegisterContributor Evergreen.V28.Wiki.Slug RegisterContributorPayload
    | LoginContributor Evergreen.V28.Wiki.Slug LoginContributorPayload
    | LogoutContributor Evergreen.V28.Wiki.Slug
    | SubmitNewPage Evergreen.V28.Wiki.Slug SubmitNewPagePayload
    | SubmitPageEdit Evergreen.V28.Wiki.Slug Evergreen.V28.Page.Slug String String
    | RequestPublishedPageDeletion Evergreen.V28.Wiki.Slug Evergreen.V28.Page.Slug String
    | DeletePublishedPageImmediately Evergreen.V28.Wiki.Slug Evergreen.V28.Page.Slug String
    | SaveNewPageDraft
        Evergreen.V28.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , rawPageSlug : String
        , rawMarkdown : String
        , rawTags : String
        }
    | SavePageEditDraft
        Evergreen.V28.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V28.Page.Slug
        , rawMarkdown : String
        , rawTags : String
        }
    | SavePageDeleteDraft
        Evergreen.V28.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V28.Page.Slug
        , rawReason : String
        }
    | SubmitDraftForReview Evergreen.V28.Wiki.Slug String
    | WithdrawSubmission Evergreen.V28.Wiki.Slug String
    | DeleteMySubmission Evergreen.V28.Wiki.Slug String
    | ApproveSubmission Evergreen.V28.Wiki.Slug String
    | RejectSubmission Evergreen.V28.Wiki.Slug RejectSubmissionPayload
    | RequestSubmissionChanges Evergreen.V28.Wiki.Slug RequestSubmissionChangesPayload
    | HostAdminLogin String
    | RequestHostWikiList
    | RequestHostAuditLog Evergreen.V28.WikiAuditLog.HostAuditLogFilter
    | RequestHostAuditEventDiff Evergreen.V28.WikiAuditLog.HostAuditLogFilter Int
    | RequestHostWikiDetail Evergreen.V28.Wiki.Slug
    | CreateHostedWiki CreateHostedWikiPayload
    | UpdateHostedWikiMetadata Evergreen.V28.Wiki.Slug UpdateHostedWikiMetadataPayload
    | DeactivateHostedWiki Evergreen.V28.Wiki.Slug
    | ReactivateHostedWiki Evergreen.V28.Wiki.Slug
    | DeleteHostedWiki Evergreen.V28.Wiki.Slug String
    | RequestHostAdminDataExport
    | ImportHostAdminDataSnapshot String
    | RequestHostAdminWikiDataExport Evergreen.V28.Wiki.Slug
    | ImportHostAdminWikiDataSnapshot Evergreen.V28.Wiki.Slug String
    | ImportHostAdminWikiDataSnapshotAuto String


type BackendMsg
    = ToBackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Time.Posix


type ToFrontend
    = WikiCatalogResponse (Dict.Dict Evergreen.V28.Wiki.Slug Evergreen.V28.Wiki.CatalogEntry)
    | WikiStatsResponse Evergreen.V28.Wiki.Slug Evergreen.V28.CacheVersion.Versions (Maybe Evergreen.V28.WikiStats.Summary)
    | WikiStatsUnchanged
    | WikiCacheInvalidated Evergreen.V28.Wiki.Slug Evergreen.V28.CacheVersion.Versions
    | WikiSlugRenamed Evergreen.V28.Wiki.Slug Evergreen.V28.Wiki.Slug
    | PendingReviewCountUpdated Evergreen.V28.Wiki.Slug Int
    | WikiFrontendDetailsResponse Evergreen.V28.Wiki.Slug (Maybe Evergreen.V28.Wiki.FrontendDetails)
    | WikiTodosResponse Evergreen.V28.Wiki.Slug Int (Result () (List Evergreen.V28.WikiTodos.TableRow))
    | WikiTodosUnchanged
    | PageFrontendDetailsResponse Evergreen.V28.Wiki.Slug Evergreen.V28.Page.Slug (Maybe Evergreen.V28.Page.FrontendDetails)
    | WikiSearchResponse Evergreen.V28.Wiki.Slug String (List Evergreen.V28.WikiSearch.ResultItem)
    | MyPendingSubmissionsResponse Evergreen.V28.Wiki.Slug (Result Evergreen.V28.Submission.MyPendingSubmissionsError (List Evergreen.V28.Submission.MyPendingSubmissionListItem))
    | ReviewQueueResponse Evergreen.V28.Wiki.Slug (Result Evergreen.V28.Submission.ReviewQueueError (List Evergreen.V28.Submission.ReviewQueueItem))
    | ReviewSubmissionDetailResponse Evergreen.V28.Wiki.Slug String (Result Evergreen.V28.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V28.SubmissionReviewDetail.SubmissionReviewDetail)
    | WikiUsersResponse Evergreen.V28.Wiki.Slug (Result Evergreen.V28.WikiAdminUsers.Error (List Evergreen.V28.WikiAdminUsers.ListedUser))
    | WikiAuditLogResponse Evergreen.V28.Wiki.Slug Evergreen.V28.WikiAuditLog.AuditLogFilter Int (Result Evergreen.V28.WikiAuditLog.Error (List Evergreen.V28.WikiAuditLog.AuditEventSummary))
    | WikiAuditEventDiffResponse Evergreen.V28.Wiki.Slug Evergreen.V28.WikiAuditLog.AuditLogFilter Int (Result Evergreen.V28.WikiAuditLog.EventDiffError Evergreen.V28.WikiAuditLog.TrustedPublishAuditDiff)
    | WikiAuditLogUnchanged Evergreen.V28.Wiki.Slug
    | PromoteContributorToTrustedResponse Evergreen.V28.Wiki.Slug (Result Evergreen.V28.WikiAdminUsers.PromoteContributorError ())
    | DemoteTrustedToContributorResponse Evergreen.V28.Wiki.Slug (Result Evergreen.V28.WikiAdminUsers.DemoteTrustedError ())
    | GrantWikiAdminResponse Evergreen.V28.Wiki.Slug (Result Evergreen.V28.WikiAdminUsers.GrantTrustedToAdminError ())
    | RevokeWikiAdminResponse Evergreen.V28.Wiki.Slug (Result Evergreen.V28.WikiAdminUsers.RevokeAdminError ())
    | SubmissionDetailsResponse Evergreen.V28.Wiki.Slug String (Result Evergreen.V28.Submission.DetailsError Evergreen.V28.Submission.ContributorView)
    | RegisterContributorResponse Evergreen.V28.Wiki.Slug (Result Evergreen.V28.ContributorAccount.RegisterContributorError Evergreen.V28.WikiRole.WikiRole)
    | LoginContributorResponse Evergreen.V28.Wiki.Slug (Result Evergreen.V28.ContributorAccount.LoginContributorError Evergreen.V28.WikiRole.WikiRole)
    | LogoutContributorResponse Evergreen.V28.Wiki.Slug
    | SubmitNewPageResponse Evergreen.V28.Wiki.Slug (Result Evergreen.V28.Submission.SubmitNewPageError Evergreen.V28.Submission.NewPageSubmitSuccess)
    | SubmitPageEditResponse Evergreen.V28.Wiki.Slug (Result Evergreen.V28.Submission.SubmitPageEditError Evergreen.V28.Submission.EditSubmitSuccess)
    | RequestPublishedPageDeletionResponse Evergreen.V28.Wiki.Slug (Result Evergreen.V28.Submission.RequestPublishedPageDeletionError Evergreen.V28.Submission.Id)
    | DeletePublishedPageImmediatelyResponse Evergreen.V28.Wiki.Slug (Result Evergreen.V28.Submission.DeletePublishedPageImmediatelyError ())
    | SaveNewPageDraftResponse Evergreen.V28.Wiki.Slug (Result Evergreen.V28.Submission.SaveNewPageDraftError Evergreen.V28.Submission.Id)
    | SavePageEditDraftResponse Evergreen.V28.Wiki.Slug (Result Evergreen.V28.Submission.SavePageEditDraftError Evergreen.V28.Submission.Id)
    | SavePageDeleteDraftResponse Evergreen.V28.Wiki.Slug (Result Evergreen.V28.Submission.SavePageDeleteDraftError Evergreen.V28.Submission.Id)
    | SubmitDraftForReviewResponse Evergreen.V28.Wiki.Slug String (Result Evergreen.V28.Submission.SubmitDraftForReviewError ())
    | WithdrawSubmissionResponse Evergreen.V28.Wiki.Slug String (Result Evergreen.V28.Submission.WithdrawSubmissionError ())
    | DeleteMySubmissionResponse Evergreen.V28.Wiki.Slug String (Result Evergreen.V28.Submission.DeleteMySubmissionError ())
    | ApproveSubmissionResponse Evergreen.V28.Wiki.Slug String (Result Evergreen.V28.Submission.ApproveSubmissionError ())
    | RejectSubmissionResponse Evergreen.V28.Wiki.Slug String (Result Evergreen.V28.Submission.RejectSubmissionError ())
    | RequestSubmissionChangesResponse Evergreen.V28.Wiki.Slug String (Result Evergreen.V28.Submission.RequestChangesSubmissionError ())
    | HostAdminLoginResponse (Result Evergreen.V28.HostAdmin.LoginError ())
    | HostAdminWikiListResponse (Result Evergreen.V28.HostAdmin.ProtectedError (List Evergreen.V28.Wiki.CatalogEntry))
    | HostAuditLogResponse Evergreen.V28.WikiAuditLog.HostAuditLogFilter (Result Evergreen.V28.HostAdmin.ProtectedError (List Evergreen.V28.WikiAuditLog.ScopedAuditEventSummary))
    | HostAuditEventDiffResponse Evergreen.V28.WikiAuditLog.HostAuditLogFilter Int (Result Evergreen.V28.HostAdmin.ProtectedError (Result Evergreen.V28.WikiAuditLog.EventDiffError Evergreen.V28.WikiAuditLog.TrustedPublishAuditDiff))
    | CreateHostedWikiResponse (Result Evergreen.V28.HostAdmin.CreateHostedWikiError Evergreen.V28.Wiki.CatalogEntry)
    | HostWikiDetailResponse Evergreen.V28.Wiki.Slug (Result Evergreen.V28.HostAdmin.HostWikiDetailError Evergreen.V28.Wiki.CatalogEntry)
    | UpdateHostedWikiMetadataResponse Evergreen.V28.Wiki.Slug (Result Evergreen.V28.HostAdmin.UpdateHostedWikiMetadataError Evergreen.V28.Wiki.CatalogEntry)
    | DeactivateHostedWikiResponse Evergreen.V28.Wiki.Slug (Result Evergreen.V28.HostAdmin.WikiLifecycleError Evergreen.V28.Wiki.CatalogEntry)
    | ReactivateHostedWikiResponse Evergreen.V28.Wiki.Slug (Result Evergreen.V28.HostAdmin.WikiLifecycleError Evergreen.V28.Wiki.CatalogEntry)
    | DeleteHostedWikiResponse Evergreen.V28.Wiki.Slug (Result Evergreen.V28.HostAdmin.DeleteHostedWikiError ())
    | HostAdminDataExportResponse (Result Evergreen.V28.HostAdmin.DataExportError String)
    | HostAdminDataImportResponse (Result Evergreen.V28.HostAdmin.DataImportError ())
    | HostAdminWikiDataExportResponse Evergreen.V28.Wiki.Slug (Result Evergreen.V28.HostAdmin.WikiDataExportError String)
    | HostAdminWikiDataImportResponse Evergreen.V28.Wiki.Slug (Result Evergreen.V28.HostAdmin.WikiDataImportError ())
    | HostAdminWikiDataImportAutoResponse (Result Evergreen.V28.HostAdmin.WikiDataImportError Evergreen.V28.Wiki.Slug)

module Evergreen.V29.Types exposing (..)

import Dict
import Effect.Browser
import Effect.Browser.Navigation
import Effect.File
import Effect.Lamdera
import Evergreen.V29.CacheVersion
import Evergreen.V29.ColorTheme
import Evergreen.V29.ContributorAccount
import Evergreen.V29.ContributorWikiSession
import Evergreen.V29.HostAdmin
import Evergreen.V29.Page
import Evergreen.V29.PendingReviewCount
import Evergreen.V29.Route
import Evergreen.V29.Store
import Evergreen.V29.Submission
import Evergreen.V29.SubmissionReviewDetail
import Evergreen.V29.Wiki
import Evergreen.V29.WikiAdminUsers
import Evergreen.V29.WikiAuditLog
import Evergreen.V29.WikiContributors
import Evergreen.V29.WikiFrontendSubscription
import Evergreen.V29.WikiMarkdownEditorPane
import Evergreen.V29.WikiRole
import Evergreen.V29.WikiSearch
import Evergreen.V29.WikiStats
import Evergreen.V29.WikiTodos
import Evergreen.V29.WikiUser
import RemoteData
import Set
import Time
import Url


type alias RegisterDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V29.ContributorAccount.RegisterContributorError ())
    }


type alias LoginDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V29.ContributorAccount.LoginContributorError ())
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
    , lastResult : Maybe (Result Evergreen.V29.Submission.SubmitNewPageError Evergreen.V29.Submission.NewPageSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V29.Submission.SaveNewPageDraftError Evergreen.V29.Submission.Id)
    }


type alias PageEditSubmitDraft =
    { markdownBody : String
    , tagsInput : String
    , publishedRowCollapsed : Bool
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V29.Submission.SubmitPageEditError Evergreen.V29.Submission.EditSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V29.Submission.SavePageEditDraftError Evergreen.V29.Submission.Id)
    }


type alias PageDeleteSubmitDraft =
    { reasonText : String
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V29.Submission.PageDeleteFormError Evergreen.V29.Submission.PageDeleteFormSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V29.Submission.SavePageDeleteDraftError Evergreen.V29.Submission.Id)
    }


type alias ReviewApproveDraft =
    { inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V29.Submission.ApproveSubmissionError ())
    }


type ReviewDecision
    = ReviewDecisionApprove
    | ReviewDecisionRequestChanges
    | ReviewDecisionReject


type alias ReviewRejectDraft =
    { reasonText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V29.Submission.RejectSubmissionError ())
    }


type alias ReviewRequestChangesDraft =
    { guidanceText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V29.Submission.RequestChangesSubmissionError ())
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
    , lastResult : Maybe (Result Evergreen.V29.HostAdmin.LoginError ())
    }


type alias HostAdminCreateWikiDraft =
    { slug : String
    , name : String
    , initialAdminUsername : String
    , initialAdminPassword : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V29.HostAdmin.CreateHostedWikiError Evergreen.V29.Wiki.CatalogEntry)
    }


type alias HostAdminWikiDetailDraft =
    { wikiSlug : Evergreen.V29.Wiki.Slug
    , load : RemoteData.RemoteData () (Result Evergreen.V29.HostAdmin.HostWikiDetailError Evergreen.V29.Wiki.CatalogEntry)
    , slugDraft : String
    , nameDraft : String
    , summaryDraft : String
    , saveInFlight : Bool
    , lastSaveResult : Maybe (Result Evergreen.V29.HostAdmin.UpdateHostedWikiMetadataError ())
    , lifecycleInFlight : Bool
    , lastLifecycleResult : Maybe (Result Evergreen.V29.HostAdmin.WikiLifecycleError ())
    , deleteConfirmDraft : String
    , deleteInFlight : Bool
    , lastDeleteResult : Maybe (Result Evergreen.V29.HostAdmin.DeleteHostedWikiError ())
    }


type alias FrontendModel =
    { key : Effect.Browser.Navigation.Key
    , colorThemePreference : Evergreen.V29.ColorTheme.ColorThemePreference
    , systemColorTheme : Evergreen.V29.ColorTheme.ColorTheme
    , currentUrl : Url.Url
    , route : Evergreen.V29.Route.Route
    , navigationFragment : Maybe String
    , store : Evergreen.V29.Store.Store
    , contributorWikiSessions : Dict.Dict Evergreen.V29.Wiki.Slug Evergreen.V29.ContributorWikiSession.ContributorWikiSession
    , registerDraft : RegisterDraft
    , loginDraft : LoginDraft
    , headerSearchQuery : String
    , headerSearchResults : List Evergreen.V29.WikiSearch.ResultItem
    , headerSearchPending : Maybe ( Evergreen.V29.Wiki.Slug, String )
    , wikiSearchPageQuery : String
    , wikiSearchPageResults : List Evergreen.V29.WikiSearch.ResultItem
    , wikiSearchPagePending : Maybe ( Evergreen.V29.Wiki.Slug, String )
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
    , wikiAdminAuditFilterSelectedKindTags : List Evergreen.V29.WikiAuditLog.AuditEventKindFilterTag
    , wikiAdminAuditAppliedFilter : Evergreen.V29.WikiAuditLog.AuditLogFilter
    , hostAdminAuditFilterWikiDraft : String
    , hostAdminAuditFilterActorDraft : String
    , hostAdminAuditFilterPageDraft : String
    , hostAdminAuditFilterSelectedKindTags : List Evergreen.V29.WikiAuditLog.AuditEventKindFilterTag
    , hostAdminAuditAppliedFilter : Evergreen.V29.WikiAuditLog.HostAuditLogFilter
    , hostAdminAuditLog : RemoteData.RemoteData () (Result Evergreen.V29.HostAdmin.ProtectedError (List Evergreen.V29.WikiAuditLog.ScopedAuditEventSummary))
    , auditTrustedPublishDiffByKey : Dict.Dict Evergreen.V29.WikiAuditLog.AuditDiffCacheKey (RemoteData.RemoteData () (Result Evergreen.V29.WikiAuditLog.EventDiffError Evergreen.V29.WikiAuditLog.TrustedPublishAuditDiff))
    , hostAdminLoginDraft : HostAdminLoginDraft
    , hostAdminCreateWikiDraft : HostAdminCreateWikiDraft
    , hostAdminWikiDetailDraft : HostAdminWikiDetailDraft
    , hostAdminWikis : RemoteData.RemoteData () (Result Evergreen.V29.HostAdmin.ProtectedError (List Evergreen.V29.Wiki.CatalogEntry))
    , hostAdminSessionAuthenticated : Bool
    , hostAdminExportInFlight : Bool
    , hostAdminImportInFlight : Bool
    , hostAdminBackupNotice : Maybe String
    , hostAdminWikiExportInFlightSlug : Maybe Evergreen.V29.Wiki.Slug
    , hostAdminWikiImportInFlightSlug : Maybe Evergreen.V29.Wiki.Slug
    , hostAdminWikiImportPendingSlug : Maybe Evergreen.V29.Wiki.Slug
    , hostAdminWikisNotice : Maybe String
    , sideNavOpen : Bool
    , wikiPageMobileRightRailCollapsed : Bool
    , wikiMarkdownEditorPane : Evergreen.V29.WikiMarkdownEditorPane.WikiMarkdownEditorPane
    , wikiStatsDailyActivityHover :
        Maybe
            { metric : String
            , day : String
            , count : Int
            }
    }


type alias WikiStatsPartitions =
    { fromWiki : Evergreen.V29.WikiStats.FromWiki
    , fromAudit : Evergreen.V29.WikiStats.FromAudit
    , fromViews : Evergreen.V29.WikiStats.FromViews
    }


type alias BackendModel =
    { wikis : Dict.Dict Evergreen.V29.Wiki.Slug Evergreen.V29.Wiki.Wiki
    , contributors : Evergreen.V29.WikiContributors.Registry
    , contributorSessions : Evergreen.V29.WikiUser.SessionTable
    , hostSessions : Set.Set String
    , submissions : Dict.Dict String Evergreen.V29.Submission.Submission
    , nextSubmissionCounter : Int
    , wikiAuditEvents : Dict.Dict Evergreen.V29.Wiki.Slug (List Evergreen.V29.WikiAuditLog.AuditEvent)
    , wikiAuditVersions : Dict.Dict Evergreen.V29.Wiki.Slug Int
    , pendingReviewCounts : Dict.Dict Evergreen.V29.Wiki.Slug Int
    , pendingReviewClients : Evergreen.V29.PendingReviewCount.PendingReviewClientSets
    , wikiFrontendClients : Evergreen.V29.WikiFrontendSubscription.WikiFrontendClientSets
    , wikiSearchIndexes : Dict.Dict Evergreen.V29.Wiki.Slug Evergreen.V29.WikiSearch.PrefixIndex
    , wikiTodosCaches : Dict.Dict Evergreen.V29.Wiki.Slug (List Evergreen.V29.WikiTodos.TableRow)
    , pageViewCounts : Dict.Dict Evergreen.V29.Wiki.Slug (Dict.Dict Evergreen.V29.Page.Slug Int)
    , wikiViewsVersions : Dict.Dict Evergreen.V29.Wiki.Slug Int
    , wikiStatsCache : Dict.Dict Evergreen.V29.Wiki.Slug WikiStatsPartitions
    }


type FrontendMsg
    = UrlClicked Effect.Browser.UrlRequest
    | UrlChanged Url.Url
    | UrlFragmentScrollDone
    | ColorThemeToggled
    | ColorThemeFromJs (Maybe Evergreen.V29.ColorTheme.Incoming)
    | RegisterFormUsernameChanged String
    | RegisterFormPasswordChanged String
    | RegisterFormSubmitted
    | LoginFormUsernameChanged String
    | LoginFormPasswordChanged String
    | LoginFormSubmitted
    | HeaderSearchQueryChanged String
    | HeaderSearchTimeoutReached Evergreen.V29.Wiki.Slug String
    | HeaderSearchSubmitted
    | WikiSearchPageQueryChanged String
    | WikiSearchPageTimeoutReached Evergreen.V29.Wiki.Slug String
    | ContributorLogoutWiki Evergreen.V29.Wiki.Slug
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
    | WikiAdminAuditFilterTypeTagToggled Evergreen.V29.WikiAuditLog.AuditEventKindFilterTag Bool
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
    | HostAdminAuditFilterTypeTagToggled Evergreen.V29.WikiAuditLog.AuditEventKindFilterTag Bool
    | HostAdminDataExportClicked
    | HostAdminDataImportPickRequested
    | HostAdminDataImportFileSelected Effect.File.File
    | HostAdminDataImportFileRead (Result () String)
    | HostAdminWikisDataImportPickRequested
    | HostAdminWikisDataImportFileSelected Effect.File.File
    | HostAdminWikisDataImportFileRead (Result () String)
    | HostAdminWikiDataExportClicked Evergreen.V29.Wiki.Slug
    | HostAdminWikiDataImportPickRequested Evergreen.V29.Wiki.Slug
    | HostAdminWikiDataImportFileSelected Effect.File.File
    | HostAdminWikiDataImportFileRead Evergreen.V29.Wiki.Slug (Result () String)
    | SideNavOpened
    | SideNavClosed
    | WikiMarkdownEditorPaneSelected Evergreen.V29.WikiMarkdownEditorPane.WikiMarkdownEditorPane
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
    | RequestWikiStats Evergreen.V29.Wiki.Slug (Maybe Evergreen.V29.CacheVersion.Versions)
    | RequestWikiFrontendDetails Evergreen.V29.Wiki.Slug
    | RequestWikiTodos Evergreen.V29.Wiki.Slug (Maybe Int)
    | RequestPageFrontendDetails Evergreen.V29.Wiki.Slug Evergreen.V29.Page.Slug
    | RequestWikiSearch Evergreen.V29.Wiki.Slug String
    | RequestMyPendingSubmissions Evergreen.V29.Wiki.Slug
    | RequestReviewQueue Evergreen.V29.Wiki.Slug
    | RequestReviewSubmissionDetail Evergreen.V29.Wiki.Slug String
    | RequestWikiUsers Evergreen.V29.Wiki.Slug
    | RequestWikiAuditLog Evergreen.V29.Wiki.Slug Evergreen.V29.WikiAuditLog.AuditLogFilter (Maybe Int)
    | RequestWikiAuditEventDiff Evergreen.V29.Wiki.Slug Evergreen.V29.WikiAuditLog.AuditLogFilter Int
    | PromoteContributorToTrusted Evergreen.V29.Wiki.Slug String
    | DemoteTrustedToContributor Evergreen.V29.Wiki.Slug String
    | GrantWikiAdmin Evergreen.V29.Wiki.Slug String
    | RevokeWikiAdmin Evergreen.V29.Wiki.Slug String
    | RequestSubmissionDetails Evergreen.V29.Wiki.Slug String
    | RegisterContributor Evergreen.V29.Wiki.Slug RegisterContributorPayload
    | LoginContributor Evergreen.V29.Wiki.Slug LoginContributorPayload
    | LogoutContributor Evergreen.V29.Wiki.Slug
    | SubmitNewPage Evergreen.V29.Wiki.Slug SubmitNewPagePayload
    | SubmitPageEdit Evergreen.V29.Wiki.Slug Evergreen.V29.Page.Slug String String
    | RequestPublishedPageDeletion Evergreen.V29.Wiki.Slug Evergreen.V29.Page.Slug String
    | DeletePublishedPageImmediately Evergreen.V29.Wiki.Slug Evergreen.V29.Page.Slug String
    | SaveNewPageDraft
        Evergreen.V29.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , rawPageSlug : String
        , rawMarkdown : String
        , rawTags : String
        }
    | SavePageEditDraft
        Evergreen.V29.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V29.Page.Slug
        , rawMarkdown : String
        , rawTags : String
        }
    | SavePageDeleteDraft
        Evergreen.V29.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V29.Page.Slug
        , rawReason : String
        }
    | SubmitDraftForReview Evergreen.V29.Wiki.Slug String
    | WithdrawSubmission Evergreen.V29.Wiki.Slug String
    | DeleteMySubmission Evergreen.V29.Wiki.Slug String
    | ApproveSubmission Evergreen.V29.Wiki.Slug String
    | RejectSubmission Evergreen.V29.Wiki.Slug RejectSubmissionPayload
    | RequestSubmissionChanges Evergreen.V29.Wiki.Slug RequestSubmissionChangesPayload
    | HostAdminLogin String
    | RequestHostWikiList
    | RequestHostAuditLog Evergreen.V29.WikiAuditLog.HostAuditLogFilter
    | RequestHostAuditEventDiff Evergreen.V29.WikiAuditLog.HostAuditLogFilter Int
    | RequestHostWikiDetail Evergreen.V29.Wiki.Slug
    | CreateHostedWiki CreateHostedWikiPayload
    | UpdateHostedWikiMetadata Evergreen.V29.Wiki.Slug UpdateHostedWikiMetadataPayload
    | DeactivateHostedWiki Evergreen.V29.Wiki.Slug
    | ReactivateHostedWiki Evergreen.V29.Wiki.Slug
    | DeleteHostedWiki Evergreen.V29.Wiki.Slug String
    | RequestHostAdminDataExport
    | ImportHostAdminDataSnapshot String
    | RequestHostAdminWikiDataExport Evergreen.V29.Wiki.Slug
    | ImportHostAdminWikiDataSnapshot Evergreen.V29.Wiki.Slug String
    | ImportHostAdminWikiDataSnapshotAuto String


type BackendMsg
    = ToBackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Time.Posix


type ToFrontend
    = WikiCatalogResponse (Dict.Dict Evergreen.V29.Wiki.Slug Evergreen.V29.Wiki.CatalogEntry)
    | WikiStatsResponse Evergreen.V29.Wiki.Slug Evergreen.V29.CacheVersion.Versions (Maybe Evergreen.V29.WikiStats.Summary)
    | WikiStatsUnchanged
    | WikiCacheInvalidated Evergreen.V29.Wiki.Slug Evergreen.V29.CacheVersion.Versions
    | WikiSlugRenamed Evergreen.V29.Wiki.Slug Evergreen.V29.Wiki.Slug
    | PendingReviewCountUpdated Evergreen.V29.Wiki.Slug Int
    | WikiFrontendDetailsResponse Evergreen.V29.Wiki.Slug (Maybe Evergreen.V29.Wiki.FrontendDetails)
    | WikiTodosResponse Evergreen.V29.Wiki.Slug Int (Result () (List Evergreen.V29.WikiTodos.TableRow))
    | WikiTodosUnchanged
    | PageFrontendDetailsResponse Evergreen.V29.Wiki.Slug Evergreen.V29.Page.Slug (Maybe Evergreen.V29.Page.FrontendDetails)
    | WikiSearchResponse Evergreen.V29.Wiki.Slug String (List Evergreen.V29.WikiSearch.ResultItem)
    | MyPendingSubmissionsResponse Evergreen.V29.Wiki.Slug (Result Evergreen.V29.Submission.MyPendingSubmissionsError (List Evergreen.V29.Submission.MyPendingSubmissionListItem))
    | ReviewQueueResponse Evergreen.V29.Wiki.Slug (Result Evergreen.V29.Submission.ReviewQueueError (List Evergreen.V29.Submission.ReviewQueueItem))
    | ReviewSubmissionDetailResponse Evergreen.V29.Wiki.Slug String (Result Evergreen.V29.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V29.SubmissionReviewDetail.SubmissionReviewDetail)
    | WikiUsersResponse Evergreen.V29.Wiki.Slug (Result Evergreen.V29.WikiAdminUsers.Error (List Evergreen.V29.WikiAdminUsers.ListedUser))
    | WikiAuditLogResponse Evergreen.V29.Wiki.Slug Evergreen.V29.WikiAuditLog.AuditLogFilter Int (Result Evergreen.V29.WikiAuditLog.Error (List Evergreen.V29.WikiAuditLog.AuditEventSummary))
    | WikiAuditEventDiffResponse Evergreen.V29.Wiki.Slug Evergreen.V29.WikiAuditLog.AuditLogFilter Int (Result Evergreen.V29.WikiAuditLog.EventDiffError Evergreen.V29.WikiAuditLog.TrustedPublishAuditDiff)
    | WikiAuditLogUnchanged Evergreen.V29.Wiki.Slug
    | PromoteContributorToTrustedResponse Evergreen.V29.Wiki.Slug (Result Evergreen.V29.WikiAdminUsers.PromoteContributorError ())
    | DemoteTrustedToContributorResponse Evergreen.V29.Wiki.Slug (Result Evergreen.V29.WikiAdminUsers.DemoteTrustedError ())
    | GrantWikiAdminResponse Evergreen.V29.Wiki.Slug (Result Evergreen.V29.WikiAdminUsers.GrantTrustedToAdminError ())
    | RevokeWikiAdminResponse Evergreen.V29.Wiki.Slug (Result Evergreen.V29.WikiAdminUsers.RevokeAdminError ())
    | SubmissionDetailsResponse Evergreen.V29.Wiki.Slug String (Result Evergreen.V29.Submission.DetailsError Evergreen.V29.Submission.ContributorView)
    | RegisterContributorResponse Evergreen.V29.Wiki.Slug (Result Evergreen.V29.ContributorAccount.RegisterContributorError Evergreen.V29.WikiRole.WikiRole)
    | LoginContributorResponse Evergreen.V29.Wiki.Slug (Result Evergreen.V29.ContributorAccount.LoginContributorError Evergreen.V29.WikiRole.WikiRole)
    | LogoutContributorResponse Evergreen.V29.Wiki.Slug
    | SubmitNewPageResponse Evergreen.V29.Wiki.Slug (Result Evergreen.V29.Submission.SubmitNewPageError Evergreen.V29.Submission.NewPageSubmitSuccess)
    | SubmitPageEditResponse Evergreen.V29.Wiki.Slug (Result Evergreen.V29.Submission.SubmitPageEditError Evergreen.V29.Submission.EditSubmitSuccess)
    | RequestPublishedPageDeletionResponse Evergreen.V29.Wiki.Slug (Result Evergreen.V29.Submission.RequestPublishedPageDeletionError Evergreen.V29.Submission.Id)
    | DeletePublishedPageImmediatelyResponse Evergreen.V29.Wiki.Slug (Result Evergreen.V29.Submission.DeletePublishedPageImmediatelyError ())
    | SaveNewPageDraftResponse Evergreen.V29.Wiki.Slug (Result Evergreen.V29.Submission.SaveNewPageDraftError Evergreen.V29.Submission.Id)
    | SavePageEditDraftResponse Evergreen.V29.Wiki.Slug (Result Evergreen.V29.Submission.SavePageEditDraftError Evergreen.V29.Submission.Id)
    | SavePageDeleteDraftResponse Evergreen.V29.Wiki.Slug (Result Evergreen.V29.Submission.SavePageDeleteDraftError Evergreen.V29.Submission.Id)
    | SubmitDraftForReviewResponse Evergreen.V29.Wiki.Slug String (Result Evergreen.V29.Submission.SubmitDraftForReviewError ())
    | WithdrawSubmissionResponse Evergreen.V29.Wiki.Slug String (Result Evergreen.V29.Submission.WithdrawSubmissionError ())
    | DeleteMySubmissionResponse Evergreen.V29.Wiki.Slug String (Result Evergreen.V29.Submission.DeleteMySubmissionError ())
    | ApproveSubmissionResponse Evergreen.V29.Wiki.Slug String (Result Evergreen.V29.Submission.ApproveSubmissionError ())
    | RejectSubmissionResponse Evergreen.V29.Wiki.Slug String (Result Evergreen.V29.Submission.RejectSubmissionError ())
    | RequestSubmissionChangesResponse Evergreen.V29.Wiki.Slug String (Result Evergreen.V29.Submission.RequestChangesSubmissionError ())
    | HostAdminLoginResponse (Result Evergreen.V29.HostAdmin.LoginError ())
    | HostAdminWikiListResponse (Result Evergreen.V29.HostAdmin.ProtectedError (List Evergreen.V29.Wiki.CatalogEntry))
    | HostAuditLogResponse Evergreen.V29.WikiAuditLog.HostAuditLogFilter (Result Evergreen.V29.HostAdmin.ProtectedError (List Evergreen.V29.WikiAuditLog.ScopedAuditEventSummary))
    | HostAuditEventDiffResponse Evergreen.V29.WikiAuditLog.HostAuditLogFilter Int (Result Evergreen.V29.HostAdmin.ProtectedError (Result Evergreen.V29.WikiAuditLog.EventDiffError Evergreen.V29.WikiAuditLog.TrustedPublishAuditDiff))
    | CreateHostedWikiResponse (Result Evergreen.V29.HostAdmin.CreateHostedWikiError Evergreen.V29.Wiki.CatalogEntry)
    | HostWikiDetailResponse Evergreen.V29.Wiki.Slug (Result Evergreen.V29.HostAdmin.HostWikiDetailError Evergreen.V29.Wiki.CatalogEntry)
    | UpdateHostedWikiMetadataResponse Evergreen.V29.Wiki.Slug (Result Evergreen.V29.HostAdmin.UpdateHostedWikiMetadataError Evergreen.V29.Wiki.CatalogEntry)
    | DeactivateHostedWikiResponse Evergreen.V29.Wiki.Slug (Result Evergreen.V29.HostAdmin.WikiLifecycleError Evergreen.V29.Wiki.CatalogEntry)
    | ReactivateHostedWikiResponse Evergreen.V29.Wiki.Slug (Result Evergreen.V29.HostAdmin.WikiLifecycleError Evergreen.V29.Wiki.CatalogEntry)
    | DeleteHostedWikiResponse Evergreen.V29.Wiki.Slug (Result Evergreen.V29.HostAdmin.DeleteHostedWikiError ())
    | HostAdminDataExportResponse (Result Evergreen.V29.HostAdmin.DataExportError String)
    | HostAdminDataImportResponse (Result Evergreen.V29.HostAdmin.DataImportError ())
    | HostAdminWikiDataExportResponse Evergreen.V29.Wiki.Slug (Result Evergreen.V29.HostAdmin.WikiDataExportError String)
    | HostAdminWikiDataImportResponse Evergreen.V29.Wiki.Slug (Result Evergreen.V29.HostAdmin.WikiDataImportError ())
    | HostAdminWikiDataImportAutoResponse (Result Evergreen.V29.HostAdmin.WikiDataImportError Evergreen.V29.Wiki.Slug)

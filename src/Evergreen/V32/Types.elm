module Evergreen.V32.Types exposing (..)

import Dict
import Effect.Browser
import Effect.Browser.Navigation
import Effect.File
import Effect.Lamdera
import Evergreen.V32.CacheVersion
import Evergreen.V32.ColorTheme
import Evergreen.V32.ContributorAccount
import Evergreen.V32.ContributorWikiSession
import Evergreen.V32.HostAdmin
import Evergreen.V32.Page
import Evergreen.V32.PendingReviewCount
import Evergreen.V32.Route
import Evergreen.V32.Store
import Evergreen.V32.Submission
import Evergreen.V32.SubmissionReviewDetail
import Evergreen.V32.Wiki
import Evergreen.V32.WikiAdminUsers
import Evergreen.V32.WikiAuditLog
import Evergreen.V32.WikiContributors
import Evergreen.V32.WikiFrontendSubscription
import Evergreen.V32.WikiMarkdownEditorPane
import Evergreen.V32.WikiRole
import Evergreen.V32.WikiSearch
import Evergreen.V32.WikiStats
import Evergreen.V32.WikiTodos
import Evergreen.V32.WikiUser
import RemoteData
import Set
import Time
import Url


type alias RegisterDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V32.ContributorAccount.RegisterContributorError ())
    }


type alias LoginDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V32.ContributorAccount.LoginContributorError ())
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
    , lastResult : Maybe (Result Evergreen.V32.Submission.SubmitNewPageError Evergreen.V32.Submission.NewPageSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V32.Submission.SaveNewPageDraftError Evergreen.V32.Submission.Id)
    }


type alias PageEditSubmitDraft =
    { markdownBody : String
    , tagsInput : String
    , publishedRowCollapsed : Bool
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V32.Submission.SubmitPageEditError Evergreen.V32.Submission.EditSubmitSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V32.Submission.SavePageEditDraftError Evergreen.V32.Submission.Id)
    }


type alias PageDeleteSubmitDraft =
    { reasonText : String
    , maybeSavedDraftId : Maybe String
    , inFlight : Bool
    , saveDraftInFlight : Bool
    , pendingSubmitAfterSave : Bool
    , lastResult : Maybe (Result Evergreen.V32.Submission.PageDeleteFormError Evergreen.V32.Submission.PageDeleteFormSuccess)
    , lastSaveDraftResult : Maybe (Result Evergreen.V32.Submission.SavePageDeleteDraftError Evergreen.V32.Submission.Id)
    }


type alias ReviewApproveDraft =
    { inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V32.Submission.ApproveSubmissionError ())
    }


type ReviewDecision
    = ReviewDecisionApprove
    | ReviewDecisionRequestChanges
    | ReviewDecisionReject


type alias ReviewRejectDraft =
    { reasonText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V32.Submission.RejectSubmissionError ())
    }


type alias ReviewRequestChangesDraft =
    { guidanceText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V32.Submission.RequestChangesSubmissionError ())
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
    , lastResult : Maybe (Result Evergreen.V32.HostAdmin.LoginError ())
    }


type alias HostAdminCreateWikiDraft =
    { slug : String
    , name : String
    , initialAdminUsername : String
    , initialAdminPassword : String
    , inFlight : Bool
    , lastResult : Maybe (Result Evergreen.V32.HostAdmin.CreateHostedWikiError Evergreen.V32.Wiki.CatalogEntry)
    }


type alias HostAdminWikiDetailDraft =
    { wikiSlug : Evergreen.V32.Wiki.Slug
    , load : RemoteData.RemoteData () (Result Evergreen.V32.HostAdmin.HostWikiDetailError Evergreen.V32.Wiki.CatalogEntry)
    , slugDraft : String
    , nameDraft : String
    , summaryDraft : String
    , saveInFlight : Bool
    , lastSaveResult : Maybe (Result Evergreen.V32.HostAdmin.UpdateHostedWikiMetadataError ())
    , lifecycleInFlight : Bool
    , lastLifecycleResult : Maybe (Result Evergreen.V32.HostAdmin.WikiLifecycleError ())
    , deleteConfirmDraft : String
    , deleteInFlight : Bool
    , lastDeleteResult : Maybe (Result Evergreen.V32.HostAdmin.DeleteHostedWikiError ())
    }


type alias FrontendModel =
    { key : Effect.Browser.Navigation.Key
    , colorThemePreference : Evergreen.V32.ColorTheme.ColorThemePreference
    , systemColorTheme : Evergreen.V32.ColorTheme.ColorTheme
    , currentUrl : Url.Url
    , route : Evergreen.V32.Route.Route
    , navigationFragment : Maybe String
    , store : Evergreen.V32.Store.Store
    , contributorWikiSessions : Dict.Dict Evergreen.V32.Wiki.Slug Evergreen.V32.ContributorWikiSession.ContributorWikiSession
    , registerDraft : RegisterDraft
    , loginDraft : LoginDraft
    , headerSearchQuery : String
    , headerSearchResults : List Evergreen.V32.WikiSearch.ResultItem
    , headerSearchPending : Maybe ( Evergreen.V32.Wiki.Slug, String )
    , wikiSearchPageQuery : String
    , wikiSearchPageResults : List Evergreen.V32.WikiSearch.ResultItem
    , wikiSearchPagePending : Maybe ( Evergreen.V32.Wiki.Slug, String )
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
    , wikiAdminAuditFilterSelectedKindTags : List Evergreen.V32.WikiAuditLog.AuditEventKindFilterTag
    , wikiAdminAuditAppliedFilter : Evergreen.V32.WikiAuditLog.AuditLogFilter
    , hostAdminAuditFilterWikiDraft : String
    , hostAdminAuditFilterActorDraft : String
    , hostAdminAuditFilterPageDraft : String
    , hostAdminAuditFilterSelectedKindTags : List Evergreen.V32.WikiAuditLog.AuditEventKindFilterTag
    , hostAdminAuditAppliedFilter : Evergreen.V32.WikiAuditLog.HostAuditLogFilter
    , hostAdminAuditLog : RemoteData.RemoteData () (Result Evergreen.V32.HostAdmin.ProtectedError (List Evergreen.V32.WikiAuditLog.ScopedAuditEventSummary))
    , auditTrustedPublishDiffByKey : Dict.Dict Evergreen.V32.WikiAuditLog.AuditDiffCacheKey (RemoteData.RemoteData () (Result Evergreen.V32.WikiAuditLog.EventDiffError Evergreen.V32.WikiAuditLog.TrustedPublishAuditDiff))
    , hostAdminLoginDraft : HostAdminLoginDraft
    , hostAdminCreateWikiDraft : HostAdminCreateWikiDraft
    , hostAdminWikiDetailDraft : HostAdminWikiDetailDraft
    , hostAdminWikis : RemoteData.RemoteData () (Result Evergreen.V32.HostAdmin.ProtectedError (List Evergreen.V32.Wiki.CatalogEntry))
    , hostAdminSessionAuthenticated : Bool
    , hostAdminExportInFlight : Bool
    , hostAdminImportInFlight : Bool
    , hostAdminBackupNotice : Maybe String
    , hostAdminWikiExportInFlightSlug : Maybe Evergreen.V32.Wiki.Slug
    , hostAdminWikiImportInFlightSlug : Maybe Evergreen.V32.Wiki.Slug
    , hostAdminWikiImportPendingSlug : Maybe Evergreen.V32.Wiki.Slug
    , hostAdminWikisNotice : Maybe String
    , sideNavOpen : Bool
    , wikiPageMobileRightRailCollapsed : Bool
    , wikiMarkdownEditorPane : Evergreen.V32.WikiMarkdownEditorPane.WikiMarkdownEditorPane
    , wikiStatsDailyActivityHover :
        Maybe
            { metric : String
            , day : String
            , count : Int
            }
    }


type alias WikiStatsPartitions =
    { fromWiki : Evergreen.V32.WikiStats.FromWiki
    , fromAudit : Evergreen.V32.WikiStats.FromAudit
    , fromViews : Evergreen.V32.WikiStats.FromViews
    }


type alias BackendModel =
    { wikis : Dict.Dict Evergreen.V32.Wiki.Slug Evergreen.V32.Wiki.Wiki
    , contributors : Evergreen.V32.WikiContributors.Registry
    , contributorSessions : Evergreen.V32.WikiUser.SessionTable
    , hostSessions : Set.Set String
    , submissions : Dict.Dict String Evergreen.V32.Submission.Submission
    , nextSubmissionCounter : Int
    , wikiAuditEvents : Dict.Dict Evergreen.V32.Wiki.Slug (List Evergreen.V32.WikiAuditLog.AuditEvent)
    , wikiAuditVersions : Dict.Dict Evergreen.V32.Wiki.Slug Int
    , pendingReviewCounts : Dict.Dict Evergreen.V32.Wiki.Slug Int
    , pendingReviewClients : Evergreen.V32.PendingReviewCount.PendingReviewClientSets
    , wikiFrontendClients : Evergreen.V32.WikiFrontendSubscription.WikiFrontendClientSets
    , wikiSearchIndexes : Dict.Dict Evergreen.V32.Wiki.Slug Evergreen.V32.WikiSearch.PrefixIndex
    , wikiTodosCaches : Dict.Dict Evergreen.V32.Wiki.Slug (List Evergreen.V32.WikiTodos.TableRow)
    , pageViewCounts : Dict.Dict Evergreen.V32.Wiki.Slug (Dict.Dict Evergreen.V32.Page.Slug Int)
    , wikiViewsVersions : Dict.Dict Evergreen.V32.Wiki.Slug Int
    , wikiStatsCache : Dict.Dict Evergreen.V32.Wiki.Slug WikiStatsPartitions
    }


type FrontendMsg
    = UrlClicked Effect.Browser.UrlRequest
    | UrlChanged Url.Url
    | UrlFragmentScrollDone
    | ColorThemeToggled
    | ColorThemeFromJs (Maybe Evergreen.V32.ColorTheme.Incoming)
    | RegisterFormUsernameChanged String
    | RegisterFormPasswordChanged String
    | RegisterFormSubmitted
    | LoginFormUsernameChanged String
    | LoginFormPasswordChanged String
    | LoginFormSubmitted
    | HeaderSearchQueryChanged String
    | HeaderSearchTimeoutReached Evergreen.V32.Wiki.Slug String
    | HeaderSearchSubmitted
    | WikiSearchPageQueryChanged String
    | WikiSearchPageTimeoutReached Evergreen.V32.Wiki.Slug String
    | ContributorLogoutWiki Evergreen.V32.Wiki.Slug
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
    | WikiAdminAuditFilterTypeTagToggled Evergreen.V32.WikiAuditLog.AuditEventKindFilterTag Bool
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
    | HostAdminAuditFilterTypeTagToggled Evergreen.V32.WikiAuditLog.AuditEventKindFilterTag Bool
    | HostAdminDataExportClicked
    | HostAdminDataImportPickRequested
    | HostAdminDataImportFileSelected Effect.File.File
    | HostAdminDataImportFileRead (Result () String)
    | HostAdminWikisDataImportPickRequested
    | HostAdminWikisDataImportFileSelected Effect.File.File
    | HostAdminWikisDataImportFileRead (Result () String)
    | HostAdminWikiDataExportClicked Evergreen.V32.Wiki.Slug
    | HostAdminWikiDataImportPickRequested Evergreen.V32.Wiki.Slug
    | HostAdminWikiDataImportFileSelected Effect.File.File
    | HostAdminWikiDataImportFileRead Evergreen.V32.Wiki.Slug (Result () String)
    | SideNavOpened
    | SideNavClosed
    | WikiMarkdownEditorPaneSelected Evergreen.V32.WikiMarkdownEditorPane.WikiMarkdownEditorPane
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
    | RequestWikiStats Evergreen.V32.Wiki.Slug (Maybe Evergreen.V32.CacheVersion.Versions)
    | RequestWikiFrontendDetails Evergreen.V32.Wiki.Slug
    | RequestWikiTodos Evergreen.V32.Wiki.Slug (Maybe Int)
    | RequestPageFrontendDetails Evergreen.V32.Wiki.Slug Evergreen.V32.Page.Slug
    | RequestWikiSearch Evergreen.V32.Wiki.Slug String
    | RequestMyPendingSubmissions Evergreen.V32.Wiki.Slug
    | RequestReviewQueue Evergreen.V32.Wiki.Slug
    | RequestReviewSubmissionDetail Evergreen.V32.Wiki.Slug String
    | RequestWikiUsers Evergreen.V32.Wiki.Slug
    | RequestWikiAuditLog Evergreen.V32.Wiki.Slug Evergreen.V32.WikiAuditLog.AuditLogFilter (Maybe Int)
    | RequestWikiAuditEventDiff Evergreen.V32.Wiki.Slug Int
    | PromoteContributorToTrusted Evergreen.V32.Wiki.Slug String
    | DemoteTrustedToContributor Evergreen.V32.Wiki.Slug String
    | GrantWikiAdmin Evergreen.V32.Wiki.Slug String
    | RevokeWikiAdmin Evergreen.V32.Wiki.Slug String
    | RequestSubmissionDetails Evergreen.V32.Wiki.Slug String
    | RegisterContributor Evergreen.V32.Wiki.Slug RegisterContributorPayload
    | LoginContributor Evergreen.V32.Wiki.Slug LoginContributorPayload
    | LogoutContributor Evergreen.V32.Wiki.Slug
    | SubmitNewPage Evergreen.V32.Wiki.Slug SubmitNewPagePayload
    | SubmitPageEdit Evergreen.V32.Wiki.Slug Evergreen.V32.Page.Slug String String
    | RequestPublishedPageDeletion Evergreen.V32.Wiki.Slug Evergreen.V32.Page.Slug String
    | DeletePublishedPageImmediately Evergreen.V32.Wiki.Slug Evergreen.V32.Page.Slug String
    | SaveNewPageDraft
        Evergreen.V32.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , rawPageSlug : String
        , rawMarkdown : String
        , rawTags : String
        }
    | SavePageEditDraft
        Evergreen.V32.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V32.Page.Slug
        , rawMarkdown : String
        , rawTags : String
        }
    | SavePageDeleteDraft
        Evergreen.V32.Wiki.Slug
        { maybeSubmissionId : Maybe String
        , pageSlug : Evergreen.V32.Page.Slug
        , rawReason : String
        }
    | SubmitDraftForReview Evergreen.V32.Wiki.Slug String
    | WithdrawSubmission Evergreen.V32.Wiki.Slug String
    | DeleteMySubmission Evergreen.V32.Wiki.Slug String
    | ApproveSubmission Evergreen.V32.Wiki.Slug String
    | RejectSubmission Evergreen.V32.Wiki.Slug RejectSubmissionPayload
    | RequestSubmissionChanges Evergreen.V32.Wiki.Slug RequestSubmissionChangesPayload
    | HostAdminLogin String
    | RequestHostWikiList
    | RequestHostAuditLog Evergreen.V32.WikiAuditLog.HostAuditLogFilter
    | RequestHostAuditEventDiff Evergreen.V32.Wiki.Slug Int
    | RequestHostWikiDetail Evergreen.V32.Wiki.Slug
    | CreateHostedWiki CreateHostedWikiPayload
    | UpdateHostedWikiMetadata Evergreen.V32.Wiki.Slug UpdateHostedWikiMetadataPayload
    | DeactivateHostedWiki Evergreen.V32.Wiki.Slug
    | ReactivateHostedWiki Evergreen.V32.Wiki.Slug
    | DeleteHostedWiki Evergreen.V32.Wiki.Slug String
    | RequestHostAdminDataExport
    | ImportHostAdminDataSnapshot String
    | RequestHostAdminWikiDataExport Evergreen.V32.Wiki.Slug
    | ImportHostAdminWikiDataSnapshot Evergreen.V32.Wiki.Slug String
    | ImportHostAdminWikiDataSnapshotAuto String


type BackendMsg
    = ToBackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Time.Posix


type ToFrontend
    = WikiCatalogResponse (Dict.Dict Evergreen.V32.Wiki.Slug Evergreen.V32.Wiki.CatalogEntry)
    | WikiStatsResponse Evergreen.V32.Wiki.Slug Evergreen.V32.CacheVersion.Versions (Maybe Evergreen.V32.WikiStats.Summary)
    | WikiStatsUnchanged
    | WikiCacheInvalidated Evergreen.V32.Wiki.Slug Evergreen.V32.CacheVersion.Versions
    | WikiSlugRenamed Evergreen.V32.Wiki.Slug Evergreen.V32.Wiki.Slug
    | PendingReviewCountUpdated Evergreen.V32.Wiki.Slug Int
    | WikiFrontendDetailsResponse Evergreen.V32.Wiki.Slug (Maybe Evergreen.V32.Wiki.FrontendDetails)
    | WikiTodosResponse Evergreen.V32.Wiki.Slug Int (Result () (List Evergreen.V32.WikiTodos.TableRow))
    | WikiTodosUnchanged
    | PageFrontendDetailsResponse Evergreen.V32.Wiki.Slug Evergreen.V32.Page.Slug (Maybe Evergreen.V32.Page.FrontendDetails)
    | WikiSearchResponse Evergreen.V32.Wiki.Slug String (List Evergreen.V32.WikiSearch.ResultItem)
    | MyPendingSubmissionsResponse Evergreen.V32.Wiki.Slug (Result Evergreen.V32.Submission.MyPendingSubmissionsError (List Evergreen.V32.Submission.MyPendingSubmissionListItem))
    | ReviewQueueResponse Evergreen.V32.Wiki.Slug (Result Evergreen.V32.Submission.ReviewQueueError (List Evergreen.V32.Submission.ReviewQueueItem))
    | ReviewSubmissionDetailResponse Evergreen.V32.Wiki.Slug String (Result Evergreen.V32.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V32.SubmissionReviewDetail.SubmissionReviewDetail)
    | WikiUsersResponse Evergreen.V32.Wiki.Slug (Result Evergreen.V32.WikiAdminUsers.Error (List Evergreen.V32.WikiAdminUsers.ListedUser))
    | WikiAuditLogResponse Evergreen.V32.Wiki.Slug Evergreen.V32.WikiAuditLog.AuditLogFilter Int (Result Evergreen.V32.WikiAuditLog.Error (List Evergreen.V32.WikiAuditLog.AuditEventSummary))
    | WikiAuditEventDiffResponse Evergreen.V32.Wiki.Slug Int (Result Evergreen.V32.WikiAuditLog.EventDiffError Evergreen.V32.WikiAuditLog.TrustedPublishAuditDiff)
    | WikiAuditLogUnchanged Evergreen.V32.Wiki.Slug
    | PromoteContributorToTrustedResponse Evergreen.V32.Wiki.Slug (Result Evergreen.V32.WikiAdminUsers.PromoteContributorError ())
    | DemoteTrustedToContributorResponse Evergreen.V32.Wiki.Slug (Result Evergreen.V32.WikiAdminUsers.DemoteTrustedError ())
    | GrantWikiAdminResponse Evergreen.V32.Wiki.Slug (Result Evergreen.V32.WikiAdminUsers.GrantTrustedToAdminError ())
    | RevokeWikiAdminResponse Evergreen.V32.Wiki.Slug (Result Evergreen.V32.WikiAdminUsers.RevokeAdminError ())
    | SubmissionDetailsResponse Evergreen.V32.Wiki.Slug String (Result Evergreen.V32.Submission.DetailsError Evergreen.V32.Submission.ContributorView)
    | RegisterContributorResponse Evergreen.V32.Wiki.Slug (Result Evergreen.V32.ContributorAccount.RegisterContributorError Evergreen.V32.WikiRole.WikiRole)
    | LoginContributorResponse Evergreen.V32.Wiki.Slug (Result Evergreen.V32.ContributorAccount.LoginContributorError Evergreen.V32.WikiRole.WikiRole)
    | LogoutContributorResponse Evergreen.V32.Wiki.Slug
    | SubmitNewPageResponse Evergreen.V32.Wiki.Slug (Result Evergreen.V32.Submission.SubmitNewPageError Evergreen.V32.Submission.NewPageSubmitSuccess)
    | SubmitPageEditResponse Evergreen.V32.Wiki.Slug (Result Evergreen.V32.Submission.SubmitPageEditError Evergreen.V32.Submission.EditSubmitSuccess)
    | RequestPublishedPageDeletionResponse Evergreen.V32.Wiki.Slug (Result Evergreen.V32.Submission.RequestPublishedPageDeletionError Evergreen.V32.Submission.Id)
    | DeletePublishedPageImmediatelyResponse Evergreen.V32.Wiki.Slug (Result Evergreen.V32.Submission.DeletePublishedPageImmediatelyError ())
    | SaveNewPageDraftResponse Evergreen.V32.Wiki.Slug (Result Evergreen.V32.Submission.SaveNewPageDraftError Evergreen.V32.Submission.Id)
    | SavePageEditDraftResponse Evergreen.V32.Wiki.Slug (Result Evergreen.V32.Submission.SavePageEditDraftError Evergreen.V32.Submission.Id)
    | SavePageDeleteDraftResponse Evergreen.V32.Wiki.Slug (Result Evergreen.V32.Submission.SavePageDeleteDraftError Evergreen.V32.Submission.Id)
    | SubmitDraftForReviewResponse Evergreen.V32.Wiki.Slug String (Result Evergreen.V32.Submission.SubmitDraftForReviewError ())
    | WithdrawSubmissionResponse Evergreen.V32.Wiki.Slug String (Result Evergreen.V32.Submission.WithdrawSubmissionError ())
    | DeleteMySubmissionResponse Evergreen.V32.Wiki.Slug String (Result Evergreen.V32.Submission.DeleteMySubmissionError ())
    | ApproveSubmissionResponse Evergreen.V32.Wiki.Slug String (Result Evergreen.V32.Submission.ApproveSubmissionError ())
    | RejectSubmissionResponse Evergreen.V32.Wiki.Slug String (Result Evergreen.V32.Submission.RejectSubmissionError ())
    | RequestSubmissionChangesResponse Evergreen.V32.Wiki.Slug String (Result Evergreen.V32.Submission.RequestChangesSubmissionError ())
    | HostAdminLoginResponse (Result Evergreen.V32.HostAdmin.LoginError ())
    | HostAdminWikiListResponse (Result Evergreen.V32.HostAdmin.ProtectedError (List Evergreen.V32.Wiki.CatalogEntry))
    | HostAuditLogResponse Evergreen.V32.WikiAuditLog.HostAuditLogFilter (Result Evergreen.V32.HostAdmin.ProtectedError (List Evergreen.V32.WikiAuditLog.ScopedAuditEventSummary))
    | HostAuditEventDiffResponse Evergreen.V32.Wiki.Slug Int (Result Evergreen.V32.HostAdmin.ProtectedError (Result Evergreen.V32.WikiAuditLog.EventDiffError Evergreen.V32.WikiAuditLog.TrustedPublishAuditDiff))
    | CreateHostedWikiResponse (Result Evergreen.V32.HostAdmin.CreateHostedWikiError Evergreen.V32.Wiki.CatalogEntry)
    | HostWikiDetailResponse Evergreen.V32.Wiki.Slug (Result Evergreen.V32.HostAdmin.HostWikiDetailError Evergreen.V32.Wiki.CatalogEntry)
    | UpdateHostedWikiMetadataResponse Evergreen.V32.Wiki.Slug (Result Evergreen.V32.HostAdmin.UpdateHostedWikiMetadataError Evergreen.V32.Wiki.CatalogEntry)
    | DeactivateHostedWikiResponse Evergreen.V32.Wiki.Slug (Result Evergreen.V32.HostAdmin.WikiLifecycleError Evergreen.V32.Wiki.CatalogEntry)
    | ReactivateHostedWikiResponse Evergreen.V32.Wiki.Slug (Result Evergreen.V32.HostAdmin.WikiLifecycleError Evergreen.V32.Wiki.CatalogEntry)
    | DeleteHostedWikiResponse Evergreen.V32.Wiki.Slug (Result Evergreen.V32.HostAdmin.DeleteHostedWikiError ())
    | HostAdminDataExportResponse (Result Evergreen.V32.HostAdmin.DataExportError String)
    | HostAdminDataImportResponse (Result Evergreen.V32.HostAdmin.DataImportError ())
    | HostAdminWikiDataExportResponse Evergreen.V32.Wiki.Slug (Result Evergreen.V32.HostAdmin.WikiDataExportError String)
    | HostAdminWikiDataImportResponse Evergreen.V32.Wiki.Slug (Result Evergreen.V32.HostAdmin.WikiDataImportError ())
    | HostAdminWikiDataImportAutoResponse (Result Evergreen.V32.HostAdmin.WikiDataImportError Evergreen.V32.Wiki.Slug)

module Types exposing
    ( BackendModel
    , BackendMsg(..)
    , FrontendModel
    , FrontendMsg(..)
    , HostAdminCreateWikiDraft
    , HostAdminLoginDraft
    , HostAdminWikiDetailDraft
    , LoginDraft
    , NewPageSubmitDraft
    , PageDeleteSubmitDraft
    , PageEditSubmitDraft
    , RegisterDraft
    , ReviewApproveDraft
    , ReviewRejectDraft
    , ReviewRequestChangesDraft
    , ToBackend(..)
    , ToFrontend(..)
    )

import ColorTheme exposing (ColorTheme)
import ContributorAccount
import Dict exposing (Dict)
import Effect.Browser
import HostAdmin
import Effect.Browser.Navigation
import HostedWikiSlugPolicy exposing (HostedWikiSlugPolicy)
import Page
import RemoteData exposing (RemoteData)
import Route exposing (Route)
import Set exposing (Set)
import Store exposing (Store)
import Submission
import SubmissionReviewDetail
import Url exposing (Url)
import Wiki exposing (Wiki)
import WikiAdminUsers
import WikiAuditLog
import WikiContributors
import WikiRole
import WikiUser


type ToBackend
    = RequestWikiCatalog
    | RequestWikiFrontendDetails Wiki.Slug
    | RequestPageFrontendDetails Wiki.Slug Page.Slug
    | RequestReviewQueue Wiki.Slug
    | RequestReviewSubmissionDetail Wiki.Slug String
    | RequestWikiUsers Wiki.Slug
    | RequestWikiAuditLog Wiki.Slug WikiAuditLog.AuditLogFilter
    | PromoteContributorToTrusted Wiki.Slug String
    | DemoteTrustedToContributor Wiki.Slug String
    | GrantWikiAdmin Wiki.Slug String
    | RevokeWikiAdmin Wiki.Slug String
    | RequestSubmissionDetails Wiki.Slug String
    | RegisterContributor Wiki.Slug String String
    | LoginContributor Wiki.Slug String String
    | SubmitNewPage Wiki.Slug String String
    | SubmitPageEdit Wiki.Slug Page.Slug String
    | SubmitPageDelete Wiki.Slug Page.Slug String
    | ApproveSubmission Wiki.Slug String
    | RejectSubmission Wiki.Slug String String
    | RequestSubmissionChanges Wiki.Slug String String
    | HostAdminLogin String
    | RequestHostWikiList
    | RequestHostWikiDetail Wiki.Slug
    | CreateHostedWiki String String
    | UpdateHostedWikiMetadata Wiki.Slug String String HostedWikiSlugPolicy
    | DeactivateHostedWiki Wiki.Slug
    | ReactivateHostedWiki Wiki.Slug
    | DeleteHostedWiki Wiki.Slug String


type ToFrontend
    = WikiCatalogResponse (Dict Wiki.Slug Wiki.CatalogEntry)
    | WikiFrontendDetailsResponse Wiki.Slug (Maybe Wiki.FrontendDetails)
    | PageFrontendDetailsResponse Wiki.Slug Page.Slug (Maybe Page.FrontendDetails)
    | ReviewQueueResponse Wiki.Slug (Result Submission.ReviewQueueError (List Submission.ReviewQueueItem))
    | ReviewSubmissionDetailResponse Wiki.Slug String (Result SubmissionReviewDetail.ReviewSubmissionDetailError SubmissionReviewDetail.SubmissionReviewDetail)
    | WikiUsersResponse Wiki.Slug (Result WikiAdminUsers.Error (List WikiAdminUsers.ListedUser))
    | WikiAuditLogResponse Wiki.Slug WikiAuditLog.AuditLogFilter (Result WikiAuditLog.Error (List WikiAuditLog.AuditEvent))
    | PromoteContributorToTrustedResponse Wiki.Slug String (Result WikiAdminUsers.PromoteContributorError ())
    | DemoteTrustedToContributorResponse Wiki.Slug String (Result WikiAdminUsers.DemoteTrustedError ())
    | GrantWikiAdminResponse Wiki.Slug String (Result WikiAdminUsers.GrantTrustedToAdminError ())
    | RevokeWikiAdminResponse Wiki.Slug String (Result WikiAdminUsers.RevokeAdminError ())
    | SubmissionDetailsResponse Wiki.Slug String (Result Submission.DetailsError Submission.ContributorView)
    | RegisterContributorResponse Wiki.Slug (Result ContributorAccount.RegisterContributorError WikiRole.WikiRole)
    | LoginContributorResponse Wiki.Slug (Result ContributorAccount.LoginContributorError WikiRole.WikiRole)
    | SubmitNewPageResponse Wiki.Slug (Result Submission.SubmitNewPageError Submission.NewPageSubmitSuccess)
    | SubmitPageEditResponse Wiki.Slug (Result Submission.SubmitPageEditError Submission.EditSubmitSuccess)
    | SubmitPageDeleteResponse Wiki.Slug (Result Submission.SubmitPageDeleteError Submission.DeleteSubmitSuccess)
    | ApproveSubmissionResponse Wiki.Slug String (Result Submission.ApproveSubmissionError ())
    | RejectSubmissionResponse Wiki.Slug String (Result Submission.RejectSubmissionError ())
    | RequestSubmissionChangesResponse Wiki.Slug String (Result Submission.RequestChangesSubmissionError ())
    | HostAdminLoginResponse (Result HostAdmin.LoginError ())
    | HostAdminWikiListResponse (Result HostAdmin.ProtectedError (List Wiki.CatalogEntry))
    | CreateHostedWikiResponse (Result HostAdmin.CreateHostedWikiError Wiki.CatalogEntry)
    | HostWikiDetailResponse Wiki.Slug (Result HostAdmin.HostWikiDetailError Wiki.CatalogEntry)
    | UpdateHostedWikiMetadataResponse Wiki.Slug (Result HostAdmin.UpdateHostedWikiMetadataError Wiki.CatalogEntry)
    | DeactivateHostedWikiResponse Wiki.Slug (Result HostAdmin.WikiLifecycleError Wiki.CatalogEntry)
    | ReactivateHostedWikiResponse Wiki.Slug (Result HostAdmin.WikiLifecycleError Wiki.CatalogEntry)
    | DeleteHostedWikiResponse Wiki.Slug (Result HostAdmin.DeleteHostedWikiError ())


type alias BackendModel =
    { wikis : Dict Wiki.Slug Wiki
    , contributors : WikiContributors.Registry
    , contributorSessions : WikiUser.SessionTable
    , hostSessions : Set String
    , submissions : Dict String Submission.Submission
    , nextSubmissionCounter : Int
    , wikiAuditEvents : Dict Wiki.Slug (List WikiAuditLog.AuditEvent)
    , auditClockMillis : Int
    }


type BackendMsg
    = BackendNoOp


type alias RegisterDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result ContributorAccount.RegisterContributorError ())
    }


type alias LoginDraft =
    { username : String
    , password : String
    , inFlight : Bool
    , lastResult : Maybe (Result ContributorAccount.LoginContributorError ())
    }


type alias HostAdminLoginDraft =
    { password : String
    , inFlight : Bool
    , lastResult : Maybe (Result HostAdmin.LoginError ())
    }


type alias HostAdminCreateWikiDraft =
    { slug : String
    , name : String
    , inFlight : Bool
    , lastResult : Maybe (Result HostAdmin.CreateHostedWikiError Wiki.CatalogEntry)
    }


type alias HostAdminWikiDetailDraft =
    { wikiSlug : Wiki.Slug
    , load : RemoteData () (Result HostAdmin.HostWikiDetailError Wiki.CatalogEntry)
    , nameDraft : String
    , summaryDraft : String
    , slugPolicyDraft : HostedWikiSlugPolicy
    , saveInFlight : Bool
    , lastSaveResult : Maybe (Result HostAdmin.UpdateHostedWikiMetadataError ())
    , lifecycleInFlight : Bool
    , lastLifecycleResult : Maybe (Result HostAdmin.WikiLifecycleError ())
    , deleteConfirmDraft : String
    , deleteInFlight : Bool
    , lastDeleteResult : Maybe (Result HostAdmin.DeleteHostedWikiError ())
    }


type alias NewPageSubmitDraft =
    { pageSlug : String
    , markdownBody : String
    , inFlight : Bool
    , lastResult : Maybe (Result Submission.SubmitNewPageError Submission.NewPageSubmitSuccess)
    }


type alias PageEditSubmitDraft =
    { markdownBody : String
    , inFlight : Bool
    , lastResult : Maybe (Result Submission.SubmitPageEditError Submission.EditSubmitSuccess)
    }


type alias PageDeleteSubmitDraft =
    { reasonText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Submission.SubmitPageDeleteError Submission.DeleteSubmitSuccess)
    }


type alias ReviewApproveDraft =
    { inFlight : Bool
    , lastResult : Maybe (Result Submission.ApproveSubmissionError ())
    }


type alias ReviewRejectDraft =
    { reasonText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Submission.RejectSubmissionError ())
    }


type alias ReviewRequestChangesDraft =
    { guidanceText : String
    , inFlight : Bool
    , lastResult : Maybe (Result Submission.RequestChangesSubmissionError ())
    }


type alias FrontendModel =
    { key : Effect.Browser.Navigation.Key
    , colorTheme : ColorTheme
    , route : Route
    , store : Store
    , contributorWikiSession : Maybe Wiki.Slug
    , contributorWikiRole : Maybe WikiRole.WikiRole
    , contributorDisplayUsername : Maybe String
    , registerDraft : RegisterDraft
    , loginDraft : LoginDraft
    , newPageSubmitDraft : NewPageSubmitDraft
    , pageEditSubmitDraft : PageEditSubmitDraft
    , pageDeleteSubmitDraft : PageDeleteSubmitDraft
    , reviewApproveDraft : ReviewApproveDraft
    , reviewRejectDraft : ReviewRejectDraft
    , reviewRequestChangesDraft : ReviewRequestChangesDraft
    , adminPromoteError : Maybe String
    , adminDemoteError : Maybe String
    , adminGrantAdminError : Maybe String
    , adminRevokeAdminError : Maybe String
    , wikiAdminAuditFilterActorDraft : String
    , wikiAdminAuditFilterPageDraft : String
    , wikiAdminAuditFilterSelectedKindTags : List WikiAuditLog.AuditEventKindFilterTag
    , wikiAdminAuditAppliedFilter : WikiAuditLog.AuditLogFilter
    , hostAdminLoginDraft : HostAdminLoginDraft
    , hostAdminCreateWikiDraft : HostAdminCreateWikiDraft
    , hostAdminWikiDetailDraft : HostAdminWikiDetailDraft
    , hostAdminWikis : RemoteData () (Result HostAdmin.ProtectedError (List Wiki.CatalogEntry))
    }


type FrontendMsg
    = UrlClicked Effect.Browser.UrlRequest
    | UrlChanged Url
    | ColorThemeToggled
    | RegisterFormUsernameChanged String
    | RegisterFormPasswordChanged String
    | RegisterFormSubmitted
    | LoginFormUsernameChanged String
    | LoginFormPasswordChanged String
    | LoginFormSubmitted
    | NewPageSubmitSlugChanged String
    | NewPageSubmitMarkdownChanged String
    | NewPageSubmitFormSubmitted
    | PageEditSubmitMarkdownChanged String
    | PageEditSubmitFormSubmitted
    | PageDeleteSubmitReasonChanged String
    | PageDeleteSubmitFormSubmitted
    | ReviewApproveSubmitted
    | ReviewRejectReasonChanged String
    | ReviewRejectSubmitted
    | ReviewRequestChangesNoteChanged String
    | ReviewRequestChangesSubmitted
    | WikiAdminPromoteToTrustedClicked String
    | WikiAdminDemoteToContributorClicked String
    | WikiAdminGrantAdminClicked String
    | WikiAdminRevokeAdminClicked String
    | WikiAdminAuditFilterActorChanged String
    | WikiAdminAuditFilterPageChanged String
    | WikiAdminAuditFilterTypeTagToggled WikiAuditLog.AuditEventKindFilterTag Bool
    | WikiAdminAuditFilterApplyClicked
    | HostAdminLoginPasswordChanged String
    | HostAdminLoginSubmitted
    | HostAdminCreateWikiSlugChanged String
    | HostAdminCreateWikiNameChanged String
    | HostAdminCreateWikiSubmitted
    | HostAdminWikiDetailNameChanged String
    | HostAdminWikiDetailSummaryChanged String
    | HostAdminWikiDetailSlugPolicyFormChanged String
    | HostAdminWikiDetailSaveClicked
    | HostAdminWikiDetailDeactivateClicked
    | HostAdminWikiDetailReactivateClicked
    | HostAdminWikiDetailDeleteConfirmChanged String
    | HostAdminWikiDetailDeleteSubmitted

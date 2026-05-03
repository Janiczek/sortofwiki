module Evergreen.V29.Store exposing (..)

import Dict
import Evergreen.V29.CacheVersion
import Evergreen.V29.Page
import Evergreen.V29.Submission
import Evergreen.V29.SubmissionReviewDetail
import Evergreen.V29.Wiki
import Evergreen.V29.WikiAdminUsers
import Evergreen.V29.WikiAuditLog
import Evergreen.V29.WikiStats
import Evergreen.V29.WikiTodos
import RemoteData


type alias Versioned version value =
    { version : version
    , value : RemoteData.RemoteData () value
    }


type alias Store =
    { wikiCatalog : RemoteData.RemoteData () (Dict.Dict Evergreen.V29.Wiki.Slug Evergreen.V29.Wiki.CatalogEntry)
    , wikiDetails : Dict.Dict Evergreen.V29.Wiki.Slug (RemoteData.RemoteData () Evergreen.V29.Wiki.FrontendDetails)
    , publishedPages : Dict.Dict ( Evergreen.V29.Wiki.Slug, Evergreen.V29.Page.Slug ) (RemoteData.RemoteData () Evergreen.V29.Page.FrontendDetails)
    , reviewQueues : Dict.Dict Evergreen.V29.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V29.Submission.ReviewQueueError (List Evergreen.V29.Submission.ReviewQueueItem)))
    , myPendingSubmissions : Dict.Dict Evergreen.V29.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V29.Submission.MyPendingSubmissionsError (List Evergreen.V29.Submission.MyPendingSubmissionListItem)))
    , submissionDetails : Dict.Dict ( Evergreen.V29.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V29.Submission.DetailsError Evergreen.V29.Submission.ContributorView))
    , reviewSubmissionDetails : Dict.Dict ( Evergreen.V29.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V29.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V29.SubmissionReviewDetail.SubmissionReviewDetail))
    , wikiUsers : Dict.Dict Evergreen.V29.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V29.WikiAdminUsers.Error (List Evergreen.V29.WikiAdminUsers.ListedUser)))
    , wikiAuditLogs : Dict.Dict Evergreen.V29.Wiki.Slug (Dict.Dict String (Versioned Int (Result Evergreen.V29.WikiAuditLog.Error (List Evergreen.V29.WikiAuditLog.AuditEventSummary))))
    , wikiTodos : Dict.Dict Evergreen.V29.Wiki.Slug (Versioned Int (Result () (List Evergreen.V29.WikiTodos.TableRow)))
    , wikiStats : Dict.Dict Evergreen.V29.Wiki.Slug (Versioned Evergreen.V29.CacheVersion.Versions (Maybe Evergreen.V29.WikiStats.Summary))
    }

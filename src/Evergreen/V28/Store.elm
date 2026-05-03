module Evergreen.V28.Store exposing (..)

import Dict
import Evergreen.V28.CacheVersion
import Evergreen.V28.Page
import Evergreen.V28.Submission
import Evergreen.V28.SubmissionReviewDetail
import Evergreen.V28.Wiki
import Evergreen.V28.WikiAdminUsers
import Evergreen.V28.WikiAuditLog
import Evergreen.V28.WikiStats
import Evergreen.V28.WikiTodos
import RemoteData


type alias Versioned version value =
    { version : version
    , value : RemoteData.RemoteData () value
    }


type alias Store =
    { wikiCatalog : RemoteData.RemoteData () (Dict.Dict Evergreen.V28.Wiki.Slug Evergreen.V28.Wiki.CatalogEntry)
    , wikiDetails : Dict.Dict Evergreen.V28.Wiki.Slug (RemoteData.RemoteData () Evergreen.V28.Wiki.FrontendDetails)
    , publishedPages : Dict.Dict ( Evergreen.V28.Wiki.Slug, Evergreen.V28.Page.Slug ) (RemoteData.RemoteData () Evergreen.V28.Page.FrontendDetails)
    , reviewQueues : Dict.Dict Evergreen.V28.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V28.Submission.ReviewQueueError (List Evergreen.V28.Submission.ReviewQueueItem)))
    , myPendingSubmissions : Dict.Dict Evergreen.V28.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V28.Submission.MyPendingSubmissionsError (List Evergreen.V28.Submission.MyPendingSubmissionListItem)))
    , submissionDetails : Dict.Dict ( Evergreen.V28.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V28.Submission.DetailsError Evergreen.V28.Submission.ContributorView))
    , reviewSubmissionDetails : Dict.Dict ( Evergreen.V28.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V28.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V28.SubmissionReviewDetail.SubmissionReviewDetail))
    , wikiUsers : Dict.Dict Evergreen.V28.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V28.WikiAdminUsers.Error (List Evergreen.V28.WikiAdminUsers.ListedUser)))
    , wikiAuditLogs : Dict.Dict Evergreen.V28.Wiki.Slug (Dict.Dict String (Versioned Int (Result Evergreen.V28.WikiAuditLog.Error (List Evergreen.V28.WikiAuditLog.AuditEventSummary))))
    , wikiTodos : Dict.Dict Evergreen.V28.Wiki.Slug (Versioned Int (Result () (List Evergreen.V28.WikiTodos.TableRow)))
    , wikiStats : Dict.Dict Evergreen.V28.Wiki.Slug (Versioned Evergreen.V28.CacheVersion.Versions (Maybe Evergreen.V28.WikiStats.Summary))
    }

module Evergreen.V32.Store exposing (..)

import Dict
import Evergreen.V32.CacheVersion
import Evergreen.V32.Page
import Evergreen.V32.Submission
import Evergreen.V32.SubmissionReviewDetail
import Evergreen.V32.Wiki
import Evergreen.V32.WikiAdminUsers
import Evergreen.V32.WikiAuditLog
import Evergreen.V32.WikiStats
import Evergreen.V32.WikiTodos
import RemoteData


type alias Versioned version value =
    { version : version
    , value : RemoteData.RemoteData () value
    }


type alias Store =
    { wikiCatalog : RemoteData.RemoteData () (Dict.Dict Evergreen.V32.Wiki.Slug Evergreen.V32.Wiki.CatalogEntry)
    , wikiDetails : Dict.Dict Evergreen.V32.Wiki.Slug (RemoteData.RemoteData () Evergreen.V32.Wiki.FrontendDetails)
    , publishedPages : Dict.Dict ( Evergreen.V32.Wiki.Slug, Evergreen.V32.Page.Slug ) (RemoteData.RemoteData () Evergreen.V32.Page.FrontendDetails)
    , reviewQueues : Dict.Dict Evergreen.V32.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V32.Submission.ReviewQueueError (List Evergreen.V32.Submission.ReviewQueueItem)))
    , myPendingSubmissions : Dict.Dict Evergreen.V32.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V32.Submission.MyPendingSubmissionsError (List Evergreen.V32.Submission.MyPendingSubmissionListItem)))
    , submissionDetails : Dict.Dict ( Evergreen.V32.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V32.Submission.DetailsError Evergreen.V32.Submission.ContributorView))
    , reviewSubmissionDetails : Dict.Dict ( Evergreen.V32.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V32.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V32.SubmissionReviewDetail.SubmissionReviewDetail))
    , wikiUsers : Dict.Dict Evergreen.V32.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V32.WikiAdminUsers.Error (List Evergreen.V32.WikiAdminUsers.ListedUser)))
    , wikiAuditLogs : Dict.Dict Evergreen.V32.Wiki.Slug (Dict.Dict String (Versioned Int (Result Evergreen.V32.WikiAuditLog.Error (List Evergreen.V32.WikiAuditLog.AuditEventSummary))))
    , wikiTodos : Dict.Dict Evergreen.V32.Wiki.Slug (Versioned Int (Result () (List Evergreen.V32.WikiTodos.TableRow)))
    , wikiStats : Dict.Dict Evergreen.V32.Wiki.Slug (Versioned Evergreen.V32.CacheVersion.Versions (Maybe Evergreen.V32.WikiStats.Summary))
    }

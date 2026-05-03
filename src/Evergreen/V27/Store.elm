module Evergreen.V27.Store exposing (..)

import Dict
import Evergreen.V27.CacheVersion
import Evergreen.V27.Page
import Evergreen.V27.Submission
import Evergreen.V27.SubmissionReviewDetail
import Evergreen.V27.Wiki
import Evergreen.V27.WikiAdminUsers
import Evergreen.V27.WikiAuditLog
import Evergreen.V27.WikiStats
import Evergreen.V27.WikiTodos
import RemoteData


type alias Versioned version value =
    { version : version
    , value : RemoteData.RemoteData () value
    }


type alias Store =
    { wikiCatalog : RemoteData.RemoteData () (Dict.Dict Evergreen.V27.Wiki.Slug Evergreen.V27.Wiki.CatalogEntry)
    , wikiDetails : Dict.Dict Evergreen.V27.Wiki.Slug (RemoteData.RemoteData () Evergreen.V27.Wiki.FrontendDetails)
    , publishedPages : Dict.Dict ( Evergreen.V27.Wiki.Slug, Evergreen.V27.Page.Slug ) (RemoteData.RemoteData () Evergreen.V27.Page.FrontendDetails)
    , reviewQueues : Dict.Dict Evergreen.V27.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V27.Submission.ReviewQueueError (List Evergreen.V27.Submission.ReviewQueueItem)))
    , myPendingSubmissions : Dict.Dict Evergreen.V27.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V27.Submission.MyPendingSubmissionsError (List Evergreen.V27.Submission.MyPendingSubmissionListItem)))
    , submissionDetails : Dict.Dict ( Evergreen.V27.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V27.Submission.DetailsError Evergreen.V27.Submission.ContributorView))
    , reviewSubmissionDetails : Dict.Dict ( Evergreen.V27.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V27.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V27.SubmissionReviewDetail.SubmissionReviewDetail))
    , wikiUsers : Dict.Dict Evergreen.V27.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V27.WikiAdminUsers.Error (List Evergreen.V27.WikiAdminUsers.ListedUser)))
    , wikiAuditLogs : Dict.Dict Evergreen.V27.Wiki.Slug (Dict.Dict String (Versioned Int (Result Evergreen.V27.WikiAuditLog.Error (List Evergreen.V27.WikiAuditLog.AuditEvent))))
    , wikiTodos : Dict.Dict Evergreen.V27.Wiki.Slug (Versioned Int (Result () (List Evergreen.V27.WikiTodos.TableRow)))
    , wikiStats : Dict.Dict Evergreen.V27.Wiki.Slug (Versioned Evergreen.V27.CacheVersion.Versions (Maybe Evergreen.V27.WikiStats.Summary))
    }

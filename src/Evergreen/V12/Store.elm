module Evergreen.V12.Store exposing (..)

import Dict
import Evergreen.V12.Page
import Evergreen.V12.Submission
import Evergreen.V12.SubmissionReviewDetail
import Evergreen.V12.Wiki
import Evergreen.V12.WikiAdminUsers
import Evergreen.V12.WikiAuditLog
import RemoteData


type alias Store =
    { wikiCatalog : RemoteData.RemoteData () (Dict.Dict Evergreen.V12.Wiki.Slug Evergreen.V12.Wiki.CatalogEntry)
    , wikiDetails : Dict.Dict Evergreen.V12.Wiki.Slug (RemoteData.RemoteData () Evergreen.V12.Wiki.FrontendDetails)
    , publishedPages : Dict.Dict ( Evergreen.V12.Wiki.Slug, Evergreen.V12.Page.Slug ) (RemoteData.RemoteData () Evergreen.V12.Page.FrontendDetails)
    , reviewQueues : Dict.Dict Evergreen.V12.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V12.Submission.ReviewQueueError (List Evergreen.V12.Submission.ReviewQueueItem)))
    , myPendingSubmissions : Dict.Dict Evergreen.V12.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V12.Submission.MyPendingSubmissionsError (List Evergreen.V12.Submission.MyPendingSubmissionListItem)))
    , submissionDetails : Dict.Dict ( Evergreen.V12.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V12.Submission.DetailsError Evergreen.V12.Submission.ContributorView))
    , reviewSubmissionDetails : Dict.Dict ( Evergreen.V12.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V12.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V12.SubmissionReviewDetail.SubmissionReviewDetail))
    , wikiUsers : Dict.Dict Evergreen.V12.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V12.WikiAdminUsers.Error (List Evergreen.V12.WikiAdminUsers.ListedUser)))
    , wikiAuditLogs : Dict.Dict Evergreen.V12.Wiki.Slug (Dict.Dict String (RemoteData.RemoteData () (Result Evergreen.V12.WikiAuditLog.Error (List Evergreen.V12.WikiAuditLog.AuditEvent))))
    }

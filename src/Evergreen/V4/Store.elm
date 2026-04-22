module Evergreen.V4.Store exposing (..)

import Dict
import Evergreen.V4.Page
import Evergreen.V4.Submission
import Evergreen.V4.SubmissionReviewDetail
import Evergreen.V4.Wiki
import Evergreen.V4.WikiAdminUsers
import Evergreen.V4.WikiAuditLog
import RemoteData


type alias Store =
    { wikiCatalog : RemoteData.RemoteData () (Dict.Dict Evergreen.V4.Wiki.Slug Evergreen.V4.Wiki.CatalogEntry)
    , wikiDetails : Dict.Dict Evergreen.V4.Wiki.Slug (RemoteData.RemoteData () Evergreen.V4.Wiki.FrontendDetails)
    , publishedPages : Dict.Dict ( Evergreen.V4.Wiki.Slug, Evergreen.V4.Page.Slug ) (RemoteData.RemoteData () Evergreen.V4.Page.FrontendDetails)
    , reviewQueues : Dict.Dict Evergreen.V4.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V4.Submission.ReviewQueueError (List Evergreen.V4.Submission.ReviewQueueItem)))
    , myPendingSubmissions : Dict.Dict Evergreen.V4.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V4.Submission.MyPendingSubmissionsError (List Evergreen.V4.Submission.MyPendingSubmissionListItem)))
    , submissionDetails : Dict.Dict ( Evergreen.V4.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V4.Submission.DetailsError Evergreen.V4.Submission.ContributorView))
    , reviewSubmissionDetails : Dict.Dict ( Evergreen.V4.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V4.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V4.SubmissionReviewDetail.SubmissionReviewDetail))
    , wikiUsers : Dict.Dict Evergreen.V4.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V4.WikiAdminUsers.Error (List Evergreen.V4.WikiAdminUsers.ListedUser)))
    , wikiAuditLogs : Dict.Dict Evergreen.V4.Wiki.Slug (Dict.Dict String (RemoteData.RemoteData () (Result Evergreen.V4.WikiAuditLog.Error (List Evergreen.V4.WikiAuditLog.AuditEvent))))
    }

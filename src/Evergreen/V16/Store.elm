module Evergreen.V16.Store exposing (..)

import Dict
import Evergreen.V16.Page
import Evergreen.V16.Submission
import Evergreen.V16.SubmissionReviewDetail
import Evergreen.V16.Wiki
import Evergreen.V16.WikiAdminUsers
import Evergreen.V16.WikiAuditLog
import RemoteData


type alias Store =
    { wikiCatalog : RemoteData.RemoteData () (Dict.Dict Evergreen.V16.Wiki.Slug Evergreen.V16.Wiki.CatalogEntry)
    , wikiDetails : Dict.Dict Evergreen.V16.Wiki.Slug (RemoteData.RemoteData () Evergreen.V16.Wiki.FrontendDetails)
    , publishedPages : Dict.Dict ( Evergreen.V16.Wiki.Slug, Evergreen.V16.Page.Slug ) (RemoteData.RemoteData () Evergreen.V16.Page.FrontendDetails)
    , reviewQueues : Dict.Dict Evergreen.V16.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V16.Submission.ReviewQueueError (List Evergreen.V16.Submission.ReviewQueueItem)))
    , myPendingSubmissions : Dict.Dict Evergreen.V16.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V16.Submission.MyPendingSubmissionsError (List Evergreen.V16.Submission.MyPendingSubmissionListItem)))
    , submissionDetails : Dict.Dict ( Evergreen.V16.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V16.Submission.DetailsError Evergreen.V16.Submission.ContributorView))
    , reviewSubmissionDetails : Dict.Dict ( Evergreen.V16.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V16.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V16.SubmissionReviewDetail.SubmissionReviewDetail))
    , wikiUsers : Dict.Dict Evergreen.V16.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V16.WikiAdminUsers.Error (List Evergreen.V16.WikiAdminUsers.ListedUser)))
    , wikiAuditLogs : Dict.Dict Evergreen.V16.Wiki.Slug (Dict.Dict String (RemoteData.RemoteData () (Result Evergreen.V16.WikiAuditLog.Error (List Evergreen.V16.WikiAuditLog.AuditEvent))))
    }

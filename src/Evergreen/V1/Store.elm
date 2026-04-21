module Evergreen.V1.Store exposing (..)

import Dict
import Evergreen.V1.Page
import Evergreen.V1.Submission
import Evergreen.V1.SubmissionReviewDetail
import Evergreen.V1.Wiki
import Evergreen.V1.WikiAdminUsers
import Evergreen.V1.WikiAuditLog
import RemoteData


type alias Store =
    { wikiCatalog : RemoteData.RemoteData () (Dict.Dict Evergreen.V1.Wiki.Slug Evergreen.V1.Wiki.CatalogEntry)
    , wikiDetails : Dict.Dict Evergreen.V1.Wiki.Slug (RemoteData.RemoteData () Evergreen.V1.Wiki.FrontendDetails)
    , publishedPages : Dict.Dict ( Evergreen.V1.Wiki.Slug, Evergreen.V1.Page.Slug ) (RemoteData.RemoteData () Evergreen.V1.Page.FrontendDetails)
    , reviewQueues : Dict.Dict Evergreen.V1.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V1.Submission.ReviewQueueError (List Evergreen.V1.Submission.ReviewQueueItem)))
    , myPendingSubmissions : Dict.Dict Evergreen.V1.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V1.Submission.MyPendingSubmissionsError (List Evergreen.V1.Submission.MyPendingSubmissionListItem)))
    , submissionDetails : Dict.Dict ( Evergreen.V1.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V1.Submission.DetailsError Evergreen.V1.Submission.ContributorView))
    , reviewSubmissionDetails : Dict.Dict ( Evergreen.V1.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V1.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V1.SubmissionReviewDetail.SubmissionReviewDetail))
    , wikiUsers : Dict.Dict Evergreen.V1.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V1.WikiAdminUsers.Error (List Evergreen.V1.WikiAdminUsers.ListedUser)))
    , wikiAuditLogs : Dict.Dict Evergreen.V1.Wiki.Slug (Dict.Dict String (RemoteData.RemoteData () (Result Evergreen.V1.WikiAuditLog.Error (List Evergreen.V1.WikiAuditLog.AuditEvent))))
    }

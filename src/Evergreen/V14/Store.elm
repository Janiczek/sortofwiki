module Evergreen.V14.Store exposing (..)

import Dict
import Evergreen.V14.Page
import Evergreen.V14.Submission
import Evergreen.V14.SubmissionReviewDetail
import Evergreen.V14.Wiki
import Evergreen.V14.WikiAdminUsers
import Evergreen.V14.WikiAuditLog
import RemoteData


type alias Store =
    { wikiCatalog : RemoteData.RemoteData () (Dict.Dict Evergreen.V14.Wiki.Slug Evergreen.V14.Wiki.CatalogEntry)
    , wikiDetails : Dict.Dict Evergreen.V14.Wiki.Slug (RemoteData.RemoteData () Evergreen.V14.Wiki.FrontendDetails)
    , publishedPages : Dict.Dict ( Evergreen.V14.Wiki.Slug, Evergreen.V14.Page.Slug ) (RemoteData.RemoteData () Evergreen.V14.Page.FrontendDetails)
    , reviewQueues : Dict.Dict Evergreen.V14.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V14.Submission.ReviewQueueError (List Evergreen.V14.Submission.ReviewQueueItem)))
    , myPendingSubmissions : Dict.Dict Evergreen.V14.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V14.Submission.MyPendingSubmissionsError (List Evergreen.V14.Submission.MyPendingSubmissionListItem)))
    , submissionDetails : Dict.Dict ( Evergreen.V14.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V14.Submission.DetailsError Evergreen.V14.Submission.ContributorView))
    , reviewSubmissionDetails : Dict.Dict ( Evergreen.V14.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V14.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V14.SubmissionReviewDetail.SubmissionReviewDetail))
    , wikiUsers : Dict.Dict Evergreen.V14.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V14.WikiAdminUsers.Error (List Evergreen.V14.WikiAdminUsers.ListedUser)))
    , wikiAuditLogs : Dict.Dict Evergreen.V14.Wiki.Slug (Dict.Dict String (RemoteData.RemoteData () (Result Evergreen.V14.WikiAuditLog.Error (List Evergreen.V14.WikiAuditLog.AuditEvent))))
    }

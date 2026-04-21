module Evergreen.V2.Store exposing (..)

import Dict
import Evergreen.V2.Page
import Evergreen.V2.Submission
import Evergreen.V2.SubmissionReviewDetail
import Evergreen.V2.Wiki
import Evergreen.V2.WikiAdminUsers
import Evergreen.V2.WikiAuditLog
import RemoteData


type alias Store =
    { wikiCatalog : RemoteData.RemoteData () (Dict.Dict Evergreen.V2.Wiki.Slug Evergreen.V2.Wiki.CatalogEntry)
    , wikiDetails : Dict.Dict Evergreen.V2.Wiki.Slug (RemoteData.RemoteData () Evergreen.V2.Wiki.FrontendDetails)
    , publishedPages : Dict.Dict ( Evergreen.V2.Wiki.Slug, Evergreen.V2.Page.Slug ) (RemoteData.RemoteData () Evergreen.V2.Page.FrontendDetails)
    , reviewQueues : Dict.Dict Evergreen.V2.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V2.Submission.ReviewQueueError (List Evergreen.V2.Submission.ReviewQueueItem)))
    , myPendingSubmissions : Dict.Dict Evergreen.V2.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V2.Submission.MyPendingSubmissionsError (List Evergreen.V2.Submission.MyPendingSubmissionListItem)))
    , submissionDetails : Dict.Dict ( Evergreen.V2.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V2.Submission.DetailsError Evergreen.V2.Submission.ContributorView))
    , reviewSubmissionDetails : Dict.Dict ( Evergreen.V2.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V2.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V2.SubmissionReviewDetail.SubmissionReviewDetail))
    , wikiUsers : Dict.Dict Evergreen.V2.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V2.WikiAdminUsers.Error (List Evergreen.V2.WikiAdminUsers.ListedUser)))
    , wikiAuditLogs : Dict.Dict Evergreen.V2.Wiki.Slug (Dict.Dict String (RemoteData.RemoteData () (Result Evergreen.V2.WikiAuditLog.Error (List Evergreen.V2.WikiAuditLog.AuditEvent))))
    }

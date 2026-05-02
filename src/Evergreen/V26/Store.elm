module Evergreen.V26.Store exposing (..)

import Dict
import Evergreen.V26.Page
import Evergreen.V26.Submission
import Evergreen.V26.SubmissionReviewDetail
import Evergreen.V26.Wiki
import Evergreen.V26.WikiAdminUsers
import Evergreen.V26.WikiAuditLog
import Evergreen.V26.WikiTodos
import RemoteData


type alias Store =
    { wikiCatalog : RemoteData.RemoteData () (Dict.Dict Evergreen.V26.Wiki.Slug Evergreen.V26.Wiki.CatalogEntry)
    , wikiDetails : Dict.Dict Evergreen.V26.Wiki.Slug (RemoteData.RemoteData () Evergreen.V26.Wiki.FrontendDetails)
    , publishedPages : Dict.Dict ( Evergreen.V26.Wiki.Slug, Evergreen.V26.Page.Slug ) (RemoteData.RemoteData () Evergreen.V26.Page.FrontendDetails)
    , reviewQueues : Dict.Dict Evergreen.V26.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V26.Submission.ReviewQueueError (List Evergreen.V26.Submission.ReviewQueueItem)))
    , myPendingSubmissions : Dict.Dict Evergreen.V26.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V26.Submission.MyPendingSubmissionsError (List Evergreen.V26.Submission.MyPendingSubmissionListItem)))
    , submissionDetails : Dict.Dict ( Evergreen.V26.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V26.Submission.DetailsError Evergreen.V26.Submission.ContributorView))
    , reviewSubmissionDetails : Dict.Dict ( Evergreen.V26.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V26.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V26.SubmissionReviewDetail.SubmissionReviewDetail))
    , wikiUsers : Dict.Dict Evergreen.V26.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V26.WikiAdminUsers.Error (List Evergreen.V26.WikiAdminUsers.ListedUser)))
    , wikiAuditLogs : Dict.Dict Evergreen.V26.Wiki.Slug (Dict.Dict String (RemoteData.RemoteData () (Result Evergreen.V26.WikiAuditLog.Error (List Evergreen.V26.WikiAuditLog.AuditEvent))))
    , wikiTodos : Dict.Dict Evergreen.V26.Wiki.Slug (RemoteData.RemoteData () (Result () (List Evergreen.V26.WikiTodos.TableRow)))
    }

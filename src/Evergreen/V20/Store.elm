module Evergreen.V20.Store exposing (..)

import Dict
import Evergreen.V20.Page
import Evergreen.V20.Submission
import Evergreen.V20.SubmissionReviewDetail
import Evergreen.V20.Wiki
import Evergreen.V20.WikiAdminUsers
import Evergreen.V20.WikiAuditLog
import Evergreen.V20.WikiTodos
import RemoteData


type alias Store =
    { wikiCatalog : RemoteData.RemoteData () (Dict.Dict Evergreen.V20.Wiki.Slug Evergreen.V20.Wiki.CatalogEntry)
    , wikiDetails : Dict.Dict Evergreen.V20.Wiki.Slug (RemoteData.RemoteData () Evergreen.V20.Wiki.FrontendDetails)
    , publishedPages : Dict.Dict ( Evergreen.V20.Wiki.Slug, Evergreen.V20.Page.Slug ) (RemoteData.RemoteData () Evergreen.V20.Page.FrontendDetails)
    , reviewQueues : Dict.Dict Evergreen.V20.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V20.Submission.ReviewQueueError (List Evergreen.V20.Submission.ReviewQueueItem)))
    , myPendingSubmissions : Dict.Dict Evergreen.V20.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V20.Submission.MyPendingSubmissionsError (List Evergreen.V20.Submission.MyPendingSubmissionListItem)))
    , submissionDetails : Dict.Dict ( Evergreen.V20.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V20.Submission.DetailsError Evergreen.V20.Submission.ContributorView))
    , reviewSubmissionDetails : Dict.Dict ( Evergreen.V20.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V20.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V20.SubmissionReviewDetail.SubmissionReviewDetail))
    , wikiUsers : Dict.Dict Evergreen.V20.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V20.WikiAdminUsers.Error (List Evergreen.V20.WikiAdminUsers.ListedUser)))
    , wikiAuditLogs : Dict.Dict Evergreen.V20.Wiki.Slug (Dict.Dict String (RemoteData.RemoteData () (Result Evergreen.V20.WikiAuditLog.Error (List Evergreen.V20.WikiAuditLog.AuditEvent))))
    , wikiTodos : Dict.Dict Evergreen.V20.Wiki.Slug (RemoteData.RemoteData () (Result () (List Evergreen.V20.WikiTodos.TableRow)))
    }

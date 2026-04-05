module Submission exposing
    ( ApproveSubmissionError(..)
    , ContributorSubmissionKind(..)
    , ContributorView
    , DeleteMySubmissionError(..)
    , DeletePageBody
    , DeletePublishedPageImmediatelyError(..)
    , DeleteReasonError(..)
    , DetailsError(..)
    , EditConflictContext
    , EditPageBody
    , EditSubmitSuccess(..)
    , Id
    , Kind(..)
    , MyPendingSubmissionListItem
    , MyPendingSubmissionsError(..)
    , NewPageBody
    , NewPageSubmitSuccess(..)
    , PageDeleteFormError(..)
    , PageDeleteFormSuccess(..)
    , PageDeletionPreconditionError(..)
    , RejectReasonError(..)
    , RejectSubmissionError(..)
    , RequestChangesSubmissionError(..)
    , RequestPublishedPageDeletionError(..)
    , ReviewQueueError(..)
    , ReviewQueueItem
    , SaveNewPageDraftError(..)
    , SavePageDeleteDraftError(..)
    , SavePageEditDraftError(..)
    , Status(..)
    , Submission
    , SubmitDraftForReviewError(..)
    , SubmitNewPageError(..)
    , SubmitPageEditError(..)
    , ValidationError(..)
    , WithdrawSubmissionError(..)
    , applyApprovedSubmission
    , approveSubmissionErrorToUserText
    , contributorViewFromSubmission
    , deleteReasonErrorToUserText
    , currentPublishedRevision
    , deleteMySubmissionErrorToUserText
    , detailsErrorToUserText
    , idFromCounter
    , idFromKey
    , idToString
    , isStalePendingEditSubmission
    , kindSummaryUserText
    , markStalePendingEditNeedsRevision
    , mayContributorDeleteSubmission
    , myPendingSubmissionListItemFromSubmission
    , myPendingSubmissionsErrorToUserText
    , mySubmissionsForAuthorOnWiki
    , pageDeleteFormErrorToUserText
    , pageSlugConstraintTitle
    , pageSlugFromKind
    , pageSlugHtmlMaxLength
    , pageSlugHtmlPattern
    , pendingEditForAuthorOnPageInUse
    , pendingNewPageSlugBlocksTrustedPublish
    , pendingNewPageSlugInUse
    , pendingNewPageSlugInUseExcept
    , pendingSubmissionsForWiki
    , promoteDraftToPending
    , rejectPendingSubmission
    , rejectReasonMaxLength
    , rejectSubmissionErrorToUserText
    , remapWikiSlugInSubmissions
    , removeAuthorDraftNewPageSubmissionsForSlug
    , requestChangesSubmissionErrorToUserText
    , requestPendingSubmissionChanges
    , reviewQueueErrorToUserText
    , reviewQueueItemFromSubmission
    , reviewerNoteForDisplay
    , saveNewPageDraftErrorToUserText
    , savePageDeleteDraftErrorToUserText
    , savePageEditDraftErrorToUserText
    , statusLabelUserText
    , submitDraftForReviewErrorToUserText
    , submitNewPageErrorToUserText
    , submitPageEditErrorToUserText
    , validateDeleteReason
    , validateDeleteReasonRequired
    , validateEditMarkdown
    , validateEditMarkdownDraft
    , validateNewPageDraftFields
    , validateNewPageFields
    , validatePageSlug
    , validateRejectReason
    , validationErrorToUserText
    , wikiHasPublishedPage
    , withdrawSubmissionErrorToUserText
    , withdrawSubmissionToDraft
    )

import ContributorAccount
import Dict exposing (Dict)
import Page
import Wiki


{-| Opaque server-issued submission id (string wire format).
-}
type Id
    = Id String


idToString : Id -> String
idToString (Id s) =
    s


{-| Sequential opaque ids from backend counter (not derived from payload).
-}
idFromCounter : Int -> Id
idFromCounter n =
    Id ("sub_" ++ String.fromInt n)


{-| Opaque id from URL segment or seed key (distinct from counter-based ids).
-}
idFromKey : String -> Id
idFromKey s =
    Id s


idEquals : Id -> Id -> Bool
idEquals (Id a) (Id b) =
    a == b


type Status
    = Draft
    | Pending
    | Approved
    | Rejected
    | NeedsRevision


statusLabelUserText : Status -> String
statusLabelUserText status =
    case status of
        Draft ->
            "Draft"

        Pending ->
            "Pending review"

        Approved ->
            "Approved"

        Rejected ->
            "Rejected"

        NeedsRevision ->
            "Needs revision"


kindSummaryUserText : Kind -> String
kindSummaryUserText kind =
    case kind of
        NewPage body ->
            "New page: " ++ body.pageSlug

        EditPage body ->
            "Edit page: " ++ body.pageSlug

        DeletePage body ->
            "Delete page: " ++ body.pageSlug


type DetailsError
    = DetailsNotLoggedIn
    | DetailsWrongWikiSession
    | DetailsWikiInactive
    | DetailsNotFound
    | DetailsForbidden


detailsErrorToUserText : DetailsError -> String
detailsErrorToUserText err =
    case err of
        DetailsNotLoggedIn ->
            "Log in on this wiki to view this submission."

        DetailsWrongWikiSession ->
            "Your session is for a different wiki. Log in again on this wiki."

        DetailsWikiInactive ->
            "This wiki is currently paused."

        DetailsNotFound ->
            "That submission was not found."

        DetailsForbidden ->
            "You cannot view this submission."


{-| Which contribution shape this submission uses (for client save/submit wiring).
-}
type ContributorSubmissionKind
    = ContributorKindNewPage
    | ContributorKindEditPage
    | ContributorKindDeletePage


{-| Payload for contributor submission detail.
Optional reviewer feedback when status is Rejected or NeedsRevision.
Compare columns: original vs proposed (or placeholder for new pages / delete reasons).
-}
type alias ContributorView =
    { id : Id
    , status : Status
    , kindSummary : String
    , contributionKind : ContributorSubmissionKind
    , reviewerNote : Maybe String
    , conflictContext : Maybe EditConflictContext
    , compareOriginalMarkdown : String
    , compareNewMarkdown : String
    , maybeNewPageSlug : Maybe Page.Slug
    , maybeEditPageSlug : Maybe Page.Slug
    }


type alias EditConflictContext =
    { pageSlug : Page.Slug
    , baseMarkdown : String
    , baseRevision : Int
    , proposedMarkdown : String
    , currentMarkdown : String
    , currentRevision : Int
    }


{-| Trim reviewer note for display; Nothing when missing or whitespace-only.
-}
reviewerNoteForDisplay : Maybe String -> Maybe String
reviewerNoteForDisplay maybeRaw =
    case maybeRaw of
        Nothing ->
            Nothing

        Just raw ->
            let
                trimmed : String
                trimmed =
                    String.trim raw
            in
            if String.isEmpty trimmed then
                Nothing

            else
                Just trimmed


contributorViewFromSubmission : Maybe Wiki.Wiki -> Submission -> ContributorView
contributorViewFromSubmission maybeWiki sub =
    let
        fromKind :
            { original : String
            , new_ : String
            , maybeNewSlug : Maybe Page.Slug
            , maybeEditSlug : Maybe Page.Slug
            , ck : ContributorSubmissionKind
            , conflict : Maybe EditConflictContext
            }
        fromKind =
            case sub.kind of
                NewPage body ->
                    { original = "(No published page yet.)"
                    , new_ = body.markdown
                    , maybeNewSlug = Just body.pageSlug
                    , maybeEditSlug = Nothing
                    , ck = ContributorKindNewPage
                    , conflict = Nothing
                    }

                EditPage body ->
                    { original = body.baseMarkdown
                    , new_ = body.proposedMarkdown
                    , maybeNewSlug = Nothing
                    , maybeEditSlug = Just body.pageSlug
                    , ck = ContributorKindEditPage
                    , conflict =
                        Just
                            { pageSlug = body.pageSlug
                            , baseMarkdown = body.baseMarkdown
                            , baseRevision = body.baseRevision
                            , proposedMarkdown = body.proposedMarkdown
                            , currentMarkdown =
                                maybeWiki
                                    |> Maybe.map (\wiki -> currentPublishedMarkdown wiki body.pageSlug)
                                    |> Maybe.withDefault body.baseMarkdown
                            , currentRevision =
                                maybeWiki
                                    |> Maybe.andThen (\wiki -> currentPublishedRevision wiki body.pageSlug)
                                    |> Maybe.withDefault body.baseRevision
                            }
                    }

                DeletePage body ->
                    { original =
                        maybeWiki
                            |> Maybe.map (\wiki -> currentPublishedMarkdown wiki body.pageSlug)
                            |> Maybe.withDefault "(Page not found.)"
                    , new_ =
                        body.reason
                            |> Maybe.withDefault "(No reason given.)"
                    , maybeNewSlug = Nothing
                    , maybeEditSlug = Just body.pageSlug
                    , ck = ContributorKindDeletePage
                    , conflict = Nothing
                    }
    in
    { id = sub.id
    , status = sub.status
    , kindSummary = kindSummaryUserText sub.kind
    , contributionKind = fromKind.ck
    , reviewerNote = reviewerNoteForDisplay sub.reviewerNote
    , conflictContext = fromKind.conflict
    , compareOriginalMarkdown = fromKind.original
    , compareNewMarkdown = fromKind.new_
    , maybeNewPageSlug = fromKind.maybeNewSlug
    , maybeEditPageSlug = fromKind.maybeEditSlug
    }


{-| Trusted-only review queue.
-}
type ReviewQueueError
    = ReviewQueueNotLoggedIn
    | ReviewQueueWrongWikiSession
    | ReviewQueueForbidden
    | ReviewQueueWikiInactive


reviewQueueErrorToUserText : ReviewQueueError -> String
reviewQueueErrorToUserText err =
    case err of
        ReviewQueueNotLoggedIn ->
            "Log in on this wiki to open the review queue."

        ReviewQueueWrongWikiSession ->
            "Your session is for a different wiki. Log in again on this wiki."

        ReviewQueueForbidden ->
            "You do not have access to the review queue."

        ReviewQueueWikiInactive ->
            "This wiki is currently paused."


{-| Summary row for moderators.
-}
type alias ReviewQueueItem =
    { id : Id
    , kindLabel : String
    , authorDisplay : String
    , maybePageSlug : Maybe Page.Slug
    }


pageSlugFromKind : Kind -> Maybe Page.Slug
pageSlugFromKind kind =
    case kind of
        NewPage body ->
            Just body.pageSlug

        EditPage body ->
            Just body.pageSlug

        DeletePage body ->
            Just body.pageSlug


{-| Submissions awaiting review for one wiki (pure).
-}
pendingSubmissionsForWiki : Wiki.Slug -> Dict String Submission -> List Submission
pendingSubmissionsForWiki wikiSlug submissions =
    submissions
        |> Dict.values
        |> List.filter
            (\sub ->
                sub.wikiSlug == wikiSlug && sub.status == Pending
            )
        |> List.sortBy (\sub -> idToString sub.id)


{-| After a hosted wiki slug rename: point submissions and embedded author ids at the new slug.
-}
remapWikiSlugInSubmissions : Wiki.Slug -> Wiki.Slug -> Dict String Submission -> Dict String Submission
remapWikiSlugInSubmissions oldSlug newSlug submissions =
    Dict.map
        (\_ sub ->
            if sub.wikiSlug == oldSlug then
                { sub
                    | wikiSlug = newSlug
                    , authorId = ContributorAccount.remapIdForWikiSlug oldSlug newSlug sub.authorId
                }

            else
                sub
        )
        submissions


authorDisplayForReviewQueue : (ContributorAccount.Id -> Maybe String) -> ContributorAccount.Id -> String
authorDisplayForReviewQueue lookupUsername accountId =
    lookupUsername accountId
        |> Maybe.withDefault (ContributorAccount.idToString accountId)


reviewQueueItemFromSubmission : (ContributorAccount.Id -> Maybe String) -> Submission -> ReviewQueueItem
reviewQueueItemFromSubmission lookupAuthor sub =
    { id = sub.id
    , kindLabel = kindSummaryUserText sub.kind
    , authorDisplay = authorDisplayForReviewQueue lookupAuthor sub.authorId
    , maybePageSlug = pageSlugFromKind sub.kind
    }


{-| Contributor-only list of submissions still awaiting review on one wiki.
-}
type MyPendingSubmissionsError
    = MyPendingSubmissionsNotLoggedIn
    | MyPendingSubmissionsWrongWikiSession
    | MyPendingSubmissionsWikiInactive
    | MyPendingSubmissionsForbiddenTrustedModerator


myPendingSubmissionsErrorToUserText : MyPendingSubmissionsError -> String
myPendingSubmissionsErrorToUserText err =
    case err of
        MyPendingSubmissionsNotLoggedIn ->
            "Log in on this wiki to see your submissions waiting for review."

        MyPendingSubmissionsWrongWikiSession ->
            "Your session is for a different wiki. Log in again on this wiki."

        MyPendingSubmissionsWikiInactive ->
            "This wiki is currently paused."

        MyPendingSubmissionsForbiddenTrustedModerator ->
            "Trusted moderators and wiki admins publish directly; the My Submissions list is only for standard contributors."


type alias MyPendingSubmissionListItem =
    { id : Id
    , status : Status
    , statusLabel : String
    , kindLabel : String
    , maybePageSlug : Maybe Page.Slug
    }


{-| Submissions listed on the contributor **My submissions** page: pending review, needs revision, or rejected (excludes approved).
-}
mySubmissionsForAuthorOnWiki : Wiki.Slug -> ContributorAccount.Id -> Dict String Submission -> List Submission
mySubmissionsForAuthorOnWiki wikiSlug authorId submissions =
    let
        listedStatus : Status -> Bool
        listedStatus status =
            case status of
                Draft ->
                    True

                Pending ->
                    True

                NeedsRevision ->
                    True

                Rejected ->
                    True

                Approved ->
                    False
    in
    submissions
        |> Dict.values
        |> List.filter
            (\sub ->
                sub.wikiSlug == wikiSlug && sub.authorId == authorId && listedStatus sub.status
            )
        |> List.sortBy (\sub -> idToString sub.id)


myPendingSubmissionListItemFromSubmission : Submission -> MyPendingSubmissionListItem
myPendingSubmissionListItemFromSubmission sub =
    { id = sub.id
    , status = sub.status
    , statusLabel = statusLabelUserText sub.status
    , kindLabel = kindSummaryUserText sub.kind
    , maybePageSlug = pageSlugFromKind sub.kind
    }


{-| Trusted approval of a pending submission.
-}
type ApproveSubmissionError
    = ApproveNotLoggedIn
    | ApproveWrongWikiSession
    | ApproveForbidden
    | ApproveWikiNotFound
    | ApproveWikiInactive
    | ApproveSubmissionNotFound
    | ApproveNotPending
    | ApproveNewPageSlugTaken
    | ApproveEditTargetNotPublished
    | ApproveDeleteTargetNotPublished


{-| Moderator rejection reason: trimmed, non-empty, bounded length.
-}
type RejectReasonError
    = RejectReasonEmpty
    | RejectReasonTooLong


rejectReasonMaxLength : Int
rejectReasonMaxLength =
    2000


rejectReasonErrorToUserText : RejectReasonError -> String
rejectReasonErrorToUserText err =
    case err of
        RejectReasonEmpty ->
            "Enter a reason for rejecting this submission."

        RejectReasonTooLong ->
            "Rejection reason must be at most 2000 characters."


validateRejectReason : String -> Result RejectReasonError String
validateRejectReason raw =
    let
        trimmed : String
        trimmed =
            String.trim raw
    in
    if String.isEmpty trimmed then
        Err RejectReasonEmpty

    else if String.length trimmed > rejectReasonMaxLength then
        Err RejectReasonTooLong

    else
        Ok trimmed


{-| Trusted rejection of a pending submission; wiki content unchanged.
-}
type RejectSubmissionError
    = RejectNotLoggedIn
    | RejectWrongWikiSession
    | RejectForbidden
    | RejectWikiNotFound
    | RejectWikiInactive
    | RejectSubmissionNotFound
    | RejectNotPending
    | RejectReasonInvalid RejectReasonError


rejectSubmissionErrorToUserText : RejectSubmissionError -> String
rejectSubmissionErrorToUserText err =
    case err of
        RejectNotLoggedIn ->
            "Log in on this wiki to reject submissions."

        RejectWrongWikiSession ->
            "Your session is for a different wiki. Log in again on this wiki."

        RejectForbidden ->
            "You do not have permission to reject submissions."

        RejectWikiNotFound ->
            "This wiki does not exist."

        RejectWikiInactive ->
            "This wiki is currently paused."

        RejectSubmissionNotFound ->
            "That submission was not found."

        RejectNotPending ->
            "That submission is no longer pending review."

        RejectReasonInvalid e ->
            rejectReasonErrorToUserText e


{-| Pure: mark pending submission rejected with validated reason.
-}
rejectPendingSubmission : String -> Submission -> Result RejectSubmissionError Submission
rejectPendingSubmission rawReason sub =
    if sub.status /= Pending then
        Err RejectNotPending

    else
        case validateRejectReason rawReason of
            Err e ->
                Err (RejectReasonInvalid e)

            Ok note ->
                Ok
                    { sub
                        | status = Rejected
                        , reviewerNote = Just note
                    }


{-| Trusted request for revision; wiki content unchanged.
-}
type RequestChangesSubmissionError
    = RequestChangesNotLoggedIn
    | RequestChangesWrongWikiSession
    | RequestChangesForbidden
    | RequestChangesWikiNotFound
    | RequestChangesWikiInactive
    | RequestChangesSubmissionNotFound
    | RequestChangesNotPending
    | RequestChangesGuidanceInvalid RejectReasonError


requestChangesSubmissionErrorToUserText : RequestChangesSubmissionError -> String
requestChangesSubmissionErrorToUserText err =
    case err of
        RequestChangesNotLoggedIn ->
            "Log in on this wiki to request changes."

        RequestChangesWrongWikiSession ->
            "Your session is for a different wiki. Log in again on this wiki."

        RequestChangesForbidden ->
            "You do not have permission to request changes on submissions."

        RequestChangesWikiNotFound ->
            "This wiki does not exist."

        RequestChangesWikiInactive ->
            "This wiki is currently paused."

        RequestChangesSubmissionNotFound ->
            "That submission was not found."

        RequestChangesNotPending ->
            "That submission is no longer pending review."

        RequestChangesGuidanceInvalid e ->
            case e of
                RejectReasonEmpty ->
                    "Enter guidance for the contributor."

                RejectReasonTooLong ->
                    "Guidance must be at most 2000 characters."


{-| Pure: mark pending submission as needing revision with validated guidance note.
-}
requestPendingSubmissionChanges : String -> Submission -> Result RequestChangesSubmissionError Submission
requestPendingSubmissionChanges rawGuidance sub =
    if sub.status /= Pending then
        Err RequestChangesNotPending

    else
        case validateRejectReason rawGuidance of
            Err e ->
                Err (RequestChangesGuidanceInvalid e)

            Ok note ->
                Ok
                    { sub
                        | status = NeedsRevision
                        , reviewerNote = Just note
                    }


approveSubmissionErrorToUserText : ApproveSubmissionError -> String
approveSubmissionErrorToUserText err =
    case err of
        ApproveNotLoggedIn ->
            "Log in on this wiki to approve submissions."

        ApproveWrongWikiSession ->
            "Your session is for a different wiki. Log in again on this wiki."

        ApproveForbidden ->
            "You do not have permission to approve submissions."

        ApproveWikiNotFound ->
            "This wiki does not exist."

        ApproveWikiInactive ->
            "This wiki is currently paused."

        ApproveSubmissionNotFound ->
            "That submission was not found."

        ApproveNotPending ->
            "That submission is no longer pending review."

        ApproveNewPageSlugTaken ->
            "A published page already uses this slug; approve the submission only when the slug is free."

        ApproveEditTargetNotPublished ->
            "The target page does not exist or has no published content yet."

        ApproveDeleteTargetNotPublished ->
            "The target page does not exist or has no published content yet."


{-| Apply wiki mutation and mark submission approved. `wiki` is the current wiki state for `sub.wikiSlug`.
-}
applyApprovedSubmission : Wiki.Wiki -> Submission -> Result ApproveSubmissionError { wiki : Wiki.Wiki, submission : Submission }
applyApprovedSubmission wiki sub =
    if sub.status /= Pending then
        Err ApproveNotPending

    else
        case sub.kind of
            NewPage body ->
                if Dict.member body.pageSlug wiki.pages then
                    Err ApproveNewPageSlugTaken

                else
                    Ok
                        { wiki = Wiki.publishNewPageOnWiki body wiki
                        , submission =
                            { sub
                                | status = Approved
                                , reviewerNote = Nothing
                            }
                        }

            EditPage body ->
                if not (wikiHasPublishedPage body.pageSlug wiki) then
                    Err ApproveEditTargetNotPublished

                else
                    Ok
                        { wiki = Wiki.applyPublishedMarkdownEdit body.pageSlug body.proposedMarkdown wiki
                        , submission =
                            { sub
                                | status = Approved
                                , reviewerNote = Nothing
                            }
                        }

            DeletePage body ->
                if not (wikiHasPublishedPage body.pageSlug wiki) then
                    Err ApproveDeleteTargetNotPublished

                else
                    Ok
                        { wiki = Wiki.removePublishedPage body.pageSlug wiki
                        , submission =
                            { sub
                                | status = Approved
                                , reviewerNote = Nothing
                            }
                        }


type alias NewPageBody =
    { pageSlug : Page.Slug
    , markdown : String
    }


type alias EditPageBody =
    { pageSlug : Page.Slug
    , baseMarkdown : String
    , baseRevision : Int
    , proposedMarkdown : String
    }


type alias DeletePageBody =
    { pageSlug : Page.Slug
    , reason : Maybe String
    }


type Kind
    = NewPage NewPageBody
    | EditPage EditPageBody
    | DeletePage DeletePageBody


type alias Submission =
    { id : Id
    , wikiSlug : Wiki.Slug
    , authorId : ContributorAccount.Id
    , kind : Kind
    , status : Status
    , reviewerNote : Maybe String
    }


type ValidationError
    = SlugEmpty
    | SlugTooLong
    | SlugInvalidChars
    | BodyEmpty


validationErrorToUserText : ValidationError -> String
validationErrorToUserText err =
    case err of
        SlugEmpty ->
            "Enter a page slug."

        SlugTooLong ->
            "Page slug must be at most 64 characters."

        SlugInvalidChars ->
            "Page slug must be PascalCase letters and digits only."

        BodyEmpty ->
            "Enter page content (markdown)."


type SubmitNewPageError
    = NotLoggedIn
    | WrongWikiSession
    | WikiNotFound
    | WikiInactive
    | Validation ValidationError
    | SlugAlreadyInUse


{-| Trusted contributors publish immediately; standard contributors get a pending submission id.
-}
type NewPageSubmitSuccess
    = NewPagePublishedImmediately
    | NewPageSubmittedForReview Id


submitNewPageErrorToUserText : SubmitNewPageError -> String
submitNewPageErrorToUserText err =
    case err of
        NotLoggedIn ->
            "You must be logged in to submit a page."

        WrongWikiSession ->
            "Your session is for a different wiki. Log in again on this wiki."

        WikiNotFound ->
            "This wiki does not exist."

        WikiInactive ->
            "This wiki is currently paused."

        Validation e ->
            validationErrorToUserText e

        SlugAlreadyInUse ->
            "A page or pending submission already uses this slug."


type SubmitPageEditError
    = EditNotLoggedIn
    | EditWrongWikiSession
    | EditWikiNotFound
    | EditWikiInactive
    | EditValidation ValidationError
    | EditTargetPageNotPublished
    | EditAlreadyPendingForAuthor


type EditSubmitSuccess
    = EditPublishedImmediately
    | EditSubmittedForReview Id


submitPageEditErrorToUserText : SubmitPageEditError -> String
submitPageEditErrorToUserText err =
    case err of
        EditNotLoggedIn ->
            "You must be logged in to submit an edit."

        EditWrongWikiSession ->
            "Your session is for a different wiki. Log in again on this wiki."

        EditWikiNotFound ->
            "This wiki does not exist."

        EditWikiInactive ->
            "This wiki is currently paused."

        EditValidation e ->
            validationErrorToUserText e

        EditTargetPageNotPublished ->
            "That page does not exist or has no published content yet."

        EditAlreadyPendingForAuthor ->
            "You already have a pending edit for this page."


type DeleteReasonError
    = ReasonRequired
    | ReasonTooLong


deleteReasonMaxLength : Int
deleteReasonMaxLength =
    2000


deleteReasonErrorToUserText : DeleteReasonError -> String
deleteReasonErrorToUserText err =
    case err of
        ReasonRequired ->
            "A deletion reason is required."

        ReasonTooLong ->
            "Reason must be at most 2000 characters."


{-| Optional moderator-facing reason; empty or whitespace-only becomes Nothing.
-}
validateDeleteReason : String -> Result DeleteReasonError (Maybe String)
validateDeleteReason raw =
    let
        trimmed : String
        trimmed =
            String.trim raw
    in
    if String.isEmpty trimmed then
        Ok Nothing

    else if String.length trimmed > deleteReasonMaxLength then
        Err ReasonTooLong

    else
        Ok (Just trimmed)


{-| Required for trusted immediate page removal; trimmed non-empty string within max length.
-}
validateDeleteReasonRequired : String -> Result DeleteReasonError String
validateDeleteReasonRequired raw =
    let
        trimmed : String
        trimmed =
            String.trim raw
    in
    if String.isEmpty trimmed then
        Err ReasonRequired

    else if String.length trimmed > deleteReasonMaxLength then
        Err ReasonTooLong

    else
        Ok trimmed


{-| Shared validation failures before applying a page-deletion intent (request vs immediate).
-}
type PageDeletionPreconditionError
    = PageDeletionNotLoggedIn
    | PageDeletionWrongWikiSession
    | PageDeletionWikiNotFound
    | PageDeletionWikiInactive
    | PageDeletionValidation DeleteReasonError
    | PageDeletionTargetNotPublished


pageDeletionPreconditionForRequestToUserText : PageDeletionPreconditionError -> String
pageDeletionPreconditionForRequestToUserText err =
    case err of
        PageDeletionNotLoggedIn ->
            "You must be logged in to request a page deletion."

        PageDeletionWrongWikiSession ->
            "Your session is for a different wiki. Log in again on this wiki."

        PageDeletionWikiNotFound ->
            "This wiki does not exist."

        PageDeletionWikiInactive ->
            "This wiki is currently paused."

        PageDeletionValidation e ->
            deleteReasonErrorToUserText e

        PageDeletionTargetNotPublished ->
            "That page does not exist or has no published content yet."


pageDeletionPreconditionForImmediateDeleteToUserText : PageDeletionPreconditionError -> String
pageDeletionPreconditionForImmediateDeleteToUserText err =
    case err of
        PageDeletionNotLoggedIn ->
            "You must be logged in to remove a published page."

        PageDeletionWrongWikiSession ->
            "Your session is for a different wiki. Log in again on this wiki."

        PageDeletionWikiNotFound ->
            "This wiki does not exist."

        PageDeletionWikiInactive ->
            "This wiki is currently paused."

        PageDeletionValidation e ->
            deleteReasonErrorToUserText e

        PageDeletionTargetNotPublished ->
            "That page does not exist or has no published content yet."


{-| `RequestPublishedPageDeletion` ToBackend: untrusted contributors only (pending delete submission).
-}
type RequestPublishedPageDeletionError
    = RequestPublishedPageDeletionPrecondition PageDeletionPreconditionError
    | RequestPublishedPageDeletionForbiddenTrustedModerator
    | RequestPublishedPageDeletionSubmitDraftStepFailed SubmitDraftForReviewError


requestPublishedPageDeletionErrorToUserText : RequestPublishedPageDeletionError -> String
requestPublishedPageDeletionErrorToUserText err =
    case err of
        RequestPublishedPageDeletionPrecondition e ->
            pageDeletionPreconditionForRequestToUserText e

        RequestPublishedPageDeletionForbiddenTrustedModerator ->
            "Trusted contributors and wiki admins remove pages immediately; use delete, not request deletion."

        RequestPublishedPageDeletionSubmitDraftStepFailed e ->
            submitDraftForReviewErrorToUserText e


{-| `DeletePublishedPageImmediately` ToBackend: trusted contributors and wiki admins only.
-}
type DeletePublishedPageImmediatelyError
    = DeletePublishedPageImmediatelyPrecondition PageDeletionPreconditionError
    | DeletePublishedPageImmediatelyForbiddenUntrustedContributor


deletePublishedPageImmediatelyErrorToUserText : DeletePublishedPageImmediatelyError -> String
deletePublishedPageImmediatelyErrorToUserText err =
    case err of
        DeletePublishedPageImmediatelyPrecondition e ->
            pageDeletionPreconditionForImmediateDeleteToUserText e

        DeletePublishedPageImmediatelyForbiddenUntrustedContributor ->
            "Request deletion so a trusted contributor can review; only trusted contributors and wiki admins may remove a page immediately."


{-| Form state after either deletion path returns from the backend.
-}
type PageDeleteFormError
    = PageDeleteRequestFailed RequestPublishedPageDeletionError
    | PageDeleteImmediateFailed DeletePublishedPageImmediatelyError


pageDeleteFormErrorToUserText : PageDeleteFormError -> String
pageDeleteFormErrorToUserText err =
    case err of
        PageDeleteRequestFailed e ->
            requestPublishedPageDeletionErrorToUserText e

        PageDeleteImmediateFailed e ->
            deletePublishedPageImmediatelyErrorToUserText e


type PageDeleteFormSuccess
    = DeletePublishedImmediately
    | DeleteSubmittedForReview Id


{-| True when the wiki has a page key with published markdown (same rule as public page reads).
-}
wikiHasPublishedPage : Page.Slug -> Wiki.Wiki -> Bool
wikiHasPublishedPage pageSlug wiki =
    case Dict.get pageSlug wiki.pages of
        Nothing ->
            False

        Just page ->
            Page.hasPublished page


{-| Proposed replacement markdown for an edit submission (trimmed); body must be non-empty.
-}
validateEditMarkdown : String -> Result ValidationError String
validateEditMarkdown rawMarkdown =
    let
        markdown : String
        markdown =
            String.trim rawMarkdown
    in
    if String.isEmpty markdown then
        Err BodyEmpty

    else
        Ok markdown


slugCharsOk : String -> Bool
slugCharsOk s =
    case String.uncons s of
        Nothing ->
            False

        Just ( first, rest ) ->
            Char.isUpper first && String.all Char.isAlphaNum rest


{-| Max length after trim (wiki and page slugs).
-}
pageSlugMaxLength : Int
pageSlugMaxLength =
    64


{-| HTML [`pattern`](https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/pattern) for constraint validation.
Uses implicit full-string anchoring; allows optional surrounding ASCII whitespace so values still align with `String.trim` in `validatePageSlug`.
-}
pageSlugHtmlPattern : String
pageSlugHtmlPattern =
    "\\s*[A-Z][A-Za-z0-9]{0,63}\\s*"


{-| Upper bound on raw field length (trimmed slug is at most `pageSlugMaxLength`; allows modest surrounding whitespace).
-}
pageSlugHtmlMaxLength : Int
pageSlugHtmlMaxLength =
    96


{-| Shown as native validation hint (`title`) for pattern mismatches.
-}
pageSlugConstraintTitle : String
pageSlugConstraintTitle =
    "PascalCase: capital first letter, then letters or digits only; at most 64 characters after trimming spaces."


{-| Trim slug before validating.
-}
normalizePageSlug : String -> String
normalizePageSlug raw =
    raw
        |> String.trim


{-| Page slug rules only (trim, length, PascalCase character class). Same rules as hosted wiki slugs.
-}
validatePageSlug : String -> Result ValidationError Page.Slug
validatePageSlug rawSlug =
    let
        pageSlug : String
        pageSlug =
            normalizePageSlug rawSlug
    in
    if String.isEmpty pageSlug then
        Err SlugEmpty

    else if String.length pageSlug > pageSlugMaxLength then
        Err SlugTooLong

    else if not (slugCharsOk pageSlug) then
        Err SlugInvalidChars

    else
        Ok pageSlug


validateNewPageFields : String -> String -> Result ValidationError { pageSlug : Page.Slug, markdown : String }
validateNewPageFields rawSlug rawMarkdown =
    case validatePageSlug rawSlug of
        Err e ->
            Err e

        Ok pageSlug ->
            let
                markdown : String
                markdown =
                    String.trim rawMarkdown
            in
            if String.isEmpty markdown then
                Err BodyEmpty

            else
                Ok { pageSlug = pageSlug, markdown = markdown }


{-| Draft save: slug rules apply; markdown may be empty.
-}
validateNewPageDraftFields : String -> String -> Result ValidationError { pageSlug : Page.Slug, markdown : String }
validateNewPageDraftFields rawSlug rawMarkdown =
    case validatePageSlug rawSlug of
        Err e ->
            Err e

        Ok pageSlug ->
            Ok { pageSlug = pageSlug, markdown = String.trim rawMarkdown }


{-| Draft save: proposed markdown may be empty.
-}
validateEditMarkdownDraft : String -> Result ValidationError String
validateEditMarkdownDraft rawMarkdown =
    Ok (String.trim rawMarkdown)


{-| For trusted `SubmitNewPage`: pending new-page (any author) blocks; another contributor's draft
with that slug blocks; the author's own draft for that slug does not (they are publishing over it).
-}
pendingNewPageSlugBlocksTrustedPublish : ContributorAccount.Id -> Wiki.Slug -> Page.Slug -> Dict String Submission -> Bool
pendingNewPageSlugBlocksTrustedPublish accountId wikiSlug pageSlug submissions =
    submissions
        |> Dict.values
        |> List.any
            (\sub ->
                if sub.wikiSlug /= wikiSlug then
                    False

                else if not (newPageKindUsesSlug pageSlug sub) then
                    False

                else
                    case sub.status of
                        Pending ->
                            True

                        Draft ->
                            sub.authorId /= accountId

                        Approved ->
                            False

                        Rejected ->
                            False

                        NeedsRevision ->
                            False
            )


{-| True when a draft or pending new-page submission already uses this slug on the wiki (any author).
-}
pendingNewPageSlugInUse : Wiki.Slug -> Page.Slug -> Dict String Submission -> Bool
pendingNewPageSlugInUse wikiSlug pageSlug submissions =
    submissions
        |> Dict.values
        |> List.any
            (\sub ->
                if sub.wikiSlug /= wikiSlug then
                    False

                else
                    case sub.status of
                        Pending ->
                            newPageKindUsesSlug pageSlug sub

                        Draft ->
                            newPageKindUsesSlug pageSlug sub

                        Approved ->
                            False

                        Rejected ->
                            False

                        NeedsRevision ->
                            False
            )


newPageKindUsesSlug : Page.Slug -> Submission -> Bool
newPageKindUsesSlug pageSlug sub =
    case sub.kind of
        NewPage body ->
            body.pageSlug == pageSlug

        EditPage _ ->
            False

        DeletePage _ ->
            False


{-| After a trusted author publishes a new page live, drop their draft rows for that slug so
submissions state stays consistent.
-}
removeAuthorDraftNewPageSubmissionsForSlug : ContributorAccount.Id -> Wiki.Slug -> Page.Slug -> Dict String Submission -> Dict String Submission
removeAuthorDraftNewPageSubmissionsForSlug accountId wikiSlug pageSlug submissions =
    submissions
        |> Dict.filter
            (\_ sub ->
                not
                    (sub.wikiSlug
                        == wikiSlug
                        && sub.authorId
                        == accountId
                        && sub.status
                        == Draft
                        && (case sub.kind of
                                NewPage body ->
                                    body.pageSlug == pageSlug

                                EditPage _ ->
                                    False

                                DeletePage _ ->
                                    False
                           )
                    )
            )


{-| Same as `pendingNewPageSlugInUse` but ignores one submission id (e.g. promoting own draft).
-}
pendingNewPageSlugInUseExcept : Maybe Id -> Wiki.Slug -> Page.Slug -> Dict String Submission -> Bool
pendingNewPageSlugInUseExcept maybeExcludeId wikiSlug pageSlug submissions =
    submissions
        |> Dict.toList
        |> List.any
            (\( key, sub ) ->
                case maybeExcludeId of
                    Just ex ->
                        if idEquals (idFromKey key) ex || idEquals sub.id ex then
                            False

                        else
                            sub.wikiSlug == wikiSlug && statusReservesNewPageSlug sub.status && newPageKindUsesSlug pageSlug sub

                    Nothing ->
                        sub.wikiSlug == wikiSlug && statusReservesNewPageSlug sub.status && newPageKindUsesSlug pageSlug sub
            )


statusReservesNewPageSlug : Status -> Bool
statusReservesNewPageSlug status =
    case status of
        Draft ->
            True

        Pending ->
            True

        NeedsRevision ->
            False

        Approved ->
            False

        Rejected ->
            False


pendingEditForAuthorOnPageInUse : Wiki.Slug -> ContributorAccount.Id -> Page.Slug -> Dict String Submission -> Bool
pendingEditForAuthorOnPageInUse wikiSlug authorId pageSlug submissions =
    submissions
        |> Dict.values
        |> List.any
            (\sub ->
                if sub.wikiSlug /= wikiSlug || sub.authorId /= authorId then
                    False

                else
                    case sub.status of
                        Draft ->
                            editKindUsesSlug pageSlug sub

                        Pending ->
                            editKindUsesSlug pageSlug sub

                        Approved ->
                            False

                        Rejected ->
                            False

                        NeedsRevision ->
                            editKindUsesSlug pageSlug sub
            )


editKindUsesSlug : Page.Slug -> Submission -> Bool
editKindUsesSlug pageSlug sub =
    case sub.kind of
        EditPage body ->
            body.pageSlug == pageSlug

        NewPage _ ->
            False

        DeletePage _ ->
            False


pendingEditForAuthorOnPageInUseExcept : Maybe Id -> Wiki.Slug -> ContributorAccount.Id -> Page.Slug -> Dict String Submission -> Bool
pendingEditForAuthorOnPageInUseExcept maybeExcludeId wikiSlug authorId pageSlug submissions =
    submissions
        |> Dict.toList
        |> List.any
            (\( key, sub ) ->
                let
                    excluded : Bool
                    excluded =
                        case maybeExcludeId of
                            Just ex ->
                                idEquals (idFromKey key) ex || idEquals sub.id ex

                            Nothing ->
                                False
                in
                if excluded then
                    False

                else
                    sub.wikiSlug
                        == wikiSlug
                        && sub.authorId
                        == authorId
                        && statusReservesEditSubmission sub.status
                        && editKindUsesSlug pageSlug sub
            )


statusReservesEditSubmission : Status -> Bool
statusReservesEditSubmission status =
    case status of
        Draft ->
            True

        Pending ->
            True

        NeedsRevision ->
            True

        Approved ->
            False

        Rejected ->
            False


currentPublishedRevision : Wiki.Wiki -> Page.Slug -> Maybe Int
currentPublishedRevision wiki pageSlug =
    Dict.get pageSlug wiki.pages
        |> Maybe.andThen
            (\page ->
                if Page.hasPublished page then
                    Just (Page.publishedRevision page)

                else
                    Nothing
            )


currentPublishedMarkdown : Wiki.Wiki -> Page.Slug -> String
currentPublishedMarkdown wiki pageSlug =
    Dict.get pageSlug wiki.pages
        |> Maybe.map Page.publishedMarkdownForLinks
        |> Maybe.withDefault ""


type SaveNewPageDraftError
    = SaveNewPageDraftNotLoggedIn
    | SaveNewPageDraftWrongWikiSession
    | SaveNewPageDraftValidation ValidationError
    | SaveNewPageDraftSlugReserved
    | SaveNewPageDraftNotFound
    | SaveNewPageDraftForbidden
    | SaveNewPageDraftWikiNotFound
    | SaveNewPageDraftWikiInactive


saveNewPageDraftErrorToUserText : SaveNewPageDraftError -> String
saveNewPageDraftErrorToUserText err =
    case err of
        SaveNewPageDraftNotLoggedIn ->
            "You must be logged in to save a draft."

        SaveNewPageDraftWrongWikiSession ->
            "Your session is for a different wiki. Log in again on this wiki."

        SaveNewPageDraftValidation e ->
            validationErrorToUserText e

        SaveNewPageDraftSlugReserved ->
            "Another draft or submission already uses this page slug."

        SaveNewPageDraftNotFound ->
            "That draft was not found."

        SaveNewPageDraftForbidden ->
            "You cannot update this draft."

        SaveNewPageDraftWikiNotFound ->
            "This wiki does not exist."

        SaveNewPageDraftWikiInactive ->
            "This wiki is currently paused."


type SavePageEditDraftError
    = SavePageEditDraftNotLoggedIn
    | SavePageEditDraftWrongWikiSession
    | SavePageEditDraftValidation ValidationError
    | SavePageEditDraftTargetNotPublished
    | SavePageEditDraftAlreadyPendingEdit
    | SavePageEditDraftNotFound
    | SavePageEditDraftForbidden
    | SavePageEditDraftWikiNotFound
    | SavePageEditDraftWikiInactive


savePageEditDraftErrorToUserText : SavePageEditDraftError -> String
savePageEditDraftErrorToUserText err =
    case err of
        SavePageEditDraftNotLoggedIn ->
            "You must be logged in to save a draft."

        SavePageEditDraftWrongWikiSession ->
            "Your session is for a different wiki. Log in again on this wiki."

        SavePageEditDraftValidation e ->
            validationErrorToUserText e

        SavePageEditDraftTargetNotPublished ->
            "That page does not exist or has no published content yet."

        SavePageEditDraftAlreadyPendingEdit ->
            "You already have a draft or pending edit for this page."

        SavePageEditDraftNotFound ->
            "That draft was not found."

        SavePageEditDraftForbidden ->
            "You cannot update this draft."

        SavePageEditDraftWikiNotFound ->
            "This wiki does not exist."

        SavePageEditDraftWikiInactive ->
            "This wiki is currently paused."


type SavePageDeleteDraftError
    = SavePageDeleteDraftNotLoggedIn
    | SavePageDeleteDraftWrongWikiSession
    | SavePageDeleteDraftReasonInvalid DeleteReasonError
    | SavePageDeleteDraftTargetNotPublished
    | SavePageDeleteDraftNotFound
    | SavePageDeleteDraftForbidden
    | SavePageDeleteDraftWikiNotFound
    | SavePageDeleteDraftWikiInactive
    | SavePageDeleteDraftForbiddenTrustedModerator


savePageDeleteDraftErrorToUserText : SavePageDeleteDraftError -> String
savePageDeleteDraftErrorToUserText err =
    case err of
        SavePageDeleteDraftNotLoggedIn ->
            "You must be logged in to save a draft."

        SavePageDeleteDraftWrongWikiSession ->
            "Your session is for a different wiki. Log in again on this wiki."

        SavePageDeleteDraftReasonInvalid e ->
            deleteReasonErrorToUserText e

        SavePageDeleteDraftTargetNotPublished ->
            "That page does not exist or has no published content yet."

        SavePageDeleteDraftNotFound ->
            "That draft was not found."

        SavePageDeleteDraftForbidden ->
            "You cannot update this draft."

        SavePageDeleteDraftWikiNotFound ->
            "This wiki does not exist."

        SavePageDeleteDraftWikiInactive ->
            "This wiki is currently paused."

        SavePageDeleteDraftForbiddenTrustedModerator ->
            "Trusted contributors and wiki admins remove pages directly; deletion drafts are not used."


type WithdrawSubmissionError
    = WithdrawSubmissionNotLoggedIn
    | WithdrawSubmissionWrongWikiSession
    | WithdrawSubmissionWikiNotFound
    | WithdrawSubmissionWikiInactive
    | WithdrawSubmissionNotPendingOrNeedsRevision
    | WithdrawSubmissionNotFound
    | WithdrawSubmissionForbidden


withdrawSubmissionErrorToUserText : WithdrawSubmissionError -> String
withdrawSubmissionErrorToUserText err =
    case err of
        WithdrawSubmissionNotLoggedIn ->
            "You must be logged in to withdraw a submission."

        WithdrawSubmissionWrongWikiSession ->
            "Your session is for a different wiki. Log in again on this wiki."

        WithdrawSubmissionWikiNotFound ->
            "This wiki does not exist."

        WithdrawSubmissionWikiInactive ->
            "This wiki is currently paused."

        WithdrawSubmissionNotPendingOrNeedsRevision ->
            "Only submissions waiting for review can be withdrawn to edit as a draft."

        WithdrawSubmissionNotFound ->
            "That submission was not found."

        WithdrawSubmissionForbidden ->
            "You cannot withdraw this submission."


withdrawSubmissionToDraft : Submission -> Result WithdrawSubmissionError Submission
withdrawSubmissionToDraft sub =
    case sub.status of
        Pending ->
            Ok { sub | status = Draft }

        NeedsRevision ->
            Ok { sub | status = Draft }

        Draft ->
            Err WithdrawSubmissionNotPendingOrNeedsRevision

        Approved ->
            Err WithdrawSubmissionNotPendingOrNeedsRevision

        Rejected ->
            Err WithdrawSubmissionNotPendingOrNeedsRevision


type SubmitDraftForReviewError
    = SubmitDraftForReviewNotLoggedIn
    | SubmitDraftForReviewWrongWikiSession
    | SubmitDraftForReviewWikiNotFound
    | SubmitDraftForReviewWikiInactive
    | SubmitDraftForReviewNotDraft
    | SubmitDraftForReviewValidation ValidationError
    | SubmitDraftForReviewSlugInUse
    | SubmitDraftForReviewPageExists
    | SubmitDraftForReviewEditTargetNotPublished
    | SubmitDraftForReviewEditAlreadyPending
    | SubmitDraftForReviewDeleteTargetNotPublished
    | SubmitDraftForReviewDeleteReasonInvalid DeleteReasonError
    | SubmitDraftForReviewNotFound
    | SubmitDraftForReviewForbidden
    | SubmitDraftForReviewDeleteForbiddenTrustedModerator


submitDraftForReviewErrorToUserText : SubmitDraftForReviewError -> String
submitDraftForReviewErrorToUserText err =
    case err of
        SubmitDraftForReviewNotLoggedIn ->
            "You must be logged in to submit for review."

        SubmitDraftForReviewWrongWikiSession ->
            "Your session is for a different wiki. Log in again on this wiki."

        SubmitDraftForReviewWikiNotFound ->
            "This wiki does not exist."

        SubmitDraftForReviewWikiInactive ->
            "This wiki is currently paused."

        SubmitDraftForReviewNotDraft ->
            "That submission is not a draft."

        SubmitDraftForReviewValidation e ->
            validationErrorToUserText e

        SubmitDraftForReviewSlugInUse ->
            "A page or pending submission already uses this slug."

        SubmitDraftForReviewPageExists ->
            "A published page already uses this slug."

        SubmitDraftForReviewEditTargetNotPublished ->
            "That page does not exist or has no published content yet."

        SubmitDraftForReviewEditAlreadyPending ->
            "You already have a pending edit for this page."

        SubmitDraftForReviewDeleteTargetNotPublished ->
            "That page does not exist or has no published content yet."

        SubmitDraftForReviewDeleteReasonInvalid e ->
            deleteReasonErrorToUserText e

        SubmitDraftForReviewNotFound ->
            "That submission was not found."

        SubmitDraftForReviewForbidden ->
            "You cannot submit this draft."

        SubmitDraftForReviewDeleteForbiddenTrustedModerator ->
            "Trusted contributors and wiki admins remove pages immediately; submit this deletion for review is not available for your account."


{-| Turn a contributor draft into a pending review submission (pure). Rebases edit proposals on current published markdown.
-}
promoteDraftToPending : Wiki.Wiki -> Dict String Submission -> Submission -> Result SubmitDraftForReviewError Submission
promoteDraftToPending wiki allSubs sub =
    if sub.status /= Draft then
        Err SubmitDraftForReviewNotDraft

    else
        case sub.kind of
            NewPage body ->
                case validateNewPageFields body.pageSlug body.markdown of
                    Err e ->
                        Err (SubmitDraftForReviewValidation e)

                    Ok payload ->
                        if Dict.member payload.pageSlug wiki.pages then
                            Err SubmitDraftForReviewPageExists

                        else if pendingNewPageSlugInUseExcept (Just sub.id) sub.wikiSlug payload.pageSlug allSubs then
                            Err SubmitDraftForReviewSlugInUse

                        else
                            Ok
                                { sub
                                    | status = Pending
                                    , reviewerNote = Nothing
                                    , kind =
                                        NewPage
                                            { pageSlug = payload.pageSlug
                                            , markdown = payload.markdown
                                            }
                                }

            EditPage body ->
                case validateEditMarkdown body.proposedMarkdown of
                    Err e ->
                        Err (SubmitDraftForReviewValidation e)

                    Ok proposedMarkdown ->
                        if not (wikiHasPublishedPage body.pageSlug wiki) then
                            Err SubmitDraftForReviewEditTargetNotPublished

                        else if pendingEditForAuthorOnPageInUseExcept (Just sub.id) sub.wikiSlug sub.authorId body.pageSlug allSubs then
                            Err SubmitDraftForReviewEditAlreadyPending

                        else
                            let
                                currentMarkdown : String
                                currentMarkdown =
                                    currentPublishedMarkdown wiki body.pageSlug

                                currentRevision : Int
                                currentRevision =
                                    currentPublishedRevision wiki body.pageSlug
                                        |> Maybe.withDefault 0
                            in
                            Ok
                                { sub
                                    | status = Pending
                                    , reviewerNote = Nothing
                                    , kind =
                                        EditPage
                                            { pageSlug = body.pageSlug
                                            , baseMarkdown = currentMarkdown
                                            , baseRevision = currentRevision
                                            , proposedMarkdown = proposedMarkdown
                                            }
                                }

            DeletePage body ->
                case validateDeleteReasonRequired (body.reason |> Maybe.withDefault "") of
                    Err e ->
                        Err (SubmitDraftForReviewDeleteReasonInvalid e)

                    Ok trimmedReason ->
                        if not (wikiHasPublishedPage body.pageSlug wiki) then
                            Err SubmitDraftForReviewDeleteTargetNotPublished

                        else
                            Ok
                                { sub
                                    | status = Pending
                                    , reviewerNote = Nothing
                                    , kind =
                                        DeletePage
                                            { pageSlug = body.pageSlug
                                            , reason = Just trimmedReason
                                            }
                                }


type DeleteMySubmissionError
    = DeleteMySubmissionNotLoggedIn
    | DeleteMySubmissionWrongWikiSession
    | DeleteMySubmissionWikiNotFound
    | DeleteMySubmissionWikiInactive
    | DeleteMySubmissionApproved
    | DeleteMySubmissionNotFound
    | DeleteMySubmissionForbidden


deleteMySubmissionErrorToUserText : DeleteMySubmissionError -> String
deleteMySubmissionErrorToUserText err =
    case err of
        DeleteMySubmissionNotLoggedIn ->
            "You must be logged in to delete a submission."

        DeleteMySubmissionWrongWikiSession ->
            "Your session is for a different wiki. Log in again on this wiki."

        DeleteMySubmissionWikiNotFound ->
            "This wiki does not exist."

        DeleteMySubmissionWikiInactive ->
            "This wiki is currently paused."

        DeleteMySubmissionApproved ->
            "Approved submissions cannot be deleted."

        DeleteMySubmissionNotFound ->
            "That submission was not found."

        DeleteMySubmissionForbidden ->
            "You cannot delete this submission."


{-| Pure: contributor may delete non-approved submissions.
-}
mayContributorDeleteSubmission : Submission -> Result DeleteMySubmissionError ()
mayContributorDeleteSubmission sub =
    case sub.status of
        Draft ->
            Ok ()

        Pending ->
            Ok ()

        NeedsRevision ->
            Ok ()

        Rejected ->
            Ok ()

        Approved ->
            Err DeleteMySubmissionApproved


isStalePendingEditSubmission : { pageSlug : Page.Slug, currentRevision : Int } -> Submission -> Bool
isStalePendingEditSubmission payload sub =
    if sub.status /= Pending then
        False

    else
        case sub.kind of
            NewPage _ ->
                False

            EditPage body ->
                body.pageSlug == payload.pageSlug && body.baseRevision /= payload.currentRevision

            DeletePage _ ->
                False


markStalePendingEditNeedsRevision : String -> Submission -> Submission
markStalePendingEditNeedsRevision systemNote sub =
    { sub
        | status = NeedsRevision
        , reviewerNote = Just systemNote
    }

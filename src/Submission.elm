module Submission exposing
    ( ApproveSubmissionError(..)
    , ContributorView
    , DeletePageBody
    , DeleteReasonError(..)
    , DeleteSubmitSuccess(..)
    , DetailsError(..)
    , EditConflictContext
    , EditPageBody
    , EditSubmitSuccess(..)
    , Id
    , Kind(..)
    , NewPageBody
    , NewPageSubmitSuccess(..)
    , RejectReasonError(..)
    , RejectSubmissionError(..)
    , RequestChangesSubmissionError(..)
    , ResubmitPageEditError(..)
    , ReviewQueueError(..)
    , ReviewQueueItem
    , Status(..)
    , Submission
    , SubmitNewPageError(..)
    , SubmitPageDeleteError(..)
    , SubmitPageEditError(..)
    , ValidationError(..)
    , applyApprovedSubmission
    , approveSubmissionErrorToUserText
    , contributorViewFromSubmission
    , currentPublishedRevision
    , detailsErrorToUserText
    , idFromCounter
    , idFromKey
    , idToString
    , isStalePendingEditSubmission
    , kindSummaryUserText
    , markStalePendingEditNeedsRevision
    , pageSlugFromKind
    , pendingEditForAuthorOnPageInUse
    , pendingNewPageSlugInUse
    , pendingSubmissionsForWiki
    , rejectPendingSubmission
    , rejectReasonMaxLength
    , rejectSubmissionErrorToUserText
    , requestChangesSubmissionErrorToUserText
    , requestPendingSubmissionChanges
    , resubmitNeedsRevisionEdit
    , resubmitPageEditErrorToUserText
    , reviewQueueErrorToUserText
    , reviewQueueItemFromSubmission
    , reviewerNoteForDisplay
    , statusLabelUserText
    , submitNewPageErrorToUserText
    , submitPageDeleteErrorToUserText
    , submitPageEditErrorToUserText
    , validateDeleteReason
    , validateEditMarkdown
    , validateNewPageFields
    , validatePageSlug
    , validateRejectReason
    , wikiHasPublishedPage
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


{-| Story 9: sequential opaque ids from backend counter (not derived from payload).
-}
idFromCounter : Int -> Id
idFromCounter n =
    Id ("sub_" ++ String.fromInt n)


{-| Opaque id from URL segment or seed key (distinct from counter-based ids).
-}
idFromKey : String -> Id
idFromKey s =
    Id s


type Status
    = Pending
    | Approved
    | Rejected
    | NeedsRevision


statusLabelUserText : Status -> String
statusLabelUserText status =
    case status of
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
    | DetailsNotFound
    | DetailsForbidden


detailsErrorToUserText : DetailsError -> String
detailsErrorToUserText err =
    case err of
        DetailsNotLoggedIn ->
            "Log in on this wiki to view this submission."

        DetailsWrongWikiSession ->
            "Your session is for a different wiki. Log in again on this wiki."

        DetailsNotFound ->
            "That submission was not found."

        DetailsForbidden ->
            "You cannot view this submission."


{-| Payload for contributor submission detail (story 12); no full markdown on the wire.
Story 13: optional reviewer feedback when status is Rejected or NeedsRevision.
-}
type alias ContributorView =
    { id : Id
    , status : Status
    , kindSummary : String
    , reviewerNote : Maybe String
    , conflictContext : Maybe EditConflictContext
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
    { id = sub.id
    , status = sub.status
    , kindSummary = kindSummaryUserText sub.kind
    , reviewerNote = reviewerNoteForDisplay sub.reviewerNote
    , conflictContext =
        case sub.kind of
            NewPage _ ->
                Nothing

            EditPage body ->
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

            DeletePage _ ->
                Nothing
    }


{-| Trusted-only review queue (story 15).
-}
type ReviewQueueError
    = ReviewQueueNotLoggedIn
    | ReviewQueueWrongWikiSession
    | ReviewQueueForbidden


reviewQueueErrorToUserText : ReviewQueueError -> String
reviewQueueErrorToUserText err =
    case err of
        ReviewQueueNotLoggedIn ->
            "Log in on this wiki to open the review queue."

        ReviewQueueWrongWikiSession ->
            "Your session is for a different wiki. Log in again on this wiki."

        ReviewQueueForbidden ->
            "You do not have access to the review queue."


{-| Summary row for moderators (story 15).
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


{-| Trusted approval of a pending submission (story 17).
-}
type ApproveSubmissionError
    = ApproveNotLoggedIn
    | ApproveWrongWikiSession
    | ApproveForbidden
    | ApproveWikiNotFound
    | ApproveSubmissionNotFound
    | ApproveNotPending
    | ApproveNewPageSlugTaken
    | ApproveEditTargetNotPublished
    | ApproveDeleteTargetNotPublished


{-| Moderator rejection reason (story 18): trimmed, non-empty, bounded length.
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


{-| Trusted rejection of a pending submission (story 18); wiki content unchanged.
-}
type RejectSubmissionError
    = RejectNotLoggedIn
    | RejectWrongWikiSession
    | RejectForbidden
    | RejectWikiNotFound
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


{-| Trusted request for revision (story 19); wiki content unchanged.
-}
type RequestChangesSubmissionError
    = RequestChangesNotLoggedIn
    | RequestChangesWrongWikiSession
    | RequestChangesForbidden
    | RequestChangesWikiNotFound
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


{-| Apply wiki mutation and mark submission approved (story 17). `wiki` is the current wiki state for `sub.wikiSlug`.
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
    | Validation ValidationError
    | SlugAlreadyInUse


{-| Story 14: trusted contributors publish immediately; standard contributors get a pending submission id.
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

        Validation e ->
            validationErrorToUserText e

        SlugAlreadyInUse ->
            "A page or pending submission already uses this slug."


type SubmitPageEditError
    = EditNotLoggedIn
    | EditWrongWikiSession
    | EditWikiNotFound
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

        EditValidation e ->
            validationErrorToUserText e

        EditTargetPageNotPublished ->
            "That page does not exist or has no published content yet."

        EditAlreadyPendingForAuthor ->
            "You already have a pending edit for this page."


type DeleteReasonError
    = ReasonTooLong


deleteReasonMaxLength : Int
deleteReasonMaxLength =
    2000


deleteReasonErrorToUserText : DeleteReasonError -> String
deleteReasonErrorToUserText err =
    case err of
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


type SubmitPageDeleteError
    = DeleteNotLoggedIn
    | DeleteWrongWikiSession
    | DeleteWikiNotFound
    | DeleteValidation DeleteReasonError
    | DeleteTargetPageNotPublished


type DeleteSubmitSuccess
    = DeletePublishedImmediately
    | DeleteSubmittedForReview Id


submitPageDeleteErrorToUserText : SubmitPageDeleteError -> String
submitPageDeleteErrorToUserText err =
    case err of
        DeleteNotLoggedIn ->
            "You must be logged in to request a page deletion."

        DeleteWrongWikiSession ->
            "Your session is for a different wiki. Log in again on this wiki."

        DeleteWikiNotFound ->
            "This wiki does not exist."

        DeleteValidation e ->
            deleteReasonErrorToUserText e

        DeleteTargetPageNotPublished ->
            "That page does not exist or has no published content yet."


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


{-| Trim slug before validating.
-}
normalizePageSlug : String -> String
normalizePageSlug raw =
    raw
        |> String.trim


{-| Page slug rules only (trim, length, PascalCase character class). Same rules as hosted wiki slugs (story 29).
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

    else if String.length pageSlug > 64 then
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
                            case sub.kind of
                                NewPage body ->
                                    body.pageSlug == pageSlug

                                EditPage _ ->
                                    False

                                DeletePage _ ->
                                    False

                        Approved ->
                            False

                        Rejected ->
                            False

                        NeedsRevision ->
                            False
            )


pendingEditForAuthorOnPageInUse : Wiki.Slug -> ContributorAccount.Id -> Page.Slug -> Dict String Submission -> Bool
pendingEditForAuthorOnPageInUse wikiSlug authorId pageSlug submissions =
    submissions
        |> Dict.values
        |> List.any
            (\sub ->
                if sub.wikiSlug /= wikiSlug || sub.authorId /= authorId || sub.status /= Pending then
                    False

                else
                    case sub.kind of
                        EditPage body ->
                            body.pageSlug == pageSlug

                        NewPage _ ->
                            False

                        DeletePage _ ->
                            False
            )


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


type ResubmitPageEditError
    = ResubmitEditNotLoggedIn
    | ResubmitEditWrongWikiSession
    | ResubmitEditWikiNotFound
    | ResubmitEditSubmissionNotFound
    | ResubmitEditForbidden
    | ResubmitEditTargetPageNotPublished
    | ResubmitEditNotNeedsRevision
    | ResubmitEditNotEditKind
    | ResubmitEditValidation ValidationError


resubmitPageEditErrorToUserText : ResubmitPageEditError -> String
resubmitPageEditErrorToUserText err =
    case err of
        ResubmitEditNotLoggedIn ->
            "You must be logged in to resubmit this edit."

        ResubmitEditWrongWikiSession ->
            "Your session is for a different wiki. Log in again on this wiki."

        ResubmitEditWikiNotFound ->
            "This wiki does not exist."

        ResubmitEditSubmissionNotFound ->
            "This submission was not found."

        ResubmitEditForbidden ->
            "You can only resubmit your own submissions."

        ResubmitEditTargetPageNotPublished ->
            "That page does not exist or has no published content yet."

        ResubmitEditNotNeedsRevision ->
            "Only submissions in \"Needs revision\" can be resubmitted."

        ResubmitEditNotEditKind ->
            "Only page-edit submissions can be resubmitted from this form."

        ResubmitEditValidation validationError ->
            validationErrorToUserText validationError


resubmitNeedsRevisionEdit : { markdown : String, currentMarkdown : String, currentRevision : Int } -> Submission -> Result ResubmitPageEditError Submission
resubmitNeedsRevisionEdit payload sub =
    if sub.status /= NeedsRevision then
        Err ResubmitEditNotNeedsRevision

    else
        case sub.kind of
            NewPage _ ->
                Err ResubmitEditNotEditKind

            EditPage body ->
                case validateEditMarkdown payload.markdown of
                    Err validationError ->
                        Err (ResubmitEditValidation validationError)

                    Ok proposedMarkdown ->
                        Ok
                            { sub
                                | status = Pending
                                , reviewerNote = Nothing
                                , kind =
                                    EditPage
                                        { body
                                            | baseMarkdown = payload.currentMarkdown
                                            , baseRevision = payload.currentRevision
                                            , proposedMarkdown = proposedMarkdown
                                        }
                            }

            DeletePage _ ->
                Err ResubmitEditNotEditKind


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

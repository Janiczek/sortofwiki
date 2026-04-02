module HostAdmin exposing
    ( CreateHostedWikiError(..)
    , DeleteHostedWikiError(..)
    , HostWikiDetailError(..)
    , LoginError(..)
    , ProtectedError(..)
    , UpdateHostedWikiMetadataError(..)
    , WikiLifecycleError(..)
    , WikiNameError(..)
    , WikiSummaryError(..)
    , createHostedWikiErrorToUserText
    , deleteHostedWikiConfirmationMatches
    , deleteHostedWikiErrorToUserText
    , hostWikiDetailErrorToUserText
    , loginErrorToUserText
    , protectedErrorToUserText
    , updateHostedWikiMetadataErrorToUserText
    , wikiLifecycleErrorToUserText
    , validateHostedWikiName
    , validateHostedWikiSummary
    , wikiNameMaxLength
    , wikiSummaryMaxLength
    )

import Submission


{-| Wrong password for host-admin login (story 27).
-}
type LoginError
    = WrongPassword


{-| Client is not in a host-authenticated session (story 27+).
-}
type ProtectedError
    = NotHostAuthenticated


{-| Hosted wiki display name validation (story 29).
-}
type WikiNameError
    = WikiNameEmpty
    | WikiNameTooLong


wikiNameMaxLength : Int
wikiNameMaxLength =
    200


wikiSummaryMaxLength : Int
wikiSummaryMaxLength =
    4000


{-| Load single wiki for host admin detail (story 30).
-}
type HostWikiDetailError
    = HostWikiDetailNotHostAuthenticated
    | HostWikiDetailWikiNotFound


{-| Deactivate / reactivate hosted wiki (story 31).
-}
type WikiLifecycleError
    = WikiLifecycleNotHostAuthenticated
    | WikiLifecycleWikiNotFound


{-| Irreversible delete with confirmation phrase (story 32).
-}
type DeleteHostedWikiError
    = DeleteHostedWikiNotHostAuthenticated
    | DeleteHostedWikiWikiNotFound
    | DeleteHostedWikiConfirmationMismatch


deleteHostedWikiErrorToUserText : DeleteHostedWikiError -> String
deleteHostedWikiErrorToUserText err =
    case err of
        DeleteHostedWikiNotHostAuthenticated ->
            protectedErrorToUserText NotHostAuthenticated

        DeleteHostedWikiWikiNotFound ->
            "That wiki was not found."

        DeleteHostedWikiConfirmationMismatch ->
            "Confirmation must match the wiki slug or the word DELETE."


{-| After `String.trim`, the phrase must equal the wiki slug or exactly `DELETE`.
-}
deleteHostedWikiConfirmationMatches : String -> String -> Bool
deleteHostedWikiConfirmationMatches wikiSlug raw =
    let
        trimmed : String
        trimmed =
            String.trim raw
    in
    trimmed == wikiSlug || trimmed == "DELETE"


wikiLifecycleErrorToUserText : WikiLifecycleError -> String
wikiLifecycleErrorToUserText err =
    case err of
        WikiLifecycleNotHostAuthenticated ->
            protectedErrorToUserText NotHostAuthenticated

        WikiLifecycleWikiNotFound ->
            "That wiki was not found."


{-| Persist metadata from host admin detail form (story 30).
-}
type UpdateHostedWikiMetadataError
    = UpdateMetadataNotHostAuthenticated
    | UpdateMetadataWikiNotFound
    | UpdateMetadataWikiNameInvalid WikiNameError
    | UpdateMetadataWikiSummaryInvalid WikiSummaryError


{-| Public wiki blurb length (story 30).
-}
type WikiSummaryError
    = WikiSummaryTooLong


hostWikiDetailErrorToUserText : HostWikiDetailError -> String
hostWikiDetailErrorToUserText err =
    case err of
        HostWikiDetailNotHostAuthenticated ->
            protectedErrorToUserText NotHostAuthenticated

        HostWikiDetailWikiNotFound ->
            "That wiki was not found."


updateHostedWikiMetadataErrorToUserText : UpdateHostedWikiMetadataError -> String
updateHostedWikiMetadataErrorToUserText err =
    case err of
        UpdateMetadataNotHostAuthenticated ->
            protectedErrorToUserText NotHostAuthenticated

        UpdateMetadataWikiNotFound ->
            "That wiki was not found."

        UpdateMetadataWikiNameInvalid e ->
            wikiNameErrorToUserText e

        UpdateMetadataWikiSummaryInvalid e ->
            wikiSummaryErrorToUserText e


wikiSummaryErrorToUserText : WikiSummaryError -> String
wikiSummaryErrorToUserText err =
    case err of
        WikiSummaryTooLong ->
            "Summary must be at most "
                ++ String.fromInt wikiSummaryMaxLength
                ++ " characters."


{-| Trims; empty summary is allowed; length cap only.
-}
validateHostedWikiSummary : String -> Result WikiSummaryError String
validateHostedWikiSummary raw =
    let
        text : String
        text =
            String.trim raw
    in
    if String.length text > wikiSummaryMaxLength then
        Err WikiSummaryTooLong

    else
        Ok text


{-| Create hosted wiki failed (story 29).
-}
type CreateHostedWikiError
    = CreateNotHostAuthenticated
    | CreateSlugInvalid Submission.ValidationError
    | CreateWikiNameInvalid WikiNameError
    | CreateWikiSlugTaken


loginErrorToUserText : LoginError -> String
loginErrorToUserText err =
    case err of
        WrongPassword ->
            "Invalid password."


protectedErrorToUserText : ProtectedError -> String
protectedErrorToUserText err =
    case err of
        NotHostAuthenticated ->
            "Host admin sign-in required."


wikiNameErrorToUserText : WikiNameError -> String
wikiNameErrorToUserText err =
    case err of
        WikiNameEmpty ->
            "Enter a wiki name."

        WikiNameTooLong ->
            "Wiki name must be at most 200 characters."


hostedWikiSlugErrorToUserText : Submission.ValidationError -> String
hostedWikiSlugErrorToUserText slugErr =
    case slugErr of
        Submission.SlugEmpty ->
            "Enter a wiki slug."

        Submission.SlugTooLong ->
            "Wiki slug must be at most 64 characters."

        Submission.SlugInvalidChars ->
            "Wiki slug may only use letters, digits, underscores, and hyphens (start with a letter or digit)."

        Submission.BodyEmpty ->
            "Invalid wiki slug."


createHostedWikiErrorToUserText : CreateHostedWikiError -> String
createHostedWikiErrorToUserText err =
    case err of
        CreateNotHostAuthenticated ->
            protectedErrorToUserText NotHostAuthenticated

        CreateSlugInvalid e ->
            hostedWikiSlugErrorToUserText e

        CreateWikiNameInvalid e ->
            wikiNameErrorToUserText e

        CreateWikiSlugTaken ->
            "A wiki with this slug already exists."


{-| Trimmed non-empty name, at most `wikiNameMaxLength` characters.
-}
validateHostedWikiName : String -> Result WikiNameError String
validateHostedWikiName raw =
    let
        name : String
        name =
            String.trim raw
    in
    if String.isEmpty name then
        Err WikiNameEmpty

    else if String.length name > wikiNameMaxLength then
        Err WikiNameTooLong

    else
        Ok name

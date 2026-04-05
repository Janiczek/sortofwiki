module HostAdmin exposing
    ( CreateHostedWikiError(..)
    , DataExportError(..)
    , DataImportError(..)
    , DeleteHostedWikiError(..)
    , HostWikiDetailError(..)
    , LoginError(..)
    , ProtectedError(..)
    , UpdateHostedWikiMetadataError(..)
    , WikiDataExportError(..)
    , WikiDataImportError(..)
    , WikiLifecycleError(..)
    , WikiNameError(..)
    , WikiSummaryError(..)
    , createHostedWikiErrorToUserText
    , dataExportErrorToUserText
    , dataImportErrorToUserText
    , deleteHostedWikiConfirmationMatches
    , deleteHostedWikiErrorToUserText
    , hostWikiDetailErrorToUserText
    , loginErrorToUserText
    , protectedErrorToUserText
    , updateHostedWikiMetadataErrorToUserText
    , validateHostedWikiMetadataSlug
    , validateHostedWikiName
    , validateHostedWikiSummary
    , wikiDataExportErrorToUserText
    , wikiDataImportErrorToUserText
    , wikiLifecycleErrorToUserText
    , wikiNameMaxLength
    , wikiSummaryMaxLength
    )

import ContributorAccount
import Submission
import Wiki


{-| Wrong password for host-admin login.
-}
type LoginError
    = WrongPassword


{-| Client is not in a host-authenticated session.
-}
type ProtectedError
    = NotHostAuthenticated


{-| Host-admin JSON export (full backup download).
-}
type DataExportError
    = DataExportNotHostAuthenticated


{-| Host-admin JSON import (full restore).
-}
type DataImportError
    = DataImportNotHostAuthenticated
    | DataImportInvalid String


{-| Per-wiki JSON export from the host admin wiki list.
-}
type WikiDataExportError
    = WikiDataExportNotHostAuthenticated
    | WikiDataExportWikiNotFound


{-| Per-wiki JSON import (replaces one wiki slice).
-}
type WikiDataImportError
    = WikiDataImportNotHostAuthenticated
    | WikiDataImportWikiNotFound
    | WikiDataImportInvalid String


dataExportErrorToUserText : DataExportError -> String
dataExportErrorToUserText err =
    case err of
        DataExportNotHostAuthenticated ->
            protectedErrorToUserText NotHostAuthenticated


dataImportErrorToUserText : DataImportError -> String
dataImportErrorToUserText err =
    case err of
        DataImportNotHostAuthenticated ->
            protectedErrorToUserText NotHostAuthenticated

        DataImportInvalid detail ->
            detail


wikiDataExportErrorToUserText : WikiDataExportError -> String
wikiDataExportErrorToUserText err =
    case err of
        WikiDataExportNotHostAuthenticated ->
            protectedErrorToUserText NotHostAuthenticated

        WikiDataExportWikiNotFound ->
            "That wiki was not found."


wikiDataImportErrorToUserText : WikiDataImportError -> String
wikiDataImportErrorToUserText err =
    case err of
        WikiDataImportNotHostAuthenticated ->
            protectedErrorToUserText NotHostAuthenticated

        WikiDataImportWikiNotFound ->
            "That wiki was not found."

        WikiDataImportInvalid detail ->
            detail


{-| Hosted wiki display name validation.
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


{-| Load single wiki for host admin detail.
-}
type HostWikiDetailError
    = HostWikiDetailNotHostAuthenticated
    | HostWikiDetailWikiNotFound


{-| Deactivate / reactivate hosted wiki.
-}
type WikiLifecycleError
    = WikiLifecycleNotHostAuthenticated
    | WikiLifecycleWikiNotFound


{-| Irreversible delete with confirmation phrase.
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
            "Type the wiki slug exactly to confirm deletion."


{-| After `String.trim`, the phrase must equal the wiki slug.
-}
deleteHostedWikiConfirmationMatches : String -> String -> Bool
deleteHostedWikiConfirmationMatches wikiSlug raw =
    String.trim raw == wikiSlug


wikiLifecycleErrorToUserText : WikiLifecycleError -> String
wikiLifecycleErrorToUserText err =
    case err of
        WikiLifecycleNotHostAuthenticated ->
            protectedErrorToUserText NotHostAuthenticated

        WikiLifecycleWikiNotFound ->
            "That wiki was not found."


{-| Persist metadata from host admin detail form.
-}
type UpdateHostedWikiMetadataError
    = UpdateMetadataNotHostAuthenticated
    | UpdateMetadataWikiNotFound
    | UpdateMetadataWikiNameInvalid WikiNameError
    | UpdateMetadataWikiSummaryInvalid WikiSummaryError
    | UpdateMetadataWikiSlugInvalid Submission.ValidationError
    | UpdateMetadataWikiSlugTaken


{-| Public wiki blurb length.
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

        UpdateMetadataWikiSlugInvalid e ->
            hostedWikiSlugErrorToUserText e

        UpdateMetadataWikiSlugTaken ->
            "A wiki with this slug already exists."


wikiSummaryErrorToUserText : WikiSummaryError -> String
wikiSummaryErrorToUserText err =
    case err of
        WikiSummaryTooLong ->
            "Summary must be at most "
                ++ String.fromInt wikiSummaryMaxLength
                ++ " characters."


{-| Slug field on host wiki detail: unchanged value keeps legacy slugs; a new value uses the same rules as create.
-}
validateHostedWikiMetadataSlug : Wiki.Slug -> String -> Result UpdateHostedWikiMetadataError String
validateHostedWikiMetadataSlug currentSlug raw =
    let
        trimmed : String
        trimmed =
            String.trim raw
    in
    if trimmed == currentSlug then
        Ok trimmed

    else
        case Submission.validatePageSlug trimmed of
            Err e ->
                Err (UpdateMetadataWikiSlugInvalid e)

            Ok s ->
                Ok s


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


{-| Create hosted wiki failed.
-}
type CreateHostedWikiError
    = CreateNotHostAuthenticated
    | CreateSlugInvalid Submission.ValidationError
    | CreateWikiNameInvalid WikiNameError
    | CreateWikiSlugTaken
    | CreateInitialAdminInvalid ContributorAccount.RegisterContributorError


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
            "Wiki slug must be PascalCase letters and digits only."

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

        CreateInitialAdminInvalid e ->
            ContributorAccount.registerErrorToUserText e


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

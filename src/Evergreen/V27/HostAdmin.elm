module Evergreen.V27.HostAdmin exposing (..)

import Evergreen.V27.ContributorAccount
import Evergreen.V27.Submission


type ProtectedError
    = NotHostAuthenticated


type LoginError
    = WrongPassword


type WikiNameError
    = WikiNameEmpty
    | WikiNameTooLong


type CreateHostedWikiError
    = CreateNotHostAuthenticated
    | CreateSlugInvalid Evergreen.V27.Submission.ValidationError
    | CreateWikiNameInvalid WikiNameError
    | CreateWikiSlugTaken
    | CreateInitialAdminInvalid Evergreen.V27.ContributorAccount.RegisterContributorError


type HostWikiDetailError
    = HostWikiDetailNotHostAuthenticated
    | HostWikiDetailWikiNotFound


type WikiSummaryError
    = WikiSummaryTooLong


type UpdateHostedWikiMetadataError
    = UpdateMetadataNotHostAuthenticated
    | UpdateMetadataWikiNotFound
    | UpdateMetadataWikiNameInvalid WikiNameError
    | UpdateMetadataWikiSummaryInvalid WikiSummaryError
    | UpdateMetadataWikiSlugInvalid Evergreen.V27.Submission.ValidationError
    | UpdateMetadataWikiSlugTaken


type WikiLifecycleError
    = WikiLifecycleNotHostAuthenticated
    | WikiLifecycleWikiNotFound


type DeleteHostedWikiError
    = DeleteHostedWikiNotHostAuthenticated
    | DeleteHostedWikiWikiNotFound
    | DeleteHostedWikiConfirmationMismatch


type DataExportError
    = DataExportNotHostAuthenticated


type DataImportError
    = DataImportNotHostAuthenticated
    | DataImportInvalid String


type WikiDataExportError
    = WikiDataExportNotHostAuthenticated
    | WikiDataExportWikiNotFound


type WikiDataImportError
    = WikiDataImportNotHostAuthenticated
    | WikiDataImportWikiNotFound
    | WikiDataImportInvalid String

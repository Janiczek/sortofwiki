module Evergreen.V1.Route exposing (..)

import Evergreen.V1.Page
import Evergreen.V1.Wiki
import Url


type Route
    = WikiList
    | HostAdmin (Maybe String)
    | HostAdminWikis
    | HostAdminWikiNew
    | HostAdminWikiDetail Evergreen.V1.Wiki.Slug
    | HostAdminAudit
    | HostAdminBackup
    | WikiHome Evergreen.V1.Wiki.Slug
    | WikiPage Evergreen.V1.Wiki.Slug Evergreen.V1.Page.Slug
    | WikiLogin Evergreen.V1.Wiki.Slug (Maybe String)
    | WikiRegister Evergreen.V1.Wiki.Slug
    | WikiSubmitNew Evergreen.V1.Wiki.Slug
    | WikiSubmitEdit Evergreen.V1.Wiki.Slug Evergreen.V1.Page.Slug
    | WikiSubmitDelete Evergreen.V1.Wiki.Slug Evergreen.V1.Page.Slug
    | WikiSubmissionDetail Evergreen.V1.Wiki.Slug String
    | WikiMySubmissions Evergreen.V1.Wiki.Slug
    | WikiReview Evergreen.V1.Wiki.Slug
    | WikiReviewDetail Evergreen.V1.Wiki.Slug String
    | WikiAdminUsers Evergreen.V1.Wiki.Slug
    | WikiAdminAudit Evergreen.V1.Wiki.Slug
    | NotFound Url.Url

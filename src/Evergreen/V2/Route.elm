module Evergreen.V2.Route exposing (..)

import Evergreen.V2.Page
import Evergreen.V2.Wiki
import Url


type Route
    = WikiList
    | HostAdmin (Maybe String)
    | HostAdminWikis
    | HostAdminWikiNew
    | HostAdminWikiDetail Evergreen.V2.Wiki.Slug
    | HostAdminAudit
    | HostAdminBackup
    | WikiHome Evergreen.V2.Wiki.Slug
    | WikiPage Evergreen.V2.Wiki.Slug Evergreen.V2.Page.Slug
    | WikiLogin Evergreen.V2.Wiki.Slug (Maybe String)
    | WikiRegister Evergreen.V2.Wiki.Slug
    | WikiSubmitNew Evergreen.V2.Wiki.Slug
    | WikiSubmitEdit Evergreen.V2.Wiki.Slug Evergreen.V2.Page.Slug
    | WikiSubmitDelete Evergreen.V2.Wiki.Slug Evergreen.V2.Page.Slug
    | WikiSubmissionDetail Evergreen.V2.Wiki.Slug String
    | WikiMySubmissions Evergreen.V2.Wiki.Slug
    | WikiReview Evergreen.V2.Wiki.Slug
    | WikiReviewDetail Evergreen.V2.Wiki.Slug String
    | WikiAdminUsers Evergreen.V2.Wiki.Slug
    | WikiAdminAudit Evergreen.V2.Wiki.Slug
    | NotFound Url.Url

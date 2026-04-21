module Evergreen.V3.Route exposing (..)

import Evergreen.V3.Page
import Evergreen.V3.Wiki
import Url


type Route
    = WikiList
    | HostAdmin (Maybe String)
    | HostAdminWikis
    | HostAdminWikiNew
    | HostAdminWikiDetail Evergreen.V3.Wiki.Slug
    | HostAdminAudit
    | HostAdminBackup
    | WikiHome Evergreen.V3.Wiki.Slug
    | WikiTodos Evergreen.V3.Wiki.Slug
    | WikiGraph Evergreen.V3.Wiki.Slug
    | WikiPage Evergreen.V3.Wiki.Slug Evergreen.V3.Page.Slug
    | WikiLogin Evergreen.V3.Wiki.Slug (Maybe String)
    | WikiRegister Evergreen.V3.Wiki.Slug
    | WikiSubmitNew Evergreen.V3.Wiki.Slug
    | WikiSubmitEdit Evergreen.V3.Wiki.Slug Evergreen.V3.Page.Slug
    | WikiSubmitDelete Evergreen.V3.Wiki.Slug Evergreen.V3.Page.Slug
    | WikiSubmissionDetail Evergreen.V3.Wiki.Slug String
    | WikiMySubmissions Evergreen.V3.Wiki.Slug
    | WikiReview Evergreen.V3.Wiki.Slug
    | WikiReviewDetail Evergreen.V3.Wiki.Slug String
    | WikiAdminUsers Evergreen.V3.Wiki.Slug
    | WikiAdminAudit Evergreen.V3.Wiki.Slug
    | NotFound Url.Url

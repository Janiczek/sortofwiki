module Evergreen.V17.Route exposing (..)

import Evergreen.V17.Page
import Evergreen.V17.Wiki
import Url


type Route
    = WikiList
    | HostAdmin (Maybe String)
    | HostAdminWikis
    | HostAdminWikiNew
    | HostAdminWikiDetail Evergreen.V17.Wiki.Slug
    | HostAdminAudit
    | HostAdminAuditDiff Evergreen.V17.Wiki.Slug Int
    | HostAdminBackup
    | WikiHome Evergreen.V17.Wiki.Slug
    | WikiTodos Evergreen.V17.Wiki.Slug
    | WikiGraph Evergreen.V17.Wiki.Slug
    | WikiSearch Evergreen.V17.Wiki.Slug
    | WikiPage Evergreen.V17.Wiki.Slug Evergreen.V17.Page.Slug
    | WikiPageGraph Evergreen.V17.Wiki.Slug Evergreen.V17.Page.Slug
    | WikiLogin Evergreen.V17.Wiki.Slug (Maybe String)
    | WikiRegister Evergreen.V17.Wiki.Slug
    | WikiSubmitNew Evergreen.V17.Wiki.Slug
    | WikiSubmitEdit Evergreen.V17.Wiki.Slug Evergreen.V17.Page.Slug
    | WikiSubmitDelete Evergreen.V17.Wiki.Slug Evergreen.V17.Page.Slug
    | WikiSubmissionDetail Evergreen.V17.Wiki.Slug String
    | WikiMySubmissions Evergreen.V17.Wiki.Slug
    | WikiReview Evergreen.V17.Wiki.Slug
    | WikiReviewDetail Evergreen.V17.Wiki.Slug String
    | WikiAdminUsers Evergreen.V17.Wiki.Slug
    | WikiAdminAudit Evergreen.V17.Wiki.Slug
    | WikiAdminAuditDiff Evergreen.V17.Wiki.Slug Int
    | NotFound Url.Url

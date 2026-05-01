module Evergreen.V16.Route exposing (..)

import Evergreen.V16.Page
import Evergreen.V16.Wiki
import Url


type Route
    = WikiList
    | HostAdmin (Maybe String)
    | HostAdminWikis
    | HostAdminWikiNew
    | HostAdminWikiDetail Evergreen.V16.Wiki.Slug
    | HostAdminAudit
    | HostAdminAuditDiff Evergreen.V16.Wiki.Slug Int
    | HostAdminBackup
    | WikiHome Evergreen.V16.Wiki.Slug
    | WikiTodos Evergreen.V16.Wiki.Slug
    | WikiGraph Evergreen.V16.Wiki.Slug
    | WikiSearch Evergreen.V16.Wiki.Slug
    | WikiPage Evergreen.V16.Wiki.Slug Evergreen.V16.Page.Slug
    | WikiPageGraph Evergreen.V16.Wiki.Slug Evergreen.V16.Page.Slug
    | WikiLogin Evergreen.V16.Wiki.Slug (Maybe String)
    | WikiRegister Evergreen.V16.Wiki.Slug
    | WikiSubmitNew Evergreen.V16.Wiki.Slug
    | WikiSubmitEdit Evergreen.V16.Wiki.Slug Evergreen.V16.Page.Slug
    | WikiSubmitDelete Evergreen.V16.Wiki.Slug Evergreen.V16.Page.Slug
    | WikiSubmissionDetail Evergreen.V16.Wiki.Slug String
    | WikiMySubmissions Evergreen.V16.Wiki.Slug
    | WikiReview Evergreen.V16.Wiki.Slug
    | WikiReviewDetail Evergreen.V16.Wiki.Slug String
    | WikiAdminUsers Evergreen.V16.Wiki.Slug
    | WikiAdminAudit Evergreen.V16.Wiki.Slug
    | WikiAdminAuditDiff Evergreen.V16.Wiki.Slug Int
    | NotFound Url.Url

module Evergreen.V14.Route exposing (..)

import Evergreen.V14.Page
import Evergreen.V14.Wiki
import Url


type Route
    = WikiList
    | HostAdmin (Maybe String)
    | HostAdminWikis
    | HostAdminWikiNew
    | HostAdminWikiDetail Evergreen.V14.Wiki.Slug
    | HostAdminAudit
    | HostAdminAuditDiff Evergreen.V14.Wiki.Slug Int
    | HostAdminBackup
    | WikiHome Evergreen.V14.Wiki.Slug
    | WikiTodos Evergreen.V14.Wiki.Slug
    | WikiGraph Evergreen.V14.Wiki.Slug
    | WikiSearch Evergreen.V14.Wiki.Slug
    | WikiPage Evergreen.V14.Wiki.Slug Evergreen.V14.Page.Slug
    | WikiPageGraph Evergreen.V14.Wiki.Slug Evergreen.V14.Page.Slug
    | WikiLogin Evergreen.V14.Wiki.Slug (Maybe String)
    | WikiRegister Evergreen.V14.Wiki.Slug
    | WikiSubmitNew Evergreen.V14.Wiki.Slug
    | WikiSubmitEdit Evergreen.V14.Wiki.Slug Evergreen.V14.Page.Slug
    | WikiSubmitDelete Evergreen.V14.Wiki.Slug Evergreen.V14.Page.Slug
    | WikiSubmissionDetail Evergreen.V14.Wiki.Slug String
    | WikiMySubmissions Evergreen.V14.Wiki.Slug
    | WikiReview Evergreen.V14.Wiki.Slug
    | WikiReviewDetail Evergreen.V14.Wiki.Slug String
    | WikiAdminUsers Evergreen.V14.Wiki.Slug
    | WikiAdminAudit Evergreen.V14.Wiki.Slug
    | WikiAdminAuditDiff Evergreen.V14.Wiki.Slug Int
    | NotFound Url.Url

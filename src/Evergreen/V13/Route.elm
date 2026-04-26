module Evergreen.V13.Route exposing (..)

import Evergreen.V13.Page
import Evergreen.V13.Wiki
import Url


type Route
    = WikiList
    | HostAdmin (Maybe String)
    | HostAdminWikis
    | HostAdminWikiNew
    | HostAdminWikiDetail Evergreen.V13.Wiki.Slug
    | HostAdminAudit
    | HostAdminAuditDiff Evergreen.V13.Wiki.Slug Int
    | HostAdminBackup
    | WikiHome Evergreen.V13.Wiki.Slug
    | WikiTodos Evergreen.V13.Wiki.Slug
    | WikiGraph Evergreen.V13.Wiki.Slug
    | WikiSearch Evergreen.V13.Wiki.Slug
    | WikiPage Evergreen.V13.Wiki.Slug Evergreen.V13.Page.Slug
    | WikiPageGraph Evergreen.V13.Wiki.Slug Evergreen.V13.Page.Slug
    | WikiLogin Evergreen.V13.Wiki.Slug (Maybe String)
    | WikiRegister Evergreen.V13.Wiki.Slug
    | WikiSubmitNew Evergreen.V13.Wiki.Slug
    | WikiSubmitEdit Evergreen.V13.Wiki.Slug Evergreen.V13.Page.Slug
    | WikiSubmitDelete Evergreen.V13.Wiki.Slug Evergreen.V13.Page.Slug
    | WikiSubmissionDetail Evergreen.V13.Wiki.Slug String
    | WikiMySubmissions Evergreen.V13.Wiki.Slug
    | WikiReview Evergreen.V13.Wiki.Slug
    | WikiReviewDetail Evergreen.V13.Wiki.Slug String
    | WikiAdminUsers Evergreen.V13.Wiki.Slug
    | WikiAdminAudit Evergreen.V13.Wiki.Slug
    | WikiAdminAuditDiff Evergreen.V13.Wiki.Slug Int
    | NotFound Url.Url

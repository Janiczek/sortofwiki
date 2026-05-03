module Evergreen.V28.Route exposing (..)

import Evergreen.V28.Page
import Evergreen.V28.Wiki
import Url


type Route
    = WikiList
    | HostAdmin (Maybe String)
    | HostAdminWikis
    | HostAdminWikiNew
    | HostAdminWikiDetail Evergreen.V28.Wiki.Slug
    | HostAdminAudit
    | HostAdminAuditDiff Evergreen.V28.Wiki.Slug Int
    | HostAdminBackup
    | WikiHome Evergreen.V28.Wiki.Slug
    | WikiTodos Evergreen.V28.Wiki.Slug
    | WikiGraph Evergreen.V28.Wiki.Slug
    | WikiSearch Evergreen.V28.Wiki.Slug
    | WikiStats Evergreen.V28.Wiki.Slug
    | WikiPage Evergreen.V28.Wiki.Slug Evergreen.V28.Page.Slug
    | WikiPageGraph Evergreen.V28.Wiki.Slug Evergreen.V28.Page.Slug
    | WikiLogin Evergreen.V28.Wiki.Slug (Maybe String)
    | WikiRegister Evergreen.V28.Wiki.Slug
    | WikiSubmitNew Evergreen.V28.Wiki.Slug
    | WikiSubmitEdit Evergreen.V28.Wiki.Slug Evergreen.V28.Page.Slug
    | WikiSubmitDelete Evergreen.V28.Wiki.Slug Evergreen.V28.Page.Slug
    | WikiSubmissionDetail Evergreen.V28.Wiki.Slug String
    | WikiMySubmissions Evergreen.V28.Wiki.Slug
    | WikiReview Evergreen.V28.Wiki.Slug
    | WikiReviewDetail Evergreen.V28.Wiki.Slug String
    | WikiAdminUsers Evergreen.V28.Wiki.Slug
    | WikiAdminAudit Evergreen.V28.Wiki.Slug
    | WikiAdminAuditDiff Evergreen.V28.Wiki.Slug Int
    | NotFound Url.Url

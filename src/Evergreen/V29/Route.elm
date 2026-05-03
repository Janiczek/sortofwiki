module Evergreen.V29.Route exposing (..)

import Evergreen.V29.Page
import Evergreen.V29.Wiki
import Url


type Route
    = WikiList
    | HostAdmin (Maybe String)
    | HostAdminWikis
    | HostAdminWikiNew
    | HostAdminWikiDetail Evergreen.V29.Wiki.Slug
    | HostAdminAudit
    | HostAdminAuditDiff Evergreen.V29.Wiki.Slug Int
    | HostAdminBackup
    | WikiHome Evergreen.V29.Wiki.Slug
    | WikiTodos Evergreen.V29.Wiki.Slug
    | WikiGraph Evergreen.V29.Wiki.Slug
    | WikiSearch Evergreen.V29.Wiki.Slug
    | WikiStats Evergreen.V29.Wiki.Slug
    | WikiPage Evergreen.V29.Wiki.Slug Evergreen.V29.Page.Slug
    | WikiPageGraph Evergreen.V29.Wiki.Slug Evergreen.V29.Page.Slug
    | WikiLogin Evergreen.V29.Wiki.Slug (Maybe String)
    | WikiRegister Evergreen.V29.Wiki.Slug
    | WikiSubmitNew Evergreen.V29.Wiki.Slug
    | WikiSubmitEdit Evergreen.V29.Wiki.Slug Evergreen.V29.Page.Slug
    | WikiSubmitDelete Evergreen.V29.Wiki.Slug Evergreen.V29.Page.Slug
    | WikiSubmissionDetail Evergreen.V29.Wiki.Slug String
    | WikiMySubmissions Evergreen.V29.Wiki.Slug
    | WikiReview Evergreen.V29.Wiki.Slug
    | WikiReviewDetail Evergreen.V29.Wiki.Slug String
    | WikiAdminUsers Evergreen.V29.Wiki.Slug
    | WikiAdminAudit Evergreen.V29.Wiki.Slug
    | WikiAdminAuditDiff Evergreen.V29.Wiki.Slug Int
    | NotFound Url.Url

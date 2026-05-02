module Evergreen.V26.Route exposing (..)

import Evergreen.V26.Page
import Evergreen.V26.Wiki
import Url


type Route
    = WikiList
    | HostAdmin (Maybe String)
    | HostAdminWikis
    | HostAdminWikiNew
    | HostAdminWikiDetail Evergreen.V26.Wiki.Slug
    | HostAdminAudit
    | HostAdminAuditDiff Evergreen.V26.Wiki.Slug Int
    | HostAdminBackup
    | WikiHome Evergreen.V26.Wiki.Slug
    | WikiTodos Evergreen.V26.Wiki.Slug
    | WikiGraph Evergreen.V26.Wiki.Slug
    | WikiSearch Evergreen.V26.Wiki.Slug
    | WikiPage Evergreen.V26.Wiki.Slug Evergreen.V26.Page.Slug
    | WikiPageGraph Evergreen.V26.Wiki.Slug Evergreen.V26.Page.Slug
    | WikiLogin Evergreen.V26.Wiki.Slug (Maybe String)
    | WikiRegister Evergreen.V26.Wiki.Slug
    | WikiSubmitNew Evergreen.V26.Wiki.Slug
    | WikiSubmitEdit Evergreen.V26.Wiki.Slug Evergreen.V26.Page.Slug
    | WikiSubmitDelete Evergreen.V26.Wiki.Slug Evergreen.V26.Page.Slug
    | WikiSubmissionDetail Evergreen.V26.Wiki.Slug String
    | WikiMySubmissions Evergreen.V26.Wiki.Slug
    | WikiReview Evergreen.V26.Wiki.Slug
    | WikiReviewDetail Evergreen.V26.Wiki.Slug String
    | WikiAdminUsers Evergreen.V26.Wiki.Slug
    | WikiAdminAudit Evergreen.V26.Wiki.Slug
    | WikiAdminAuditDiff Evergreen.V26.Wiki.Slug Int
    | NotFound Url.Url

module Evergreen.V20.Route exposing (..)

import Evergreen.V20.Page
import Evergreen.V20.Wiki
import Url


type Route
    = WikiList
    | HostAdmin (Maybe String)
    | HostAdminWikis
    | HostAdminWikiNew
    | HostAdminWikiDetail Evergreen.V20.Wiki.Slug
    | HostAdminAudit
    | HostAdminAuditDiff Evergreen.V20.Wiki.Slug Int
    | HostAdminBackup
    | WikiHome Evergreen.V20.Wiki.Slug
    | WikiTodos Evergreen.V20.Wiki.Slug
    | WikiGraph Evergreen.V20.Wiki.Slug
    | WikiSearch Evergreen.V20.Wiki.Slug
    | WikiPage Evergreen.V20.Wiki.Slug Evergreen.V20.Page.Slug
    | WikiPageGraph Evergreen.V20.Wiki.Slug Evergreen.V20.Page.Slug
    | WikiLogin Evergreen.V20.Wiki.Slug (Maybe String)
    | WikiRegister Evergreen.V20.Wiki.Slug
    | WikiSubmitNew Evergreen.V20.Wiki.Slug
    | WikiSubmitEdit Evergreen.V20.Wiki.Slug Evergreen.V20.Page.Slug
    | WikiSubmitDelete Evergreen.V20.Wiki.Slug Evergreen.V20.Page.Slug
    | WikiSubmissionDetail Evergreen.V20.Wiki.Slug String
    | WikiMySubmissions Evergreen.V20.Wiki.Slug
    | WikiReview Evergreen.V20.Wiki.Slug
    | WikiReviewDetail Evergreen.V20.Wiki.Slug String
    | WikiAdminUsers Evergreen.V20.Wiki.Slug
    | WikiAdminAudit Evergreen.V20.Wiki.Slug
    | WikiAdminAuditDiff Evergreen.V20.Wiki.Slug Int
    | NotFound Url.Url

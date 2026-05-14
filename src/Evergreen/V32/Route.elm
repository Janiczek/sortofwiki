module Evergreen.V32.Route exposing (..)

import Evergreen.V32.Page
import Evergreen.V32.Wiki
import Url


type Route
    = WikiList
    | HostAdmin (Maybe String)
    | HostAdminWikis
    | HostAdminWikiNew
    | HostAdminWikiDetail Evergreen.V32.Wiki.Slug
    | HostAdminAudit
    | HostAdminAuditDiff Evergreen.V32.Wiki.Slug Int
    | HostAdminBackup
    | WikiHome Evergreen.V32.Wiki.Slug
    | WikiTodos Evergreen.V32.Wiki.Slug
    | WikiGraph Evergreen.V32.Wiki.Slug
    | WikiSearch Evergreen.V32.Wiki.Slug
    | WikiStats Evergreen.V32.Wiki.Slug
    | WikiPage Evergreen.V32.Wiki.Slug Evergreen.V32.Page.Slug
    | WikiPageGraph Evergreen.V32.Wiki.Slug Evergreen.V32.Page.Slug
    | WikiLogin Evergreen.V32.Wiki.Slug (Maybe String)
    | WikiRegister Evergreen.V32.Wiki.Slug
    | WikiSubmitNew Evergreen.V32.Wiki.Slug
    | WikiSubmitEdit Evergreen.V32.Wiki.Slug Evergreen.V32.Page.Slug
    | WikiSubmitDelete Evergreen.V32.Wiki.Slug Evergreen.V32.Page.Slug
    | WikiSubmissionDetail Evergreen.V32.Wiki.Slug String
    | WikiMySubmissions Evergreen.V32.Wiki.Slug
    | WikiReview Evergreen.V32.Wiki.Slug
    | WikiReviewDetail Evergreen.V32.Wiki.Slug String
    | WikiAdminUsers Evergreen.V32.Wiki.Slug
    | WikiAdminAudit Evergreen.V32.Wiki.Slug
    | WikiAdminAuditDiff Evergreen.V32.Wiki.Slug Int
    | NotFound Url.Url

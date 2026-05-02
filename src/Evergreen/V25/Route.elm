module Evergreen.V25.Route exposing (..)

import Evergreen.V25.Page
import Evergreen.V25.Wiki
import Url


type Route
    = WikiList
    | HostAdmin (Maybe String)
    | HostAdminWikis
    | HostAdminWikiNew
    | HostAdminWikiDetail Evergreen.V25.Wiki.Slug
    | HostAdminAudit
    | HostAdminAuditDiff Evergreen.V25.Wiki.Slug Int
    | HostAdminBackup
    | WikiHome Evergreen.V25.Wiki.Slug
    | WikiTodos Evergreen.V25.Wiki.Slug
    | WikiGraph Evergreen.V25.Wiki.Slug
    | WikiSearch Evergreen.V25.Wiki.Slug
    | WikiPage Evergreen.V25.Wiki.Slug Evergreen.V25.Page.Slug
    | WikiPageGraph Evergreen.V25.Wiki.Slug Evergreen.V25.Page.Slug
    | WikiLogin Evergreen.V25.Wiki.Slug (Maybe String)
    | WikiRegister Evergreen.V25.Wiki.Slug
    | WikiSubmitNew Evergreen.V25.Wiki.Slug
    | WikiSubmitEdit Evergreen.V25.Wiki.Slug Evergreen.V25.Page.Slug
    | WikiSubmitDelete Evergreen.V25.Wiki.Slug Evergreen.V25.Page.Slug
    | WikiSubmissionDetail Evergreen.V25.Wiki.Slug String
    | WikiMySubmissions Evergreen.V25.Wiki.Slug
    | WikiReview Evergreen.V25.Wiki.Slug
    | WikiReviewDetail Evergreen.V25.Wiki.Slug String
    | WikiAdminUsers Evergreen.V25.Wiki.Slug
    | WikiAdminAudit Evergreen.V25.Wiki.Slug
    | WikiAdminAuditDiff Evergreen.V25.Wiki.Slug Int
    | NotFound Url.Url

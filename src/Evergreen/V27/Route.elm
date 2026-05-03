module Evergreen.V27.Route exposing (..)

import Evergreen.V27.Page
import Evergreen.V27.Wiki
import Url


type Route
    = WikiList
    | HostAdmin (Maybe String)
    | HostAdminWikis
    | HostAdminWikiNew
    | HostAdminWikiDetail Evergreen.V27.Wiki.Slug
    | HostAdminAudit
    | HostAdminAuditDiff Evergreen.V27.Wiki.Slug Int
    | HostAdminBackup
    | WikiHome Evergreen.V27.Wiki.Slug
    | WikiTodos Evergreen.V27.Wiki.Slug
    | WikiGraph Evergreen.V27.Wiki.Slug
    | WikiSearch Evergreen.V27.Wiki.Slug
    | WikiStats Evergreen.V27.Wiki.Slug
    | WikiPage Evergreen.V27.Wiki.Slug Evergreen.V27.Page.Slug
    | WikiPageGraph Evergreen.V27.Wiki.Slug Evergreen.V27.Page.Slug
    | WikiLogin Evergreen.V27.Wiki.Slug (Maybe String)
    | WikiRegister Evergreen.V27.Wiki.Slug
    | WikiSubmitNew Evergreen.V27.Wiki.Slug
    | WikiSubmitEdit Evergreen.V27.Wiki.Slug Evergreen.V27.Page.Slug
    | WikiSubmitDelete Evergreen.V27.Wiki.Slug Evergreen.V27.Page.Slug
    | WikiSubmissionDetail Evergreen.V27.Wiki.Slug String
    | WikiMySubmissions Evergreen.V27.Wiki.Slug
    | WikiReview Evergreen.V27.Wiki.Slug
    | WikiReviewDetail Evergreen.V27.Wiki.Slug String
    | WikiAdminUsers Evergreen.V27.Wiki.Slug
    | WikiAdminAudit Evergreen.V27.Wiki.Slug
    | WikiAdminAuditDiff Evergreen.V27.Wiki.Slug Int
    | NotFound Url.Url

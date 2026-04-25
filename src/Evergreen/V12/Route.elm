module Evergreen.V12.Route exposing (..)

import Evergreen.V12.Page
import Evergreen.V12.Wiki
import Url


type Route
    = WikiList
    | HostAdmin (Maybe String)
    | HostAdminWikis
    | HostAdminWikiNew
    | HostAdminWikiDetail Evergreen.V12.Wiki.Slug
    | HostAdminAudit
    | HostAdminBackup
    | WikiHome Evergreen.V12.Wiki.Slug
    | WikiTodos Evergreen.V12.Wiki.Slug
    | WikiGraph Evergreen.V12.Wiki.Slug
    | WikiPage Evergreen.V12.Wiki.Slug Evergreen.V12.Page.Slug
    | WikiPageGraph Evergreen.V12.Wiki.Slug Evergreen.V12.Page.Slug
    | WikiLogin Evergreen.V12.Wiki.Slug (Maybe String)
    | WikiRegister Evergreen.V12.Wiki.Slug
    | WikiSubmitNew Evergreen.V12.Wiki.Slug
    | WikiSubmitEdit Evergreen.V12.Wiki.Slug Evergreen.V12.Page.Slug
    | WikiSubmitDelete Evergreen.V12.Wiki.Slug Evergreen.V12.Page.Slug
    | WikiSubmissionDetail Evergreen.V12.Wiki.Slug String
    | WikiMySubmissions Evergreen.V12.Wiki.Slug
    | WikiReview Evergreen.V12.Wiki.Slug
    | WikiReviewDetail Evergreen.V12.Wiki.Slug String
    | WikiAdminUsers Evergreen.V12.Wiki.Slug
    | WikiAdminAudit Evergreen.V12.Wiki.Slug
    | NotFound Url.Url

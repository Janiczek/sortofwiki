module Evergreen.V4.Route exposing (..)

import Evergreen.V4.Page
import Evergreen.V4.Wiki
import Url


type Route
    = WikiList
    | HostAdmin (Maybe String)
    | HostAdminWikis
    | HostAdminWikiNew
    | HostAdminWikiDetail Evergreen.V4.Wiki.Slug
    | HostAdminAudit
    | HostAdminBackup
    | WikiHome Evergreen.V4.Wiki.Slug
    | WikiTodos Evergreen.V4.Wiki.Slug
    | WikiGraph Evergreen.V4.Wiki.Slug
    | WikiPage Evergreen.V4.Wiki.Slug Evergreen.V4.Page.Slug
    | WikiPageGraph Evergreen.V4.Wiki.Slug Evergreen.V4.Page.Slug
    | WikiLogin Evergreen.V4.Wiki.Slug (Maybe String)
    | WikiRegister Evergreen.V4.Wiki.Slug
    | WikiSubmitNew Evergreen.V4.Wiki.Slug
    | WikiSubmitEdit Evergreen.V4.Wiki.Slug Evergreen.V4.Page.Slug
    | WikiSubmitDelete Evergreen.V4.Wiki.Slug Evergreen.V4.Page.Slug
    | WikiSubmissionDetail Evergreen.V4.Wiki.Slug String
    | WikiMySubmissions Evergreen.V4.Wiki.Slug
    | WikiReview Evergreen.V4.Wiki.Slug
    | WikiReviewDetail Evergreen.V4.Wiki.Slug String
    | WikiAdminUsers Evergreen.V4.Wiki.Slug
    | WikiAdminAudit Evergreen.V4.Wiki.Slug
    | NotFound Url.Url

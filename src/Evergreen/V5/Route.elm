module Evergreen.V5.Route exposing (..)

import Evergreen.V5.Page
import Evergreen.V5.Wiki
import Url


type Route
    = WikiList
    | HostAdmin (Maybe String)
    | HostAdminWikis
    | HostAdminWikiNew
    | HostAdminWikiDetail Evergreen.V5.Wiki.Slug
    | HostAdminAudit
    | HostAdminBackup
    | WikiHome Evergreen.V5.Wiki.Slug
    | WikiTodos Evergreen.V5.Wiki.Slug
    | WikiGraph Evergreen.V5.Wiki.Slug
    | WikiPage Evergreen.V5.Wiki.Slug Evergreen.V5.Page.Slug
    | WikiPageGraph Evergreen.V5.Wiki.Slug Evergreen.V5.Page.Slug
    | WikiLogin Evergreen.V5.Wiki.Slug (Maybe String)
    | WikiRegister Evergreen.V5.Wiki.Slug
    | WikiSubmitNew Evergreen.V5.Wiki.Slug
    | WikiSubmitEdit Evergreen.V5.Wiki.Slug Evergreen.V5.Page.Slug
    | WikiSubmitDelete Evergreen.V5.Wiki.Slug Evergreen.V5.Page.Slug
    | WikiSubmissionDetail Evergreen.V5.Wiki.Slug String
    | WikiMySubmissions Evergreen.V5.Wiki.Slug
    | WikiReview Evergreen.V5.Wiki.Slug
    | WikiReviewDetail Evergreen.V5.Wiki.Slug String
    | WikiAdminUsers Evergreen.V5.Wiki.Slug
    | WikiAdminAudit Evergreen.V5.Wiki.Slug
    | NotFound Url.Url

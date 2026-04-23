module Evergreen.V11.Route exposing (..)

import Evergreen.V11.Page
import Evergreen.V11.Wiki
import Url


type Route
    = WikiList
    | HostAdmin (Maybe String)
    | HostAdminWikis
    | HostAdminWikiNew
    | HostAdminWikiDetail Evergreen.V11.Wiki.Slug
    | HostAdminAudit
    | HostAdminBackup
    | WikiHome Evergreen.V11.Wiki.Slug
    | WikiTodos Evergreen.V11.Wiki.Slug
    | WikiGraph Evergreen.V11.Wiki.Slug
    | WikiPage Evergreen.V11.Wiki.Slug Evergreen.V11.Page.Slug
    | WikiPageGraph Evergreen.V11.Wiki.Slug Evergreen.V11.Page.Slug
    | WikiLogin Evergreen.V11.Wiki.Slug (Maybe String)
    | WikiRegister Evergreen.V11.Wiki.Slug
    | WikiSubmitNew Evergreen.V11.Wiki.Slug
    | WikiSubmitEdit Evergreen.V11.Wiki.Slug Evergreen.V11.Page.Slug
    | WikiSubmitDelete Evergreen.V11.Wiki.Slug Evergreen.V11.Page.Slug
    | WikiSubmissionDetail Evergreen.V11.Wiki.Slug String
    | WikiMySubmissions Evergreen.V11.Wiki.Slug
    | WikiReview Evergreen.V11.Wiki.Slug
    | WikiReviewDetail Evergreen.V11.Wiki.Slug String
    | WikiAdminUsers Evergreen.V11.Wiki.Slug
    | WikiAdminAudit Evergreen.V11.Wiki.Slug
    | NotFound Url.Url

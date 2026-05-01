module Frontend exposing
    ( Model
    , Msg
    , app
    , app_
    , storeConfig
    )

import Browser
import Browser.Navigation
import ColorTheme
import ContributorAccount
import ContributorWikiSession exposing (ContributorWikiSession)
import Dict exposing (Dict)
import Effect.Browser exposing (UrlRequest)
import Effect.Browser.Dom
import Effect.Browser.Navigation
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.File
import Effect.File.Download
import Effect.File.Select
import Effect.Lamdera
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Task
import HostAdmin
import Html exposing (Attribute, Html)
import Html.Attributes as Attr
import Html.Events as Events
import Json.Decode
import Lamdera
import Markdown.Block as Block
import Markdown.Html
import Markdown.Parser as MarkdownParser
import Markdown.Renderer as MarkdownRenderer
import Page
import PageGraph
import PageMarkdown
import PageToc
import PageTodos
import PendingReviewCount
import Ports
import RemoteData exposing (RemoteData(..))
import Route exposing (Route)
import RouteAccess
import SecureRedirect
import SideNavMenu
import Store exposing (Store)
import Submission
import SubmissionReviewDetail
import Svg
import Svg.Attributes as SvgAttr
import Time
import Types exposing (FrontendModel, FrontendMsg(..), HostAdminCreateWikiDraft, HostAdminLoginDraft, HostAdminWikiDetailDraft, LoginDraft, NewPageSubmitDraft, PageDeleteSubmitDraft, PageEditSubmitDraft, RegisterDraft, ReviewApproveDraft, ReviewDecision(..), ReviewRejectDraft, ReviewRequestChangesDraft, SubmissionDetailEditDraft, ToBackend(..), ToFrontend(..), emptySubmissionDetailEditDraft)
import UI
import UI.AsyncState
import UI.Button
import UI.EditorShell
import UI.EmptyState
import UI.FormActionFooter
import UI.Graph
import UI.Heading
import UI.Link
import UI.PanelHeader
import UI.ResultNotice
import UI.SidebarSection
import UI.StatusBadge
import UI.SubmissionActions
import UI.Textarea
import Url exposing (Url)
import Url.Builder as UrlBuilder
import Wiki
import WikiAdminUsers
import WikiAuditLog
import WikiGraph
import WikiRole exposing (WikiRole)
import WikiSearch
import WikiTodos


type alias Model =
    FrontendModel


type alias Msg =
    FrontendMsg


type AppHeaderSecondary
    = AppHeaderSecondaryPlain String
    | AppHeaderSecondaryWikiLink String
    | AppHeaderSecondaryPlainThenWikiLink { plainPrefix : String, wikiLabel : String }
    | AppHeaderSecondaryWikiLinkThenPlain { wikiLabel : String, plainSuffix : String }


type alias AppHeaderTitle =
    { primary : String
    , primaryHref : Maybe String
    , secondary : Maybe AppHeaderSecondary
    }


wikiLoadedHeaderTitle : Wiki.CatalogEntry -> Maybe AppHeaderSecondary -> AppHeaderTitle
wikiLoadedHeaderTitle summary maybeSecondary =
    { primary = "SortOfWiki"
    , primaryHref = Just Wiki.wikiListUrlPath
    , secondary =
        maybeSecondary
            |> Maybe.withDefault (AppHeaderSecondaryPlain summary.name)
            |> Just
    }


sortOfWikiAppHeaderTitle : Maybe AppHeaderSecondary -> AppHeaderTitle
sortOfWikiAppHeaderTitle secondary =
    { primary = "SortOfWiki"
    , primaryHref = Just Wiki.wikiListUrlPath
    , secondary = secondary
    }


submissionDetailConflictResolveSecondary : Maybe AppHeaderSecondary
submissionDetailConflictResolveSecondary =
    Nothing


storeConfig : Store.Config ToBackend
storeConfig =
    { requestWikiCatalog = RequestWikiCatalog
    , requestWikiFrontendDetails = RequestWikiFrontendDetails
    , requestPageFrontendDetails = RequestPageFrontendDetails
    , requestMyPendingSubmissions = RequestMyPendingSubmissions
    , requestReviewQueue = RequestReviewQueue
    , requestReviewSubmissionDetail = RequestReviewSubmissionDetail
    , requestWikiUsers = RequestWikiUsers
    , requestWikiAuditLog = RequestWikiAuditLog
    , requestSubmissionDetails = RequestSubmissionDetails
    }


emptyRegisterDraft : RegisterDraft
emptyRegisterDraft =
    { username = ""
    , password = ""
    , inFlight = False
    , lastResult = Nothing
    }


emptyLoginDraft : LoginDraft
emptyLoginDraft =
    { username = ""
    , password = ""
    , inFlight = False
    , lastResult = Nothing
    }


emptyHostAdminLoginDraft : HostAdminLoginDraft
emptyHostAdminLoginDraft =
    { password = ""
    , inFlight = False
    , lastResult = Nothing
    }


emptyHostAdminCreateWikiDraft : HostAdminCreateWikiDraft
emptyHostAdminCreateWikiDraft =
    { slug = ""
    , name = ""
    , initialAdminUsername = ""
    , initialAdminPassword = ""
    , inFlight = False
    , lastResult = Nothing
    }


emptyHostAdminWikiDetailDraft : HostAdminWikiDetailDraft
emptyHostAdminWikiDetailDraft =
    { wikiSlug = ""
    , load = NotAsked
    , slugDraft = ""
    , nameDraft = ""
    , summaryDraft = ""
    , saveInFlight = False
    , lastSaveResult = Nothing
    , lifecycleInFlight = False
    , lastLifecycleResult = Nothing
    , deleteConfirmDraft = ""
    , deleteInFlight = False
    , lastDeleteResult = Nothing
    }


hostAdminWikiDetailDraftLoading : Wiki.Slug -> HostAdminWikiDetailDraft
hostAdminWikiDetailDraftLoading slug =
    { wikiSlug = slug
    , load = Loading
    , slugDraft = slug
    , nameDraft = ""
    , summaryDraft = ""
    , saveInFlight = False
    , lastSaveResult = Nothing
    , lifecycleInFlight = False
    , lastLifecycleResult = Nothing
    , deleteConfirmDraft = ""
    , deleteInFlight = False
    , lastDeleteResult = Nothing
    }


emptyNewPageSubmitDraft : NewPageSubmitDraft
emptyNewPageSubmitDraft =
    { pageSlug = ""
    , pageSlugLockedFromQuery = False
    , markdownBody = ""
    , tagsInput = ""
    , maybeSavedDraftId = Nothing
    , inFlight = False
    , saveDraftInFlight = False
    , pendingSubmitAfterSave = False
    , lastResult = Nothing
    , lastSaveDraftResult = Nothing
    }


splitQueryPair : String -> Maybe ( String, String )
splitQueryPair pair =
    case String.indexes "=" pair of
        [] ->
            Nothing

        i :: _ ->
            Just ( String.left i pair, String.dropLeft (i + 1) pair )


pageParamFromQuery : Maybe String -> Maybe String
pageParamFromQuery maybeQuery =
    queryParamFromQuery "page" maybeQuery


queryParamFromQuery : String -> Maybe String -> Maybe String
queryParamFromQuery wantedKey maybeQuery =
    maybeQuery
        |> Maybe.andThen
            (\q ->
                q
                    |> String.split "&"
                    |> List.filterMap
                        (\pair ->
                            case splitQueryPair pair of
                                Just ( k, v ) ->
                                    if k == wantedKey then
                                        Url.percentDecode v

                                    else
                                        Nothing

                                Nothing ->
                                    Nothing
                        )
                    |> List.head
            )


searchParamFromQuery : Maybe String -> String
searchParamFromQuery maybeQuery =
    queryParamFromQuery "q" maybeQuery
        |> Maybe.withDefault ""


searchUrlWithQuery : Wiki.Slug -> String -> String
searchUrlWithQuery wikiSlug query =
    let
        trimmed : String
        trimmed =
            String.trim query
    in
    if String.isEmpty trimmed then
        Wiki.searchUrlPath wikiSlug

    else
        Wiki.searchUrlPath wikiSlug
            ++ UrlBuilder.toQuery [ UrlBuilder.string "q" trimmed ]


newPageSubmitDraftForRoute : Route -> Url -> NewPageSubmitDraft
newPageSubmitDraftForRoute route url =
    case route of
        Route.WikiSubmitNew _ ->
            case pageParamFromQuery url.query of
                Just slug ->
                    { emptyNewPageSubmitDraft
                        | pageSlug = slug
                        , pageSlugLockedFromQuery = True
                    }

                Nothing ->
                    emptyNewPageSubmitDraft

        _ ->
            emptyNewPageSubmitDraft


wikiIsInPublicCatalog : Store -> Wiki.Slug -> Bool
wikiIsInPublicCatalog store slug =
    case store.wikiCatalog of
        Success dict ->
            Dict.get slug dict
                |> (/=) Nothing

        _ ->
            False


{-| After `WikiFrontendDetailsResponse slug Nothing`, details are stored as Failure.
Show "Wiki not found" in the header without waiting for the catalog.
-}
wikiFrontendDetailsKnownMissing : Store -> Wiki.Slug -> Bool
wikiFrontendDetailsKnownMissing store slug =
    case Dict.get slug store.wikiDetails of
        Just (Failure _) ->
            True

        _ ->
            False


publishedSlugExistsFromWikiDetails : Wiki.FrontendDetails -> Page.Slug -> Bool
publishedSlugExistsFromWikiDetails details refSlug =
    List.any (\s -> String.toLower s == String.toLower refSlug) details.pageSlugs


wikiSideNavSlugIfActive : Model -> Maybe Wiki.Slug
wikiSideNavSlugIfActive model =
    let
        maybeSlug : Maybe Wiki.Slug
        maybeSlug =
            case model.route of
                Route.WikiHome s ->
                    Just s

                Route.WikiPage s _ ->
                    Just s

                Route.WikiPageGraph s _ ->
                    Just s

                Route.WikiTodos s ->
                    Just s

                Route.WikiGraph s ->
                    Just s

                Route.WikiSearch s ->
                    Just s

                Route.WikiRegister s ->
                    Just s

                Route.WikiLogin s _ ->
                    Just s

                Route.WikiSubmitNew s ->
                    Just s

                Route.WikiSubmitEdit s _ ->
                    Just s

                Route.WikiSubmitDelete s _ ->
                    Just s

                Route.WikiSubmissionDetail s _ ->
                    Just s

                Route.WikiMySubmissions s ->
                    Just s

                Route.WikiReview s ->
                    Just s

                Route.WikiReviewDetail s _ ->
                    Just s

                Route.WikiAdminUsers s ->
                    Just s

                Route.WikiAdminAudit s ->
                    Just s

                _ ->
                    Nothing
    in
    maybeSlug
        |> Maybe.andThen
            (\slug ->
                if wikiIsInPublicCatalog model.store slug then
                    Just slug

                else
                    Nothing
            )


emptyPageEditSubmitDraft : PageEditSubmitDraft
emptyPageEditSubmitDraft =
    { markdownBody = ""
    , tagsInput = ""
    , maybeSavedDraftId = Nothing
    , inFlight = False
    , saveDraftInFlight = False
    , pendingSubmitAfterSave = False
    , lastResult = Nothing
    , lastSaveDraftResult = Nothing
    }


pageEditSubmitDraftForRoute : Route -> Store -> PageEditSubmitDraft
pageEditSubmitDraftForRoute route store =
    case route of
        Route.WikiSubmitEdit wikiSlug pageSlug ->
            case Store.get_ ( wikiSlug, pageSlug ) store.publishedPages of
                Success details ->
                    { emptyPageEditSubmitDraft
                        | markdownBody = details.maybeMarkdownSource |> Maybe.withDefault ""
                        , tagsInput = String.join ", " details.tags
                    }

                Failure _ ->
                    emptyPageEditSubmitDraft

                Loading ->
                    emptyPageEditSubmitDraft

                NotAsked ->
                    emptyPageEditSubmitDraft

        _ ->
            emptyPageEditSubmitDraft


emptyPageDeleteSubmitDraft : PageDeleteSubmitDraft
emptyPageDeleteSubmitDraft =
    { reasonText = ""
    , maybeSavedDraftId = Nothing
    , inFlight = False
    , saveDraftInFlight = False
    , pendingSubmitAfterSave = False
    , lastResult = Nothing
    , lastSaveDraftResult = Nothing
    }


emptyReviewApproveDraft : ReviewApproveDraft
emptyReviewApproveDraft =
    { inFlight = False
    , lastResult = Nothing
    }


emptyReviewRejectDraft : ReviewRejectDraft
emptyReviewRejectDraft =
    { reasonText = ""
    , inFlight = False
    , lastResult = Nothing
    }


emptyReviewRequestChangesDraft : ReviewRequestChangesDraft
emptyReviewRequestChangesDraft =
    { guidanceText = ""
    , inFlight = False
    , lastResult = Nothing
    }


submissionDetailEditDraftFromDetail : Submission.ContributorView -> SubmissionDetailEditDraft
submissionDetailEditDraftFromDetail detail =
    { emptySubmissionDetailEditDraft
        | markdownBody = detail.compareNewMarkdown
        , newPageSlug = detail.maybeNewPageSlug |> Maybe.withDefault ""
    }


submissionDetailNextStepsText : Submission.Status -> String
submissionDetailNextStepsText status =
    case status of
        Submission.Draft ->
            "This is a draft. Save your changes, then submit for review when you are ready. A trusted contributor will approve, reject, or request changes before anything goes live on the wiki."

        Submission.Pending ->
            "A trusted contributor will review this submission. They may approve it, reject it, or ask you to revise it before it affects the wiki."

        Submission.NeedsRevision ->
            "A reviewer asked for changes. Withdraw to edit as a draft, then submit again when you are ready."

        Submission.Rejected ->
            "This submission was rejected. You can delete it to remove it from your list."

        Submission.Approved ->
            "This submission was approved and applied to the wiki."


submitDraftForReviewErrorToSubmitNewPageError : Submission.SubmitDraftForReviewError -> Submission.SubmitNewPageError
submitDraftForReviewErrorToSubmitNewPageError err =
    case err of
        Submission.SubmitDraftForReviewNotLoggedIn ->
            Submission.NotLoggedIn

        Submission.SubmitDraftForReviewWrongWikiSession ->
            Submission.WrongWikiSession

        Submission.SubmitDraftForReviewWikiNotFound ->
            Submission.WikiNotFound

        Submission.SubmitDraftForReviewWikiInactive ->
            Submission.WikiInactive

        Submission.SubmitDraftForReviewNotDraft ->
            Submission.Validation Submission.BodyEmpty

        Submission.SubmitDraftForReviewValidation ve ->
            Submission.Validation ve

        Submission.SubmitDraftForReviewSlugInUse ->
            Submission.SlugAlreadyInUse

        Submission.SubmitDraftForReviewPageExists ->
            Submission.SlugAlreadyInUse

        Submission.SubmitDraftForReviewEditTargetNotPublished ->
            Submission.Validation Submission.BodyEmpty

        Submission.SubmitDraftForReviewEditAlreadyPending ->
            Submission.Validation Submission.BodyEmpty

        Submission.SubmitDraftForReviewDeleteTargetNotPublished ->
            Submission.Validation Submission.BodyEmpty

        Submission.SubmitDraftForReviewDeleteReasonInvalid _ ->
            Submission.Validation Submission.BodyEmpty

        Submission.SubmitDraftForReviewNotFound ->
            Submission.WikiNotFound

        Submission.SubmitDraftForReviewForbidden ->
            Submission.WrongWikiSession

        Submission.SubmitDraftForReviewDeleteForbiddenTrustedModerator ->
            Submission.WrongWikiSession


submitDraftForReviewErrorToSubmitPageEditError : Submission.SubmitDraftForReviewError -> Submission.SubmitPageEditError
submitDraftForReviewErrorToSubmitPageEditError err =
    case err of
        Submission.SubmitDraftForReviewNotLoggedIn ->
            Submission.EditNotLoggedIn

        Submission.SubmitDraftForReviewWrongWikiSession ->
            Submission.EditWrongWikiSession

        Submission.SubmitDraftForReviewWikiNotFound ->
            Submission.EditWikiNotFound

        Submission.SubmitDraftForReviewWikiInactive ->
            Submission.EditWikiInactive

        Submission.SubmitDraftForReviewNotDraft ->
            Submission.EditValidation Submission.BodyEmpty

        Submission.SubmitDraftForReviewValidation ve ->
            Submission.EditValidation ve

        Submission.SubmitDraftForReviewSlugInUse ->
            Submission.EditValidation Submission.BodyEmpty

        Submission.SubmitDraftForReviewPageExists ->
            Submission.EditValidation Submission.BodyEmpty

        Submission.SubmitDraftForReviewEditTargetNotPublished ->
            Submission.EditTargetPageNotPublished

        Submission.SubmitDraftForReviewEditAlreadyPending ->
            Submission.EditAlreadyPendingForAuthor

        Submission.SubmitDraftForReviewDeleteTargetNotPublished ->
            Submission.EditValidation Submission.BodyEmpty

        Submission.SubmitDraftForReviewDeleteReasonInvalid _ ->
            Submission.EditValidation Submission.BodyEmpty

        Submission.SubmitDraftForReviewNotFound ->
            Submission.EditWikiNotFound

        Submission.SubmitDraftForReviewForbidden ->
            Submission.EditWrongWikiSession

        Submission.SubmitDraftForReviewDeleteForbiddenTrustedModerator ->
            Submission.EditWrongWikiSession


submitDraftForReviewErrorToPageDeleteFormError : Submission.SubmitDraftForReviewError -> Submission.PageDeleteFormError
submitDraftForReviewErrorToPageDeleteFormError err =
    Submission.PageDeleteRequestFailed (Submission.RequestPublishedPageDeletionSubmitDraftStepFailed err)


app_ :
    { init : Url -> Effect.Browser.Navigation.Key -> ( Model, Command FrontendOnly ToBackend Msg )
    , onUrlRequest : UrlRequest -> Msg
    , onUrlChange : Url -> Msg
    , update : Msg -> Model -> ( Model, Command FrontendOnly ToBackend Msg )
    , updateFromBackend : ToFrontend -> Model -> ( Model, Command FrontendOnly ToBackend Msg )
    , view : Model -> Effect.Browser.Document Msg
    , subscriptions : Model -> Subscription FrontendOnly Msg
    }
app_ =
    { init = init
    , onUrlRequest = UrlClicked
    , onUrlChange = UrlChanged
    , update = update
    , updateFromBackend = updateFromBackend
    , subscriptions = subscriptions
    , view = view
    }


subscriptions : Model -> Subscription FrontendOnly Msg
subscriptions _ =
    Subscription.fromJs "colorThemeFromJs"
        Ports.colorThemeFromJs
        (\value ->
            ColorThemeFromJs
                (Json.Decode.decodeValue ColorTheme.incomingDecoder value
                    |> Result.toMaybe
                )
        )


app :
    { init : Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
    , view : Model -> Browser.Document Msg
    , update : Msg -> Model -> ( Model, Cmd Msg )
    , updateFromBackend : ToFrontend -> Model -> ( Model, Cmd Msg )
    , subscriptions : Model -> Sub Msg
    , onUrlRequest : UrlRequest -> Msg
    , onUrlChange : Url -> Msg
    }
app =
    Effect.Lamdera.frontend Lamdera.sendToBackend app_


runStoreActions :
    Store
    -> List Store.Action
    -> ( Store, Command FrontendOnly ToBackend Msg )
runStoreActions store actions =
    List.foldl
        (\action ( s, cmds ) ->
            let
                ( s2, c2 ) =
                    Store.perform storeConfig action s
            in
            ( s2, c2 :: cmds )
        )
        ( store, [] )
        actions
        |> (\( s, cmds ) -> ( s, Command.batch cmds ))


runRouteStoreActions :
    ( Model, Command FrontendOnly ToBackend Msg )
    -> ( Model, Command FrontendOnly ToBackend Msg )
runRouteStoreActions ( model, cmd ) =
    let
        ( store, storeCmd ) =
            Route.storeActions model.route
                |> runStoreActions model.store

        hostWikisCmd : Command FrontendOnly ToBackend Msg
        hostWikisCmd =
            case model.route of
                Route.HostAdminWikis ->
                    Effect.Lamdera.sendToBackend RequestHostWikiList

                Route.HostAdminBackup ->
                    Effect.Lamdera.sendToBackend RequestHostWikiList

                Route.WikiList ->
                    Command.none

                Route.HostAdmin _ ->
                    Command.none

                Route.HostAdminWikiNew ->
                    Effect.Lamdera.sendToBackend RequestHostWikiList

                Route.HostAdminWikiDetail slug ->
                    Effect.Lamdera.sendToBackend (RequestHostWikiDetail slug)

                Route.HostAdminAudit ->
                    Effect.Lamdera.sendToBackend (RequestHostAuditLog model.hostAdminAuditAppliedFilter)

                Route.HostAdminAuditDiff _ _ ->
                    Effect.Lamdera.sendToBackend (RequestHostAuditLog model.hostAdminAuditAppliedFilter)

                Route.WikiHome _ ->
                    Command.none

                Route.WikiPage _ _ ->
                    Command.none

                Route.WikiPageGraph _ _ ->
                    Command.none

                Route.WikiTodos _ ->
                    Command.none

                Route.WikiGraph _ ->
                    Command.none

                Route.WikiSearch _ ->
                    Command.none

                Route.WikiRegister _ ->
                    Command.none

                Route.WikiLogin _ _ ->
                    Command.none

                Route.WikiSubmitNew _ ->
                    Command.none

                Route.WikiSubmitEdit _ _ ->
                    Command.none

                Route.WikiSubmitDelete _ _ ->
                    Command.none

                Route.WikiSubmissionDetail _ _ ->
                    Command.none

                Route.WikiMySubmissions _ ->
                    Command.none

                Route.WikiReview _ ->
                    Command.none

                Route.WikiReviewDetail _ _ ->
                    Command.none

                Route.WikiAdminUsers _ ->
                    Command.none

                Route.WikiAdminAudit _ ->
                    Command.none

                Route.WikiAdminAuditDiff _ _ ->
                    Command.none

                Route.NotFound _ ->
                    Command.none
    in
    ( { model | store = store }
    , Command.batch [ cmd, storeCmd, hostWikisCmd ]
    )


{-| History API URL updates (e.g. `pushUrl`) do not scroll to `#fragment`; mirror native behavior via `Browser.Dom`.

The article column scrolls inside `UI.appMainScrollRegionId` (`overflow-y-auto`), not the window — use `getViewportOf` / `setViewportOf` on that node.

When page details arrive later, only scroll if the address bar still has a fragment (or empty `#`) — do not snap to top on `Nothing` or we fight the user while `RemoteData` resolves.

-}
mainScrollRegionId : Effect.Browser.Dom.HtmlId
mainScrollRegionId =
    Effect.Browser.Dom.id UI.appMainScrollRegionId


scrollMainColumnToTopTask : Effect.Task.Task FrontendOnly Effect.Browser.Dom.Error ()
scrollMainColumnToTopTask =
    Effect.Browser.Dom.setViewportOf mainScrollRegionId 0 0


{-| Scroll the main column so the target id sits at the top of that scroll region (`getBoundingClientRect` delta + current `scrollTop`).
-}
scrollMainColumnToFragmentTask : String -> Effect.Task.Task FrontendOnly Effect.Browser.Dom.Error ()
scrollMainColumnToFragmentTask frag =
    let
        targetId : Effect.Browser.Dom.HtmlId
        targetId =
            Effect.Browser.Dom.id frag
    in
    Effect.Browser.Dom.getViewportOf mainScrollRegionId
        |> Effect.Task.andThen
            (\vp ->
                Effect.Browser.Dom.getElement targetId
                    |> Effect.Task.andThen
                        (\el ->
                            Effect.Browser.Dom.getElement mainScrollRegionId
                                |> Effect.Task.andThen
                                    (\containerEl ->
                                        Effect.Browser.Dom.setViewportOf
                                            mainScrollRegionId
                                            0
                                            (vp.viewport.y + el.element.y - containerEl.element.y)
                                    )
                        )
            )


scrollToNavigationFragmentCmd : Maybe String -> Command FrontendOnly ToBackend Msg
scrollToNavigationFragmentCmd maybeFragment =
    case maybeFragment of
        Nothing ->
            Command.none

        Just "" ->
            scrollMainColumnToTopTask
                |> Effect.Task.attempt (\_ -> UrlFragmentScrollDone)

        Just frag ->
            scrollMainColumnToFragmentTask frag
                |> Effect.Task.attempt (\_ -> UrlFragmentScrollDone)


{-| After `init` / `UrlChanged`, the browser URL has been updated. No fragment means the hash was cleared or the new location has no hash — scroll to the top like a full navigation would.
-}
scrollAfterUrlChangeCmd : Maybe String -> Command FrontendOnly ToBackend Msg
scrollAfterUrlChangeCmd maybeFragment =
    case maybeFragment of
        Nothing ->
            scrollMainColumnToTopTask
                |> Effect.Task.attempt (\_ -> UrlFragmentScrollDone)

        Just "" ->
            scrollMainColumnToTopTask
                |> Effect.Task.attempt (\_ -> UrlFragmentScrollDone)

        Just frag ->
            scrollMainColumnToFragmentTask frag
                |> Effect.Task.attempt (\_ -> UrlFragmentScrollDone)


batchScrollAfterUrlChange :
    Maybe String
    -> ( Model, Command FrontendOnly ToBackend Msg )
    -> ( Model, Command FrontendOnly ToBackend Msg )
batchScrollAfterUrlChange fragment ( m, c ) =
    ( m, Command.batch [ c, scrollAfterUrlChangeCmd fragment ] )


anonGatedWikiRoute : Model -> Url -> Route -> ( Route, Maybe String )
anonGatedWikiRoute model url parsed =
    case RouteAccess.contributorForcedRedirect model.contributorWikiSessions url parsed of
        Just (RouteAccess.ToContributorLogin wikiSlug ret) ->
            ( Route.WikiLogin wikiSlug (Just ret)
            , Just (Wiki.loginUrlPathWithRedirect wikiSlug ret)
            )

        Just (RouteAccess.AwayFromMySubmissions wikiSlug) ->
            ( Route.WikiHome wikiSlug
            , Just (Wiki.wikiHomeUrlPath wikiSlug)
            )

        Nothing ->
            ( parsed, Nothing )


postLogoutNavigationCmd : Wiki.Slug -> Model -> Command FrontendOnly ToBackend Msg
postLogoutNavigationCmd loggedOutWiki model =
    case RouteAccess.contributorRestrictedReturnPath model.route of
        Just ( w, retPath ) ->
            if w == loggedOutWiki then
                Effect.Browser.Navigation.replaceUrl model.key (Wiki.loginUrlPathWithRedirect loggedOutWiki retPath)

            else
                Command.none

        Nothing ->
            Command.none


gatedWikiRoute : Model -> Url -> ( Route, Maybe String )
gatedWikiRoute model url =
    let
        parsed : Route
        parsed =
            Route.fromUrl url
    in
    case parsed of
        Route.WikiLogin wikiSlug _ ->
            if contributorLoggedInOnWikiSlug wikiSlug model then
                ( Route.WikiHome wikiSlug, Just (Wiki.wikiHomeUrlPath wikiSlug) )

            else
                anonGatedWikiRoute model url parsed

        _ ->
            anonGatedWikiRoute model url parsed


contributorLoggedInOnWikiSlug : Wiki.Slug -> Model -> Bool
contributorLoggedInOnWikiSlug wikiSlug model =
    Dict.member wikiSlug model.contributorWikiSessions


syncContributorWikiSessionFromFrontendDetails :
    Wiki.Slug
    -> Maybe Wiki.FrontendDetails
    -> Dict Wiki.Slug ContributorWikiSession
    -> Dict Wiki.Slug ContributorWikiSession
syncContributorWikiSessionFromFrontendDetails wikiSlug maybeDetails sessions =
    case maybeDetails |> Maybe.andThen .viewerSession of
        Just viewerSession ->
            Dict.insert wikiSlug viewerSession sessions

        Nothing ->
            Dict.remove wikiSlug sessions


contributorRouteNeedsSessionRefresh : Wiki.Slug -> Route -> Bool
contributorRouteNeedsSessionRefresh wikiSlug route =
    case route of
        Route.WikiLogin routeWikiSlug _ ->
            routeWikiSlug == wikiSlug

        Route.WikiRegister routeWikiSlug ->
            routeWikiSlug == wikiSlug

        _ ->
            case RouteAccess.contributorRestrictedReturnPath route of
                Just ( routeWikiSlug, _ ) ->
                    routeWikiSlug == wikiSlug

                Nothing ->
                    False


currentRouteUrl : Route -> Url
currentRouteUrl route =
    Url.fromString ("https://sortofwiki.test" ++ Route.navUrlPath route)
        |> Maybe.withDefault
            { protocol = Url.Https
            , host = "sortofwiki.test"
            , port_ = Nothing
            , path = Route.navUrlPath route
            , query = Nothing
            , fragment = Nothing
            }


contributorRouteRefreshCmd : Wiki.Slug -> Model -> Command FrontendOnly ToBackend Msg
contributorRouteRefreshCmd wikiSlug model =
    if contributorRouteNeedsSessionRefresh wikiSlug model.route then
        case model.route of
            Route.WikiLogin routeWikiSlug maybeRedirect ->
                if routeWikiSlug == wikiSlug && contributorLoggedInOnWikiSlug wikiSlug model then
                    Effect.Browser.Navigation.replaceUrl model.key
                        (maybeRedirect |> Maybe.withDefault (Wiki.wikiHomeUrlPath wikiSlug))

                else
                    Command.none

            Route.WikiRegister routeWikiSlug ->
                if routeWikiSlug == wikiSlug && contributorLoggedInOnWikiSlug wikiSlug model then
                    Effect.Browser.Navigation.replaceUrl model.key (Wiki.wikiHomeUrlPath wikiSlug)

                else
                    Command.none

            _ ->
                case RouteAccess.contributorForcedRedirect model.contributorWikiSessions (currentRouteUrl model.route) model.route of
                    Just (RouteAccess.ToContributorLogin routeWikiSlug ret) ->
                        if routeWikiSlug == wikiSlug then
                            Effect.Browser.Navigation.replaceUrl model.key (Wiki.loginUrlPathWithRedirect routeWikiSlug ret)

                        else
                            Command.none

                    Just (RouteAccess.AwayFromMySubmissions routeWikiSlug) ->
                        if routeWikiSlug == wikiSlug then
                            Effect.Browser.Navigation.replaceUrl model.key (Wiki.wikiHomeUrlPath routeWikiSlug)

                        else
                            Command.none

                    Nothing ->
                        Command.none

    else
        Command.none


wikiSessionTrustedOnWiki : Wiki.Slug -> Model -> Bool
wikiSessionTrustedOnWiki wikiSlug model =
    model.contributorWikiSessions
        |> Dict.get wikiSlug
        |> Maybe.map (.role >> WikiRole.isTrustedModerator)
        |> Maybe.withDefault False


{-| True when the platform host-admin session is known to be valid (from login or any
successful host-admin response). Not tied to whether the wiki list RemoteData is loaded
for the current route, so chrome stays consistent across `/admin/wikis` and `/admin/wikis/:slug`.
-}
hostAdminAuthenticated : Model -> Bool
hostAdminAuthenticated model =
    model.hostAdminSessionAuthenticated


hostAdminSectionNavVisible : Model -> Bool
hostAdminSectionNavVisible model =
    case model.route of
        Route.HostAdminWikis ->
            True

        Route.HostAdminWikiNew ->
            True

        Route.HostAdminWikiDetail _ ->
            True

        Route.HostAdminAudit ->
            True

        Route.HostAdminAuditDiff _ _ ->
            True

        Route.HostAdminBackup ->
            True

        Route.HostAdmin _ ->
            case model.hostAdminLoginDraft.lastResult of
                Just (Ok ()) ->
                    True

                _ ->
                    False

        _ ->
            False


sideNavLinkLi : SideNavMenu.Link -> Html Msg
sideNavLinkLi link =
    case link.linkRoute of
        Route.HostAdmin Nothing ->
            Html.li []
                [ UI.Link.navListItemMuted link.linkEmphasized
                    [ Attr.href (Route.navUrlPath link.linkRoute)
                    ]
                    [ Html.text link.linkLabel ]
                ]

        _ ->
            Html.li []
                [ UI.Link.navListItem link.linkEmphasized
                    [ Attr.href (Route.navUrlPath link.linkRoute)
                    ]
                    [ Html.text link.linkLabel ]
                ]


reviewQueueCountForWiki :
    WikiRole.WikiRole
    -> Wiki.Slug
    -> Store
    -> Maybe Int
reviewQueueCountForWiki role wikiSlug store =
    let
        fromDetails : Maybe Int
        fromDetails =
            if WikiRole.isTrustedModerator role then
                case Store.get_ wikiSlug store.wikiDetails of
                    Success details ->
                        details.pendingReviewCountForTrustedViewer

                    _ ->
                        Nothing

            else
                Nothing

        fromQueue : Maybe Int
        fromQueue =
            case Store.get_ wikiSlug store.reviewQueues of
                Success (Ok reviewQueue) ->
                    Just (List.length reviewQueue)

                _ ->
                    Nothing
    in
    case ( fromDetails, fromQueue ) of
        ( Just n, _ ) ->
            Just n

        ( Nothing, Just n ) ->
            Just n

        ( Nothing, Nothing ) ->
            Nothing


withReviewQueueCount : Wiki.Slug -> Maybe Int -> List SideNavMenu.Link -> List SideNavMenu.Link
withReviewQueueCount wikiSlug maybeReviewCount links =
    links
        |> List.map
            (\link ->
                case link.linkRoute of
                    Route.WikiReview routeWikiSlug ->
                        if routeWikiSlug == wikiSlug then
                            case maybeReviewCount of
                                Just reviewCount ->
                                    { link
                                        | linkLabel = "Review (" ++ String.fromInt reviewCount ++ ")"
                                        , linkEmphasized = reviewCount > 0
                                    }

                                Nothing ->
                                    { link
                                        | linkLabel = "Review (…)"
                                        , linkEmphasized = False
                                    }

                        else
                            link

                    _ ->
                        link
            )


sideNavSectionFromMenu : SideNavMenu.Section -> SideNavSection Msg
sideNavSectionFromMenu section =
    { heading = section.sectionTitle
    , items = List.map sideNavLinkLi section.links
    }


type alias SideNavSection msg =
    { heading : String
    , items : List (Html msg)
    }


viewSideNavSections : List (SideNavSection Msg) -> List (Html Msg)
viewSideNavSections sections =
    sections
        |> List.map
            (\section ->
                Html.div []
                    [ UI.Heading.sidebarHeading section.heading
                    , Html.div [ UI.sidebarNavSectionBodyAttr ]
                        [ Html.ul [ UI.sideNavListAttr ] section.items ]
                    ]
            )


viewSideNavBottomLinks : List (SideNavSection Msg) -> List (Html Msg)
viewSideNavBottomLinks sections =
    sections
        |> List.concatMap .items
        |> Html.ul [ UI.sideNavListAttr ]
        |> List.singleton


viewSideNav : String -> List (SideNavSection Msg) -> Html Msg
viewSideNav ariaLabel sections =
    let
        ( topSections, bottomSections ) =
            List.partition (\section -> section.heading /= "Site") sections

        navChildren : List (Html Msg)
        navChildren =
            [ Html.div [ UI.sideNavMainSectionAttr ]
                [ Html.div [ UI.sideNavStackAttr ] (viewSideNavSections topSections) ]
            ]
                ++ (if List.isEmpty bottomSections then
                        []

                    else
                        [ Html.div [ UI.sideNavBottomSectionAttr ]
                            [ Html.div [ UI.sideNavStackAttr ] (viewSideNavBottomLinks bottomSections) ]
                        ]
                   )
    in
    Html.nav
        [ UI.sideNavNavAttr
        , Attr.attribute "aria-label" ariaLabel
        ]
        navChildren


viewSortOfWikiSideNavSections : Model -> List (SideNavSection Msg)
viewSortOfWikiSideNavSections model =
    SideNavMenu.globalChromeSections
        { hostAdminAuthenticated = hostAdminAuthenticated model
        , showHostAdminTools = hostAdminSectionNavVisible model
        }
        |> List.map sideNavSectionFromMenu


init :
    Url
    -> Effect.Browser.Navigation.Key
    -> ( Model, Command FrontendOnly ToBackend Msg )
init url key =
    let
        emptySessionModel : Model
        emptySessionModel =
            { key = key
            , colorThemePreference = ColorTheme.FollowSystem
            , systemColorTheme = ColorTheme.Dark
            , route = Route.WikiList
            , store = Store.empty
            , contributorWikiSessions = Dict.empty
            , registerDraft = emptyRegisterDraft
            , loginDraft = emptyLoginDraft
            , headerSearchQuery = ""
            , wikiSearchPageQuery = ""
            , newPageSubmitDraft = emptyNewPageSubmitDraft
            , pageEditSubmitDraft = emptyPageEditSubmitDraft
            , pageDeleteSubmitDraft = emptyPageDeleteSubmitDraft
            , reviewApproveDraft = emptyReviewApproveDraft
            , reviewDecision = ReviewDecisionApprove
            , reviewRejectDraft = emptyReviewRejectDraft
            , reviewRequestChangesDraft = emptyReviewRequestChangesDraft
            , submissionDetailEditDraft = emptySubmissionDetailEditDraft
            , adminPromoteError = Nothing
            , adminDemoteError = Nothing
            , adminGrantAdminError = Nothing
            , adminRevokeAdminError = Nothing
            , wikiAdminAuditFilterActorDraft = ""
            , wikiAdminAuditFilterPageDraft = ""
            , wikiAdminAuditFilterSelectedKindTags = []
            , wikiAdminAuditAppliedFilter = WikiAuditLog.emptyAuditLogFilter
            , hostAdminAuditFilterWikiDraft = ""
            , hostAdminAuditFilterActorDraft = ""
            , hostAdminAuditFilterPageDraft = ""
            , hostAdminAuditFilterSelectedKindTags = []
            , hostAdminAuditAppliedFilter = WikiAuditLog.emptyHostAuditLogFilter
            , hostAdminAuditLog = RemoteData.NotAsked
            , hostAdminLoginDraft = emptyHostAdminLoginDraft
            , hostAdminCreateWikiDraft = emptyHostAdminCreateWikiDraft
            , hostAdminWikiDetailDraft = emptyHostAdminWikiDetailDraft
            , hostAdminWikis = RemoteData.NotAsked
            , hostAdminSessionAuthenticated = False
            , hostAdminExportInFlight = False
            , hostAdminImportInFlight = False
            , hostAdminBackupNotice = Nothing
            , hostAdminWikiExportInFlightSlug = Nothing
            , hostAdminWikiImportInFlightSlug = Nothing
            , hostAdminWikiImportPendingSlug = Nothing
            , hostAdminWikisNotice = Nothing
            , navigationFragment = Nothing
            }

        ( route, maybeContributorReplace ) =
            gatedWikiRoute emptySessionModel url

        navCmd : Command FrontendOnly ToBackend Msg
        navCmd =
            maybeContributorReplace
                |> Maybe.map (\target -> Effect.Browser.Navigation.replaceUrl key target)
                |> Maybe.withDefault Command.none

        model : Model
        model =
            { key = key
            , colorThemePreference = ColorTheme.FollowSystem
            , systemColorTheme = ColorTheme.Dark
            , route = route
            , store = Store.empty
            , contributorWikiSessions = Dict.empty
            , registerDraft = emptyRegisterDraft
            , loginDraft = emptyLoginDraft
            , headerSearchQuery =
                case route of
                    Route.WikiSearch _ ->
                        searchParamFromQuery url.query

                    _ ->
                        ""
            , wikiSearchPageQuery =
                case route of
                    Route.WikiSearch _ ->
                        searchParamFromQuery url.query

                    _ ->
                        ""
            , newPageSubmitDraft = newPageSubmitDraftForRoute route url
            , pageEditSubmitDraft = pageEditSubmitDraftForRoute route Store.empty
            , pageDeleteSubmitDraft = emptyPageDeleteSubmitDraft
            , reviewApproveDraft = emptyReviewApproveDraft
            , reviewDecision = ReviewDecisionApprove
            , reviewRejectDraft = emptyReviewRejectDraft
            , reviewRequestChangesDraft = emptyReviewRequestChangesDraft
            , submissionDetailEditDraft = emptySubmissionDetailEditDraft
            , adminPromoteError = Nothing
            , adminDemoteError = Nothing
            , adminGrantAdminError = Nothing
            , adminRevokeAdminError = Nothing
            , wikiAdminAuditFilterActorDraft = ""
            , wikiAdminAuditFilterPageDraft = ""
            , wikiAdminAuditFilterSelectedKindTags = []
            , wikiAdminAuditAppliedFilter = WikiAuditLog.emptyAuditLogFilter
            , hostAdminAuditFilterWikiDraft = ""
            , hostAdminAuditFilterActorDraft = ""
            , hostAdminAuditFilterPageDraft = ""
            , hostAdminAuditFilterSelectedKindTags = []
            , hostAdminAuditAppliedFilter = WikiAuditLog.emptyHostAuditLogFilter
            , hostAdminAuditLog =
                case route of
                    Route.HostAdminAudit ->
                        RemoteData.Loading

                    Route.HostAdminAuditDiff _ _ ->
                        RemoteData.Loading

                    _ ->
                        RemoteData.NotAsked
            , hostAdminLoginDraft = emptyHostAdminLoginDraft
            , hostAdminCreateWikiDraft = emptyHostAdminCreateWikiDraft
            , hostAdminWikiDetailDraft =
                case route of
                    Route.HostAdminWikiDetail slug ->
                        hostAdminWikiDetailDraftLoading slug

                    _ ->
                        emptyHostAdminWikiDetailDraft
            , hostAdminWikis =
                case route of
                    Route.HostAdminWikis ->
                        RemoteData.Loading

                    Route.HostAdminBackup ->
                        RemoteData.Loading

                    Route.HostAdminWikiNew ->
                        RemoteData.Loading

                    _ ->
                        RemoteData.NotAsked
            , hostAdminSessionAuthenticated = False
            , hostAdminExportInFlight = False
            , hostAdminImportInFlight = False
            , hostAdminBackupNotice = Nothing
            , hostAdminWikiExportInFlightSlug = Nothing
            , hostAdminWikiImportInFlightSlug = Nothing
            , hostAdminWikiImportPendingSlug = Nothing
            , hostAdminWikisNotice = Nothing
            , navigationFragment = url.fragment
            }
    in
    ( model, navCmd )
        |> runRouteStoreActions
        |> batchScrollAfterUrlChange url.fragment


storeInModel :
    ( Model, Command FrontendOnly ToBackend Msg )
    -> ( Store, Command FrontendOnly ToBackend Msg )
    -> ( Model, Command FrontendOnly ToBackend Msg )
storeInModel ( model, mCmd ) ( store, sCmd ) =
    ( { model | store = store }
    , Command.batch [ mCmd, sCmd ]
    )


routeUsesAuditLogFillLayout : Route -> Bool
routeUsesAuditLogFillLayout route =
    case route of
        Route.WikiList ->
            False

        Route.HostAdmin _ ->
            False

        Route.HostAdminWikis ->
            False

        Route.HostAdminWikiNew ->
            False

        Route.HostAdminWikiDetail _ ->
            False

        Route.HostAdminAudit ->
            True

        Route.HostAdminAuditDiff _ _ ->
            True

        Route.HostAdminBackup ->
            False

        Route.WikiHome _ ->
            False

        Route.WikiPage _ _ ->
            False

        Route.WikiPageGraph _ _ ->
            False

        Route.WikiTodos _ ->
            False

        Route.WikiGraph _ ->
            False

        Route.WikiSearch _ ->
            False

        Route.WikiLogin _ _ ->
            False

        Route.WikiRegister _ ->
            False

        Route.WikiSubmitNew _ ->
            True

        Route.WikiSubmitEdit _ _ ->
            True

        Route.WikiSubmitDelete _ _ ->
            False

        Route.WikiSubmissionDetail _ _ ->
            False

        Route.WikiMySubmissions _ ->
            False

        Route.WikiReview _ ->
            False

        Route.WikiReviewDetail _ _ ->
            False

        Route.WikiAdminUsers _ ->
            False

        Route.WikiAdminAudit _ ->
            True

        Route.WikiAdminAuditDiff _ _ ->
            True

        Route.NotFound _ ->
            False


applyWikiAdminAuditFilterFromModel : Model -> ( Model, Command FrontendOnly ToBackend Msg )
applyWikiAdminAuditFilterFromModel model =
    case model.route of
        Route.WikiAdminAudit wikiSlug ->
            let
                applied : WikiAuditLog.AuditLogFilter
                applied =
                    { actorUsernameSubstring = model.wikiAdminAuditFilterActorDraft
                    , pageSlugSubstring = model.wikiAdminAuditFilterPageDraft
                    , eventKindTags = model.wikiAdminAuditFilterSelectedKindTags
                    }

                withApplied : Model
                withApplied =
                    { model | wikiAdminAuditAppliedFilter = applied }
            in
            storeInModel ( withApplied, Command.none )
                (Store.perform storeConfig (Store.RefreshWikiAuditLog wikiSlug applied) withApplied.store)

        Route.WikiAdminAuditDiff _ _ ->
            ( model, Command.none )

        Route.WikiList ->
            ( model, Command.none )

        Route.HostAdmin _ ->
            ( model, Command.none )

        Route.HostAdminWikis ->
            ( model, Command.none )

        Route.HostAdminWikiNew ->
            ( model, Command.none )

        Route.HostAdminWikiDetail _ ->
            ( model, Command.none )

        Route.HostAdminAudit ->
            ( model, Command.none )

        Route.HostAdminAuditDiff _ _ ->
            ( model, Command.none )

        Route.HostAdminBackup ->
            ( model, Command.none )

        Route.WikiHome _ ->
            ( model, Command.none )

        Route.WikiPage _ _ ->
            ( model, Command.none )

        Route.WikiPageGraph _ _ ->
            ( model, Command.none )

        Route.WikiTodos _ ->
            ( model, Command.none )

        Route.WikiGraph _ ->
            ( model, Command.none )

        Route.WikiSearch _ ->
            ( model, Command.none )

        Route.WikiLogin _ _ ->
            ( model, Command.none )

        Route.WikiRegister _ ->
            ( model, Command.none )

        Route.WikiSubmitNew _ ->
            ( model, Command.none )

        Route.WikiSubmitEdit _ _ ->
            ( model, Command.none )

        Route.WikiSubmitDelete _ _ ->
            ( model, Command.none )

        Route.WikiSubmissionDetail _ _ ->
            ( model, Command.none )

        Route.WikiMySubmissions _ ->
            ( model, Command.none )

        Route.WikiReview _ ->
            ( model, Command.none )

        Route.WikiReviewDetail _ _ ->
            ( model, Command.none )

        Route.WikiAdminUsers _ ->
            ( model, Command.none )

        Route.NotFound _ ->
            ( model, Command.none )


applyHostAdminAuditFilterFromModel : Model -> ( Model, Command FrontendOnly ToBackend Msg )
applyHostAdminAuditFilterFromModel model =
    case model.route of
        Route.HostAdminAudit ->
            let
                applied : WikiAuditLog.HostAuditLogFilter
                applied =
                    { wikiSlugSubstring = model.hostAdminAuditFilterWikiDraft
                    , actorUsernameSubstring = model.hostAdminAuditFilterActorDraft
                    , pageSlugSubstring = model.hostAdminAuditFilterPageDraft
                    , eventKindTags = model.hostAdminAuditFilterSelectedKindTags
                    }
            in
            if WikiAuditLog.hostAuditLogFilterCacheKey applied == WikiAuditLog.hostAuditLogFilterCacheKey model.hostAdminAuditAppliedFilter then
                ( model, Command.none )

            else
                ( { model
                    | hostAdminAuditAppliedFilter = applied
                    , hostAdminAuditLog = RemoteData.Loading
                  }
                , Effect.Lamdera.sendToBackend (RequestHostAuditLog applied)
                )

        Route.HostAdminAuditDiff _ _ ->
            ( model, Command.none )

        Route.WikiList ->
            ( model, Command.none )

        Route.HostAdmin _ ->
            ( model, Command.none )

        Route.HostAdminWikis ->
            ( model, Command.none )

        Route.HostAdminWikiNew ->
            ( model, Command.none )

        Route.HostAdminWikiDetail _ ->
            ( model, Command.none )

        Route.HostAdminBackup ->
            ( model, Command.none )

        Route.WikiHome _ ->
            ( model, Command.none )

        Route.WikiPage _ _ ->
            ( model, Command.none )

        Route.WikiPageGraph _ _ ->
            ( model, Command.none )

        Route.WikiTodos _ ->
            ( model, Command.none )

        Route.WikiGraph _ ->
            ( model, Command.none )

        Route.WikiSearch _ ->
            ( model, Command.none )

        Route.WikiLogin _ _ ->
            ( model, Command.none )

        Route.WikiRegister _ ->
            ( model, Command.none )

        Route.WikiSubmitNew _ ->
            ( model, Command.none )

        Route.WikiSubmitEdit _ _ ->
            ( model, Command.none )

        Route.WikiSubmitDelete _ _ ->
            ( model, Command.none )

        Route.WikiSubmissionDetail _ _ ->
            ( model, Command.none )

        Route.WikiMySubmissions _ ->
            ( model, Command.none )

        Route.WikiReview _ ->
            ( model, Command.none )

        Route.WikiReviewDetail _ _ ->
            ( model, Command.none )

        Route.WikiAdminUsers _ ->
            ( model, Command.none )

        Route.WikiAdminAudit _ ->
            ( model, Command.none )

        Route.WikiAdminAuditDiff _ _ ->
            ( model, Command.none )

        Route.NotFound _ ->
            ( model, Command.none )


{-| After trusted direct publish, drop cached wiki index and page payloads so the next fetch sees server state.
-}
invalidateWikiPublishedCaches : Wiki.Slug -> Store -> Store
invalidateWikiPublishedCaches wikiSlug store =
    { store
        | wikiDetails = Dict.remove wikiSlug store.wikiDetails
        , publishedPages =
            store.publishedPages
                |> Dict.filter (\( w, _ ) _ -> w /= wikiSlug)
    }


{-| Trusted immediate publish: clear this wiki's published page payloads (they are stale) but keep
`wikiDetails` when already loaded and extend `pageSlugs` so we do not drop to Loading on
`/submit/new` (which would flash until `WikiFrontendDetailsResponse`). Navigation to the new page
uses `pushUrl` in the same update.
-}
afterTrustedNewPagePublishedImmediately : Wiki.Slug -> { pageSlug : Page.Slug, markdown : String, tags : List Page.Slug } -> Store -> Store
afterTrustedNewPagePublishedImmediately wikiSlug payload store =
    let
        publishedPagesNext : Dict ( Wiki.Slug, Page.Slug ) (RemoteData () Page.FrontendDetails)
        publishedPagesNext =
            store.publishedPages
                |> Dict.filter (\( w, _ ) _ -> w /= wikiSlug)

        wikiDetailsNext : Dict Wiki.Slug (RemoteData () Wiki.FrontendDetails)
        wikiDetailsNext =
            case Dict.get wikiSlug store.wikiDetails of
                Just (Success details) ->
                    Dict.insert wikiSlug
                        (Success
                            { details
                                | pageSlugs =
                                    if List.member payload.pageSlug details.pageSlugs then
                                        details.pageSlugs

                                    else
                                        payload.pageSlug :: details.pageSlugs |> List.sort
                                , publishedPageMarkdownSources =
                                    Dict.insert payload.pageSlug payload.markdown details.publishedPageMarkdownSources
                                , publishedPageTags =
                                    Dict.insert payload.pageSlug payload.tags details.publishedPageTags
                            }
                        )
                        store.wikiDetails

                _ ->
                    Dict.remove wikiSlug store.wikiDetails
    in
    { store | publishedPages = publishedPagesNext, wikiDetails = wikiDetailsNext }


{-| Trusted immediate edit: extend cached wiki details with new markdown and tags for this slug (matches server `Wiki.applyPublishedMarkdownEdit`).
-}
afterTrustedEditPublishedImmediately :
    Wiki.Slug
    -> Page.Slug
    -> { proposedMarkdown : String, tags : List Page.Slug }
    -> Store
    -> Store
afterTrustedEditPublishedImmediately wikiSlug pageSlug edit store =
    case Dict.get wikiSlug store.wikiDetails of
        Just (Success details) ->
            { store
                | wikiDetails =
                    Dict.insert wikiSlug
                        (Success
                            { details
                                | publishedPageMarkdownSources =
                                    Dict.insert pageSlug edit.proposedMarkdown details.publishedPageMarkdownSources
                                , publishedPageTags =
                                    Dict.insert pageSlug edit.tags details.publishedPageTags
                            }
                        )
                        store.wikiDetails
                , publishedPages =
                    Dict.remove ( wikiSlug, pageSlug ) store.publishedPages
            }

        _ ->
            invalidateWikiPublishedCaches wikiSlug store


{-| After a successful approve, drop cached wiki/page/review data so the next fetch matches the server.
-}
afterApproveSubmissionCaches : Wiki.Slug -> String -> Store -> Store
afterApproveSubmissionCaches wikiSlug submissionId store =
    let
        base : Store
        base =
            invalidateWikiPublishedCaches wikiSlug store
    in
    { base
        | reviewQueues = Dict.remove wikiSlug base.reviewQueues
        , myPendingSubmissions = Dict.remove wikiSlug base.myPendingSubmissions
        , reviewSubmissionDetails =
            Dict.remove ( wikiSlug, submissionId ) base.reviewSubmissionDetails
    }


{-| After a successful reject: review caches + contributor submission detail; wiki pages unchanged.
-}
afterRejectSubmissionCaches : Wiki.Slug -> String -> Store -> Store
afterRejectSubmissionCaches wikiSlug submissionId store =
    { store
        | reviewQueues = Dict.remove wikiSlug store.reviewQueues
        , myPendingSubmissions = Dict.remove wikiSlug store.myPendingSubmissions
        , reviewSubmissionDetails =
            Dict.remove ( wikiSlug, submissionId ) store.reviewSubmissionDetails
        , submissionDetails =
            Dict.remove ( wikiSlug, submissionId ) store.submissionDetails
    }


{-| Same-origin `pushUrl` string: path, query, and fragment only. Full `Url.toString` breaks `lamdera/program-test` navigation simulation.
-}
navigationUrlForPush : Url -> String
navigationUrlForPush u =
    let
        basePath : String
        basePath =
            if u.path == "" then
                "/"

            else
                u.path
    in
    basePath
        |> (\p ->
                case u.query of
                    Nothing ->
                        p

                    Just q ->
                        p ++ "?" ++ q
           )
        |> (\p ->
                case u.fragment of
                    Nothing ->
                        p

                    Just f ->
                        p ++ "#" ++ f
           )


update : Msg -> Model -> ( Model, Command FrontendOnly ToBackend Msg )
update msg model =
    case msg of
        ColorThemeToggled ->
            let
                nextPreference : ColorTheme.ColorThemePreference
                nextPreference =
                    ColorTheme.cyclePreference model.colorThemePreference
            in
            ( { model | colorThemePreference = nextPreference }
            , Command.sendToJs "colorThemeToJs" Ports.colorThemeToJs (ColorTheme.encodePreferenceToJs nextPreference)
            )

        ColorThemeFromJs maybeIncoming ->
            case maybeIncoming of
                Just (ColorTheme.Sync preference systemTheme) ->
                    ( { model
                        | colorThemePreference = preference
                        , systemColorTheme = systemTheme
                      }
                    , Command.none
                    )

                Just (ColorTheme.System systemTheme) ->
                    ( { model | systemColorTheme = systemTheme }
                    , Command.none
                    )

                Nothing ->
                    ( model, Command.none )

        UrlClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model
                    , Effect.Browser.Navigation.pushUrl model.key (navigationUrlForPush url)
                    )

                Browser.External url ->
                    ( model
                    , Effect.Browser.Navigation.load url
                    )

        UrlChanged url ->
            let
                ( route, maybeContributorReplace ) =
                    gatedWikiRoute model url

                navCmd : Command FrontendOnly ToBackend Msg
                navCmd =
                    maybeContributorReplace
                        |> Maybe.map (\target -> Effect.Browser.Navigation.replaceUrl model.key target)
                        |> Maybe.withDefault Command.none

                storeForRoute : Store
                storeForRoute =
                    let
                        store : Store
                        store =
                            model.store
                    in
                    case route of
                        Route.WikiLogin slug _ ->
                            { store
                                | wikiUsers = Dict.remove slug store.wikiUsers
                                , wikiAuditLogs = Dict.remove slug store.wikiAuditLogs
                            }

                        _ ->
                            store

                baseNext : Model
                baseNext =
                    { model
                        | route = route
                        , navigationFragment = url.fragment
                        , store = storeForRoute
                        , registerDraft = emptyRegisterDraft
                        , loginDraft = emptyLoginDraft
                        , headerSearchQuery =
                            case route of
                                Route.WikiSearch _ ->
                                    searchParamFromQuery url.query

                                _ ->
                                    ""
                        , wikiSearchPageQuery =
                            case route of
                                Route.WikiSearch _ ->
                                    searchParamFromQuery url.query

                                _ ->
                                    ""
                        , newPageSubmitDraft = newPageSubmitDraftForRoute route url
                        , pageEditSubmitDraft = pageEditSubmitDraftForRoute route storeForRoute
                        , pageDeleteSubmitDraft = emptyPageDeleteSubmitDraft
                        , reviewApproveDraft = emptyReviewApproveDraft
                        , reviewDecision = ReviewDecisionApprove
                        , reviewRejectDraft = emptyReviewRejectDraft
                        , reviewRequestChangesDraft = emptyReviewRequestChangesDraft
                        , submissionDetailEditDraft = emptySubmissionDetailEditDraft
                        , adminPromoteError = Nothing
                        , adminDemoteError = Nothing
                        , adminGrantAdminError = Nothing
                        , adminRevokeAdminError = Nothing
                        , hostAdminLoginDraft = emptyHostAdminLoginDraft
                        , hostAdminCreateWikiDraft = emptyHostAdminCreateWikiDraft
                        , hostAdminWikis =
                            case route of
                                Route.HostAdminWikis ->
                                    RemoteData.Loading

                                Route.HostAdminBackup ->
                                    RemoteData.Loading

                                Route.WikiList ->
                                    RemoteData.NotAsked

                                Route.HostAdmin _ ->
                                    RemoteData.NotAsked

                                Route.HostAdminWikiNew ->
                                    RemoteData.Loading

                                Route.HostAdminWikiDetail _ ->
                                    RemoteData.NotAsked

                                Route.HostAdminAudit ->
                                    RemoteData.NotAsked

                                Route.HostAdminAuditDiff _ _ ->
                                    RemoteData.NotAsked

                                Route.WikiHome _ ->
                                    RemoteData.NotAsked

                                Route.WikiPage _ _ ->
                                    RemoteData.NotAsked

                                Route.WikiPageGraph _ _ ->
                                    RemoteData.NotAsked

                                Route.WikiTodos _ ->
                                    RemoteData.NotAsked

                                Route.WikiGraph _ ->
                                    RemoteData.NotAsked

                                Route.WikiSearch _ ->
                                    RemoteData.NotAsked

                                Route.WikiRegister _ ->
                                    RemoteData.NotAsked

                                Route.WikiLogin _ _ ->
                                    RemoteData.NotAsked

                                Route.WikiSubmitNew _ ->
                                    RemoteData.NotAsked

                                Route.WikiSubmitEdit _ _ ->
                                    RemoteData.NotAsked

                                Route.WikiSubmitDelete _ _ ->
                                    RemoteData.NotAsked

                                Route.WikiSubmissionDetail _ _ ->
                                    RemoteData.NotAsked

                                Route.WikiMySubmissions _ ->
                                    RemoteData.NotAsked

                                Route.WikiReview _ ->
                                    RemoteData.NotAsked

                                Route.WikiReviewDetail _ _ ->
                                    RemoteData.NotAsked

                                Route.WikiAdminUsers _ ->
                                    RemoteData.NotAsked

                                Route.WikiAdminAudit _ ->
                                    RemoteData.NotAsked

                                Route.WikiAdminAuditDiff _ _ ->
                                    RemoteData.NotAsked

                                Route.NotFound _ ->
                                    RemoteData.NotAsked
                        , hostAdminWikiDetailDraft =
                            case route of
                                Route.HostAdminWikiDetail slug ->
                                    hostAdminWikiDetailDraftLoading slug

                                _ ->
                                    emptyHostAdminWikiDetailDraft
                        , hostAdminAuditLog =
                            case route of
                                Route.HostAdminAudit ->
                                    RemoteData.Loading

                                Route.HostAdminAuditDiff _ _ ->
                                    RemoteData.Loading

                                _ ->
                                    RemoteData.NotAsked
                        , hostAdminExportInFlight = False
                        , hostAdminImportInFlight = False
                        , hostAdminBackupNotice = Nothing
                        , hostAdminWikiExportInFlightSlug = Nothing
                        , hostAdminWikiImportInFlightSlug = Nothing
                        , hostAdminWikiImportPendingSlug = Nothing
                        , hostAdminWikisNotice = Nothing
                    }

                next : Model
                next =
                    case route of
                        Route.WikiAdminAudit _ ->
                            { baseNext
                                | wikiAdminAuditFilterActorDraft = ""
                                , wikiAdminAuditFilterPageDraft = ""
                                , wikiAdminAuditFilterSelectedKindTags = []
                                , wikiAdminAuditAppliedFilter = WikiAuditLog.emptyAuditLogFilter
                            }

                        Route.WikiAdminAuditDiff _ _ ->
                            baseNext

                        Route.HostAdminAudit ->
                            { baseNext
                                | hostAdminAuditFilterWikiDraft = ""
                                , hostAdminAuditFilterActorDraft = ""
                                , hostAdminAuditFilterPageDraft = ""
                                , hostAdminAuditFilterSelectedKindTags = []
                                , hostAdminAuditAppliedFilter = WikiAuditLog.emptyHostAuditLogFilter
                            }

                        Route.HostAdminAuditDiff _ _ ->
                            baseNext

                        _ ->
                            baseNext
            in
            ( next, navCmd )
                |> runRouteStoreActions
                |> batchScrollAfterUrlChange url.fragment

        UrlFragmentScrollDone ->
            ( model, Command.none )

        ContributorLogoutWiki wikiSlug ->
            ( model, Effect.Lamdera.sendToBackend (LogoutContributor wikiSlug) )

        RegisterFormUsernameChanged value ->
            let
                d : RegisterDraft
                d =
                    model.registerDraft
            in
            ( { model | registerDraft = { d | username = value } }
            , Command.none
            )

        RegisterFormPasswordChanged value ->
            let
                d : RegisterDraft
                d =
                    model.registerDraft
            in
            ( { model | registerDraft = { d | password = value } }
            , Command.none
            )

        RegisterFormSubmitted ->
            case model.route of
                Route.WikiList ->
                    ( model, Command.none )

                Route.WikiHome _ ->
                    ( model, Command.none )

                Route.WikiPage _ _ ->
                    ( model, Command.none )

                Route.WikiPageGraph _ _ ->
                    ( model, Command.none )

                Route.WikiTodos _ ->
                    ( model, Command.none )

                Route.WikiGraph _ ->
                    ( model, Command.none )

                Route.WikiSearch _ ->
                    ( model, Command.none )

                Route.WikiLogin _ _ ->
                    ( model, Command.none )

                Route.WikiSubmitNew _ ->
                    ( model, Command.none )

                Route.WikiSubmitEdit _ _ ->
                    ( model, Command.none )

                Route.WikiSubmitDelete _ _ ->
                    ( model, Command.none )

                Route.WikiSubmissionDetail _ _ ->
                    ( model, Command.none )

                Route.WikiMySubmissions _ ->
                    ( model, Command.none )

                Route.WikiReview _ ->
                    ( model, Command.none )

                Route.WikiReviewDetail _ _ ->
                    ( model, Command.none )

                Route.WikiAdminUsers _ ->
                    ( model, Command.none )

                Route.WikiAdminAudit _ ->
                    ( model, Command.none )

                Route.WikiAdminAuditDiff _ _ ->
                    ( model, Command.none )

                Route.HostAdminAudit ->
                    ( model, Command.none )

                Route.HostAdminAuditDiff _ _ ->
                    ( model, Command.none )

                Route.HostAdmin _ ->
                    ( model, Command.none )

                Route.HostAdminWikis ->
                    ( model, Command.none )

                Route.HostAdminBackup ->
                    ( model, Command.none )

                Route.HostAdminWikiNew ->
                    ( model, Command.none )

                Route.HostAdminWikiDetail _ ->
                    ( model, Command.none )

                Route.WikiRegister wikiSlug ->
                    let
                        d : RegisterDraft
                        d =
                            model.registerDraft
                    in
                    case ContributorAccount.validateRegistrationFields d.username d.password of
                        Err e ->
                            ( { model
                                | registerDraft =
                                    { d
                                        | lastResult = Just (Err e)
                                        , inFlight = False
                                    }
                              }
                            , Command.none
                            )

                        Ok _ ->
                            ( { model
                                | registerDraft =
                                    { d
                                        | inFlight = True
                                        , lastResult = Nothing
                                    }
                              }
                            , Effect.Lamdera.sendToBackend
                                (RegisterContributor wikiSlug { username = d.username, password = d.password })
                            )

                Route.NotFound _ ->
                    ( model, Command.none )

        LoginFormUsernameChanged value ->
            let
                d : LoginDraft
                d =
                    model.loginDraft
            in
            ( { model | loginDraft = { d | username = value } }
            , Command.none
            )

        LoginFormPasswordChanged value ->
            let
                d : LoginDraft
                d =
                    model.loginDraft
            in
            ( { model | loginDraft = { d | password = value } }
            , Command.none
            )

        LoginFormSubmitted ->
            case wikiSideNavSlugIfActive model of
                Nothing ->
                    ( model, Command.none )

                Just wikiSlug ->
                    let
                        d : LoginDraft
                        d =
                            model.loginDraft
                    in
                    case ContributorAccount.validateLoginFields d.username d.password of
                        Err e ->
                            ( { model
                                | loginDraft =
                                    { d
                                        | lastResult = Just (Err e)
                                        , inFlight = False
                                    }
                              }
                            , Command.none
                            )

                        Ok _ ->
                            ( { model
                                | loginDraft =
                                    { d
                                        | inFlight = True
                                        , lastResult = Nothing
                                    }
                              }
                            , Effect.Lamdera.sendToBackend
                                (LoginContributor wikiSlug { username = d.username, password = d.password })
                            )

        HeaderSearchQueryChanged value ->
            ( { model | headerSearchQuery = value }
            , Command.none
            )

        HeaderSearchSubmitted ->
            case wikiSideNavSlugIfActive model of
                Just wikiSlug ->
                    case model.route of
                        Route.WikiSearch _ ->
                            ( model, Command.none )

                        _ ->
                            ( model
                            , Effect.Browser.Navigation.pushUrl model.key (searchUrlWithQuery wikiSlug model.headerSearchQuery)
                            )

                Nothing ->
                    ( model, Command.none )

        WikiSearchPageQueryChanged value ->
            ( { model | wikiSearchPageQuery = value }
            , Command.none
            )

        NewPageSubmitMarkdownChanged value ->
            let
                d : NewPageSubmitDraft
                d =
                    model.newPageSubmitDraft
            in
            ( { model | newPageSubmitDraft = { d | markdownBody = value } }
            , Command.none
            )

        NewPageSubmitSlugChanged value ->
            let
                d : NewPageSubmitDraft
                d =
                    model.newPageSubmitDraft
            in
            if d.pageSlugLockedFromQuery then
                ( model, Command.none )

            else
                ( { model | newPageSubmitDraft = { d | pageSlug = value } }
                , Command.none
                )

        NewPageSubmitTagsChanged value ->
            let
                d : NewPageSubmitDraft
                d =
                    model.newPageSubmitDraft
            in
            ( { model | newPageSubmitDraft = { d | tagsInput = value } }
            , Command.none
            )

        NewPageSubmitFormSubmitted ->
            case model.route of
                Route.WikiList ->
                    ( model, Command.none )

                Route.WikiHome _ ->
                    ( model, Command.none )

                Route.WikiPage _ _ ->
                    ( model, Command.none )

                Route.WikiPageGraph _ _ ->
                    ( model, Command.none )

                Route.WikiTodos _ ->
                    ( model, Command.none )

                Route.WikiGraph _ ->
                    ( model, Command.none )

                Route.WikiSearch _ ->
                    ( model, Command.none )

                Route.WikiLogin _ _ ->
                    ( model, Command.none )

                Route.WikiRegister _ ->
                    ( model, Command.none )

                Route.WikiSubmitNew wikiSlug ->
                    let
                        d : NewPageSubmitDraft
                        d =
                            model.newPageSubmitDraft
                    in
                    case Submission.validateNewPageFields d.pageSlug d.markdownBody d.tagsInput of
                        Err ve ->
                            ( { model
                                | newPageSubmitDraft =
                                    { d
                                        | lastResult = Just (Err (Submission.Validation ve))
                                        , inFlight = False
                                    }
                              }
                            , Command.none
                            )

                        Ok _ ->
                            let
                                trustedPublishesDirectly : Bool
                                trustedPublishesDirectly =
                                    wikiSessionTrustedOnWiki wikiSlug model
                            in
                            if trustedPublishesDirectly then
                                ( { model
                                    | newPageSubmitDraft =
                                        { d
                                            | inFlight = True
                                            , lastResult = Nothing
                                        }
                                  }
                                , Effect.Lamdera.sendToBackend
                                    (SubmitNewPage wikiSlug { rawPageSlug = d.pageSlug, rawMarkdown = d.markdownBody, rawTags = d.tagsInput })
                                )

                            else
                                case d.maybeSavedDraftId of
                                    Just draftId ->
                                        ( { model
                                            | newPageSubmitDraft =
                                                { d
                                                    | inFlight = True
                                                    , lastResult = Nothing
                                                }
                                          }
                                        , Effect.Lamdera.sendToBackend (SubmitDraftForReview wikiSlug draftId)
                                        )

                                    Nothing ->
                                        ( { model
                                            | newPageSubmitDraft =
                                                { d
                                                    | inFlight = True
                                                    , lastResult = Nothing
                                                }
                                          }
                                        , Effect.Lamdera.sendToBackend
                                            (SubmitNewPage wikiSlug { rawPageSlug = d.pageSlug, rawMarkdown = d.markdownBody, rawTags = d.tagsInput })
                                        )

                Route.WikiSubmitEdit _ _ ->
                    ( model, Command.none )

                Route.WikiSubmitDelete _ _ ->
                    ( model, Command.none )

                Route.WikiSubmissionDetail _ _ ->
                    ( model, Command.none )

                Route.WikiMySubmissions _ ->
                    ( model, Command.none )

                Route.WikiReview _ ->
                    ( model, Command.none )

                Route.WikiReviewDetail _ _ ->
                    ( model, Command.none )

                Route.WikiAdminUsers _ ->
                    ( model, Command.none )

                Route.WikiAdminAudit _ ->
                    ( model, Command.none )

                Route.WikiAdminAuditDiff _ _ ->
                    ( model, Command.none )

                Route.HostAdminAudit ->
                    ( model, Command.none )

                Route.HostAdminAuditDiff _ _ ->
                    ( model, Command.none )

                Route.HostAdmin _ ->
                    ( model, Command.none )

                Route.HostAdminWikis ->
                    ( model, Command.none )

                Route.HostAdminBackup ->
                    ( model, Command.none )

                Route.HostAdminWikiNew ->
                    ( model, Command.none )

                Route.HostAdminWikiDetail _ ->
                    ( model, Command.none )

                Route.NotFound _ ->
                    ( model, Command.none )

        NewPageSaveDraftClicked ->
            case model.route of
                Route.WikiSubmitNew wikiSlug ->
                    let
                        d : NewPageSubmitDraft
                        d =
                            model.newPageSubmitDraft
                    in
                    case Submission.validateNewPageDraftFields d.pageSlug d.markdownBody d.tagsInput of
                        Err ve ->
                            ( { model
                                | newPageSubmitDraft =
                                    { d
                                        | lastSaveDraftResult = Just (Err (Submission.SaveNewPageDraftValidation ve))
                                        , saveDraftInFlight = False
                                    }
                              }
                            , Command.none
                            )

                        Ok _ ->
                            ( { model
                                | newPageSubmitDraft =
                                    { d
                                        | saveDraftInFlight = True
                                        , pendingSubmitAfterSave = False
                                        , lastSaveDraftResult = Nothing
                                    }
                              }
                            , Effect.Lamdera.sendToBackend
                                (SaveNewPageDraft wikiSlug
                                    { maybeSubmissionId = d.maybeSavedDraftId
                                    , rawPageSlug = d.pageSlug
                                    , rawMarkdown = d.markdownBody
                                    , rawTags = d.tagsInput
                                    }
                                )
                            )

                _ ->
                    ( model, Command.none )

        PageEditSubmitMarkdownChanged value ->
            let
                d : PageEditSubmitDraft
                d =
                    model.pageEditSubmitDraft
            in
            ( { model | pageEditSubmitDraft = { d | markdownBody = value } }
            , Command.none
            )

        PageEditSubmitTagsChanged value ->
            let
                d : PageEditSubmitDraft
                d =
                    model.pageEditSubmitDraft
            in
            ( { model | pageEditSubmitDraft = { d | tagsInput = value } }
            , Command.none
            )

        PageEditSubmitFormSubmitted ->
            case model.route of
                Route.WikiList ->
                    ( model, Command.none )

                Route.WikiHome _ ->
                    ( model, Command.none )

                Route.WikiPage _ _ ->
                    ( model, Command.none )

                Route.WikiPageGraph _ _ ->
                    ( model, Command.none )

                Route.WikiTodos _ ->
                    ( model, Command.none )

                Route.WikiGraph _ ->
                    ( model, Command.none )

                Route.WikiSearch _ ->
                    ( model, Command.none )

                Route.WikiLogin _ _ ->
                    ( model, Command.none )

                Route.WikiRegister _ ->
                    ( model, Command.none )

                Route.WikiSubmitNew _ ->
                    ( model, Command.none )

                Route.WikiSubmitEdit wikiSlug pageSlug ->
                    let
                        d : PageEditSubmitDraft
                        d =
                            model.pageEditSubmitDraft
                    in
                    case d.maybeSavedDraftId of
                        Just draftId ->
                            case Submission.validateEditMarkdown d.markdownBody d.tagsInput pageSlug of
                                Err ve ->
                                    ( { model
                                        | pageEditSubmitDraft =
                                            { d
                                                | lastResult = Just (Err (Submission.EditValidation ve))
                                                , inFlight = False
                                            }
                                      }
                                    , Command.none
                                    )

                                Ok _ ->
                                    ( { model
                                        | pageEditSubmitDraft =
                                            { d
                                                | inFlight = True
                                                , lastResult = Nothing
                                            }
                                      }
                                    , Effect.Lamdera.sendToBackend (SubmitDraftForReview wikiSlug draftId)
                                    )

                        Nothing ->
                            case Submission.validateEditMarkdown d.markdownBody d.tagsInput pageSlug of
                                Err ve ->
                                    ( { model
                                        | pageEditSubmitDraft =
                                            { d
                                                | lastResult = Just (Err (Submission.EditValidation ve))
                                                , inFlight = False
                                            }
                                      }
                                    , Command.none
                                    )

                                Ok _ ->
                                    ( { model
                                        | pageEditSubmitDraft =
                                            { d
                                                | inFlight = True
                                                , lastResult = Nothing
                                            }
                                      }
                                    , Effect.Lamdera.sendToBackend
                                        (SubmitPageEdit wikiSlug pageSlug d.markdownBody d.tagsInput)
                                    )

                Route.WikiSubmitDelete _ _ ->
                    ( model, Command.none )

                Route.WikiSubmissionDetail _ _ ->
                    ( model, Command.none )

                Route.WikiMySubmissions _ ->
                    ( model, Command.none )

                Route.WikiReview _ ->
                    ( model, Command.none )

                Route.WikiReviewDetail _ _ ->
                    ( model, Command.none )

                Route.WikiAdminUsers _ ->
                    ( model, Command.none )

                Route.WikiAdminAudit _ ->
                    ( model, Command.none )

                Route.WikiAdminAuditDiff _ _ ->
                    ( model, Command.none )

                Route.HostAdminAudit ->
                    ( model, Command.none )

                Route.HostAdminAuditDiff _ _ ->
                    ( model, Command.none )

                Route.HostAdmin _ ->
                    ( model, Command.none )

                Route.HostAdminWikis ->
                    ( model, Command.none )

                Route.HostAdminBackup ->
                    ( model, Command.none )

                Route.HostAdminWikiNew ->
                    ( model, Command.none )

                Route.HostAdminWikiDetail _ ->
                    ( model, Command.none )

                Route.NotFound _ ->
                    ( model, Command.none )

        PageEditSaveDraftClicked ->
            case model.route of
                Route.WikiSubmitEdit wikiSlug pageSlug ->
                    let
                        d : PageEditSubmitDraft
                        d =
                            model.pageEditSubmitDraft
                    in
                    case Submission.validateEditMarkdownDraft d.markdownBody d.tagsInput pageSlug of
                        Err ve ->
                            ( { model
                                | pageEditSubmitDraft =
                                    { d
                                        | lastSaveDraftResult = Just (Err (Submission.SavePageEditDraftValidation ve))
                                        , saveDraftInFlight = False
                                    }
                              }
                            , Command.none
                            )

                        Ok _ ->
                            ( { model
                                | pageEditSubmitDraft =
                                    { d
                                        | saveDraftInFlight = True
                                        , pendingSubmitAfterSave = False
                                        , lastSaveDraftResult = Nothing
                                    }
                              }
                            , Effect.Lamdera.sendToBackend
                                (SavePageEditDraft wikiSlug
                                    { maybeSubmissionId = d.maybeSavedDraftId
                                    , pageSlug = pageSlug
                                    , rawMarkdown = d.markdownBody
                                    , rawTags = d.tagsInput
                                    }
                                )
                            )

                _ ->
                    ( model, Command.none )

        PageDeleteSubmitReasonChanged value ->
            let
                d : PageDeleteSubmitDraft
                d =
                    model.pageDeleteSubmitDraft
            in
            ( { model | pageDeleteSubmitDraft = { d | reasonText = value } }
            , Command.none
            )

        PageDeleteRequestDeletionSubmitted ->
            case model.route of
                Route.WikiList ->
                    ( model, Command.none )

                Route.WikiHome _ ->
                    ( model, Command.none )

                Route.WikiPage _ _ ->
                    ( model, Command.none )

                Route.WikiPageGraph _ _ ->
                    ( model, Command.none )

                Route.WikiTodos _ ->
                    ( model, Command.none )

                Route.WikiGraph _ ->
                    ( model, Command.none )

                Route.WikiSearch _ ->
                    ( model, Command.none )

                Route.WikiLogin _ _ ->
                    ( model, Command.none )

                Route.WikiRegister _ ->
                    ( model, Command.none )

                Route.WikiSubmitNew _ ->
                    ( model, Command.none )

                Route.WikiSubmitEdit _ _ ->
                    ( model, Command.none )

                Route.WikiSubmitDelete wikiSlug pageSlug ->
                    let
                        d : PageDeleteSubmitDraft
                        d =
                            model.pageDeleteSubmitDraft

                        validationErr : Submission.DeleteReasonError -> ( Model, Command FrontendOnly ToBackend Msg )
                        validationErr ve =
                            ( { model
                                | pageDeleteSubmitDraft =
                                    { d
                                        | lastResult =
                                            Just
                                                (Err
                                                    (Submission.PageDeleteRequestFailed
                                                        (Submission.RequestPublishedPageDeletionPrecondition
                                                            (Submission.PageDeletionValidation ve)
                                                        )
                                                    )
                                                )
                                        , inFlight = False
                                    }
                              }
                            , Command.none
                            )
                    in
                    case d.maybeSavedDraftId of
                        Just draftId ->
                            case Submission.validateDeleteReasonRequired d.reasonText of
                                Err ve ->
                                    validationErr ve

                                Ok _ ->
                                    ( { model
                                        | pageDeleteSubmitDraft =
                                            { d
                                                | inFlight = True
                                                , lastResult = Nothing
                                            }
                                      }
                                    , Effect.Lamdera.sendToBackend (SubmitDraftForReview wikiSlug draftId)
                                    )

                        Nothing ->
                            case Submission.validateDeleteReasonRequired d.reasonText of
                                Err ve ->
                                    validationErr ve

                                Ok _ ->
                                    ( { model
                                        | pageDeleteSubmitDraft =
                                            { d
                                                | inFlight = True
                                                , lastResult = Nothing
                                            }
                                      }
                                    , Effect.Lamdera.sendToBackend (RequestPublishedPageDeletion wikiSlug pageSlug d.reasonText)
                                    )

                Route.WikiSubmissionDetail _ _ ->
                    ( model, Command.none )

                Route.WikiMySubmissions _ ->
                    ( model, Command.none )

                Route.WikiReview _ ->
                    ( model, Command.none )

                Route.WikiReviewDetail _ _ ->
                    ( model, Command.none )

                Route.WikiAdminUsers _ ->
                    ( model, Command.none )

                Route.WikiAdminAudit _ ->
                    ( model, Command.none )

                Route.WikiAdminAuditDiff _ _ ->
                    ( model, Command.none )

                Route.HostAdminAudit ->
                    ( model, Command.none )

                Route.HostAdminAuditDiff _ _ ->
                    ( model, Command.none )

                Route.HostAdmin _ ->
                    ( model, Command.none )

                Route.HostAdminWikis ->
                    ( model, Command.none )

                Route.HostAdminBackup ->
                    ( model, Command.none )

                Route.HostAdminWikiNew ->
                    ( model, Command.none )

                Route.HostAdminWikiDetail _ ->
                    ( model, Command.none )

                Route.NotFound _ ->
                    ( model, Command.none )

        PageDeletePublishedImmediatelySubmitted ->
            case model.route of
                Route.WikiSubmitDelete wikiSlug pageSlug ->
                    let
                        d : PageDeleteSubmitDraft
                        d =
                            model.pageDeleteSubmitDraft
                    in
                    case Submission.validateDeleteReasonRequired d.reasonText of
                        Err ve ->
                            ( { model
                                | pageDeleteSubmitDraft =
                                    { d
                                        | lastResult =
                                            Just
                                                (Err
                                                    (Submission.PageDeleteImmediateFailed
                                                        (Submission.DeletePublishedPageImmediatelyPrecondition
                                                            (Submission.PageDeletionValidation ve)
                                                        )
                                                    )
                                                )
                                        , inFlight = False
                                    }
                              }
                            , Command.none
                            )

                        Ok _ ->
                            ( { model
                                | pageDeleteSubmitDraft =
                                    { d
                                        | inFlight = True
                                        , lastResult = Nothing
                                    }
                              }
                            , Effect.Lamdera.sendToBackend (DeletePublishedPageImmediately wikiSlug pageSlug d.reasonText)
                            )

                Route.WikiList ->
                    ( model, Command.none )

                Route.WikiHome _ ->
                    ( model, Command.none )

                Route.WikiPage _ _ ->
                    ( model, Command.none )

                Route.WikiPageGraph _ _ ->
                    ( model, Command.none )

                Route.WikiTodos _ ->
                    ( model, Command.none )

                Route.WikiGraph _ ->
                    ( model, Command.none )

                Route.WikiSearch _ ->
                    ( model, Command.none )

                Route.WikiLogin _ _ ->
                    ( model, Command.none )

                Route.WikiRegister _ ->
                    ( model, Command.none )

                Route.WikiSubmitNew _ ->
                    ( model, Command.none )

                Route.WikiSubmitEdit _ _ ->
                    ( model, Command.none )

                Route.WikiSubmissionDetail _ _ ->
                    ( model, Command.none )

                Route.WikiMySubmissions _ ->
                    ( model, Command.none )

                Route.WikiReview _ ->
                    ( model, Command.none )

                Route.WikiReviewDetail _ _ ->
                    ( model, Command.none )

                Route.WikiAdminUsers _ ->
                    ( model, Command.none )

                Route.WikiAdminAudit _ ->
                    ( model, Command.none )

                Route.WikiAdminAuditDiff _ _ ->
                    ( model, Command.none )

                Route.HostAdminAudit ->
                    ( model, Command.none )

                Route.HostAdminAuditDiff _ _ ->
                    ( model, Command.none )

                Route.HostAdmin _ ->
                    ( model, Command.none )

                Route.HostAdminWikis ->
                    ( model, Command.none )

                Route.HostAdminBackup ->
                    ( model, Command.none )

                Route.HostAdminWikiNew ->
                    ( model, Command.none )

                Route.HostAdminWikiDetail _ ->
                    ( model, Command.none )

                Route.NotFound _ ->
                    ( model, Command.none )

        PageDeleteSaveDraftClicked ->
            case model.route of
                Route.WikiSubmitDelete wikiSlug pageSlug ->
                    let
                        d : PageDeleteSubmitDraft
                        d =
                            model.pageDeleteSubmitDraft
                    in
                    case Submission.validateDeleteReasonRequired d.reasonText of
                        Err ve ->
                            ( { model
                                | pageDeleteSubmitDraft =
                                    { d
                                        | lastSaveDraftResult = Just (Err (Submission.SavePageDeleteDraftReasonInvalid ve))
                                        , saveDraftInFlight = False
                                    }
                              }
                            , Command.none
                            )

                        Ok _ ->
                            ( { model
                                | pageDeleteSubmitDraft =
                                    { d
                                        | saveDraftInFlight = True
                                        , pendingSubmitAfterSave = False
                                        , lastSaveDraftResult = Nothing
                                    }
                              }
                            , Effect.Lamdera.sendToBackend
                                (SavePageDeleteDraft wikiSlug
                                    { maybeSubmissionId = d.maybeSavedDraftId
                                    , pageSlug = pageSlug
                                    , rawReason = d.reasonText
                                    }
                                )
                            )

                _ ->
                    ( model, Command.none )

        SubmissionDetailNewMarkdownChanged value ->
            let
                inter : SubmissionDetailEditDraft
                inter =
                    model.submissionDetailEditDraft
            in
            ( { model | submissionDetailEditDraft = { inter | markdownBody = value } }
            , Command.none
            )

        SubmissionDetailNewPageSlugChanged value ->
            let
                inter : SubmissionDetailEditDraft
                inter =
                    model.submissionDetailEditDraft
            in
            ( { model | submissionDetailEditDraft = { inter | newPageSlug = value } }
            , Command.none
            )

        SubmissionDetailSaveDraftClicked ->
            case model.route of
                Route.WikiSubmissionDetail wikiSlug submissionId ->
                    case Store.get_ ( wikiSlug, submissionId ) model.store.submissionDetails of
                        RemoteData.Success (Ok detail) ->
                            if detail.status /= Submission.Draft then
                                ( model, Command.none )

                            else
                                let
                                    inter : SubmissionDetailEditDraft
                                    inter =
                                        model.submissionDetailEditDraft

                                    nextInter : SubmissionDetailEditDraft
                                    nextInter =
                                        { inter
                                            | saveDraftInFlight = True
                                            , pendingSubmitAfterSave = False
                                            , lastError = Nothing
                                        }
                                in
                                case detail.contributionKind of
                                    Submission.ContributorKindNewPage ->
                                        ( { model | submissionDetailEditDraft = nextInter }
                                        , Effect.Lamdera.sendToBackend
                                            (SaveNewPageDraft wikiSlug
                                                { maybeSubmissionId = Just submissionId
                                                , rawPageSlug = inter.newPageSlug
                                                , rawMarkdown = inter.markdownBody
                                                , rawTags = ""
                                                }
                                            )
                                        )

                                    Submission.ContributorKindEditPage ->
                                        case detail.maybeEditPageSlug of
                                            Just pageSlug ->
                                                ( { model | submissionDetailEditDraft = nextInter }
                                                , Effect.Lamdera.sendToBackend
                                                    (SavePageEditDraft wikiSlug
                                                        { maybeSubmissionId = Just submissionId
                                                        , pageSlug = pageSlug
                                                        , rawMarkdown = inter.markdownBody
                                                        , rawTags = ""
                                                        }
                                                    )
                                                )

                                            Nothing ->
                                                ( model, Command.none )

                                    Submission.ContributorKindDeletePage ->
                                        case detail.maybeEditPageSlug of
                                            Just pageSlug ->
                                                case Submission.validateDeleteReasonRequired inter.markdownBody of
                                                    Err ve ->
                                                        ( { model
                                                            | submissionDetailEditDraft =
                                                                { inter
                                                                    | lastError = Just (Submission.deleteReasonErrorToUserText ve)
                                                                    , saveDraftInFlight = False
                                                                }
                                                          }
                                                        , Command.none
                                                        )

                                                    Ok _ ->
                                                        ( { model | submissionDetailEditDraft = nextInter }
                                                        , Effect.Lamdera.sendToBackend
                                                            (SavePageDeleteDraft wikiSlug
                                                                { maybeSubmissionId = Just submissionId
                                                                , pageSlug = pageSlug
                                                                , rawReason = inter.markdownBody
                                                                }
                                                            )
                                                        )

                                            Nothing ->
                                                ( model, Command.none )

                        _ ->
                            ( model, Command.none )

                _ ->
                    ( model, Command.none )

        SubmissionDetailSubmitForReviewClicked ->
            case model.route of
                Route.WikiSubmissionDetail wikiSlug submissionId ->
                    case Store.get_ ( wikiSlug, submissionId ) model.store.submissionDetails of
                        RemoteData.Success (Ok detail) ->
                            if detail.status /= Submission.Draft then
                                ( model, Command.none )

                            else
                                let
                                    inter : SubmissionDetailEditDraft
                                    inter =
                                        model.submissionDetailEditDraft

                                    nextInter : SubmissionDetailEditDraft
                                    nextInter =
                                        { inter
                                            | saveDraftInFlight = True
                                            , pendingSubmitAfterSave = True
                                            , lastError = Nothing
                                        }
                                in
                                case detail.contributionKind of
                                    Submission.ContributorKindNewPage ->
                                        ( { model | submissionDetailEditDraft = nextInter }
                                        , Effect.Lamdera.sendToBackend
                                            (SaveNewPageDraft wikiSlug
                                                { maybeSubmissionId = Just submissionId
                                                , rawPageSlug = inter.newPageSlug
                                                , rawMarkdown = inter.markdownBody
                                                , rawTags = ""
                                                }
                                            )
                                        )

                                    Submission.ContributorKindEditPage ->
                                        case detail.maybeEditPageSlug of
                                            Just pageSlug ->
                                                ( { model | submissionDetailEditDraft = nextInter }
                                                , Effect.Lamdera.sendToBackend
                                                    (SavePageEditDraft wikiSlug
                                                        { maybeSubmissionId = Just submissionId
                                                        , pageSlug = pageSlug
                                                        , rawMarkdown = inter.markdownBody
                                                        , rawTags = ""
                                                        }
                                                    )
                                                )

                                            Nothing ->
                                                ( model, Command.none )

                                    Submission.ContributorKindDeletePage ->
                                        case detail.maybeEditPageSlug of
                                            Just pageSlug ->
                                                case Submission.validateDeleteReasonRequired inter.markdownBody of
                                                    Err ve ->
                                                        ( { model
                                                            | submissionDetailEditDraft =
                                                                { inter
                                                                    | lastError = Just (Submission.deleteReasonErrorToUserText ve)
                                                                    , submitForReviewInFlight = False
                                                                }
                                                          }
                                                        , Command.none
                                                        )

                                                    Ok _ ->
                                                        ( { model | submissionDetailEditDraft = nextInter }
                                                        , Effect.Lamdera.sendToBackend
                                                            (SavePageDeleteDraft wikiSlug
                                                                { maybeSubmissionId = Just submissionId
                                                                , pageSlug = pageSlug
                                                                , rawReason = inter.markdownBody
                                                                }
                                                            )
                                                        )

                                            Nothing ->
                                                ( model, Command.none )

                        _ ->
                            ( model, Command.none )

                _ ->
                    ( model, Command.none )

        SubmissionDetailWithdrawClicked ->
            case model.route of
                Route.WikiSubmissionDetail wikiSlug submissionId ->
                    let
                        inter : SubmissionDetailEditDraft
                        inter =
                            model.submissionDetailEditDraft
                    in
                    ( { model
                        | submissionDetailEditDraft =
                            { inter
                                | withdrawInFlight = True
                                , lastError = Nothing
                            }
                      }
                    , Effect.Lamdera.sendToBackend (WithdrawSubmission wikiSlug submissionId)
                    )

                _ ->
                    ( model, Command.none )

        SubmissionDetailDeleteClicked ->
            case model.route of
                Route.WikiSubmissionDetail wikiSlug submissionId ->
                    let
                        inter : SubmissionDetailEditDraft
                        inter =
                            model.submissionDetailEditDraft
                    in
                    ( { model
                        | submissionDetailEditDraft =
                            { inter
                                | deleteInFlight = True
                                , lastError = Nothing
                            }
                      }
                    , Effect.Lamdera.sendToBackend (DeleteMySubmission wikiSlug submissionId)
                    )

                _ ->
                    ( model, Command.none )

        ReviewDecisionChanged decision ->
            ( { model | reviewDecision = decision }
            , Command.none
            )

        ReviewDecisionSubmitted ->
            case model.route of
                Route.WikiReviewDetail wikiSlug submissionId ->
                    case model.reviewDecision of
                        ReviewDecisionApprove ->
                            ( { model
                                | reviewApproveDraft =
                                    { inFlight = True
                                    , lastResult = Nothing
                                    }
                              }
                            , Effect.Lamdera.sendToBackend (ApproveSubmission wikiSlug submissionId)
                            )

                        ReviewDecisionReject ->
                            ( { model
                                | reviewRejectDraft =
                                    { reasonText = model.reviewRejectDraft.reasonText
                                    , inFlight = True
                                    , lastResult = Nothing
                                    }
                              }
                            , Effect.Lamdera.sendToBackend
                                (RejectSubmission wikiSlug { submissionId = submissionId, reasonText = model.reviewRejectDraft.reasonText })
                            )

                        ReviewDecisionRequestChanges ->
                            ( { model
                                | reviewRequestChangesDraft =
                                    { guidanceText = model.reviewRequestChangesDraft.guidanceText
                                    , inFlight = True
                                    , lastResult = Nothing
                                    }
                              }
                            , Effect.Lamdera.sendToBackend
                                (RequestSubmissionChanges wikiSlug { submissionId = submissionId, guidanceText = model.reviewRequestChangesDraft.guidanceText })
                            )

                Route.WikiList ->
                    ( model, Command.none )

                Route.WikiHome _ ->
                    ( model, Command.none )

                Route.WikiPage _ _ ->
                    ( model, Command.none )

                Route.WikiPageGraph _ _ ->
                    ( model, Command.none )

                Route.WikiTodos _ ->
                    ( model, Command.none )

                Route.WikiGraph _ ->
                    ( model, Command.none )

                Route.WikiSearch _ ->
                    ( model, Command.none )

                Route.WikiLogin _ _ ->
                    ( model, Command.none )

                Route.WikiRegister _ ->
                    ( model, Command.none )

                Route.WikiSubmitNew _ ->
                    ( model, Command.none )

                Route.WikiSubmitEdit _ _ ->
                    ( model, Command.none )

                Route.WikiSubmitDelete _ _ ->
                    ( model, Command.none )

                Route.WikiSubmissionDetail _ _ ->
                    ( model, Command.none )

                Route.WikiMySubmissions _ ->
                    ( model, Command.none )

                Route.WikiReview _ ->
                    ( model, Command.none )

                Route.WikiAdminUsers _ ->
                    ( model, Command.none )

                Route.WikiAdminAudit _ ->
                    ( model, Command.none )

                Route.WikiAdminAuditDiff _ _ ->
                    ( model, Command.none )

                Route.HostAdminAudit ->
                    ( model, Command.none )

                Route.HostAdminAuditDiff _ _ ->
                    ( model, Command.none )

                Route.HostAdmin _ ->
                    ( model, Command.none )

                Route.HostAdminWikis ->
                    ( model, Command.none )

                Route.HostAdminBackup ->
                    ( model, Command.none )

                Route.HostAdminWikiNew ->
                    ( model, Command.none )

                Route.HostAdminWikiDetail _ ->
                    ( model, Command.none )

                Route.NotFound _ ->
                    ( model, Command.none )

        ReviewRejectReasonChanged value ->
            let
                d : ReviewRejectDraft
                d =
                    model.reviewRejectDraft
            in
            ( { model | reviewRejectDraft = { d | reasonText = value } }
            , Command.none
            )

        ReviewRequestChangesNoteChanged value ->
            let
                d : ReviewRequestChangesDraft
                d =
                    model.reviewRequestChangesDraft
            in
            ( { model | reviewRequestChangesDraft = { d | guidanceText = value } }
            , Command.none
            )

        WikiAdminPromoteToTrustedClicked targetUsername ->
            case model.route of
                Route.WikiAdminUsers wikiSlug ->
                    ( { model | adminPromoteError = Nothing }
                    , Effect.Lamdera.sendToBackend (PromoteContributorToTrusted wikiSlug targetUsername)
                    )

                Route.WikiList ->
                    ( model, Command.none )

                Route.WikiHome _ ->
                    ( model, Command.none )

                Route.WikiPage _ _ ->
                    ( model, Command.none )

                Route.WikiPageGraph _ _ ->
                    ( model, Command.none )

                Route.WikiTodos _ ->
                    ( model, Command.none )

                Route.WikiGraph _ ->
                    ( model, Command.none )

                Route.WikiSearch _ ->
                    ( model, Command.none )

                Route.WikiLogin _ _ ->
                    ( model, Command.none )

                Route.WikiRegister _ ->
                    ( model, Command.none )

                Route.WikiSubmitNew _ ->
                    ( model, Command.none )

                Route.WikiSubmitEdit _ _ ->
                    ( model, Command.none )

                Route.WikiSubmitDelete _ _ ->
                    ( model, Command.none )

                Route.WikiSubmissionDetail _ _ ->
                    ( model, Command.none )

                Route.WikiMySubmissions _ ->
                    ( model, Command.none )

                Route.WikiReview _ ->
                    ( model, Command.none )

                Route.WikiReviewDetail _ _ ->
                    ( model, Command.none )

                Route.WikiAdminAudit _ ->
                    ( model, Command.none )

                Route.WikiAdminAuditDiff _ _ ->
                    ( model, Command.none )

                Route.HostAdminAudit ->
                    ( model, Command.none )

                Route.HostAdminAuditDiff _ _ ->
                    ( model, Command.none )

                Route.HostAdmin _ ->
                    ( model, Command.none )

                Route.HostAdminWikis ->
                    ( model, Command.none )

                Route.HostAdminBackup ->
                    ( model, Command.none )

                Route.HostAdminWikiNew ->
                    ( model, Command.none )

                Route.HostAdminWikiDetail _ ->
                    ( model, Command.none )

                Route.NotFound _ ->
                    ( model, Command.none )

        WikiAdminDemoteToContributorClicked targetUsername ->
            case model.route of
                Route.WikiAdminUsers wikiSlug ->
                    ( { model | adminDemoteError = Nothing }
                    , Effect.Lamdera.sendToBackend (DemoteTrustedToContributor wikiSlug targetUsername)
                    )

                Route.WikiList ->
                    ( model, Command.none )

                Route.WikiHome _ ->
                    ( model, Command.none )

                Route.WikiPage _ _ ->
                    ( model, Command.none )

                Route.WikiPageGraph _ _ ->
                    ( model, Command.none )

                Route.WikiTodos _ ->
                    ( model, Command.none )

                Route.WikiGraph _ ->
                    ( model, Command.none )

                Route.WikiSearch _ ->
                    ( model, Command.none )

                Route.WikiLogin _ _ ->
                    ( model, Command.none )

                Route.WikiRegister _ ->
                    ( model, Command.none )

                Route.WikiSubmitNew _ ->
                    ( model, Command.none )

                Route.WikiSubmitEdit _ _ ->
                    ( model, Command.none )

                Route.WikiSubmitDelete _ _ ->
                    ( model, Command.none )

                Route.WikiSubmissionDetail _ _ ->
                    ( model, Command.none )

                Route.WikiMySubmissions _ ->
                    ( model, Command.none )

                Route.WikiReview _ ->
                    ( model, Command.none )

                Route.WikiReviewDetail _ _ ->
                    ( model, Command.none )

                Route.WikiAdminAudit _ ->
                    ( model, Command.none )

                Route.WikiAdminAuditDiff _ _ ->
                    ( model, Command.none )

                Route.HostAdminAudit ->
                    ( model, Command.none )

                Route.HostAdminAuditDiff _ _ ->
                    ( model, Command.none )

                Route.HostAdmin _ ->
                    ( model, Command.none )

                Route.HostAdminWikis ->
                    ( model, Command.none )

                Route.HostAdminBackup ->
                    ( model, Command.none )

                Route.HostAdminWikiNew ->
                    ( model, Command.none )

                Route.HostAdminWikiDetail _ ->
                    ( model, Command.none )

                Route.NotFound _ ->
                    ( model, Command.none )

        WikiAdminGrantAdminClicked targetUsername ->
            case model.route of
                Route.WikiAdminUsers wikiSlug ->
                    ( { model | adminGrantAdminError = Nothing }
                    , Effect.Lamdera.sendToBackend (GrantWikiAdmin wikiSlug targetUsername)
                    )

                Route.WikiList ->
                    ( model, Command.none )

                Route.WikiHome _ ->
                    ( model, Command.none )

                Route.WikiPage _ _ ->
                    ( model, Command.none )

                Route.WikiPageGraph _ _ ->
                    ( model, Command.none )

                Route.WikiTodos _ ->
                    ( model, Command.none )

                Route.WikiGraph _ ->
                    ( model, Command.none )

                Route.WikiSearch _ ->
                    ( model, Command.none )

                Route.WikiLogin _ _ ->
                    ( model, Command.none )

                Route.WikiRegister _ ->
                    ( model, Command.none )

                Route.WikiSubmitNew _ ->
                    ( model, Command.none )

                Route.WikiSubmitEdit _ _ ->
                    ( model, Command.none )

                Route.WikiSubmitDelete _ _ ->
                    ( model, Command.none )

                Route.WikiSubmissionDetail _ _ ->
                    ( model, Command.none )

                Route.WikiMySubmissions _ ->
                    ( model, Command.none )

                Route.WikiReview _ ->
                    ( model, Command.none )

                Route.WikiReviewDetail _ _ ->
                    ( model, Command.none )

                Route.WikiAdminAudit _ ->
                    ( model, Command.none )

                Route.WikiAdminAuditDiff _ _ ->
                    ( model, Command.none )

                Route.HostAdminAudit ->
                    ( model, Command.none )

                Route.HostAdminAuditDiff _ _ ->
                    ( model, Command.none )

                Route.HostAdmin _ ->
                    ( model, Command.none )

                Route.HostAdminWikis ->
                    ( model, Command.none )

                Route.HostAdminBackup ->
                    ( model, Command.none )

                Route.HostAdminWikiNew ->
                    ( model, Command.none )

                Route.HostAdminWikiDetail _ ->
                    ( model, Command.none )

                Route.NotFound _ ->
                    ( model, Command.none )

        WikiAdminRevokeAdminClicked targetUsername ->
            case model.route of
                Route.WikiAdminUsers wikiSlug ->
                    ( { model | adminRevokeAdminError = Nothing }
                    , Effect.Lamdera.sendToBackend (RevokeWikiAdmin wikiSlug targetUsername)
                    )

                Route.WikiList ->
                    ( model, Command.none )

                Route.WikiHome _ ->
                    ( model, Command.none )

                Route.WikiPage _ _ ->
                    ( model, Command.none )

                Route.WikiPageGraph _ _ ->
                    ( model, Command.none )

                Route.WikiTodos _ ->
                    ( model, Command.none )

                Route.WikiGraph _ ->
                    ( model, Command.none )

                Route.WikiSearch _ ->
                    ( model, Command.none )

                Route.WikiLogin _ _ ->
                    ( model, Command.none )

                Route.WikiRegister _ ->
                    ( model, Command.none )

                Route.WikiSubmitNew _ ->
                    ( model, Command.none )

                Route.WikiSubmitEdit _ _ ->
                    ( model, Command.none )

                Route.WikiSubmitDelete _ _ ->
                    ( model, Command.none )

                Route.WikiSubmissionDetail _ _ ->
                    ( model, Command.none )

                Route.WikiMySubmissions _ ->
                    ( model, Command.none )

                Route.WikiReview _ ->
                    ( model, Command.none )

                Route.WikiReviewDetail _ _ ->
                    ( model, Command.none )

                Route.WikiAdminAudit _ ->
                    ( model, Command.none )

                Route.WikiAdminAuditDiff _ _ ->
                    ( model, Command.none )

                Route.HostAdminAudit ->
                    ( model, Command.none )

                Route.HostAdminAuditDiff _ _ ->
                    ( model, Command.none )

                Route.HostAdmin _ ->
                    ( model, Command.none )

                Route.HostAdminWikis ->
                    ( model, Command.none )

                Route.HostAdminBackup ->
                    ( model, Command.none )

                Route.HostAdminWikiNew ->
                    ( model, Command.none )

                Route.HostAdminWikiDetail _ ->
                    ( model, Command.none )

                Route.NotFound _ ->
                    ( model, Command.none )

        WikiAdminAuditFilterActorChanged value ->
            applyWikiAdminAuditFilterFromModel { model | wikiAdminAuditFilterActorDraft = value }

        WikiAdminAuditFilterPageChanged value ->
            applyWikiAdminAuditFilterFromModel { model | wikiAdminAuditFilterPageDraft = value }

        WikiAdminAuditFilterTypeTagToggled tag checked ->
            let
                nextTags : List WikiAuditLog.AuditEventKindFilterTag
                nextTags =
                    if checked then
                        if List.member tag model.wikiAdminAuditFilterSelectedKindTags then
                            model.wikiAdminAuditFilterSelectedKindTags

                        else
                            tag :: model.wikiAdminAuditFilterSelectedKindTags

                    else
                        List.filter (\t -> t /= tag) model.wikiAdminAuditFilterSelectedKindTags
            in
            applyWikiAdminAuditFilterFromModel { model | wikiAdminAuditFilterSelectedKindTags = nextTags }

        HostAdminAuditFilterWikiChanged value ->
            applyHostAdminAuditFilterFromModel { model | hostAdminAuditFilterWikiDraft = value }

        HostAdminAuditFilterActorChanged value ->
            applyHostAdminAuditFilterFromModel { model | hostAdminAuditFilterActorDraft = value }

        HostAdminAuditFilterPageChanged value ->
            applyHostAdminAuditFilterFromModel { model | hostAdminAuditFilterPageDraft = value }

        HostAdminAuditFilterTypeTagToggled tag checked ->
            let
                nextTags : List WikiAuditLog.AuditEventKindFilterTag
                nextTags =
                    if checked then
                        if List.member tag model.hostAdminAuditFilterSelectedKindTags then
                            model.hostAdminAuditFilterSelectedKindTags

                        else
                            tag :: model.hostAdminAuditFilterSelectedKindTags

                    else
                        List.filter (\t -> t /= tag) model.hostAdminAuditFilterSelectedKindTags
            in
            applyHostAdminAuditFilterFromModel { model | hostAdminAuditFilterSelectedKindTags = nextTags }

        HostAdminDataExportClicked ->
            case model.route of
                Route.HostAdminBackup ->
                    ( { model
                        | hostAdminExportInFlight = True
                        , hostAdminBackupNotice = Nothing
                      }
                    , Effect.Lamdera.sendToBackend RequestHostAdminDataExport
                    )

                _ ->
                    ( model, Command.none )

        HostAdminDataImportPickRequested ->
            case model.route of
                Route.HostAdminBackup ->
                    ( model
                    , Effect.File.Select.file [ "application/json", "text/plain" ] HostAdminDataImportFileSelected
                    )

                _ ->
                    ( model, Command.none )

        HostAdminDataImportFileSelected file ->
            ( model
            , Effect.Task.attempt HostAdminDataImportFileRead (Effect.File.toString file)
            )

        HostAdminDataImportFileRead readResult ->
            case ( model.route, readResult ) of
                ( Route.HostAdminBackup, Ok content ) ->
                    ( { model
                        | hostAdminImportInFlight = True
                        , hostAdminBackupNotice = Nothing
                      }
                    , Effect.Lamdera.sendToBackend (ImportHostAdminDataSnapshot content)
                    )

                ( Route.HostAdminBackup, Err _ ) ->
                    ( { model
                        | hostAdminBackupNotice = Just "Could not read the selected file."
                      }
                    , Command.none
                    )

                _ ->
                    ( model, Command.none )

        HostAdminWikisDataImportPickRequested ->
            case model.route of
                Route.HostAdminWikis ->
                    ( model
                    , Effect.File.Select.file [ "application/json", "text/plain" ] HostAdminWikisDataImportFileSelected
                    )

                _ ->
                    ( model, Command.none )

        HostAdminWikisDataImportFileSelected file ->
            ( model
            , Effect.Task.attempt HostAdminWikisDataImportFileRead (Effect.File.toString file)
            )

        HostAdminWikisDataImportFileRead readResult ->
            case ( model.route, readResult ) of
                ( Route.HostAdminWikis, Ok content ) ->
                    ( { model
                        | hostAdminImportInFlight = True
                        , hostAdminWikisNotice = Nothing
                      }
                    , Effect.Lamdera.sendToBackend (ImportHostAdminWikiDataSnapshotAuto content)
                    )

                ( Route.HostAdminWikis, Err _ ) ->
                    ( { model
                        | hostAdminWikisNotice = Just "Could not read the selected file."
                      }
                    , Command.none
                    )

                _ ->
                    ( model, Command.none )

        HostAdminWikiDataExportClicked wikiSlug ->
            case model.route of
                Route.HostAdminWikis ->
                    ( { model
                        | hostAdminWikiExportInFlightSlug = Just wikiSlug
                        , hostAdminWikisNotice = Nothing
                      }
                    , Effect.Lamdera.sendToBackend (RequestHostAdminWikiDataExport wikiSlug)
                    )

                _ ->
                    ( model, Command.none )

        HostAdminWikiDataImportPickRequested wikiSlug ->
            case model.route of
                Route.HostAdminWikis ->
                    ( { model | hostAdminWikiImportPendingSlug = Just wikiSlug }
                    , Effect.File.Select.file [ "application/json", "text/plain" ] HostAdminWikiDataImportFileSelected
                    )

                _ ->
                    ( model, Command.none )

        HostAdminWikiDataImportFileSelected file ->
            case model.hostAdminWikiImportPendingSlug of
                Nothing ->
                    ( model, Command.none )

                Just wikiSlug ->
                    ( model
                    , Effect.Task.attempt (HostAdminWikiDataImportFileRead wikiSlug) (Effect.File.toString file)
                    )

        HostAdminWikiDataImportFileRead wikiSlug readResult ->
            case ( model.route, readResult ) of
                ( Route.HostAdminWikis, Ok content ) ->
                    ( { model
                        | hostAdminWikiImportInFlightSlug = Just wikiSlug
                        , hostAdminWikisNotice = Nothing
                      }
                    , Effect.Lamdera.sendToBackend (ImportHostAdminWikiDataSnapshot wikiSlug content)
                    )

                ( Route.HostAdminWikis, Err _ ) ->
                    ( { model
                        | hostAdminWikisNotice = Just "Could not read the selected file."
                      }
                    , Command.none
                    )

                _ ->
                    ( model, Command.none )

        HostAdminCreateWikiSlugChanged value ->
            let
                d : HostAdminCreateWikiDraft
                d =
                    model.hostAdminCreateWikiDraft
            in
            ( { model | hostAdminCreateWikiDraft = { d | slug = value } }
            , Command.none
            )

        HostAdminCreateWikiNameChanged value ->
            let
                d : HostAdminCreateWikiDraft
                d =
                    model.hostAdminCreateWikiDraft
            in
            ( { model | hostAdminCreateWikiDraft = { d | name = value } }
            , Command.none
            )

        HostAdminCreateWikiInitialAdminUsernameChanged value ->
            let
                d : HostAdminCreateWikiDraft
                d =
                    model.hostAdminCreateWikiDraft
            in
            ( { model | hostAdminCreateWikiDraft = { d | initialAdminUsername = value } }
            , Command.none
            )

        HostAdminCreateWikiInitialAdminPasswordChanged value ->
            let
                d : HostAdminCreateWikiDraft
                d =
                    model.hostAdminCreateWikiDraft
            in
            ( { model | hostAdminCreateWikiDraft = { d | initialAdminPassword = value } }
            , Command.none
            )

        HostAdminCreateWikiSubmitted ->
            case model.route of
                Route.HostAdminWikiNew ->
                    let
                        d : HostAdminCreateWikiDraft
                        d =
                            model.hostAdminCreateWikiDraft
                    in
                    case HostAdmin.validateHostedWikiName d.name of
                        Err ne ->
                            ( { model
                                | hostAdminCreateWikiDraft =
                                    { d
                                        | lastResult = Just (Err (HostAdmin.CreateWikiNameInvalid ne))
                                        , inFlight = False
                                    }
                              }
                            , Command.none
                            )

                        Ok _ ->
                            case ContributorAccount.validateRegistrationFields d.initialAdminUsername d.initialAdminPassword of
                                Err regErr ->
                                    ( { model
                                        | hostAdminCreateWikiDraft =
                                            { d
                                                | lastResult =
                                                    Just (Err (HostAdmin.CreateInitialAdminInvalid regErr))
                                                , inFlight = False
                                            }
                                      }
                                    , Command.none
                                    )

                                Ok _ ->
                                    ( { model
                                        | hostAdminCreateWikiDraft =
                                            { d
                                                | inFlight = True
                                                , lastResult = Nothing
                                            }
                                      }
                                    , Effect.Lamdera.sendToBackend
                                        (CreateHostedWiki
                                            { rawSlug = d.slug
                                            , rawName = d.name
                                            , initialAdminUsername = d.initialAdminUsername
                                            , initialAdminPassword = d.initialAdminPassword
                                            }
                                        )
                                    )

                Route.WikiList ->
                    ( model, Command.none )

                Route.HostAdmin _ ->
                    ( model, Command.none )

                Route.HostAdminWikis ->
                    ( model, Command.none )

                Route.HostAdminBackup ->
                    ( model, Command.none )

                Route.HostAdminWikiDetail _ ->
                    ( model, Command.none )

                Route.WikiHome _ ->
                    ( model, Command.none )

                Route.WikiPage _ _ ->
                    ( model, Command.none )

                Route.WikiPageGraph _ _ ->
                    ( model, Command.none )

                Route.WikiTodos _ ->
                    ( model, Command.none )

                Route.WikiGraph _ ->
                    ( model, Command.none )

                Route.WikiSearch _ ->
                    ( model, Command.none )

                Route.WikiRegister _ ->
                    ( model, Command.none )

                Route.WikiLogin _ _ ->
                    ( model, Command.none )

                Route.WikiSubmitNew _ ->
                    ( model, Command.none )

                Route.WikiSubmitEdit _ _ ->
                    ( model, Command.none )

                Route.WikiSubmitDelete _ _ ->
                    ( model, Command.none )

                Route.WikiSubmissionDetail _ _ ->
                    ( model, Command.none )

                Route.WikiMySubmissions _ ->
                    ( model, Command.none )

                Route.WikiReview _ ->
                    ( model, Command.none )

                Route.WikiReviewDetail _ _ ->
                    ( model, Command.none )

                Route.WikiAdminUsers _ ->
                    ( model, Command.none )

                Route.WikiAdminAudit _ ->
                    ( model, Command.none )

                Route.WikiAdminAuditDiff _ _ ->
                    ( model, Command.none )

                Route.HostAdminAudit ->
                    ( model, Command.none )

                Route.HostAdminAuditDiff _ _ ->
                    ( model, Command.none )

                Route.NotFound _ ->
                    ( model, Command.none )

        HostAdminWikiDetailNameChanged value ->
            let
                d : HostAdminWikiDetailDraft
                d =
                    model.hostAdminWikiDetailDraft
            in
            ( { model | hostAdminWikiDetailDraft = { d | nameDraft = value } }
            , Command.none
            )

        HostAdminWikiDetailSlugChanged value ->
            let
                d : HostAdminWikiDetailDraft
                d =
                    model.hostAdminWikiDetailDraft
            in
            ( { model | hostAdminWikiDetailDraft = { d | slugDraft = value } }
            , Command.none
            )

        HostAdminWikiDetailSummaryChanged value ->
            let
                d : HostAdminWikiDetailDraft
                d =
                    model.hostAdminWikiDetailDraft
            in
            ( { model | hostAdminWikiDetailDraft = { d | summaryDraft = value } }
            , Command.none
            )

        HostAdminWikiDetailSaveClicked ->
            case model.route of
                Route.HostAdminWikiDetail _ ->
                    let
                        d : HostAdminWikiDetailDraft
                        d =
                            model.hostAdminWikiDetailDraft
                    in
                    if d.saveInFlight || d.lifecycleInFlight || d.deleteInFlight then
                        ( model, Command.none )

                    else
                        case HostAdmin.validateHostedWikiName d.nameDraft of
                            Err ne ->
                                ( { model
                                    | hostAdminWikiDetailDraft =
                                        { d
                                            | lastSaveResult =
                                                Just (Err (HostAdmin.UpdateMetadataWikiNameInvalid ne))
                                        }
                                  }
                                , Command.none
                                )

                            Ok name ->
                                case HostAdmin.validateHostedWikiSummary d.summaryDraft of
                                    Err se ->
                                        ( { model
                                            | hostAdminWikiDetailDraft =
                                                { d
                                                    | lastSaveResult =
                                                        Just (Err (HostAdmin.UpdateMetadataWikiSummaryInvalid se))
                                                }
                                          }
                                        , Command.none
                                        )

                                    Ok summaryText ->
                                        case d.load of
                                            RemoteData.Success (Ok entry) ->
                                                case HostAdmin.validateHostedWikiMetadataSlug entry.slug d.slugDraft of
                                                    Err slugErr ->
                                                        ( { model
                                                            | hostAdminWikiDetailDraft =
                                                                { d
                                                                    | lastSaveResult = Just (Err slugErr)
                                                                }
                                                          }
                                                        , Command.none
                                                        )

                                                    Ok slugText ->
                                                        ( { model
                                                            | hostAdminWikiDetailDraft =
                                                                { d
                                                                    | saveInFlight = True
                                                                    , lastSaveResult = Nothing
                                                                }
                                                          }
                                                        , Effect.Lamdera.sendToBackend
                                                            (UpdateHostedWikiMetadata d.wikiSlug
                                                                { rawName = name
                                                                , rawSummary = summaryText
                                                                , rawSlugDraft = slugText
                                                                }
                                                            )
                                                        )

                                            _ ->
                                                ( model, Command.none )

                Route.WikiList ->
                    ( model, Command.none )

                Route.HostAdmin _ ->
                    ( model, Command.none )

                Route.HostAdminWikis ->
                    ( model, Command.none )

                Route.HostAdminBackup ->
                    ( model, Command.none )

                Route.HostAdminWikiNew ->
                    ( model, Command.none )

                Route.WikiHome _ ->
                    ( model, Command.none )

                Route.WikiPage _ _ ->
                    ( model, Command.none )

                Route.WikiPageGraph _ _ ->
                    ( model, Command.none )

                Route.WikiTodos _ ->
                    ( model, Command.none )

                Route.WikiGraph _ ->
                    ( model, Command.none )

                Route.WikiSearch _ ->
                    ( model, Command.none )

                Route.WikiRegister _ ->
                    ( model, Command.none )

                Route.WikiLogin _ _ ->
                    ( model, Command.none )

                Route.WikiSubmitNew _ ->
                    ( model, Command.none )

                Route.WikiSubmitEdit _ _ ->
                    ( model, Command.none )

                Route.WikiSubmitDelete _ _ ->
                    ( model, Command.none )

                Route.WikiSubmissionDetail _ _ ->
                    ( model, Command.none )

                Route.WikiMySubmissions _ ->
                    ( model, Command.none )

                Route.WikiReview _ ->
                    ( model, Command.none )

                Route.WikiReviewDetail _ _ ->
                    ( model, Command.none )

                Route.WikiAdminUsers _ ->
                    ( model, Command.none )

                Route.WikiAdminAudit _ ->
                    ( model, Command.none )

                Route.WikiAdminAuditDiff _ _ ->
                    ( model, Command.none )

                Route.HostAdminAudit ->
                    ( model, Command.none )

                Route.HostAdminAuditDiff _ _ ->
                    ( model, Command.none )

                Route.NotFound _ ->
                    ( model, Command.none )

        HostAdminWikiDetailDeactivateClicked ->
            case model.route of
                Route.HostAdminWikiDetail _ ->
                    let
                        d : HostAdminWikiDetailDraft
                        d =
                            model.hostAdminWikiDetailDraft
                    in
                    if d.lifecycleInFlight || d.saveInFlight || d.deleteInFlight then
                        ( model, Command.none )

                    else
                        ( { model
                            | hostAdminWikiDetailDraft =
                                { d
                                    | lifecycleInFlight = True
                                    , lastLifecycleResult = Nothing
                                }
                          }
                        , Effect.Lamdera.sendToBackend (DeactivateHostedWiki d.wikiSlug)
                        )

                _ ->
                    ( model, Command.none )

        HostAdminWikiDetailReactivateClicked ->
            case model.route of
                Route.HostAdminWikiDetail _ ->
                    let
                        d : HostAdminWikiDetailDraft
                        d =
                            model.hostAdminWikiDetailDraft
                    in
                    if d.lifecycleInFlight || d.saveInFlight || d.deleteInFlight then
                        ( model, Command.none )

                    else
                        ( { model
                            | hostAdminWikiDetailDraft =
                                { d
                                    | lifecycleInFlight = True
                                    , lastLifecycleResult = Nothing
                                }
                          }
                        , Effect.Lamdera.sendToBackend (ReactivateHostedWiki d.wikiSlug)
                        )

                _ ->
                    ( model, Command.none )

        HostAdminWikiDetailDeleteConfirmChanged value ->
            let
                d : HostAdminWikiDetailDraft
                d =
                    model.hostAdminWikiDetailDraft
            in
            ( { model
                | hostAdminWikiDetailDraft =
                    { d
                        | deleteConfirmDraft = value
                        , lastDeleteResult = Nothing
                    }
              }
            , Command.none
            )

        HostAdminWikiDetailDeleteSubmitted ->
            case model.route of
                Route.HostAdminWikiDetail _ ->
                    let
                        d : HostAdminWikiDetailDraft
                        d =
                            model.hostAdminWikiDetailDraft
                    in
                    if d.deleteInFlight || d.saveInFlight || d.lifecycleInFlight then
                        ( model, Command.none )

                    else
                        ( { model
                            | hostAdminWikiDetailDraft =
                                { d
                                    | deleteInFlight = True
                                    , lastDeleteResult = Nothing
                                }
                          }
                        , Effect.Lamdera.sendToBackend (DeleteHostedWiki d.wikiSlug d.deleteConfirmDraft)
                        )

                _ ->
                    ( model, Command.none )

        HostAdminLoginPasswordChanged value ->
            let
                d : HostAdminLoginDraft
                d =
                    model.hostAdminLoginDraft
            in
            ( { model | hostAdminLoginDraft = { d | password = value } }
            , Command.none
            )

        HostAdminLoginSubmitted ->
            case model.route of
                Route.HostAdmin _ ->
                    let
                        d : HostAdminLoginDraft
                        d =
                            model.hostAdminLoginDraft
                    in
                    ( { model
                        | hostAdminLoginDraft =
                            { d
                                | inFlight = True
                                , lastResult = Nothing
                            }
                      }
                    , Effect.Lamdera.sendToBackend (HostAdminLogin d.password)
                    )

                Route.WikiList ->
                    ( model, Command.none )

                Route.HostAdminWikis ->
                    ( model, Command.none )

                Route.HostAdminBackup ->
                    ( model, Command.none )

                Route.HostAdminWikiNew ->
                    ( model, Command.none )

                Route.HostAdminWikiDetail _ ->
                    ( model, Command.none )

                Route.HostAdminAudit ->
                    ( model, Command.none )

                Route.HostAdminAuditDiff _ _ ->
                    ( model, Command.none )

                Route.WikiHome _ ->
                    ( model, Command.none )

                Route.WikiPage _ _ ->
                    ( model, Command.none )

                Route.WikiPageGraph _ _ ->
                    ( model, Command.none )

                Route.WikiTodos _ ->
                    ( model, Command.none )

                Route.WikiGraph _ ->
                    ( model, Command.none )

                Route.WikiSearch _ ->
                    ( model, Command.none )

                Route.WikiRegister _ ->
                    ( model, Command.none )

                Route.WikiLogin _ _ ->
                    ( model, Command.none )

                Route.WikiSubmitNew _ ->
                    ( model, Command.none )

                Route.WikiSubmitEdit _ _ ->
                    ( model, Command.none )

                Route.WikiSubmitDelete _ _ ->
                    ( model, Command.none )

                Route.WikiSubmissionDetail _ _ ->
                    ( model, Command.none )

                Route.WikiMySubmissions _ ->
                    ( model, Command.none )

                Route.WikiReview _ ->
                    ( model, Command.none )

                Route.WikiReviewDetail _ _ ->
                    ( model, Command.none )

                Route.WikiAdminUsers _ ->
                    ( model, Command.none )

                Route.WikiAdminAudit _ ->
                    ( model, Command.none )

                Route.WikiAdminAuditDiff _ _ ->
                    ( model, Command.none )

                Route.NotFound _ ->
                    ( model, Command.none )


updateFromBackend : ToFrontend -> Model -> ( Model, Command FrontendOnly ToBackend Msg )
updateFromBackend msg model =
    case msg of
        WikiCatalogResponse catalog ->
            let
                store : Store
                store =
                    model.store

                nextStore : Store
                nextStore =
                    { store | wikiCatalog = RemoteData.succeed catalog }
            in
            ( { model | store = nextStore }, Command.none )
                |> runRouteStoreActions

        PendingReviewCountUpdated wikiSlug count ->
            ( { model
                | store =
                    PendingReviewCount.mergeIntoStoreWikiDetails wikiSlug count model.store
              }
            , Command.none
            )

        WikiFrontendDetailsResponse wikiSlug maybeDetails ->
            let
                store : Store
                store =
                    model.store

                nextContributorWikiSessions : Dict Wiki.Slug ContributorWikiSession
                nextContributorWikiSessions =
                    syncContributorWikiSessionFromFrontendDetails wikiSlug maybeDetails model.contributorWikiSessions

                newStore : Store
                newStore =
                    case maybeDetails of
                        Just details ->
                            { store
                                | wikiDetails =
                                    store.wikiDetails
                                        |> Dict.insert wikiSlug (RemoteData.succeed details)
                            }

                        Nothing ->
                            { store
                                | wikiDetails =
                                    store.wikiDetails
                                        |> Dict.insert wikiSlug (RemoteData.Failure ())
                            }

                nextModel : Model
                nextModel =
                    { model
                        | store = newStore
                        , contributorWikiSessions = nextContributorWikiSessions
                    }
            in
            ( nextModel, contributorRouteRefreshCmd wikiSlug nextModel )
                |> runRouteStoreActions

        PageFrontendDetailsResponse wikiSlug pageSlug maybeDetails ->
            let
                store : Store
                store =
                    model.store

                key : ( Wiki.Slug, Page.Slug )
                key =
                    ( wikiSlug, pageSlug )

                nextStore : Store
                nextStore =
                    case maybeDetails of
                        Just details ->
                            { store
                                | publishedPages =
                                    Dict.insert key (RemoteData.succeed details) store.publishedPages
                            }

                        Nothing ->
                            { store
                                | publishedPages =
                                    Dict.insert key (RemoteData.Failure ()) store.publishedPages
                            }

                dEdit : PageEditSubmitDraft
                dEdit =
                    model.pageEditSubmitDraft

                nextPageEditSubmitDraft : PageEditSubmitDraft
                nextPageEditSubmitDraft =
                    case ( maybeDetails, model.route ) of
                        ( Just details, Route.WikiSubmitEdit rs rp ) ->
                            if rs == wikiSlug && rp == pageSlug && String.isEmpty dEdit.markdownBody then
                                { dEdit
                                    | markdownBody = details.maybeMarkdownSource |> Maybe.withDefault ""
                                    , tagsInput = String.join ", " details.tags
                                }

                            else
                                dEdit

                        _ ->
                            dEdit

                pageScrollCmd : Command FrontendOnly ToBackend Msg
                pageScrollCmd =
                    case ( maybeDetails, model.route ) of
                        ( Just _, Route.WikiPage rs rp ) ->
                            if rs == wikiSlug && rp == pageSlug then
                                scrollToNavigationFragmentCmd model.navigationFragment

                            else
                                Command.none

                        _ ->
                            Command.none

                ( storeAfterPendingFetch, fetchMyPendingCmd ) =
                    case ( maybeDetails, model.route ) of
                        ( Just details, Route.WikiPage rs rp ) ->
                            if rs == wikiSlug && rp == pageSlug && contributorLoggedInOnWikiSlug wikiSlug model then
                                case details.maybeMarkdownSource of
                                    Nothing ->
                                        runStoreActions nextStore [ Store.AskForMyPendingSubmissions wikiSlug ]

                                    Just _ ->
                                        ( nextStore, Command.none )

                            else
                                ( nextStore, Command.none )

                        _ ->
                            ( nextStore, Command.none )
            in
            ( { model | store = storeAfterPendingFetch, pageEditSubmitDraft = nextPageEditSubmitDraft }
            , fetchMyPendingCmd
            )
                |> runRouteStoreActions
                |> (\( m, c ) -> ( m, Command.batch [ c, pageScrollCmd ] ))

        ReviewQueueResponse wikiSlug result ->
            let
                store : Store
                store =
                    model.store

                nextStore : Store
                nextStore =
                    { store
                        | reviewQueues =
                            Dict.insert wikiSlug (RemoteData.succeed result) store.reviewQueues
                    }
            in
            ( { model | store = nextStore }, Command.none )

        MyPendingSubmissionsResponse wikiSlug result ->
            let
                store : Store
                store =
                    model.store

                nextStore : Store
                nextStore =
                    { store
                        | myPendingSubmissions =
                            Dict.insert wikiSlug (RemoteData.succeed result) store.myPendingSubmissions
                    }
            in
            ( { model | store = nextStore }, Command.none )

        WikiUsersResponse wikiSlug result ->
            let
                store : Store
                store =
                    model.store

                nextStore : Store
                nextStore =
                    { store
                        | wikiUsers =
                            Dict.insert wikiSlug (RemoteData.succeed result) store.wikiUsers
                    }

                nextContributorWikiSessions : Dict Wiki.Slug ContributorWikiSession
                nextContributorWikiSessions =
                    case result of
                        Ok users ->
                            case Dict.get wikiSlug model.contributorWikiSessions of
                                Just cw ->
                                    users
                                        |> List.filter (\u -> u.username == cw.displayUsername)
                                        |> List.head
                                        |> Maybe.map .role
                                        |> (\maybeNewRole ->
                                                case maybeNewRole of
                                                    Just r ->
                                                        Dict.insert wikiSlug { cw | role = r } model.contributorWikiSessions

                                                    Nothing ->
                                                        model.contributorWikiSessions
                                           )

                                Nothing ->
                                    model.contributorWikiSessions

                        Err _ ->
                            model.contributorWikiSessions
            in
            ( { model | store = nextStore, contributorWikiSessions = nextContributorWikiSessions }
            , Command.none
            )
                |> runRouteStoreActions

        WikiAuditLogResponse wikiSlug filter result ->
            let
                store : Store
                store =
                    model.store

                cacheKey : String
                cacheKey =
                    WikiAuditLog.auditLogFilterCacheKey filter

                inner0 : Dict String (RemoteData () (Result WikiAuditLog.Error (List WikiAuditLog.AuditEvent)))
                inner0 =
                    Dict.get wikiSlug store.wikiAuditLogs
                        |> Maybe.withDefault Dict.empty

                inner1 : Dict String (RemoteData () (Result WikiAuditLog.Error (List WikiAuditLog.AuditEvent)))
                inner1 =
                    Dict.insert cacheKey (RemoteData.succeed result) inner0

                nextStore : Store
                nextStore =
                    { store
                        | wikiAuditLogs =
                            Dict.insert wikiSlug inner1 store.wikiAuditLogs
                    }
            in
            ( { model | store = nextStore }, Command.none )
                |> runRouteStoreActions

        PromoteContributorToTrustedResponse wikiSlug result ->
            case result of
                Ok () ->
                    let
                        store : Store
                        store =
                            model.store

                        nextStore : Store
                        nextStore =
                            { store
                                | wikiUsers =
                                    Dict.insert wikiSlug Loading store.wikiUsers
                                , wikiAuditLogs =
                                    Dict.remove wikiSlug store.wikiAuditLogs
                            }
                    in
                    ( { model | store = nextStore, adminPromoteError = Nothing }
                    , Effect.Lamdera.sendToBackend (RequestWikiUsers wikiSlug)
                    )

                Err e ->
                    ( { model | adminPromoteError = Just (WikiAdminUsers.promoteErrorToUserText e) }
                    , Command.none
                    )

        DemoteTrustedToContributorResponse wikiSlug result ->
            case result of
                Ok () ->
                    let
                        store : Store
                        store =
                            model.store

                        nextStore : Store
                        nextStore =
                            { store
                                | wikiUsers =
                                    Dict.insert wikiSlug Loading store.wikiUsers
                                , wikiAuditLogs =
                                    Dict.remove wikiSlug store.wikiAuditLogs
                            }
                    in
                    ( { model | store = nextStore, adminDemoteError = Nothing }
                    , Effect.Lamdera.sendToBackend (RequestWikiUsers wikiSlug)
                    )

                Err e ->
                    ( { model | adminDemoteError = Just (WikiAdminUsers.demoteErrorToUserText e) }
                    , Command.none
                    )

        GrantWikiAdminResponse wikiSlug result ->
            case result of
                Ok () ->
                    let
                        store : Store
                        store =
                            model.store

                        nextStore : Store
                        nextStore =
                            { store
                                | wikiUsers =
                                    Dict.insert wikiSlug Loading store.wikiUsers
                                , wikiAuditLogs =
                                    Dict.remove wikiSlug store.wikiAuditLogs
                            }
                    in
                    ( { model | store = nextStore, adminGrantAdminError = Nothing }
                    , Effect.Lamdera.sendToBackend (RequestWikiUsers wikiSlug)
                    )

                Err e ->
                    ( { model | adminGrantAdminError = Just (WikiAdminUsers.grantTrustedToAdminErrorToUserText e) }
                    , Command.none
                    )

        RevokeWikiAdminResponse wikiSlug result ->
            case result of
                Ok () ->
                    let
                        store : Store
                        store =
                            model.store

                        nextStore : Store
                        nextStore =
                            { store
                                | wikiUsers =
                                    Dict.insert wikiSlug Loading store.wikiUsers
                                , wikiAuditLogs =
                                    Dict.remove wikiSlug store.wikiAuditLogs
                            }
                    in
                    ( { model | store = nextStore, adminRevokeAdminError = Nothing }
                    , Effect.Lamdera.sendToBackend (RequestWikiUsers wikiSlug)
                    )

                Err e ->
                    ( { model | adminRevokeAdminError = Just (WikiAdminUsers.revokeAdminErrorToUserText e) }
                    , Command.none
                    )

        RegisterContributorResponse wikiSlug result ->
            let
                d : RegisterDraft
                d =
                    model.registerDraft

                nextDraft : RegisterDraft
                nextDraft =
                    if d.inFlight then
                        case result of
                            Ok _ ->
                                { username = ""
                                , password = ""
                                , inFlight = False
                                , lastResult = Just (Ok ())
                                }

                            Err _ ->
                                { d
                                    | inFlight = False
                                    , lastResult = Just (Result.map (always ()) result)
                                }

                    else
                        d

                nextContributorWikiSessions : Dict Wiki.Slug ContributorWikiSession
                nextContributorWikiSessions =
                    if d.inFlight then
                        case result of
                            Ok role ->
                                Dict.insert wikiSlug
                                    { role = role
                                    , displayUsername = ContributorAccount.normalizeUsername d.username
                                    }
                                    model.contributorWikiSessions

                            Err _ ->
                                model.contributorWikiSessions

                    else
                        model.contributorWikiSessions

                nextStore : Store
                nextStore =
                    let
                        store : Store
                        store =
                            model.store
                    in
                    if d.inFlight then
                        case result of
                            Ok _ ->
                                { store
                                    | wikiUsers = Dict.remove wikiSlug store.wikiUsers
                                    , wikiAuditLogs = Dict.remove wikiSlug store.wikiAuditLogs
                                    , myPendingSubmissions = Dict.remove wikiSlug store.myPendingSubmissions
                                }

                            Err _ ->
                                store

                    else
                        store

                nextModel : Model
                nextModel =
                    { model
                        | registerDraft = nextDraft
                        , contributorWikiSessions = nextContributorWikiSessions
                        , store = nextStore
                    }

                afterRegisterCmd : Command FrontendOnly ToBackend Msg
                afterRegisterCmd =
                    case ( nextModel.route, result ) of
                        ( Route.WikiLogin _ (Just path), Ok _ ) ->
                            Effect.Browser.Navigation.pushUrl nextModel.key path

                        ( Route.WikiRegister homeWikiSlug, Ok _ ) ->
                            Effect.Browser.Navigation.pushUrl nextModel.key (Wiki.wikiHomeUrlPath homeWikiSlug)

                        _ ->
                            Command.none
            in
            ( nextModel, afterRegisterCmd )
                |> runRouteStoreActions

        LoginContributorResponse wikiSlug result ->
            let
                d : LoginDraft
                d =
                    model.loginDraft

                nextDraft : LoginDraft
                nextDraft =
                    if d.inFlight then
                        case result of
                            Ok _ ->
                                { username = ""
                                , password = ""
                                , inFlight = False
                                , lastResult = Just (Ok ())
                                }

                            Err _ ->
                                { d
                                    | inFlight = False
                                    , lastResult = Just (Result.map (always ()) result)
                                }

                    else
                        d

                nextContributorWikiSessions : Dict Wiki.Slug ContributorWikiSession
                nextContributorWikiSessions =
                    if d.inFlight then
                        case result of
                            Ok role ->
                                Dict.insert wikiSlug
                                    { role = role
                                    , displayUsername = ContributorAccount.normalizeUsername d.username
                                    }
                                    model.contributorWikiSessions

                            Err _ ->
                                model.contributorWikiSessions

                    else
                        model.contributorWikiSessions

                nextStore : Store
                nextStore =
                    let
                        store : Store
                        store =
                            model.store
                    in
                    if d.inFlight then
                        case result of
                            Ok _ ->
                                { store
                                    | wikiUsers = Dict.remove wikiSlug store.wikiUsers
                                    , wikiAuditLogs = Dict.remove wikiSlug store.wikiAuditLogs
                                    , myPendingSubmissions = Dict.remove wikiSlug store.myPendingSubmissions
                                }

                            Err _ ->
                                store

                    else
                        store

                nextModel : Model
                nextModel =
                    { model
                        | loginDraft = nextDraft
                        , contributorWikiSessions = nextContributorWikiSessions
                        , store = nextStore
                    }

                afterLoginCmd : Command FrontendOnly ToBackend Msg
                afterLoginCmd =
                    case ( nextModel.route, result ) of
                        ( Route.WikiLogin _ (Just path), Ok _ ) ->
                            Effect.Browser.Navigation.pushUrl nextModel.key path

                        ( Route.WikiLogin homeWikiSlug Nothing, Ok _ ) ->
                            Effect.Browser.Navigation.pushUrl nextModel.key (Wiki.wikiHomeUrlPath homeWikiSlug)

                        _ ->
                            Command.none
            in
            ( nextModel, afterLoginCmd )
                |> runRouteStoreActions

        LogoutContributorResponse loggedOutWiki ->
            let
                navCmd : Command FrontendOnly ToBackend Msg
                navCmd =
                    postLogoutNavigationCmd loggedOutWiki model

                store0 : Store
                store0 =
                    model.store

                nextStore : Store
                nextStore =
                    { store0
                        | wikiUsers = Dict.remove loggedOutWiki store0.wikiUsers
                        , wikiAuditLogs = Dict.remove loggedOutWiki store0.wikiAuditLogs
                        , myPendingSubmissions = Dict.remove loggedOutWiki store0.myPendingSubmissions
                    }
            in
            ( { model
                | contributorWikiSessions = Dict.remove loggedOutWiki model.contributorWikiSessions
                , store = nextStore
              }
            , navCmd
            )
                |> runRouteStoreActions

        SubmitNewPageResponse wikiSlug result ->
            let
                d : NewPageSubmitDraft
                d =
                    model.newPageSubmitDraft

                nextDraft : NewPageSubmitDraft
                nextDraft =
                    if d.inFlight then
                        case result of
                            Ok _ ->
                                { d
                                    | inFlight = False
                                    , lastResult = Just result
                                }

                            Err _ ->
                                { d
                                    | inFlight = False
                                    , lastResult = Just result
                                }

                    else
                        d

                store0 : Store
                store0 =
                    model.store

                validatedNewPagePayload : Maybe { pageSlug : Page.Slug, markdown : String, tags : List Page.Slug }
                validatedNewPagePayload =
                    Submission.validateNewPageFields d.pageSlug d.markdownBody d.tagsInput
                        |> Result.toMaybe

                immediatePublishNavCmd : Command FrontendOnly ToBackend Msg
                immediatePublishNavCmd =
                    case result of
                        Ok Submission.NewPagePublishedImmediately ->
                            validatedNewPagePayload
                                |> Maybe.map
                                    (\payload ->
                                        Effect.Browser.Navigation.pushUrl model.key
                                            (Wiki.publishedPageUrlPath wikiSlug payload.pageSlug)
                                    )
                                |> Maybe.withDefault Command.none

                        _ ->
                            Command.none

                nextStore : Store
                nextStore =
                    case result of
                        Ok Submission.NewPagePublishedImmediately ->
                            case validatedNewPagePayload of
                                Just payload ->
                                    afterTrustedNewPagePublishedImmediately wikiSlug payload store0

                                Nothing ->
                                    invalidateWikiPublishedCaches wikiSlug store0

                        Ok (Submission.NewPageSubmittedForReview _) ->
                            { store0
                                | myPendingSubmissions =
                                    Dict.remove wikiSlug store0.myPendingSubmissions
                            }

                        Err _ ->
                            store0
            in
            ( { model | newPageSubmitDraft = nextDraft, store = nextStore }, immediatePublishNavCmd )
                |> runRouteStoreActions

        SubmitPageEditResponse wikiSlug result ->
            let
                d : PageEditSubmitDraft
                d =
                    model.pageEditSubmitDraft

                nextDraft : PageEditSubmitDraft
                nextDraft =
                    if d.inFlight then
                        case result of
                            Ok _ ->
                                { d
                                    | inFlight = False
                                    , lastResult = Just result
                                }

                            Err _ ->
                                { d
                                    | inFlight = False
                                    , lastResult = Just result
                                }

                    else
                        d

                nextStore : Store
                nextStore =
                    let
                        store0 : Store
                        store0 =
                            model.store
                    in
                    case result of
                        Ok Submission.EditPublishedImmediately ->
                            let
                                validatedEditPayload : Maybe { pageSlug : Page.Slug, proposedMarkdown : String, tags : List Page.Slug }
                                validatedEditPayload =
                                    case model.route of
                                        Route.WikiSubmitEdit routeWiki pageSlug ->
                                            if routeWiki == wikiSlug then
                                                Submission.validateEditMarkdown d.markdownBody d.tagsInput pageSlug
                                                    |> Result.toMaybe
                                                    |> Maybe.map
                                                        (\edit ->
                                                            { pageSlug = pageSlug
                                                            , proposedMarkdown = edit.proposedMarkdown
                                                            , tags = edit.tags
                                                            }
                                                        )

                                            else
                                                Nothing

                                        _ ->
                                            Nothing
                            in
                            case validatedEditPayload of
                                Just editPayload ->
                                    afterTrustedEditPublishedImmediately wikiSlug
                                        editPayload.pageSlug
                                        { proposedMarkdown = editPayload.proposedMarkdown
                                        , tags = editPayload.tags
                                        }
                                        store0

                                Nothing ->
                                    invalidateWikiPublishedCaches wikiSlug store0

                        Ok (Submission.EditSubmittedForReview _) ->
                            { store0
                                | myPendingSubmissions =
                                    Dict.remove wikiSlug store0.myPendingSubmissions
                            }

                        Err _ ->
                            store0

                immediateEditPublishNavCmd : Command FrontendOnly ToBackend Msg
                immediateEditPublishNavCmd =
                    case result of
                        Ok Submission.EditPublishedImmediately ->
                            case model.route of
                                Route.WikiSubmitEdit routeWiki pageSlug ->
                                    if routeWiki == wikiSlug then
                                        Effect.Browser.Navigation.pushUrl model.key
                                            (Wiki.publishedPageUrlPath wikiSlug pageSlug)

                                    else
                                        Command.none

                                _ ->
                                    Command.none

                        _ ->
                            Command.none
            in
            ( { model | pageEditSubmitDraft = nextDraft, store = nextStore }
            , immediateEditPublishNavCmd
            )
                |> runRouteStoreActions

        RequestPublishedPageDeletionResponse wikiSlug result ->
            let
                formResult : Result Submission.PageDeleteFormError Submission.PageDeleteFormSuccess
                formResult =
                    result
                        |> Result.mapError Submission.PageDeleteRequestFailed
                        |> Result.map Submission.DeleteSubmittedForReview

                d : PageDeleteSubmitDraft
                d =
                    model.pageDeleteSubmitDraft

                nextDraft : PageDeleteSubmitDraft
                nextDraft =
                    if d.inFlight then
                        { d
                            | inFlight = False
                            , lastResult = Just formResult
                        }

                    else
                        d

                nextStore : Store
                nextStore =
                    let
                        store0 : Store
                        store0 =
                            model.store
                    in
                    case formResult of
                        Ok (Submission.DeleteSubmittedForReview _) ->
                            { store0
                                | myPendingSubmissions =
                                    Dict.remove wikiSlug store0.myPendingSubmissions
                            }

                        Ok Submission.DeletePublishedImmediately ->
                            store0

                        Err _ ->
                            store0
            in
            ( { model | pageDeleteSubmitDraft = nextDraft, store = nextStore }, Command.none )
                |> runRouteStoreActions

        DeletePublishedPageImmediatelyResponse wikiSlug result ->
            let
                formResult : Result Submission.PageDeleteFormError Submission.PageDeleteFormSuccess
                formResult =
                    result
                        |> Result.mapError Submission.PageDeleteImmediateFailed
                        |> Result.map (\() -> Submission.DeletePublishedImmediately)

                d : PageDeleteSubmitDraft
                d =
                    model.pageDeleteSubmitDraft

                nextDraft : PageDeleteSubmitDraft
                nextDraft =
                    if d.inFlight then
                        { d
                            | inFlight = False
                            , lastResult = Just formResult
                        }

                    else
                        d

                nextStore : Store
                nextStore =
                    let
                        store0 : Store
                        store0 =
                            model.store
                    in
                    case formResult of
                        Ok Submission.DeletePublishedImmediately ->
                            invalidateWikiPublishedCaches wikiSlug store0

                        Ok (Submission.DeleteSubmittedForReview _) ->
                            store0

                        Err _ ->
                            store0
            in
            ( { model | pageDeleteSubmitDraft = nextDraft, store = nextStore }, Command.none )
                |> runRouteStoreActions

        SaveNewPageDraftResponse wikiSlug result ->
            let
                formD : NewPageSubmitDraft
                formD =
                    model.newPageSubmitDraft

                inter : SubmissionDetailEditDraft
                inter =
                    model.submissionDetailEditDraft

                store0 : Store
                store0 =
                    model.store

                nextForm : NewPageSubmitDraft
                nextForm =
                    if formD.saveDraftInFlight then
                        case result of
                            Ok id ->
                                let
                                    base : NewPageSubmitDraft
                                    base =
                                        { formD
                                            | saveDraftInFlight = False
                                            , maybeSavedDraftId = Just (Submission.idToString id)
                                            , lastSaveDraftResult = Just result
                                        }
                                in
                                if formD.pendingSubmitAfterSave then
                                    case model.route of
                                        Route.WikiSubmitNew w ->
                                            if w == wikiSlug then
                                                { base | pendingSubmitAfterSave = False, inFlight = True }

                                            else
                                                { base | pendingSubmitAfterSave = False }

                                        _ ->
                                            { base | pendingSubmitAfterSave = False }

                                else
                                    base

                            Err _ ->
                                { formD
                                    | saveDraftInFlight = False
                                    , pendingSubmitAfterSave = False
                                    , lastSaveDraftResult = Just result
                                }

                    else
                        formD

                formChainCmd : Command FrontendOnly ToBackend Msg
                formChainCmd =
                    case result of
                        Ok id ->
                            if formD.saveDraftInFlight && formD.pendingSubmitAfterSave then
                                case model.route of
                                    Route.WikiSubmitNew w ->
                                        if w == wikiSlug then
                                            Effect.Lamdera.sendToBackend (SubmitDraftForReview wikiSlug (Submission.idToString id))

                                        else
                                            Command.none

                                    _ ->
                                        Command.none

                            else
                                Command.none

                        _ ->
                            Command.none

                ( nextInter, detailCmd, storeFromDetail ) =
                    if inter.saveDraftInFlight then
                        case model.route of
                            Route.WikiSubmissionDetail w sid ->
                                if w == wikiSlug then
                                    case result of
                                        Ok _ ->
                                            let
                                                invalidateMy : Store
                                                invalidateMy =
                                                    { store0
                                                        | myPendingSubmissions =
                                                            Dict.remove wikiSlug store0.myPendingSubmissions
                                                    }

                                                baseInter : SubmissionDetailEditDraft
                                                baseInter =
                                                    { inter
                                                        | saveDraftInFlight = False
                                                        , lastError = Nothing
                                                    }

                                                afterInter : SubmissionDetailEditDraft
                                                afterInter =
                                                    if inter.pendingSubmitAfterSave then
                                                        { baseInter
                                                            | pendingSubmitAfterSave = False
                                                            , submitForReviewInFlight = True
                                                        }

                                                    else
                                                        { baseInter | pendingSubmitAfterSave = False }

                                                dCmd : Command FrontendOnly ToBackend Msg
                                                dCmd =
                                                    if inter.pendingSubmitAfterSave then
                                                        Effect.Lamdera.sendToBackend (SubmitDraftForReview wikiSlug sid)

                                                    else
                                                        Command.none
                                            in
                                            ( afterInter, dCmd, invalidateMy )

                                        Err err ->
                                            ( { inter
                                                | saveDraftInFlight = False
                                                , pendingSubmitAfterSave = False
                                                , lastError = Just (Submission.saveNewPageDraftErrorToUserText err)
                                              }
                                            , Command.none
                                            , store0
                                            )

                                else
                                    ( inter, Command.none, store0 )

                            _ ->
                                ( inter, Command.none, store0 )

                    else
                        ( inter, Command.none, store0 )

                nextStore : Store
                nextStore =
                    let
                        baseStore : Store
                        baseStore =
                            storeFromDetail
                    in
                    if formD.saveDraftInFlight then
                        { baseStore
                            | myPendingSubmissions =
                                Dict.remove wikiSlug baseStore.myPendingSubmissions
                        }

                    else
                        baseStore
            in
            ( { model
                | newPageSubmitDraft = nextForm
                , submissionDetailEditDraft = nextInter
                , store = nextStore
              }
            , Command.batch [ formChainCmd, detailCmd ]
            )
                |> runRouteStoreActions

        SavePageEditDraftResponse wikiSlug result ->
            let
                formD : PageEditSubmitDraft
                formD =
                    model.pageEditSubmitDraft

                inter : SubmissionDetailEditDraft
                inter =
                    model.submissionDetailEditDraft

                store0 : Store
                store0 =
                    model.store

                nextForm : PageEditSubmitDraft
                nextForm =
                    if formD.saveDraftInFlight then
                        case result of
                            Ok id ->
                                let
                                    base : PageEditSubmitDraft
                                    base =
                                        { formD
                                            | saveDraftInFlight = False
                                            , maybeSavedDraftId = Just (Submission.idToString id)
                                            , lastSaveDraftResult = Just result
                                        }
                                in
                                if formD.pendingSubmitAfterSave then
                                    case model.route of
                                        Route.WikiSubmitEdit w _ ->
                                            if w == wikiSlug then
                                                { base | pendingSubmitAfterSave = False, inFlight = True }

                                            else
                                                { base | pendingSubmitAfterSave = False }

                                        _ ->
                                            { base | pendingSubmitAfterSave = False }

                                else
                                    base

                            Err _ ->
                                { formD
                                    | saveDraftInFlight = False
                                    , pendingSubmitAfterSave = False
                                    , lastSaveDraftResult = Just result
                                }

                    else
                        formD

                formChainCmd : Command FrontendOnly ToBackend Msg
                formChainCmd =
                    case result of
                        Ok id ->
                            if formD.saveDraftInFlight && formD.pendingSubmitAfterSave then
                                case model.route of
                                    Route.WikiSubmitEdit w _ ->
                                        if w == wikiSlug then
                                            Effect.Lamdera.sendToBackend (SubmitDraftForReview wikiSlug (Submission.idToString id))

                                        else
                                            Command.none

                                    _ ->
                                        Command.none

                            else
                                Command.none

                        _ ->
                            Command.none

                ( nextInter, detailCmd, storeFromDetail ) =
                    if inter.saveDraftInFlight then
                        case model.route of
                            Route.WikiSubmissionDetail w sid ->
                                if w == wikiSlug then
                                    case result of
                                        Ok _ ->
                                            let
                                                invalidateMy : Store
                                                invalidateMy =
                                                    { store0
                                                        | myPendingSubmissions =
                                                            Dict.remove wikiSlug store0.myPendingSubmissions
                                                    }

                                                baseInter : SubmissionDetailEditDraft
                                                baseInter =
                                                    { inter
                                                        | saveDraftInFlight = False
                                                        , lastError = Nothing
                                                    }

                                                afterInter : SubmissionDetailEditDraft
                                                afterInter =
                                                    if inter.pendingSubmitAfterSave then
                                                        { baseInter
                                                            | pendingSubmitAfterSave = False
                                                            , submitForReviewInFlight = True
                                                        }

                                                    else
                                                        { baseInter | pendingSubmitAfterSave = False }

                                                dCmd : Command FrontendOnly ToBackend Msg
                                                dCmd =
                                                    if inter.pendingSubmitAfterSave then
                                                        Effect.Lamdera.sendToBackend (SubmitDraftForReview wikiSlug sid)

                                                    else
                                                        Command.none
                                            in
                                            ( afterInter, dCmd, invalidateMy )

                                        Err err ->
                                            ( { inter
                                                | saveDraftInFlight = False
                                                , pendingSubmitAfterSave = False
                                                , lastError = Just (Submission.savePageEditDraftErrorToUserText err)
                                              }
                                            , Command.none
                                            , store0
                                            )

                                else
                                    ( inter, Command.none, store0 )

                            _ ->
                                ( inter, Command.none, store0 )

                    else
                        ( inter, Command.none, store0 )

                nextStore : Store
                nextStore =
                    let
                        baseStore : Store
                        baseStore =
                            storeFromDetail
                    in
                    if formD.saveDraftInFlight then
                        { baseStore
                            | myPendingSubmissions =
                                Dict.remove wikiSlug baseStore.myPendingSubmissions
                        }

                    else
                        baseStore
            in
            ( { model
                | pageEditSubmitDraft = nextForm
                , submissionDetailEditDraft = nextInter
                , store = nextStore
              }
            , Command.batch [ formChainCmd, detailCmd ]
            )
                |> runRouteStoreActions

        SavePageDeleteDraftResponse wikiSlug result ->
            let
                formD : PageDeleteSubmitDraft
                formD =
                    model.pageDeleteSubmitDraft

                inter : SubmissionDetailEditDraft
                inter =
                    model.submissionDetailEditDraft

                store0 : Store
                store0 =
                    model.store

                nextForm : PageDeleteSubmitDraft
                nextForm =
                    if formD.saveDraftInFlight then
                        case result of
                            Ok id ->
                                let
                                    base : PageDeleteSubmitDraft
                                    base =
                                        { formD
                                            | saveDraftInFlight = False
                                            , maybeSavedDraftId = Just (Submission.idToString id)
                                            , lastSaveDraftResult = Just result
                                        }
                                in
                                if formD.pendingSubmitAfterSave then
                                    case model.route of
                                        Route.WikiSubmitDelete w _ ->
                                            if w == wikiSlug then
                                                { base | pendingSubmitAfterSave = False, inFlight = True }

                                            else
                                                { base | pendingSubmitAfterSave = False }

                                        _ ->
                                            { base | pendingSubmitAfterSave = False }

                                else
                                    base

                            Err _ ->
                                { formD
                                    | saveDraftInFlight = False
                                    , pendingSubmitAfterSave = False
                                    , lastSaveDraftResult = Just result
                                }

                    else
                        formD

                formChainCmd : Command FrontendOnly ToBackend Msg
                formChainCmd =
                    case result of
                        Ok id ->
                            if formD.saveDraftInFlight && formD.pendingSubmitAfterSave then
                                case model.route of
                                    Route.WikiSubmitDelete w _ ->
                                        if w == wikiSlug then
                                            Effect.Lamdera.sendToBackend (SubmitDraftForReview wikiSlug (Submission.idToString id))

                                        else
                                            Command.none

                                    _ ->
                                        Command.none

                            else
                                Command.none

                        _ ->
                            Command.none

                ( nextInter, detailCmd, storeFromDetail ) =
                    if inter.saveDraftInFlight then
                        case model.route of
                            Route.WikiSubmissionDetail w sid ->
                                if w == wikiSlug then
                                    case result of
                                        Ok _ ->
                                            let
                                                invalidateMy : Store
                                                invalidateMy =
                                                    { store0
                                                        | myPendingSubmissions =
                                                            Dict.remove wikiSlug store0.myPendingSubmissions
                                                    }

                                                baseInter : SubmissionDetailEditDraft
                                                baseInter =
                                                    { inter
                                                        | saveDraftInFlight = False
                                                        , lastError = Nothing
                                                    }

                                                afterInter : SubmissionDetailEditDraft
                                                afterInter =
                                                    if inter.pendingSubmitAfterSave then
                                                        { baseInter
                                                            | pendingSubmitAfterSave = False
                                                            , submitForReviewInFlight = True
                                                        }

                                                    else
                                                        { baseInter | pendingSubmitAfterSave = False }

                                                dCmd : Command FrontendOnly ToBackend Msg
                                                dCmd =
                                                    if inter.pendingSubmitAfterSave then
                                                        Effect.Lamdera.sendToBackend (SubmitDraftForReview wikiSlug sid)

                                                    else
                                                        Command.none
                                            in
                                            ( afterInter, dCmd, invalidateMy )

                                        Err err ->
                                            ( { inter
                                                | saveDraftInFlight = False
                                                , pendingSubmitAfterSave = False
                                                , lastError = Just (Submission.savePageDeleteDraftErrorToUserText err)
                                              }
                                            , Command.none
                                            , store0
                                            )

                                else
                                    ( inter, Command.none, store0 )

                            _ ->
                                ( inter, Command.none, store0 )

                    else
                        ( inter, Command.none, store0 )

                nextStore : Store
                nextStore =
                    let
                        baseStore : Store
                        baseStore =
                            storeFromDetail
                    in
                    if formD.saveDraftInFlight then
                        { baseStore
                            | myPendingSubmissions =
                                Dict.remove wikiSlug baseStore.myPendingSubmissions
                        }

                    else
                        baseStore
            in
            ( { model
                | pageDeleteSubmitDraft = nextForm
                , submissionDetailEditDraft = nextInter
                , store = nextStore
              }
            , Command.batch [ formChainCmd, detailCmd ]
            )
                |> runRouteStoreActions

        SubmissionDetailsResponse wikiSlug submissionId result ->
            let
                store : Store
                store =
                    model.store

                key : ( Wiki.Slug, String )
                key =
                    ( wikiSlug, submissionId )

                nextStore : Store
                nextStore =
                    { store
                        | submissionDetails =
                            Dict.insert key (RemoteData.succeed result) store.submissionDetails
                    }

                nextSubmissionDetailEditDraft : SubmissionDetailEditDraft
                nextSubmissionDetailEditDraft =
                    case model.route of
                        Route.WikiSubmissionDetail rWiki rSid ->
                            if rWiki == wikiSlug && rSid == submissionId then
                                case result of
                                    Ok detail ->
                                        submissionDetailEditDraftFromDetail detail

                                    Err _ ->
                                        model.submissionDetailEditDraft

                            else
                                model.submissionDetailEditDraft

                        _ ->
                            model.submissionDetailEditDraft
            in
            ( { model | store = nextStore, submissionDetailEditDraft = nextSubmissionDetailEditDraft }
            , Command.none
            )
                |> runRouteStoreActions

        SubmitDraftForReviewResponse wikiSlug submissionIdStr result ->
            let
                formNew : NewPageSubmitDraft
                formNew =
                    model.newPageSubmitDraft

                nextFormNew : NewPageSubmitDraft
                nextFormNew =
                    if formNew.inFlight then
                        case model.route of
                            Route.WikiSubmitNew w ->
                                if w == wikiSlug && formNew.maybeSavedDraftId == Just submissionIdStr then
                                    case result of
                                        Ok () ->
                                            { formNew
                                                | inFlight = False
                                                , lastResult =
                                                    Just
                                                        (Ok
                                                            (Submission.NewPageSubmittedForReview (Submission.idFromKey submissionIdStr))
                                                        )
                                            }

                                        Err err ->
                                            { formNew
                                                | inFlight = False
                                                , lastResult = Just (Err (submitDraftForReviewErrorToSubmitNewPageError err))
                                            }

                                else
                                    formNew

                            _ ->
                                formNew

                    else
                        formNew

                formEdit : PageEditSubmitDraft
                formEdit =
                    model.pageEditSubmitDraft

                nextFormEdit : PageEditSubmitDraft
                nextFormEdit =
                    if formEdit.inFlight then
                        case model.route of
                            Route.WikiSubmitEdit w _ ->
                                if w == wikiSlug && formEdit.maybeSavedDraftId == Just submissionIdStr then
                                    case result of
                                        Ok () ->
                                            { formEdit
                                                | inFlight = False
                                                , lastResult =
                                                    Just
                                                        (Ok
                                                            (Submission.EditSubmittedForReview (Submission.idFromKey submissionIdStr))
                                                        )
                                            }

                                        Err err ->
                                            { formEdit
                                                | inFlight = False
                                                , lastResult = Just (Err (submitDraftForReviewErrorToSubmitPageEditError err))
                                            }

                                else
                                    formEdit

                            _ ->
                                formEdit

                    else
                        formEdit

                formDel : PageDeleteSubmitDraft
                formDel =
                    model.pageDeleteSubmitDraft

                nextFormDel : PageDeleteSubmitDraft
                nextFormDel =
                    if formDel.inFlight then
                        case model.route of
                            Route.WikiSubmitDelete w _ ->
                                if w == wikiSlug && formDel.maybeSavedDraftId == Just submissionIdStr then
                                    case result of
                                        Ok () ->
                                            { formDel
                                                | inFlight = False
                                                , lastResult =
                                                    Just
                                                        (Ok
                                                            (Submission.DeleteSubmittedForReview (Submission.idFromKey submissionIdStr))
                                                        )
                                            }

                                        Err err ->
                                            { formDel
                                                | inFlight = False
                                                , lastResult = Just (Err (submitDraftForReviewErrorToPageDeleteFormError err))
                                            }

                                else
                                    formDel

                            _ ->
                                formDel

                    else
                        formDel

                inter : SubmissionDetailEditDraft
                inter =
                    model.submissionDetailEditDraft

                nextInter : SubmissionDetailEditDraft
                nextInter =
                    if inter.submitForReviewInFlight then
                        case model.route of
                            Route.WikiSubmissionDetail w sid ->
                                if w == wikiSlug && sid == submissionIdStr then
                                    case result of
                                        Ok () ->
                                            { inter
                                                | submitForReviewInFlight = False
                                                , lastError = Nothing
                                            }

                                        Err err ->
                                            { inter
                                                | submitForReviewInFlight = False
                                                , lastError = Just (Submission.submitDraftForReviewErrorToUserText err)
                                            }

                                else
                                    inter

                            _ ->
                                inter

                    else
                        inter

                store0 : Store
                store0 =
                    model.store

                nextStore : Store
                nextStore =
                    case result of
                        Ok () ->
                            { store0
                                | myPendingSubmissions =
                                    Dict.remove wikiSlug store0.myPendingSubmissions
                                , submissionDetails =
                                    Dict.insert
                                        ( wikiSlug, submissionIdStr )
                                        RemoteData.Loading
                                        store0.submissionDetails
                            }

                        Err _ ->
                            store0

                refetchCmd : Command FrontendOnly ToBackend Msg
                refetchCmd =
                    case result of
                        Ok () ->
                            Effect.Lamdera.sendToBackend (RequestSubmissionDetails wikiSlug submissionIdStr)

                        _ ->
                            Command.none
            in
            ( { model
                | newPageSubmitDraft = nextFormNew
                , pageEditSubmitDraft = nextFormEdit
                , pageDeleteSubmitDraft = nextFormDel
                , submissionDetailEditDraft = nextInter
                , store = nextStore
              }
            , refetchCmd
            )
                |> runRouteStoreActions

        WithdrawSubmissionResponse wikiSlug submissionIdStr result ->
            let
                inter : SubmissionDetailEditDraft
                inter =
                    model.submissionDetailEditDraft

                nextInter : SubmissionDetailEditDraft
                nextInter =
                    { inter
                        | withdrawInFlight = False
                        , lastError =
                            case result of
                                Err err ->
                                    Just (Submission.withdrawSubmissionErrorToUserText err)

                                Ok () ->
                                    Nothing
                    }

                store0 : Store
                store0 =
                    model.store

                nextStore : Store
                nextStore =
                    case result of
                        Ok () ->
                            { store0
                                | myPendingSubmissions =
                                    Dict.remove wikiSlug store0.myPendingSubmissions
                                , submissionDetails =
                                    Dict.insert
                                        ( wikiSlug, submissionIdStr )
                                        RemoteData.Loading
                                        store0.submissionDetails
                            }

                        Err _ ->
                            store0

                refetchCmd : Command FrontendOnly ToBackend Msg
                refetchCmd =
                    case result of
                        Ok () ->
                            Effect.Lamdera.sendToBackend (RequestSubmissionDetails wikiSlug submissionIdStr)

                        _ ->
                            Command.none
            in
            ( { model | submissionDetailEditDraft = nextInter, store = nextStore }, refetchCmd )
                |> runRouteStoreActions

        DeleteMySubmissionResponse wikiSlug submissionIdStr result ->
            let
                inter : SubmissionDetailEditDraft
                inter =
                    model.submissionDetailEditDraft

                nextInter : SubmissionDetailEditDraft
                nextInter =
                    { inter
                        | deleteInFlight = False
                        , lastError =
                            case result of
                                Err err ->
                                    Just (Submission.deleteMySubmissionErrorToUserText err)

                                Ok () ->
                                    Nothing
                    }

                store0 : Store
                store0 =
                    model.store

                nextStore : Store
                nextStore =
                    case result of
                        Ok () ->
                            { store0
                                | myPendingSubmissions =
                                    Dict.remove wikiSlug store0.myPendingSubmissions
                                , submissionDetails =
                                    Dict.remove ( wikiSlug, submissionIdStr ) store0.submissionDetails
                            }

                        Err _ ->
                            store0
            in
            ( { model | submissionDetailEditDraft = nextInter, store = nextStore }, Command.none )
                |> runRouteStoreActions

        ReviewSubmissionDetailResponse wikiSlug submissionId result ->
            let
                store : Store
                store =
                    model.store

                key : ( Wiki.Slug, String )
                key =
                    ( wikiSlug, submissionId )

                nextStore : Store
                nextStore =
                    { store
                        | reviewSubmissionDetails =
                            Dict.insert key (RemoteData.succeed result) store.reviewSubmissionDetails
                    }
            in
            ( { model | store = nextStore }, Command.none )
                |> runRouteStoreActions

        ApproveSubmissionResponse wikiSlug submissionId result ->
            let
                d : ReviewApproveDraft
                d =
                    model.reviewApproveDraft

                nextDraft : ReviewApproveDraft
                nextDraft =
                    if d.inFlight then
                        { d
                            | inFlight = False
                            , lastResult = Just result
                        }

                    else
                        d

                nextStore : Store
                nextStore =
                    case result of
                        Ok () ->
                            afterApproveSubmissionCaches wikiSlug submissionId model.store

                        Err _ ->
                            model.store
            in
            ( { model | reviewApproveDraft = nextDraft, store = nextStore }, Command.none )
                |> runRouteStoreActions

        RejectSubmissionResponse wikiSlug submissionId result ->
            let
                d : ReviewRejectDraft
                d =
                    model.reviewRejectDraft

                nextDraft : ReviewRejectDraft
                nextDraft =
                    if d.inFlight then
                        case result of
                            Ok () ->
                                { reasonText = ""
                                , inFlight = False
                                , lastResult = Just (Ok ())
                                }

                            Err _ ->
                                { d
                                    | inFlight = False
                                    , lastResult = Just result
                                }

                    else
                        d

                nextStore : Store
                nextStore =
                    case result of
                        Ok () ->
                            afterRejectSubmissionCaches wikiSlug submissionId model.store

                        Err _ ->
                            model.store
            in
            ( { model | reviewRejectDraft = nextDraft, store = nextStore }, Command.none )
                |> runRouteStoreActions

        RequestSubmissionChangesResponse wikiSlug submissionId result ->
            let
                d : ReviewRequestChangesDraft
                d =
                    model.reviewRequestChangesDraft

                nextDraft : ReviewRequestChangesDraft
                nextDraft =
                    if d.inFlight then
                        case result of
                            Ok () ->
                                { guidanceText = ""
                                , inFlight = False
                                , lastResult = Just (Ok ())
                                }

                            Err _ ->
                                { d
                                    | inFlight = False
                                    , lastResult = Just result
                                }

                    else
                        d

                nextStore : Store
                nextStore =
                    case result of
                        Ok () ->
                            afterRejectSubmissionCaches wikiSlug submissionId model.store

                        Err _ ->
                            model.store
            in
            ( { model | reviewRequestChangesDraft = nextDraft, store = nextStore }, Command.none )
                |> runRouteStoreActions

        HostAdminLoginResponse result ->
            let
                d : HostAdminLoginDraft
                d =
                    model.hostAdminLoginDraft

                nextDraft : HostAdminLoginDraft
                nextDraft =
                    if d.inFlight then
                        case result of
                            Ok () ->
                                { password = ""
                                , inFlight = False
                                , lastResult = Just (Ok ())
                                }

                            Err e ->
                                { d
                                    | inFlight = False
                                    , lastResult = Just (Err e)
                                }

                    else
                        d

                hostAfterLoginCmd : Command FrontendOnly ToBackend Msg
                hostAfterLoginCmd =
                    case ( model.route, result ) of
                        ( Route.HostAdmin maybeRedirect, Ok () ) ->
                            let
                                dest : String
                                dest =
                                    maybeRedirect
                                        |> Maybe.andThen SecureRedirect.safeHostAdminReturnPath
                                        |> Maybe.withDefault Wiki.hostAdminWikisUrlPath
                            in
                            Effect.Browser.Navigation.pushUrl model.key dest

                        _ ->
                            Command.none
            in
            ( { model
                | hostAdminLoginDraft = nextDraft
                , hostAdminSessionAuthenticated =
                    case result of
                        Ok () ->
                            True

                        Err _ ->
                            model.hostAdminSessionAuthenticated
              }
            , hostAfterLoginCmd
            )

        HostAdminWikiListResponse result ->
            case ( model.route, result ) of
                ( Route.HostAdminWikis, Err HostAdmin.NotHostAuthenticated ) ->
                    ( { model
                        | hostAdminWikis = RemoteData.Success result
                        , hostAdminSessionAuthenticated = False
                        , route = Route.HostAdmin (Just Wiki.hostAdminWikisUrlPath)
                      }
                    , Effect.Browser.Navigation.replaceUrl model.key
                        (Wiki.hostAdminLoginUrlPathWithRedirect Wiki.hostAdminWikisUrlPath)
                    )

                ( Route.HostAdminBackup, Err HostAdmin.NotHostAuthenticated ) ->
                    ( { model
                        | hostAdminWikis = RemoteData.Success result
                        , hostAdminSessionAuthenticated = False
                        , route = Route.HostAdmin (Just Wiki.hostAdminBackupUrlPath)
                      }
                    , Effect.Browser.Navigation.replaceUrl model.key
                        (Wiki.hostAdminLoginUrlPathWithRedirect Wiki.hostAdminBackupUrlPath)
                    )

                ( Route.HostAdminWikiNew, Err HostAdmin.NotHostAuthenticated ) ->
                    ( { model
                        | hostAdminWikis = RemoteData.Success result
                        , hostAdminSessionAuthenticated = False
                        , route = Route.HostAdmin (Just Wiki.hostAdminNewWikiUrlPath)
                      }
                    , Effect.Browser.Navigation.replaceUrl model.key
                        (Wiki.hostAdminLoginUrlPathWithRedirect Wiki.hostAdminNewWikiUrlPath)
                    )

                _ ->
                    let
                        sessionFromList : Bool
                        sessionFromList =
                            case result of
                                Ok _ ->
                                    True

                                Err _ ->
                                    False
                    in
                    ( { model
                        | hostAdminWikis = RemoteData.Success result
                        , hostAdminSessionAuthenticated = sessionFromList
                      }
                    , Command.none
                    )

        HostAuditLogResponse filter result ->
            case model.route of
                Route.HostAdminAudit ->
                    let
                        filterKey : String
                        filterKey =
                            WikiAuditLog.hostAuditLogFilterCacheKey filter

                        appliedKey : String
                        appliedKey =
                            WikiAuditLog.hostAuditLogFilterCacheKey model.hostAdminAuditAppliedFilter
                    in
                    if filterKey /= appliedKey then
                        ( model, Command.none )

                    else
                        case result of
                            Err HostAdmin.NotHostAuthenticated ->
                                ( { model
                                    | hostAdminAuditLog = RemoteData.Success result
                                    , hostAdminSessionAuthenticated = False
                                    , route = Route.HostAdmin (Just Wiki.hostAdminAuditUrlPath)
                                  }
                                , Effect.Browser.Navigation.replaceUrl model.key
                                    (Wiki.hostAdminLoginUrlPathWithRedirect Wiki.hostAdminAuditUrlPath)
                                )

                            Ok _ ->
                                ( { model
                                    | hostAdminAuditLog = RemoteData.Success result
                                    , hostAdminSessionAuthenticated = True
                                  }
                                , Command.none
                                )

                Route.HostAdminAuditDiff _ _ ->
                    let
                        filterKey : String
                        filterKey =
                            WikiAuditLog.hostAuditLogFilterCacheKey filter

                        appliedKey : String
                        appliedKey =
                            WikiAuditLog.hostAuditLogFilterCacheKey model.hostAdminAuditAppliedFilter
                    in
                    if filterKey /= appliedKey then
                        ( model, Command.none )

                    else
                        case result of
                            Err HostAdmin.NotHostAuthenticated ->
                                ( { model
                                    | hostAdminAuditLog = RemoteData.Success result
                                    , hostAdminSessionAuthenticated = False
                                    , route = Route.HostAdmin (Just Wiki.hostAdminAuditUrlPath)
                                  }
                                , Effect.Browser.Navigation.replaceUrl model.key
                                    (Wiki.hostAdminLoginUrlPathWithRedirect Wiki.hostAdminAuditUrlPath)
                                )

                            Ok _ ->
                                ( { model
                                    | hostAdminAuditLog = RemoteData.Success result
                                    , hostAdminSessionAuthenticated = True
                                  }
                                , Command.none
                                )

                _ ->
                    ( model, Command.none )

        CreateHostedWikiResponse result ->
            let
                d : HostAdminCreateWikiDraft
                d =
                    model.hostAdminCreateWikiDraft

                nextDraft : HostAdminCreateWikiDraft
                nextDraft =
                    if d.inFlight then
                        case result of
                            Ok _ ->
                                { slug = ""
                                , name = ""
                                , initialAdminUsername = ""
                                , initialAdminPassword = ""
                                , inFlight = False
                                , lastResult = Nothing
                                }

                            Err e ->
                                { d
                                    | inFlight = False
                                    , lastResult = Just (Err e)
                                }

                    else
                        d

                withDraft : Model
                withDraft =
                    { model | hostAdminCreateWikiDraft = nextDraft }
            in
            case result of
                Ok _ ->
                    ( { withDraft | hostAdminSessionAuthenticated = True }
                    , Effect.Browser.Navigation.pushUrl model.key Wiki.hostAdminWikisUrlPath
                    )

                Err HostAdmin.CreateNotHostAuthenticated ->
                    ( { withDraft | hostAdminSessionAuthenticated = False }
                    , Command.none
                    )

                Err _ ->
                    ( withDraft, Command.none )

        HostWikiDetailResponse wikiSlug result ->
            let
                d0 : HostAdminWikiDetailDraft
                d0 =
                    model.hostAdminWikiDetailDraft
            in
            if d0.wikiSlug /= wikiSlug then
                ( model, Command.none )

            else
                let
                    nextDraft : HostAdminWikiDetailDraft
                    nextDraft =
                        case result of
                            Ok entry ->
                                { d0
                                    | load = RemoteData.Success result
                                    , slugDraft = entry.slug
                                    , nameDraft = entry.name
                                    , summaryDraft = entry.summary
                                    , deleteConfirmDraft = ""
                                    , deleteInFlight = False
                                    , lastDeleteResult = Nothing
                                }

                            Err _ ->
                                { d0 | load = RemoteData.Success result }
                in
                case result of
                    Err HostAdmin.HostWikiDetailNotHostAuthenticated ->
                        let
                            returnPath : String
                            returnPath =
                                Wiki.hostAdminWikiDetailUrlPath wikiSlug
                        in
                        ( { model
                            | hostAdminWikiDetailDraft = nextDraft
                            , hostAdminSessionAuthenticated = False
                            , route = Route.HostAdmin (Just returnPath)
                          }
                        , Effect.Browser.Navigation.replaceUrl model.key
                            (Wiki.hostAdminLoginUrlPathWithRedirect returnPath)
                        )

                    Ok _ ->
                        ( { model
                            | hostAdminWikiDetailDraft = nextDraft
                            , hostAdminSessionAuthenticated = True
                          }
                        , Command.none
                        )

                    Err HostAdmin.HostWikiDetailWikiNotFound ->
                        ( { model | hostAdminWikiDetailDraft = nextDraft }, Command.none )

        UpdateHostedWikiMetadataResponse wikiSlug result ->
            let
                d0 : HostAdminWikiDetailDraft
                d0 =
                    model.hostAdminWikiDetailDraft
            in
            if d0.wikiSlug /= wikiSlug then
                ( model, Command.none )

            else
                case result of
                    Ok entry ->
                        let
                            store0 : Store
                            store0 =
                                model.store

                            nextStore : Store
                            nextStore =
                                { store0 | wikiCatalog = RemoteData.NotAsked }

                            catalogCmd : Command FrontendOnly ToBackend Msg
                            catalogCmd =
                                Effect.Lamdera.sendToBackend RequestWikiCatalog
                        in
                        if entry.slug /= wikiSlug then
                            let
                                nextDraft : HostAdminWikiDetailDraft
                                nextDraft =
                                    { d0
                                        | saveInFlight = False
                                        , lastSaveResult = Just (Ok ())
                                        , load = RemoteData.Success (Ok entry)
                                        , wikiSlug = entry.slug
                                        , slugDraft = entry.slug
                                        , nameDraft = entry.name
                                        , summaryDraft = entry.summary
                                    }
                            in
                            ( { model | hostAdminWikiDetailDraft = nextDraft, store = nextStore }
                            , Command.batch
                                [ catalogCmd
                                , Effect.Browser.Navigation.replaceUrl model.key (Wiki.hostAdminWikiDetailUrlPath entry.slug)
                                ]
                            )

                        else
                            let
                                nextDraft : HostAdminWikiDetailDraft
                                nextDraft =
                                    { d0
                                        | saveInFlight = False
                                        , lastSaveResult = Just (Ok ())
                                        , load = RemoteData.Success (Ok entry)
                                        , wikiSlug = entry.slug
                                        , slugDraft = entry.slug
                                        , nameDraft = entry.name
                                        , summaryDraft = entry.summary
                                    }
                            in
                            ( { model | hostAdminWikiDetailDraft = nextDraft, store = nextStore }
                            , catalogCmd
                            )

                    Err e ->
                        ( { model
                            | hostAdminWikiDetailDraft =
                                { d0
                                    | saveInFlight = False
                                    , lastSaveResult = Just (Err e)
                                }
                            , hostAdminSessionAuthenticated =
                                case e of
                                    HostAdmin.UpdateMetadataNotHostAuthenticated ->
                                        False

                                    _ ->
                                        model.hostAdminSessionAuthenticated
                          }
                        , Command.none
                        )

        DeactivateHostedWikiResponse wikiSlug result ->
            let
                d0 : HostAdminWikiDetailDraft
                d0 =
                    model.hostAdminWikiDetailDraft
            in
            if d0.wikiSlug /= wikiSlug then
                ( model, Command.none )

            else
                case result of
                    Ok entry ->
                        let
                            nextDraft : HostAdminWikiDetailDraft
                            nextDraft =
                                { d0
                                    | lifecycleInFlight = False
                                    , lastLifecycleResult = Just (Ok ())
                                    , load = RemoteData.Success (Ok entry)
                                    , wikiSlug = entry.slug
                                    , slugDraft = entry.slug
                                    , nameDraft = entry.name
                                    , summaryDraft = entry.summary
                                }

                            store0 : Store
                            store0 =
                                model.store

                            nextStore : Store
                            nextStore =
                                { store0 | wikiCatalog = RemoteData.NotAsked }
                        in
                        ( { model | hostAdminWikiDetailDraft = nextDraft, store = nextStore }
                        , Effect.Lamdera.sendToBackend RequestWikiCatalog
                        )

                    Err e ->
                        ( { model
                            | hostAdminWikiDetailDraft =
                                { d0
                                    | lifecycleInFlight = False
                                    , lastLifecycleResult = Just (Err e)
                                }
                            , hostAdminSessionAuthenticated =
                                case e of
                                    HostAdmin.WikiLifecycleNotHostAuthenticated ->
                                        False

                                    _ ->
                                        model.hostAdminSessionAuthenticated
                          }
                        , Command.none
                        )

        ReactivateHostedWikiResponse wikiSlug result ->
            let
                d0 : HostAdminWikiDetailDraft
                d0 =
                    model.hostAdminWikiDetailDraft
            in
            if d0.wikiSlug /= wikiSlug then
                ( model, Command.none )

            else
                case result of
                    Ok entry ->
                        let
                            nextDraft : HostAdminWikiDetailDraft
                            nextDraft =
                                { d0
                                    | lifecycleInFlight = False
                                    , lastLifecycleResult = Just (Ok ())
                                    , load = RemoteData.Success (Ok entry)
                                    , wikiSlug = entry.slug
                                    , slugDraft = entry.slug
                                    , nameDraft = entry.name
                                    , summaryDraft = entry.summary
                                }

                            store0 : Store
                            store0 =
                                model.store

                            nextStore : Store
                            nextStore =
                                { store0 | wikiCatalog = RemoteData.NotAsked }
                        in
                        ( { model | hostAdminWikiDetailDraft = nextDraft, store = nextStore }
                        , Effect.Lamdera.sendToBackend RequestWikiCatalog
                        )

                    Err e ->
                        ( { model
                            | hostAdminWikiDetailDraft =
                                { d0
                                    | lifecycleInFlight = False
                                    , lastLifecycleResult = Just (Err e)
                                }
                            , hostAdminSessionAuthenticated =
                                case e of
                                    HostAdmin.WikiLifecycleNotHostAuthenticated ->
                                        False

                                    _ ->
                                        model.hostAdminSessionAuthenticated
                          }
                        , Command.none
                        )

        DeleteHostedWikiResponse wikiSlug result ->
            let
                d0 : HostAdminWikiDetailDraft
                d0 =
                    model.hostAdminWikiDetailDraft
            in
            if d0.wikiSlug /= wikiSlug then
                ( model, Command.none )

            else
                case result of
                    Ok () ->
                        let
                            store0 : Store
                            store0 =
                                model.store

                            nextStore : Store
                            nextStore =
                                { store0 | wikiCatalog = RemoteData.NotAsked }
                        in
                        ( { model
                            | hostAdminWikiDetailDraft =
                                { d0
                                    | deleteInFlight = False
                                    , lastDeleteResult = Just (Ok ())
                                    , deleteConfirmDraft = ""
                                }
                            , store = nextStore
                          }
                        , Command.batch
                            [ Effect.Browser.Navigation.pushUrl model.key Wiki.hostAdminWikisUrlPath
                            , Effect.Lamdera.sendToBackend RequestWikiCatalog
                            ]
                        )

                    Err e ->
                        ( { model
                            | hostAdminWikiDetailDraft =
                                { d0
                                    | deleteInFlight = False
                                    , lastDeleteResult = Just (Err e)
                                }
                            , hostAdminSessionAuthenticated =
                                case e of
                                    HostAdmin.DeleteHostedWikiNotHostAuthenticated ->
                                        False

                                    _ ->
                                        model.hostAdminSessionAuthenticated
                          }
                        , Command.none
                        )

        HostAdminDataExportResponse result ->
            case result of
                Ok json ->
                    ( { model | hostAdminExportInFlight = False }
                    , Effect.File.Download.string "sortofwiki-backup.json" "application/json; charset=utf-8" json
                    )

                Err e ->
                    ( { model
                        | hostAdminExportInFlight = False
                        , hostAdminBackupNotice = Just (HostAdmin.dataExportErrorToUserText e)
                      }
                    , Command.none
                    )

        HostAdminDataImportResponse result ->
            case result of
                Ok () ->
                    ( { model
                        | hostAdminImportInFlight = False
                        , hostAdminBackupNotice = Just "Import completed."
                        , hostAdminWikisNotice = Just "Import completed."
                        , store = Store.empty
                        , contributorWikiSessions = Dict.empty
                        , hostAdminWikis = RemoteData.Loading
                      }
                    , Command.batch
                        [ Effect.Lamdera.sendToBackend RequestHostWikiList
                        , Effect.Lamdera.sendToBackend RequestWikiCatalog
                        ]
                    )

                Err e ->
                    ( { model
                        | hostAdminImportInFlight = False
                        , hostAdminBackupNotice = Just (HostAdmin.dataImportErrorToUserText e)
                        , hostAdminWikisNotice = Just (HostAdmin.dataImportErrorToUserText e)
                      }
                    , Command.none
                    )

        HostAdminWikiDataExportResponse wikiSlug result ->
            if model.hostAdminWikiExportInFlightSlug /= Just wikiSlug then
                ( model, Command.none )

            else
                case result of
                    Ok json ->
                        ( { model | hostAdminWikiExportInFlightSlug = Nothing }
                        , Effect.File.Download.string
                            ("sortofwiki-wiki-" ++ wikiSlug ++ ".json")
                            "application/json; charset=utf-8"
                            json
                        )

                    Err e ->
                        ( { model
                            | hostAdminWikiExportInFlightSlug = Nothing
                            , hostAdminWikisNotice = Just (HostAdmin.wikiDataExportErrorToUserText e)
                          }
                        , Command.none
                        )

        HostAdminWikiDataImportResponse wikiSlug result ->
            if model.hostAdminWikiImportInFlightSlug /= Just wikiSlug then
                ( model, Command.none )

            else
                case result of
                    Ok () ->
                        let
                            store0 : Store
                            store0 =
                                model.store

                            store1 : Store
                            store1 =
                                invalidateWikiPublishedCaches wikiSlug store0
                        in
                        ( { model
                            | hostAdminWikiImportInFlightSlug = Nothing
                            , hostAdminWikisNotice = Just "Wiki import completed."
                            , store = { store1 | wikiCatalog = RemoteData.NotAsked }
                            , hostAdminWikis = RemoteData.Loading
                          }
                        , Command.batch
                            [ Effect.Lamdera.sendToBackend RequestHostWikiList
                            , Effect.Lamdera.sendToBackend RequestWikiCatalog
                            ]
                        )

                    Err e ->
                        ( { model
                            | hostAdminWikiImportInFlightSlug = Nothing
                            , hostAdminWikisNotice = Just (HostAdmin.wikiDataImportErrorToUserText e)
                          }
                        , Command.none
                        )

        HostAdminWikiDataImportAutoResponse result ->
            case result of
                Ok wikiSlug ->
                    let
                        store0 : Store
                        store0 =
                            model.store

                        store1 : Store
                        store1 =
                            invalidateWikiPublishedCaches wikiSlug store0
                    in
                    ( { model
                        | hostAdminImportInFlight = False
                        , hostAdminWikisNotice = Just "Wiki import completed."
                        , store = { store1 | wikiCatalog = RemoteData.NotAsked }
                        , hostAdminWikis = RemoteData.Loading
                      }
                    , Command.batch
                        [ Effect.Lamdera.sendToBackend RequestHostWikiList
                        , Effect.Lamdera.sendToBackend RequestWikiCatalog
                        ]
                    )

                Err e ->
                    ( { model
                        | hostAdminImportInFlight = False
                        , hostAdminWikisNotice = Just (HostAdmin.wikiDataImportErrorToUserText e)
                      }
                    , Command.none
                    )


catalogRows : Dict Wiki.Slug Wiki.CatalogEntry -> List Wiki.CatalogEntry
catalogRows wikis =
    wikis
        |> Dict.toList
        |> List.sortBy Tuple.first
        |> List.map Tuple.second


viewWikiList : Dict Wiki.Slug Wiki.CatalogEntry -> Html Msg
viewWikiList wikis =
    Html.div
        [ Attr.id "catalog-page"
        ]
        [ Html.div
            [ UI.wikiCatalogGridAttr
            , Attr.id "wiki-catalog"
            ]
            (wikis
                |> catalogRows
                |> List.map viewWikiRow
            )
        ]


viewWikiListBody : Store -> Html Msg
viewWikiListBody store =
    case store.wikiCatalog of
        RemoteData.Success catalog ->
            if Dict.isEmpty catalog then
                viewWikiListEmpty

            else
                viewWikiList catalog

        RemoteData.Failure _ ->
            Html.div
                [ Attr.id "catalog-error"
                ]
                [ UI.contentParagraph [] [ Html.text "Could not load the wiki catalog." ] ]

        RemoteData.Loading ->
            viewWikiListLoading

        RemoteData.NotAsked ->
            viewWikiListLoading


viewWikiListEmpty : Html Msg
viewWikiListEmpty =
    Html.div
        [ Attr.id "catalog-page"
        ]
        [ UI.AsyncState.empty { id = "catalog-empty", text = "There are no wikis yet." } ]


viewWikiListLoading : Html Msg
viewWikiListLoading =
    Html.div
        [ Attr.id "catalog-loading"
        ]
        [ UI.AsyncState.loading "Loading…" ]


viewWikiRow : Wiki.CatalogEntry -> Html Msg
viewWikiRow entry =
    Html.a
        [ UI.wikiCatalogCardAttr
        , Attr.href (Wiki.catalogUrlPath entry)
        , Attr.attribute "data-wiki-slug" entry.slug
        ]
        [ Html.h3
            [ UI.wikiCatalogCardTitleAttr
            ]
            [ Html.text entry.name
            , Html.text " "
            , Html.em
                [ UI.wikiCatalogCardSlugEmAttr
                ]
                [ Html.text ("/w/" ++ entry.slug) ]
            ]
        , Html.p
            [ UI.wikiCatalogCardSummaryAttr
            ]
            [ if String.isEmpty entry.summary then
                Html.text ""

              else
                Html.span
                    [ Attr.id ("wiki-catalog-summary-" ++ entry.slug)
                    , Attr.attribute "data-context" "wiki-catalog-summary"
                    ]
                    [ Html.text entry.summary ]
            ]
        ]


viewWikiHomeLoading : Html Msg
viewWikiHomeLoading =
    Html.div
        [ Attr.id "wiki-home-loading"
        ]
        [ UI.AsyncState.loading "Loading…"
        ]


viewWikiRegisterLoading : Html Msg
viewWikiRegisterLoading =
    Html.div
        [ Attr.id "wiki-register-loading"
        ]
        [ UI.AsyncState.loading "Loading…" ]


viewWikiLoginLoading : Html Msg
viewWikiLoginLoading =
    Html.div
        [ Attr.id "wiki-login-loading"
        ]
        [ UI.AsyncState.loading "Loading…" ]


viewWikiPublishedSlugList : String -> Wiki.Slug -> List Page.Slug -> Html Msg
viewWikiPublishedSlugList listId wikiSlug pageSlugs =
    Html.ul
        [ Attr.id listId
        , UI.markdownUnorderedListAttr
        ]
        (pageSlugs
            |> List.sort
            |> List.map
                (\pageSlug ->
                    Html.li []
                        [ UI.Link.contentLink
                            [ Attr.href (Wiki.publishedPageUrlPath wikiSlug pageSlug)
                            , Attr.attribute "data-page-slug" pageSlug
                            ]
                            [ Html.text pageSlug ]
                        ]
                )
        )


viewWikiHome : Wiki.Slug -> Wiki.CatalogEntry -> Wiki.FrontendDetails -> Html Msg
viewWikiHome wikiSlug summary details =
    Html.div
        [ Attr.id "wiki-home-page"
        , Attr.attribute "data-wiki-slug" wikiSlug
        ]
        [ if String.isEmpty summary.summary then
            Html.text ""

          else
            UI.contentParagraph [] [ Html.text summary.summary ]
        , UI.Heading.contentHeading2 [] [ Html.text "Pages" ]
        , if List.isEmpty details.pageSlugs then
            UI.contentParagraph
                [ Attr.id "wiki-home-no-pages"
                , Attr.attribute "data-context" "wiki-home-no-pages"
                ]
                [ Html.text "No pages yet" ]

          else
            viewWikiPublishedSlugList "wiki-home-page-slugs" wikiSlug details.pageSlugs
        ]


viewNotFound : Html Msg
viewNotFound =
    Html.div
        [ Attr.id "not-found-page"
        ]
        [ UI.contentParagraph [] [ Html.text "This URL is not part of SortOfWiki yet." ]
        ]


viewWikiNotFound : Wiki.Slug -> Html Msg
viewWikiNotFound slug =
    Html.div
        [ Attr.id "wiki-not-found-page"
        , Attr.attribute "data-wiki-slug" slug
        ]
        [ UI.contentParagraph []
            [ Html.text "The wiki "
            , Html.code [ UI.markdownCodeSpanAttr ] [ Html.text slug ]
            , Html.text " doesn't exist."
            ]
        ]


themeToggleIconSun : Html Msg
themeToggleIconSun =
    Svg.svg
        [ SvgAttr.width "22"
        , SvgAttr.height "22"
        , SvgAttr.viewBox "0 0 24 24"
        , SvgAttr.fill "none"
        , SvgAttr.stroke "currentColor"
        , SvgAttr.strokeWidth "1.5"
        , SvgAttr.strokeLinecap "round"
        ]
        [ Svg.circle
            [ SvgAttr.cx "12"
            , SvgAttr.cy "12"
            , SvgAttr.r "4"
            ]
            []
        , Svg.path
            [ SvgAttr.d "M12 2v2m0 16v2M4.93 4.93l1.41 1.41m11.32 11.32l1.41 1.41M2 12h2m16 0h2M4.93 19.07l1.41-1.41M17.66 6.34l1.41-1.41" ]
            []
        ]


themeToggleIconMoon : Html Msg
themeToggleIconMoon =
    Svg.svg
        [ SvgAttr.width "22"
        , SvgAttr.height "22"
        , SvgAttr.viewBox "0 0 24 24"
        , SvgAttr.fill "none"
        , SvgAttr.stroke "currentColor"
        , SvgAttr.strokeWidth "1.5"
        , SvgAttr.strokeLinecap "round"
        , SvgAttr.strokeLinejoin "round"
        ]
        [ Svg.path
            [ SvgAttr.d "M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" ]
            []
        ]


themeToggleIconSystem : Html Msg
themeToggleIconSystem =
    Svg.svg
        [ SvgAttr.width "22"
        , SvgAttr.height "22"
        , SvgAttr.viewBox "0 0 24 24"
        , SvgAttr.fill "none"
        , SvgAttr.stroke "currentColor"
        , SvgAttr.strokeWidth "1.5"
        , SvgAttr.strokeLinecap "round"
        , SvgAttr.strokeLinejoin "round"
        ]
        [ Svg.circle
            [ SvgAttr.cx "8"
            , SvgAttr.cy "10"
            , SvgAttr.r "3"
            ]
            []
        , Svg.path
            [ SvgAttr.d "M8 4.5v1.5m0 8v1.5m-3.89-9.89 1.06 1.06m5.66 5.66 1.06 1.06M2.5 10H4m8 0h1.5m-9.39 3.89 1.06-1.06m5.66-5.66 1.06-1.06" ]
            []
        , Svg.path
            [ SvgAttr.d "M20.5 16.5A4.5 4.5 0 1 1 16 12a3.5 3.5 0 0 0 4.5 4.5z" ]
            []
        ]


viewThemeToggle : Model -> Html Msg
viewThemeToggle model =
    let
        ariaLabel : String
        ariaLabel =
            case model.colorThemePreference of
                ColorTheme.FollowSystem ->
                    "Using system color theme"

                ColorTheme.Fixed ColorTheme.Light ->
                    "Using light theme"

                ColorTheme.Fixed ColorTheme.Dark ->
                    "Using dark theme"
    in
    UI.Button.iconGhostButton
        [ Attr.type_ "button"
        , Attr.id "color-theme-toggle"
        , Events.onClick ColorThemeToggled
        , Attr.attribute "aria-label" ariaLabel
        ]
        [ case model.colorThemePreference of
            ColorTheme.FollowSystem ->
                themeToggleIconSystem

            ColorTheme.Fixed ColorTheme.Light ->
                themeToggleIconSun

            ColorTheme.Fixed ColorTheme.Dark ->
                themeToggleIconMoon
        ]


viewAppChromeSideNav : Model -> Html Msg
viewAppChromeSideNav model =
    viewSideNav "Site" (viewSortOfWikiSideNavSections model)


wikiScopeSideNavItems : Wiki.Slug -> Model -> List (Html Msg)
wikiScopeSideNavItems wikiSlug model =
    let
        maybeCw : Maybe ContributorWikiSession
        maybeCw =
            Dict.get wikiSlug model.contributorWikiSessions

        maybeRole : Maybe WikiRole
        maybeRole =
            Maybe.map .role maybeCw

        maybeReviewCount : Maybe Int
        maybeReviewCount =
            maybeRole
                |> Maybe.andThen (\role -> reviewQueueCountForWiki role wikiSlug model.store)

        authChrome : List (Html Msg)
        authChrome =
            case maybeCw of
                Just _ ->
                    []

                Nothing ->
                    []
    in
    List.concat
        [ authChrome
        , SideNavMenu.wikiNavLinks wikiSlug maybeRole
            |> withReviewQueueCount wikiSlug maybeReviewCount
            |> List.map sideNavLinkLi
        ]


viewWikiSideNav : Wiki.Slug -> Model -> Html Msg
viewWikiSideNav wikiSlug model =
    viewSideNav "Wiki"
        ({ heading = "Wiki"
         , items = wikiScopeSideNavItems wikiSlug model
         }
            :: viewSortOfWikiSideNavSections model
        )


viewRouteSideNav : Model -> Html Msg
viewRouteSideNav model =
    case wikiSideNavSlugIfActive model of
        Just slug ->
            viewWikiSideNav slug model

        Nothing ->
            viewAppChromeSideNav model


wikiScopeHeaderTitle : Store -> Wiki.Slug -> (Wiki.CatalogEntry -> AppHeaderTitle) -> AppHeaderTitle
wikiScopeHeaderTitle store slug whenLoaded =
    if wikiFrontendDetailsKnownMissing store slug then
        sortOfWikiAppHeaderTitle (Just (AppHeaderSecondaryPlain "Wiki not found"))

    else
        case store.wikiCatalog of
            RemoteData.Success dict ->
                case Dict.get slug dict of
                    Just summary ->
                        whenLoaded summary

                    Nothing ->
                        sortOfWikiAppHeaderTitle (Just (AppHeaderSecondaryPlain "Wiki not found"))

            RemoteData.Failure _ ->
                sortOfWikiAppHeaderTitle (Just (AppHeaderSecondaryPlain "Wiki not found"))

            RemoteData.Loading ->
                sortOfWikiAppHeaderTitle (Just (AppHeaderSecondaryPlain ("Loading wiki: " ++ slug)))

            RemoteData.NotAsked ->
                sortOfWikiAppHeaderTitle (Just (AppHeaderSecondaryPlain ("Loading wiki: " ++ slug)))


appHeaderTitle : Model -> AppHeaderTitle
appHeaderTitle ({ store, route } as model) =
    case route of
        Route.WikiList ->
            sortOfWikiAppHeaderTitle (Just (AppHeaderSecondaryPlain "Wikis"))

        Route.HostAdmin _ ->
            sortOfWikiAppHeaderTitle (Just (AppHeaderSecondaryPlain "Admin: Login"))

        Route.HostAdminWikis ->
            sortOfWikiAppHeaderTitle (Just (AppHeaderSecondaryPlain "Admin: Wikis"))

        Route.HostAdminWikiNew ->
            sortOfWikiAppHeaderTitle (Just (AppHeaderSecondaryPlain "Admin: Create wiki"))

        Route.HostAdminWikiDetail slug ->
            sortOfWikiAppHeaderTitle (Just (AppHeaderSecondaryPlain ("Admin: Wiki settings: " ++ slug)))

        Route.HostAdminAudit ->
            sortOfWikiAppHeaderTitle (Just (AppHeaderSecondaryPlain "Admin: Platform audit log"))

        Route.HostAdminAuditDiff _ _ ->
            sortOfWikiAppHeaderTitle (Just (AppHeaderSecondaryPlain "Admin: Platform audit log diff"))

        Route.HostAdminBackup ->
            sortOfWikiAppHeaderTitle (Just (AppHeaderSecondaryPlain "Admin: Backup"))

        Route.WikiHome slug ->
            wikiScopeHeaderTitle store slug <|
                \summary ->
                    wikiLoadedHeaderTitle summary Nothing

        Route.WikiTodos slug ->
            wikiScopeHeaderTitle store slug <|
                \summary ->
                    wikiLoadedHeaderTitle summary (Just (AppHeaderSecondaryPlain "TODOs"))

        Route.WikiGraph slug ->
            wikiScopeHeaderTitle store slug <|
                \summary ->
                    wikiLoadedHeaderTitle summary (Just (AppHeaderSecondaryPlain "Graph"))

        Route.WikiSearch slug ->
            wikiScopeHeaderTitle store slug <|
                \summary ->
                    wikiLoadedHeaderTitle summary (Just (AppHeaderSecondaryPlain "Search"))

        Route.WikiPage wikiSlug pageSlug ->
            wikiScopeHeaderTitle store wikiSlug <|
                \summary ->
                    wikiLoadedHeaderTitle summary <|
                        Just
                            (AppHeaderSecondaryPlainThenWikiLink
                                { plainPrefix = summary.name ++ " "
                                , wikiLabel = pageSlug
                                }
                            )

        Route.WikiPageGraph wikiSlug pageSlug ->
            wikiScopeHeaderTitle store wikiSlug <|
                \summary ->
                    wikiLoadedHeaderTitle summary <|
                        Just
                            (AppHeaderSecondaryPlainThenWikiLink
                                { plainPrefix = "Graph: "
                                , wikiLabel = pageSlug
                                }
                            )

        Route.WikiRegister slug ->
            wikiScopeHeaderTitle store slug <|
                \summary ->
                    wikiLoadedHeaderTitle summary (Just (AppHeaderSecondaryPlain "Register"))

        Route.WikiLogin slug _ ->
            wikiScopeHeaderTitle store slug <|
                \summary ->
                    wikiLoadedHeaderTitle summary (Just (AppHeaderSecondaryPlain "Log in"))

        Route.WikiSubmitNew wikiSlug ->
            wikiScopeHeaderTitle store wikiSlug <|
                \summary ->
                    wikiLoadedHeaderTitle summary <|
                        let
                            pageSlug : String
                            pageSlug =
                                model.newPageSubmitDraft.pageSlug
                        in
                        if String.isEmpty pageSlug then
                            Just (AppHeaderSecondaryPlain "Create page")

                        else
                            Just
                                (AppHeaderSecondaryPlainThenWikiLink
                                    { plainPrefix = "Create "
                                    , wikiLabel = pageSlug
                                    }
                                )

        Route.WikiSubmitEdit wikiSlug pageSlug ->
            wikiScopeHeaderTitle store wikiSlug <|
                \summary ->
                    wikiLoadedHeaderTitle summary <|
                        Just
                            (AppHeaderSecondaryPlainThenWikiLink
                                { plainPrefix =
                                    if wikiSessionTrustedOnWiki wikiSlug model then
                                        "Edit "

                                    else
                                        "Propose edit "
                                , wikiLabel = pageSlug
                                }
                            )

        Route.WikiSubmitDelete wikiSlug pageSlug ->
            wikiScopeHeaderTitle store wikiSlug <|
                \summary ->
                    wikiLoadedHeaderTitle summary <|
                        Just
                            (if wikiSessionTrustedOnWiki wikiSlug model then
                                AppHeaderSecondaryPlainThenWikiLink
                                    { plainPrefix = "Delete "
                                    , wikiLabel = pageSlug
                                    }

                             else
                                AppHeaderSecondaryPlain "Request deletion"
                            )

        Route.WikiSubmissionDetail slug _ ->
            wikiScopeHeaderTitle store slug <|
                \summary ->
                    wikiLoadedHeaderTitle summary <|
                        case submissionDetailConflictResolveSecondary of
                            Just sec ->
                                Just sec

                            Nothing ->
                                Just (AppHeaderSecondaryPlain "Submission")

        Route.WikiMySubmissions slug ->
            wikiScopeHeaderTitle store slug <|
                \summary ->
                    wikiLoadedHeaderTitle summary (Just (AppHeaderSecondaryPlain "My submissions"))

        Route.WikiReview slug ->
            wikiScopeHeaderTitle store slug <|
                \summary ->
                    wikiLoadedHeaderTitle summary (Just (AppHeaderSecondaryPlain "Review"))

        Route.WikiReviewDetail slug _ ->
            wikiScopeHeaderTitle store slug <|
                \summary ->
                    wikiLoadedHeaderTitle summary (Just (AppHeaderSecondaryPlain "Review submission"))

        Route.WikiAdminUsers slug ->
            wikiScopeHeaderTitle store slug <|
                \summary ->
                    wikiLoadedHeaderTitle summary (Just (AppHeaderSecondaryPlain "Users"))

        Route.WikiAdminAuditDiff slug _ ->
            wikiScopeHeaderTitle store slug <|
                \summary ->
                    wikiLoadedHeaderTitle summary (Just (AppHeaderSecondaryPlain "Audit diff"))

        Route.WikiAdminAudit slug ->
            wikiScopeHeaderTitle store slug <|
                \summary ->
                    wikiLoadedHeaderTitle summary (Just (AppHeaderSecondaryPlain "Audit log"))

        Route.NotFound _ ->
            sortOfWikiAppHeaderTitle (Just (AppHeaderSecondaryPlain "Page not found"))


viewAppHeaderSecondary : AppHeaderSecondary -> Html Msg
viewAppHeaderSecondary secondary =
    case secondary of
        AppHeaderSecondaryPlain label ->
            Html.span [ UI.appHeaderSecondaryMetaAttr ]
                [ Html.text label
                ]

        AppHeaderSecondaryWikiLink label ->
            Html.span [ UI.appHeaderSecondaryWikiWrapAttr ]
                [ Html.span
                    [ UI.appHeaderSecondaryBracketAttr ]
                    [ Html.text <| "[[" ++ label ++ "]]" ]
                ]

        AppHeaderSecondaryPlainThenWikiLink { plainPrefix, wikiLabel } ->
            Html.span [ UI.appHeaderSecondaryMetaAttr ]
                [ Html.text plainPrefix
                , viewAppHeaderSecondary (AppHeaderSecondaryWikiLink wikiLabel)
                ]

        AppHeaderSecondaryWikiLinkThenPlain { wikiLabel, plainSuffix } ->
            Html.span [ UI.appHeaderSecondaryMetaAttr ]
                [ viewAppHeaderSecondary (AppHeaderSecondaryWikiLink wikiLabel)
                , Html.text plainSuffix
                ]


viewAppHeaderTitleInner : AppHeaderTitle -> Html Msg
viewAppHeaderTitleInner t =
    let
        primaryEl : Html Msg
        primaryEl =
            case t.primaryHref of
                Just href ->
                    UI.Link.navPrimary
                        [ Attr.href href
                        ]
                        [ Html.text t.primary ]

                Nothing ->
                    Html.span [ UI.appHeaderPrimaryPlainAttr ]
                        [ Html.text t.primary ]
    in
    case t.secondary of
        Nothing ->
            primaryEl

        Just sec ->
            Html.span [ UI.appHeaderTitleRowAttr ]
                [ Html.span [ Attr.class "inline-flex items-center" ] [ primaryEl ]
                , Html.span
                    [ UI.appHeaderSecondaryAfterDividerAttr
                    , Attr.class "inline-flex items-center"
                    ]
                    [ viewAppHeaderSecondary sec ]
                ]


viewAppHeader : Model -> Html Msg
viewAppHeader model =
    let
        wikiAuthChrome : Html Msg
        wikiAuthChrome =
            case wikiSideNavSlugIfActive model of
                Just wikiSlug ->
                    if contributorLoggedInOnWikiSlug wikiSlug model then
                        case Dict.get wikiSlug model.contributorWikiSessions of
                            Just session ->
                                viewHeaderAccountArea wikiSlug (Just session.displayUsername)

                            Nothing ->
                                Html.text ""

                    else
                        viewHeaderAccountArea wikiSlug Nothing

                Nothing ->
                    Html.text ""

        maybeSearchWikiSlug : Maybe Wiki.Slug
        maybeSearchWikiSlug =
            wikiSideNavSlugIfActive model

        hasSearchScope : Bool
        hasSearchScope =
            maybeSearchWikiSlug /= Nothing

        headerSearchMarkdownSources : Dict Page.Slug String
        headerSearchMarkdownSources =
            case maybeSearchWikiSlug of
                Just wikiSlug ->
                    case Store.get_ wikiSlug model.store.wikiDetails of
                        Success details ->
                            details.publishedPageMarkdownSources

                        _ ->
                            Dict.empty

                Nothing ->
                    Dict.empty

        headerSearchResults : List WikiSearch.ResultItem
        headerSearchResults =
            WikiSearch.search model.headerSearchQuery headerSearchMarkdownSources

        showHeaderSearch : Bool
        showHeaderSearch =
            model.route /= Route.WikiList

        maybeSearchForm : Maybe (Html Msg)
        maybeSearchForm =
            if showHeaderSearch then
                Just
                    (Html.form
                        [ Attr.id "header-search-form"
                        , Attr.class "hidden md:flex items-center relative min-w-[12rem] max-w-[18rem] flex-1"
                        , Events.onSubmit HeaderSearchSubmitted
                        ]
                        [ Html.span
                            [ Attr.class "absolute left-[0.65rem] top-1/2 -translate-y-1/2 text-[var(--fg-muted)] opacity-80 text-[1.35rem] leading-none"
                            , Attr.attribute "aria-hidden" "true"
                            ]
                            [ Html.text "⌕" ]
                        , Html.input
                            [ Attr.id "header-search-input"
                            , Attr.type_ "search"
                            , Attr.placeholder "Search..."
                            , Attr.value model.headerSearchQuery
                            , Events.onInput HeaderSearchQueryChanged
                            , Attr.disabled (not hasSearchScope)
                            , Attr.class
                                (if hasSearchScope then
                                    "w-full rounded-full border border-[var(--border-subtle)] bg-[var(--chrome-bg)] text-[0.8125rem] text-[var(--fg)] pl-[1.8rem] pr-[0.85rem] py-[0.35rem]"

                                 else
                                    "w-full rounded-full border border-[var(--border-subtle)] bg-[var(--chrome-bg)] text-[0.8125rem] text-[var(--fg-muted)] pl-[1.8rem] pr-[0.85rem] py-[0.35rem] opacity-80 cursor-not-allowed"
                                )
                            ]
                            []
                        , case maybeSearchWikiSlug of
                            Just wikiSlug ->
                                if String.isEmpty (String.trim model.headerSearchQuery) then
                                    Html.text ""

                                else
                                    Html.div
                                        [ Attr.id "header-search-popup"
                                        , Attr.class "absolute left-0 top-[calc(100%+0.45rem)] z-20 w-full rounded-lg border border-[var(--border-subtle)] bg-[var(--bg)] p-2 shadow-lg [font-family:var(--font-serif)]"
                                        ]
                                        [ if List.isEmpty headerSearchResults then
                                            Html.p
                                                [ Attr.id "header-search-popup-empty"
                                                , Attr.class "m-1 text-[0.8rem] text-[var(--fg-muted)] [font-family:var(--font-ui)]"
                                                ]
                                                [ Html.text "No matches." ]

                                          else
                                            Html.ul
                                                [ Attr.id "header-search-popup-results"
                                                , Attr.class "m-0 p-0 list-none"
                                                ]
                                                (headerSearchResults
                                                    |> List.take 5
                                                    |> List.map
                                                        (\result ->
                                                            Html.li
                                                                [ Attr.class "m-0 -mx-2 px-2 border-b border-[var(--border-subtle)] pb-2 mb-2 last:mb-0 last:pb-0 last:border-b-0" ]
                                                                [ UI.Link.subtleLink
                                                                    [ Attr.href (Wiki.publishedPageUrlPath wikiSlug result.pageSlug)
                                                                    , Attr.attribute "data-search-page-slug" result.pageSlug
                                                                    ]
                                                                    [ Html.span
                                                                        [ Attr.class "block text-[0.8125rem]" ]
                                                                        [ viewHighlightedText model.headerSearchQuery result.pageSlug ]
                                                                    ]
                                                                , Html.p
                                                                    [ Attr.class "mt-0.5 mb-0 text-[0.76rem] text-[var(--fg-muted)] leading-snug" ]
                                                                    [ Dict.get result.pageSlug headerSearchMarkdownSources
                                                                        |> Maybe.withDefault ""
                                                                        |> excerptFromMarkdown model.headerSearchQuery
                                                                        |> viewSearchExcerpt
                                                                    ]
                                                                ]
                                                        )
                                                )
                                        , Html.div [ Attr.class "mt-2 -mx-2 px-2 border-t border-[var(--border-subtle)] pt-2" ]
                                            [ UI.Link.subtleLink
                                                [ Attr.id "header-search-open-page"
                                                , Attr.href (searchUrlWithQuery wikiSlug model.headerSearchQuery)
                                                , Attr.class "text-[0.8125rem] [font-family:var(--font-ui)]"
                                                , Events.onClick (HeaderSearchQueryChanged "")
                                                ]
                                                [ Html.text "Show all results" ]
                                            ]
                                        ]

                            Nothing ->
                                Html.text ""
                        ]
                    )

            else
                Nothing
    in
    Html.header
        [ UI.appHeaderBarAttr
        , Attr.attribute "data-context" "layout-header"
        ]
        ([ Html.div [ Attr.class "min-w-0 flex-1 flex items-center gap-[0.7rem] flex-wrap" ]
            [ Html.h1 [ UI.appHeaderH1Attr ]
                [ viewAppHeaderTitleInner (appHeaderTitle model) ]
            ]
         ]
            ++ (maybeSearchForm |> Maybe.map List.singleton |> Maybe.withDefault [])
            ++ [ Html.div [ Attr.class "shrink-0 flex items-center gap-2" ]
                    [ wikiAuthChrome
                    , Html.span
                        [ Attr.class "hidden md:inline h-7 w-px bg-[var(--border-subtle)]"
                        , Attr.attribute "aria-hidden" "true"
                        ]
                        []
                    , viewThemeToggle model
                    ]
               ]
        )


siteAdminRoute : Model -> Route
siteAdminRoute model =
    if hostAdminAuthenticated model then
        Route.HostAdminWikis

    else
        Route.HostAdmin Nothing


viewWikiListBottomSiteAdminLink : Model -> Html Msg
viewWikiListBottomSiteAdminLink model =
    Html.footer
        [ Attr.class "shrink-0 border-t border-[var(--border-subtle)] bg-[var(--bg)] px-[0.85rem] py-[0.75rem] text-right shadow-[inset_0_8px_14px_-12px_rgba(73,103,49,0.3)]" ]
        [ UI.Link.subtleLink
            [ Attr.id "wiki-list-site-admin-link"
            , Attr.href (Route.navUrlPath (siteAdminRoute model))
            ]
            [ Html.text "Site admin" ]
        ]


viewHeaderAccountArea : Wiki.Slug -> Maybe String -> Html Msg
viewHeaderAccountArea wikiSlug maybeUsername =
    let
        headerAuthActionClass : String
        headerAuthActionClass =
            "text-[0.8125rem] rounded px-[0.35rem] py-[0.1rem] text-[var(--link)] hover:text-[var(--link-hover)] hover:bg-[var(--link-bg-hover)]"
    in
    case maybeUsername of
        Just username ->
            Html.div
                [ Attr.class "flex items-center gap-2 text-[0.8125rem]" ]
                [ Html.span
                    [ Attr.id "wiki-header-account-link"
                    , Attr.class "text-[var(--fg-muted)]"
                    ]
                    [ Html.text ("@" ++ username) ]
                , UI.Button.inlineLinkButton
                    [ Attr.type_ "button"
                    , Attr.id "wiki-logout-button"
                    , Attr.class headerAuthActionClass
                    , Events.onClick (ContributorLogoutWiki wikiSlug)
                    ]
                    [ Html.text "Logout" ]
                ]

        Nothing ->
            UI.Link.subtleLink
                [ Attr.id "wiki-header-login-link"
                , Attr.href (Wiki.loginUrlPath wikiSlug)
                , Attr.class headerAuthActionClass
                ]
                [ Html.text "Login" ]


viewHostAdminLoginFeedback : Result HostAdmin.LoginError () -> Html Msg
viewHostAdminLoginFeedback result =
    UI.ResultNotice.fromResult
        { id = "host-admin-login"
        , okText = "Signed in as platform host admin."
        , errToText = HostAdmin.loginErrorToUserText
        }
        result


viewHostAdminLogin : Model -> Html Msg
viewHostAdminLogin model =
    let
        draft : HostAdminLoginDraft
        draft =
            model.hostAdminLoginDraft
    in
    Html.div
        [ Attr.id "host-admin-login-page"
        , Attr.class "login-shell-page"
        ]
        [ Html.div [ Attr.class "login-shell-bg" ] []
        , Html.main_
            [ Attr.class "login-shell-main" ]
            [ Html.div [ Attr.class "login-shell-brand" ]
                [ Html.h1 [ Attr.class "m-0 text-[2.2rem] leading-[1.2] text-[var(--auth-card-heading)] [font-family:var(--font-serif)]" ]
                    [ Html.text "SortOfWiki Admin" ]
                , Html.p [ Attr.class "m-0 text-[var(--auth-card-fg-muted)] [font-family:var(--font-ui)]" ]
                    [ Html.text "Platform administration login" ]
                ]
            , Html.div [ Attr.class "login-shell-card" ]
                [ Html.form
                    [ Attr.id "host-admin-login-form"
                    , Attr.class "flex flex-col"
                    , Events.onSubmit HostAdminLoginSubmitted
                    ]
                    [ Html.div [ Attr.class "mb-2" ]
                        [ UI.contentLabel
                            [ Attr.for "host-admin-login-password"
                            , Attr.class "ml-[0.15rem] text-[0.92rem]"
                            , Attr.style "color" "var(--auth-card-fg-muted)"
                            ]
                            [ Html.text "Admin password" ]
                        , Html.input
                            [ Attr.id "host-admin-login-password"
                            , Attr.type_ "password"
                            , Attr.value draft.password
                            , Events.onInput HostAdminLoginPasswordChanged
                            , Attr.disabled draft.inFlight
                            , UI.classAttr
                                (UI.formTextInputClass
                                    ++ " w-full bg-[var(--auth-card-bg)] text-[var(--auth-card-fg)] border-[var(--border-subtle)]"
                                )
                            ]
                            []
                        ]
                    , UI.Button.button
                        [ Attr.id "host-admin-login-submit"
                        , Attr.type_ "submit"
                        , Attr.disabled draft.inFlight
                        , Attr.class "w-full mt-1"
                        ]
                        [ Html.text "Sign in" ]
                    ]
                , case draft.lastResult of
                    Nothing ->
                        Html.text ""

                    Just lastResult ->
                        Html.div [ Attr.class "mt-3" ] [ viewHostAdminLoginFeedback lastResult ]
                ]
            ]
        ]


viewHostAdminWikis : Model -> Html Msg
viewHostAdminWikis model =
    Html.div
        [ Attr.id "host-admin-wikis-page" ]
        [ case model.hostAdminWikisNotice of
            Nothing ->
                Html.text ""

            Just noticeText ->
                Html.p
                    [ Attr.id "host-admin-wikis-notice"
                    , Attr.attribute "role" "status"
                    , UI.formFeedbackRowAttr
                    ]
                    [ Html.text noticeText ]
        , case model.hostAdminWikis of
            RemoteData.NotAsked ->
                UI.contentParagraph [] [ Html.text "…" ]

            RemoteData.Loading ->
                Html.div
                    [ Attr.id "host-admin-wikis-loading" ]
                    [ UI.AsyncState.loading "Loading…" ]

            RemoteData.Failure () ->
                UI.contentParagraph [] [ Html.text "Could not load." ]

            RemoteData.Success (Err HostAdmin.NotHostAuthenticated) ->
                Html.div
                    [ Attr.id "host-admin-wikis-forbidden" ]
                    [ UI.contentParagraph [] [ Html.text "Redirecting to host admin sign-in…" ] ]

            RemoteData.Success (Ok summaries) ->
                let
                    rows : List (Html Msg)
                    rows =
                        if List.isEmpty summaries then
                            [ UI.trStriped
                                [ Attr.attribute "data-context" "host-admin-wikis-empty" ]
                                [ UI.tableTd UI.TableAlignMiddle
                                    [ Attr.colspan 4 ]
                                    [ Html.text "No wikis present" ]
                                ]
                            ]

                        else
                            List.map (viewHostAdminWikiRow model) summaries
                in
                Html.div []
                    [ Html.div [ UI.formStackMb3Attr ]
                        [ UI.Button.button
                            [ Attr.id "host-admin-import-json"
                            , Attr.type_ "button"
                            , Events.onClick HostAdminWikisDataImportPickRequested
                            , Attr.disabled (model.hostAdminExportInFlight || model.hostAdminImportInFlight)
                            ]
                            [ Html.text
                                (if model.hostAdminImportInFlight then
                                    "Importing…"

                                 else
                                    "Import new…"
                                )
                            ]
                        ]
                    , UI.table UI.TableAuto
                        []
                        { theadAttrs = []
                        , headerRowAttrs = []
                        , headerAlign = UI.TableAlignMiddle
                        , headers =
                            [ UI.tableHeaderText "Wiki"
                            , UI.tableHeaderText "Slug"
                            , UI.tableHeaderText "Status"
                            , UI.tableHeaderText "Backup"
                            ]
                        , tbodyAttrs = [ Attr.id "host-admin-wikis-list" ]
                        , rows = rows
                        }
                    ]
        ]


viewHostAdminBackupPage : Model -> Html Msg
viewHostAdminBackupPage model =
    Html.div
        [ Attr.id "host-admin-backup-page" ]
        [ viewHostAdminBackupPanel model ]


viewHostAdminBackupPanel : Model -> Html Msg
viewHostAdminBackupPanel model =
    let
        notice : Html Msg
        notice =
            case model.hostAdminBackupNotice of
                Nothing ->
                    Html.text ""

                Just text ->
                    UI.contentParagraph
                        [ Attr.id "host-admin-backup-notice"
                        , Attr.attribute "role" "status"
                        ]
                        [ Html.text text ]
    in
    Html.section
        [ Attr.id "host-admin-backup-panel"
        , Attr.attribute "data-context" "host-admin-backup"
        , UI.hostAdminBackupCardAttr
        ]
        [ UI.contentParagraph []
            [ Html.text
                "Export all wiki data as JSON, or import a file from a previous export. Import replaces all server-side data except your current host admin sign-in. Contributor sign-ins are not included in the backup; contributors must sign in again after import."
            ]
        , notice
        , Html.div [ UI.flexWrapGap2Attr ]
            [ UI.Button.button
                [ Attr.id "host-admin-export-json"
                , Attr.type_ "button"
                , Events.onClick HostAdminDataExportClicked
                , Attr.disabled (model.hostAdminExportInFlight || model.hostAdminImportInFlight)
                ]
                [ Html.text
                    (if model.hostAdminExportInFlight then
                        "Exporting…"

                     else
                        "Export JSON"
                    )
                ]
            , UI.Button.button
                [ Attr.id "host-admin-backup-import-json"
                , Attr.type_ "button"
                , Events.onClick HostAdminDataImportPickRequested
                , Attr.disabled (model.hostAdminExportInFlight || model.hostAdminImportInFlight)
                ]
                [ Html.text
                    (if model.hostAdminImportInFlight then
                        "Importing…"

                     else
                        "Import JSON"
                    )
                ]
            ]
        ]


viewHostAdminWikiRow : Model -> Wiki.CatalogEntry -> Html Msg
viewHostAdminWikiRow model summary =
    let
        wikiTableIoBusy : Bool
        wikiTableIoBusy =
            model.hostAdminWikiExportInFlightSlug
                /= Nothing
                || model.hostAdminWikiImportInFlightSlug
                /= Nothing

        thisRowExporting : Bool
        thisRowExporting =
            model.hostAdminWikiExportInFlightSlug == Just summary.slug

        thisRowImporting : Bool
        thisRowImporting =
            model.hostAdminWikiImportInFlightSlug == Just summary.slug
    in
    UI.trStriped
        [ Attr.attribute "data-context" "host-admin-wiki-row"
        , Attr.attribute "data-wiki-slug" summary.slug
        , Attr.attribute "data-wiki-active"
            (if summary.active then
                "true"

             else
                "false"
            )
        ]
        [ UI.tableTd UI.TableAlignMiddle
            []
            [ UI.Link.contentLink
                [ Attr.href (Wiki.hostAdminWikiDetailUrlPath summary.slug) ]
                [ Html.text summary.name ]
            ]
        , UI.tableTd UI.TableAlignMiddle
            []
            [ Html.span [ UI.hostAdminWikiListSlugAttr ] [ Html.text summary.slug ] ]
        , UI.tableTd UI.TableAlignMiddle
            []
            [ Html.span
                [ Attr.attribute "data-context" "host-admin-wiki-status" ]
                [ UI.StatusBadge.view
                    { isActive = summary.active
                    , text =
                        if summary.active then
                            "Active"

                        else
                            "Deactivated"
                    }
                ]
            ]
        , UI.tableTd UI.TableAlignMiddle
            []
            [ Html.div
                [ UI.flexWrapGap1Attr ]
                [ UI.Button.button
                    [ Attr.id ("host-admin-wiki-export-" ++ summary.slug)
                    , Attr.type_ "button"
                    , Events.onClick (HostAdminWikiDataExportClicked summary.slug)
                    , Attr.disabled wikiTableIoBusy
                    ]
                    [ Html.text
                        (if thisRowExporting then
                            "Exporting…"

                         else
                            "Export JSON"
                        )
                    ]
                , UI.Button.button
                    [ Attr.id ("host-admin-wiki-import-" ++ summary.slug)
                    , Attr.type_ "button"
                    , Events.onClick (HostAdminWikiDataImportPickRequested summary.slug)
                    , Attr.disabled wikiTableIoBusy
                    ]
                    [ Html.text
                        (if thisRowImporting then
                            "Importing…"

                         else
                            "Import (replace)"
                        )
                    ]
                ]
            ]
        ]


viewHostAdminAuditLoading : Html Msg
viewHostAdminAuditLoading =
    viewAuditLoading "host-admin-audit-loading"


viewAuditLoading : String -> Html Msg
viewAuditLoading loadingId =
    Html.div
        [ Attr.id loadingId ]
        [ UI.AsyncState.loading "Loading audit log…" ]


viewAuditError : String -> String -> Html Msg
viewAuditError errorId message =
    Html.div
        [ Attr.id errorId ]
        [ UI.contentParagraph [] [ Html.text message ] ]


type alias AuditTableRow =
    { wikiSlug : Wiki.Slug
    , at : Time.Posix
    , actorUsername : String
    , kind : WikiAuditLog.AuditEventKind
    , utcTimestamp : String
    }


viewAuditEventsTable :
    { tableId : String
    , tbodyId : String
    , columnClasses : List String
    , headers : List String
    , includeWikiColumn : Bool
    , isHostAuditView : Bool
    }
    -> List AuditTableRow
    -> Html Msg
viewAuditEventsTable config rows =
    UI.auditLogTableView
        { tableId = config.tableId
        , tbodyId = config.tbodyId
        , columnClasses = config.columnClasses
        , headers = config.headers
        , rows =
            rows
                |> List.indexedMap
                    (\i row ->
                        UI.trStriped
                            [ Attr.attribute "data-audit-event" (String.fromInt i)
                            , Attr.attribute "data-wiki-slug" row.wikiSlug
                            ]
                            (List.concat
                                [ [ Html.td
                                        [ UI.tableCellMonoTimestampAttr ]
                                        [ Html.text row.utcTimestamp ]
                                  ]
                                , if config.includeWikiColumn then
                                    [ UI.tableTd UI.TableAlignTop [] [ Html.text row.wikiSlug ] ]

                                  else
                                    []
                                , [ UI.tableTd UI.TableAlignTop [] [ Html.text row.actorUsername ]
                                  , UI.tableTd UI.TableAlignTop [] [ viewAuditEventKindCell config.isHostAuditView i row.wikiSlug row.kind ]
                                  ]
                                ]
                            )
                    )
        }


viewHostAdminAuditBody :
    RemoteData () (Result HostAdmin.ProtectedError (List WikiAuditLog.ScopedAuditEvent))
    -> Html Msg
viewHostAdminAuditBody remote =
    case remote of
        RemoteData.NotAsked ->
            viewHostAdminAuditLoading

        RemoteData.Loading ->
            viewHostAdminAuditLoading

        RemoteData.Failure _ ->
            viewAuditError "host-admin-audit-error" "Could not load audit log."

        RemoteData.Success (Err HostAdmin.NotHostAuthenticated) ->
            viewAuditError "host-admin-audit-forbidden" "Redirecting to host admin sign-in…"

        RemoteData.Success (Ok events) ->
            viewAuditEventsTable
                { tableId = "host-admin-audit-list"
                , tbodyId = "host-admin-audit-tbody"
                , columnClasses =
                    [ "w-[calc(19ch+1.1rem)]"
                    , "w-auto"
                    , "w-auto"
                    , "w-full"
                    ]
                , headers =
                    [ "Time (UTC)"
                    , "Wiki"
                    , "Actor"
                    , "Event"
                    ]
                , includeWikiColumn = True
                , isHostAuditView = True
                }
                (events
                    |> List.map
                        (\ev ->
                            { wikiSlug = ev.wikiSlug
                            , at = ev.at
                            , actorUsername = ev.actorUsername
                            , kind = ev.kind
                            , utcTimestamp = WikiAuditLog.eventUtcTimestampStringScoped ev
                            }
                        )
                )


viewAuditEventKindCell : Bool -> Int -> Wiki.Slug -> WikiAuditLog.AuditEventKind -> Html Msg
viewAuditEventKindCell isHostAuditView eventIndex wikiSlug kind =
    case kind of
        WikiAuditLog.TrustedPublishedNewPage { pageSlug, markdown } ->
            let
                diffHref : String
                diffHref =
                    if isHostAuditView then
                        Wiki.hostAdminAuditDiffUrlPath wikiSlug eventIndex

                    else
                        Wiki.adminAuditDiffUrlPath wikiSlug eventIndex
            in
            Html.span
                [ UI.viewDiffKindInlineAttr ]
                [ Html.text
                    ("Trusted publish: created page "
                        ++ pageSlug
                        ++ " ("
                        ++ String.fromInt (String.length markdown)
                        ++ " chars)"
                    )
                , UI.Link.subtleLink
                    [ Attr.href diffHref
                    , Attr.id ("wiki-audit-view-diff-create-" ++ pageSlug)
                    ]
                    [ Html.text "View diff" ]
                ]

        WikiAuditLog.TrustedPublishedPageEdit { pageSlug, beforeMarkdown, afterMarkdown } ->
            let
                diffHref : String
                diffHref =
                    if isHostAuditView then
                        Wiki.hostAdminAuditDiffUrlPath wikiSlug eventIndex

                    else
                        Wiki.adminAuditDiffUrlPath wikiSlug eventIndex
            in
            Html.span
                [ UI.viewDiffKindInlineAttr ]
                [ Html.text
                    ("Trusted publish: edited page "
                        ++ pageSlug
                        ++ " (before: "
                        ++ String.fromInt (String.length beforeMarkdown)
                        ++ " chars, after: "
                        ++ String.fromInt (String.length afterMarkdown)
                        ++ " chars)"
                    )
                , UI.Link.subtleLink
                    [ Attr.href diffHref ]
                    [ Html.text "View diff" ]
                ]

        _ ->
            Html.text (WikiAuditLog.eventKindUserText kind)


viewHostAdminAuditKindChip : Model -> ( WikiAuditLog.AuditEventKindFilterTag, String ) -> Html Msg
viewHostAdminAuditKindChip model ( tag, labelText ) =
    viewAuditKindChip
        { idPrefix = "host-admin-audit-filter-type-"
        , selectedTags = model.hostAdminAuditFilterSelectedKindTags
        , onToggle = HostAdminAuditFilterTypeTagToggled
        }
        ( tag, labelText )


type alias AuditKindChipConfig =
    { idPrefix : String
    , selectedTags : List WikiAuditLog.AuditEventKindFilterTag
    , onToggle : WikiAuditLog.AuditEventKindFilterTag -> Bool -> Msg
    }


viewAuditKindChip : AuditKindChipConfig -> ( WikiAuditLog.AuditEventKindFilterTag, String ) -> Html Msg
viewAuditKindChip config ( tag, labelText ) =
    let
        isOn : Bool
        isOn =
            List.member tag config.selectedTags
    in
    UI.Button.toggleChip
        [ Attr.id (config.idPrefix ++ WikiAuditLog.eventKindFilterTagToString tag) ]
        { pressed = isOn
        , onClick = config.onToggle tag (not isOn)
        , label = labelText
        }


type alias AuditFiltersConfig =
    { context : String
    , gridAttr : Html.Attribute Msg
    , maybeWikiFilter : Maybe { inputId : String, value : String, onInput : String -> Msg }
    , actorInputId : String
    , actorValue : String
    , actorOnInput : String -> Msg
    , pageInputId : String
    , pageValue : String
    , pageOnInput : String -> Msg
    , kindFilterGroupId : String
    , kindFilterLegendId : String
    , kindChipView : ( WikiAuditLog.AuditEventKindFilterTag, String ) -> Html Msg
    }


viewAuditFilters : AuditFiltersConfig -> Html Msg
viewAuditFilters config =
    Html.div
        [ Attr.attribute "data-context" config.context
        , UI.hostAdminAuditFiltersCardAttr
        ]
        [ Html.div
            [ config.gridAttr ]
            (List.concat
                [ case config.maybeWikiFilter of
                    Just wikiFilter ->
                        [ Html.div [ UI.formFieldMinW0Attr ]
                            [ Html.label
                                [ Attr.for wikiFilter.inputId
                                , UI.formFieldLabelBlockAttr
                                ]
                                [ Html.text "Wiki slug contains" ]
                            , Html.input
                                [ Attr.id wikiFilter.inputId
                                , Attr.type_ "text"
                                , Attr.value wikiFilter.value
                                , Events.onInput wikiFilter.onInput
                                , UI.formTextInputAuditFilterAttr
                                ]
                                []
                            ]
                        ]

                    Nothing ->
                        []
                , [ Html.div [ UI.formFieldMinW0Attr ]
                        [ Html.label
                            [ Attr.for config.actorInputId
                            , UI.formFieldLabelBlockAttr
                            ]
                            [ Html.text "Actor contains" ]
                        , Html.input
                            [ Attr.id config.actorInputId
                            , Attr.type_ "text"
                            , Attr.value config.actorValue
                            , Events.onInput config.actorOnInput
                            , UI.formTextInputAuditFilterAttr
                            ]
                            []
                        ]
                  , Html.div [ UI.formFieldMinW0Attr ]
                        [ Html.label
                            [ Attr.for config.pageInputId
                            , UI.formFieldLabelBlockAttr
                            ]
                            [ Html.text "Page slug contains" ]
                        , Html.input
                            [ Attr.id config.pageInputId
                            , Attr.type_ "text"
                            , Attr.value config.pageValue
                            , Events.onInput config.pageOnInput
                            , UI.formTextInputAuditFilterAttr
                            ]
                            []
                        ]
                  ]
                ]
            )
        , Html.div
            [ Attr.id config.kindFilterGroupId
            , Attr.attribute "role" "group"
            , Attr.attribute "aria-labelledby" config.kindFilterLegendId
            , UI.auditFilterTypeGroupAttr
            ]
            [ Html.p
                [ Attr.id config.kindFilterLegendId
                , UI.auditFilterLegendTextAttr
                ]
                [ Html.text "Event types" ]
            , Html.div
                [ UI.flexWrapGap2Attr ]
                (List.map config.kindChipView WikiAuditLog.eventKindFilterTagOptions)
            ]
        ]


viewHostAdminAuditFilters : Model -> Html Msg
viewHostAdminAuditFilters model =
    viewAuditFilters
        { context = "host-admin-audit-filters"
        , gridAttr = UI.hostAdminAuditFiltersGridAttr
        , maybeWikiFilter =
            Just
                { inputId = "host-admin-audit-filter-wiki"
                , value = model.hostAdminAuditFilterWikiDraft
                , onInput = HostAdminAuditFilterWikiChanged
                }
        , actorInputId = "host-admin-audit-filter-actor"
        , actorValue = model.hostAdminAuditFilterActorDraft
        , actorOnInput = HostAdminAuditFilterActorChanged
        , pageInputId = "host-admin-audit-filter-page"
        , pageValue = model.hostAdminAuditFilterPageDraft
        , pageOnInput = HostAdminAuditFilterPageChanged
        , kindFilterGroupId = "host-admin-audit-filter-type"
        , kindFilterLegendId = "host-admin-audit-filter-type-legend"
        , kindChipView = viewHostAdminAuditKindChip model
        }


viewHostAdminAudit : Model -> Html Msg
viewHostAdminAudit model =
    Html.div
        [ Attr.id "host-admin-audit-page"
        , UI.wikiAdminAuditPageShellAttr
        ]
        [ viewHostAdminAuditFilters model
        , Html.div
            [ Attr.id "host-admin-audit-table-region"
            , UI.flexRowMin0Attr
            ]
            [ viewHostAdminAuditBody model.hostAdminAuditLog ]
        ]


viewHostAdminCreateWikiFeedback : Maybe (Result HostAdmin.CreateHostedWikiError Wiki.CatalogEntry) -> Html Msg
viewHostAdminCreateWikiFeedback maybeResult =
    case maybeResult of
        Nothing ->
            Html.text ""

        Just (Ok _) ->
            Html.text ""

        Just (Err e) ->
            Html.div
                [ Attr.id "host-admin-create-wiki-error" ]
                [ UI.contentParagraph [] [ Html.text (HostAdmin.createHostedWikiErrorToUserText e) ] ]


viewHostAdminCreateWiki : Model -> Html Msg
viewHostAdminCreateWiki model =
    Html.div
        [ Attr.id "host-admin-create-wiki-page" ]
        [ case model.hostAdminWikis of
            RemoteData.Success (Err HostAdmin.NotHostAuthenticated) ->
                UI.contentParagraph
                    [ Attr.id "host-admin-create-wiki-sign-in-needed" ]
                    [ Html.text "Redirecting to host admin sign-in…" ]

            RemoteData.Success (Ok _) ->
                let
                    draft : HostAdminCreateWikiDraft
                    draft =
                        model.hostAdminCreateWikiDraft

                    formBody : List (Html Msg)
                    formBody =
                        [ Html.form
                            [ Attr.id "host-admin-create-wiki-form"
                            , Events.onSubmit HostAdminCreateWikiSubmitted
                            ]
                            [ Html.div []
                                [ UI.contentLabel [ Attr.for "host-admin-create-wiki-slug" ]
                                    [ Html.text "Wiki slug" ]
                                , Html.input
                                    [ Attr.id "host-admin-create-wiki-slug"
                                    , Attr.name "wikiSlug"
                                    , Attr.type_ "text"
                                    , Attr.value draft.slug
                                    , Attr.required True
                                    , Attr.pattern Submission.pageSlugHtmlPattern
                                    , Attr.maxlength Submission.pageSlugHtmlMaxLength
                                    , Attr.title Submission.pageSlugConstraintTitle
                                    , Events.onInput HostAdminCreateWikiSlugChanged
                                    , Attr.disabled draft.inFlight
                                    , UI.formTextInputAttr
                                    ]
                                    []
                                ]
                            , Html.div []
                                [ UI.contentLabel [ Attr.for "host-admin-create-wiki-name" ]
                                    [ Html.text "Wiki name" ]
                                , Html.input
                                    [ Attr.id "host-admin-create-wiki-name"
                                    , Attr.type_ "text"
                                    , Attr.value draft.name
                                    , Events.onInput HostAdminCreateWikiNameChanged
                                    , Attr.disabled draft.inFlight
                                    , UI.formTextInputAttr
                                    ]
                                    []
                                ]
                            , Html.div []
                                [ UI.contentLabel [ Attr.for "host-admin-create-wiki-initial-admin-username" ]
                                    [ Html.text "Initial wiki admin username" ]
                                , Html.input
                                    [ Attr.id "host-admin-create-wiki-initial-admin-username"
                                    , Attr.type_ "text"
                                    , Attr.value draft.initialAdminUsername
                                    , Events.onInput HostAdminCreateWikiInitialAdminUsernameChanged
                                    , Attr.disabled draft.inFlight
                                    , UI.formTextInputAttr
                                    ]
                                    []
                                ]
                            , Html.div []
                                [ UI.contentLabel [ Attr.for "host-admin-create-wiki-initial-admin-password" ]
                                    [ Html.text "Initial wiki admin password" ]
                                , Html.input
                                    [ Attr.id "host-admin-create-wiki-initial-admin-password"
                                    , Attr.type_ "password"
                                    , Attr.value draft.initialAdminPassword
                                    , Events.onInput HostAdminCreateWikiInitialAdminPasswordChanged
                                    , Attr.disabled draft.inFlight
                                    , UI.formTextInputAttr
                                    ]
                                    []
                                ]
                            , UI.Button.button
                                [ Attr.id "host-admin-create-wiki-submit"
                                , Attr.type_ "submit"
                                , Attr.disabled draft.inFlight
                                ]
                                [ Html.text "Create wiki" ]
                            ]
                        , viewHostAdminCreateWikiFeedback draft.lastResult
                        ]
                in
                Html.div [] formBody

            RemoteData.Loading ->
                Html.div
                    [ Attr.id "host-admin-create-wiki-session-loading" ]
                    [ UI.AsyncState.loading "Loading…" ]

            RemoteData.NotAsked ->
                Html.div
                    [ Attr.id "host-admin-create-wiki-session-loading" ]
                    [ UI.AsyncState.loading "Loading…" ]

            RemoteData.Failure () ->
                UI.contentParagraph [] [ Html.text "Could not verify host session." ]
        ]


viewHostAdminWikiDetailSaveFeedback : Maybe (Result HostAdmin.UpdateHostedWikiMetadataError ()) -> Html Msg
viewHostAdminWikiDetailSaveFeedback maybeResult =
    case maybeResult of
        Nothing ->
            Html.text ""

        Just (Ok ()) ->
            Html.div
                [ Attr.id "host-admin-wiki-detail-save-success" ]
                [ UI.contentParagraph [] [ Html.text "Saved." ] ]

        Just (Err e) ->
            Html.div
                [ Attr.id "host-admin-wiki-detail-save-error" ]
                [ UI.contentParagraph [] [ Html.text (HostAdmin.updateHostedWikiMetadataErrorToUserText e) ] ]


viewHostAdminWikiDetailLifecycleFeedback : Maybe (Result HostAdmin.WikiLifecycleError ()) -> Html Msg
viewHostAdminWikiDetailLifecycleFeedback maybeResult =
    case maybeResult of
        Nothing ->
            Html.text ""

        Just (Ok ()) ->
            Html.div
                [ Attr.id "host-admin-wiki-detail-lifecycle-success" ]
                [ UI.contentParagraph [] [ Html.text "Updated." ] ]

        Just (Err e) ->
            Html.div
                [ Attr.id "host-admin-wiki-detail-lifecycle-error" ]
                [ UI.contentParagraph [] [ Html.text (HostAdmin.wikiLifecycleErrorToUserText e) ] ]


viewHostAdminWikiDetailDeleteFeedback : Maybe (Result HostAdmin.DeleteHostedWikiError ()) -> Html Msg
viewHostAdminWikiDetailDeleteFeedback maybeResult =
    case maybeResult of
        Nothing ->
            Html.text ""

        Just (Err e) ->
            Html.div
                [ Attr.id "host-admin-delete-wiki-error" ]
                [ UI.contentParagraph [] [ Html.text (HostAdmin.deleteHostedWikiErrorToUserText e) ] ]

        Just (Ok ()) ->
            Html.text ""


viewHostAdminWikiDetail : Model -> Html Msg
viewHostAdminWikiDetail model =
    let
        d : HostAdminWikiDetailDraft
        d =
            model.hostAdminWikiDetailDraft
    in
    Html.div
        [ Attr.id "host-admin-wiki-detail-page"
        , Attr.attribute "data-wiki-slug" d.wikiSlug
        ]
        [ case d.load of
            RemoteData.NotAsked ->
                UI.contentParagraph [] [ Html.text "…" ]

            RemoteData.Loading ->
                Html.div
                    [ Attr.id "host-admin-wiki-detail-loading" ]
                    [ UI.AsyncState.loading "Loading…" ]

            RemoteData.Failure _ ->
                UI.contentParagraph [] [ Html.text "Could not load." ]

            RemoteData.Success (Err e) ->
                Html.div
                    [ Attr.id "host-admin-wiki-detail-error" ]
                    [ UI.contentParagraph [] [ Html.text (HostAdmin.hostWikiDetailErrorToUserText e) ] ]

            RemoteData.Success (Ok entry) ->
                let
                    busy : Bool
                    busy =
                        d.saveInFlight || d.lifecycleInFlight || d.deleteInFlight
                in
                Html.div [ UI.hostAdminWikiDetailShellAttr ]
                    [ Html.div [ UI.hostAdminWikiDetailGridAttr ]
                        [ Html.div [ UI.hostAdminWikiDetailMainStackAttr ]
                            [ Html.div [ UI.hostAdminWikiDetailCardAttr ]
                                [ Html.h1 [ UI.hostAdminWikiDetailPageTitleAttr ]
                                    [ Html.text entry.name ]
                                , Html.form
                                    [ Attr.id "host-admin-wiki-detail-form"
                                    , Events.onSubmit HostAdminWikiDetailSaveClicked
                                    , UI.hostAdminWikiDetailFormStackAttr
                                    ]
                                    [ Html.div []
                                        [ UI.contentLabel [ Attr.for "host-admin-wiki-detail-slug" ]
                                            [ Html.text "Wiki slug" ]
                                        , Html.input
                                            [ Attr.id "host-admin-wiki-detail-slug"
                                            , Attr.type_ "text"
                                            , Attr.value d.slugDraft
                                            , Events.onInput HostAdminWikiDetailSlugChanged
                                            , Attr.disabled busy
                                            , Attr.spellcheck False
                                            , Attr.autocomplete False
                                            , UI.inputTextFullAttr
                                            ]
                                            []
                                        ]
                                    , Html.div []
                                        [ UI.contentLabel [ Attr.for "host-admin-wiki-detail-name" ]
                                            [ Html.text "Wiki name" ]
                                        , Html.input
                                            [ Attr.id "host-admin-wiki-detail-name"
                                            , Attr.type_ "text"
                                            , Attr.value d.nameDraft
                                            , Events.onInput HostAdminWikiDetailNameChanged
                                            , Attr.disabled busy
                                            , UI.inputTextFullAttr
                                            ]
                                            []
                                        ]
                                    , Html.div []
                                        [ UI.contentLabel [ Attr.for "host-admin-wiki-detail-summary" ]
                                            [ Html.text "Public summary" ]
                                        , Html.textarea
                                            (UI.Textarea.form
                                                [ Attr.id "host-admin-wiki-detail-summary"
                                                , Attr.value d.summaryDraft
                                                , Events.onInput HostAdminWikiDetailSummaryChanged
                                                , Attr.disabled busy
                                                , Attr.style "resize" "none"
                                                ]
                                            )
                                            []
                                        ]
                                    , UI.Button.button
                                        [ Attr.id "host-admin-wiki-detail-save"
                                        , Attr.type_ "submit"
                                        , Attr.disabled busy
                                        ]
                                        [ Html.text "Save" ]
                                    ]
                                , viewHostAdminWikiDetailSaveFeedback d.lastSaveResult
                                ]
                            ]
                        , Html.div [ UI.hostAdminWikiDetailSideStackAttr ]
                            [ Html.div [ UI.hostAdminWikiDetailCardAttr ]
                                [ UI.Heading.cardHeadingSm [] [ Html.text "Lifecycle" ]
                                , Html.p [ UI.hostAdminStatusParaAttr ]
                                    [ Html.span
                                        [ Attr.id "host-admin-wiki-detail-status"
                                        , Attr.attribute "data-wiki-active"
                                            (if entry.active then
                                                "true"

                                             else
                                                "false"
                                            )
                                        ]
                                        [ UI.StatusBadge.view
                                            { isActive = entry.active
                                            , text =
                                                if entry.active then
                                                    "Active"

                                                else
                                                    "Deactivated"
                                            }
                                        ]
                                    ]
                                , if entry.active then
                                    UI.Button.button
                                        [ Attr.id "host-admin-wiki-detail-deactivate"
                                        , Attr.type_ "button"
                                        , Events.onClick HostAdminWikiDetailDeactivateClicked
                                        , Attr.disabled busy
                                        ]
                                        [ Html.text "Deactivate wiki" ]

                                  else
                                    UI.Button.button
                                        [ Attr.id "host-admin-wiki-detail-reactivate"
                                        , Attr.type_ "button"
                                        , Events.onClick HostAdminWikiDetailReactivateClicked
                                        , Attr.disabled busy
                                        ]
                                        [ Html.text "Reactivate wiki" ]
                                , viewHostAdminWikiDetailLifecycleFeedback d.lastLifecycleResult
                                ]
                            , Html.div [ UI.hostAdminWikiDetailDangerCardAttr ]
                                [ UI.Heading.cardHeadingDanger [] [ Html.text "Delete wiki" ]
                                , UI.contentParagraph [ UI.hostAdminDangerBlurbAttr ]
                                    [ Html.text
                                        ("This permanently removes the wiki, its pages, submissions, and audit log. Type the slug "
                                            ++ d.wikiSlug
                                            ++ " below to confirm."
                                        )
                                    ]
                                , Html.div
                                    [ Attr.id "host-admin-delete-wiki-form"
                                    , UI.hostAdminDeleteFormStackAttr
                                    ]
                                    [ Html.div []
                                        [ UI.contentLabel [ Attr.for "host-admin-delete-wiki-confirm" ]
                                            [ Html.text "Confirm wiki slug" ]
                                        , Html.input
                                            [ Attr.id "host-admin-delete-wiki-confirm"
                                            , Attr.type_ "text"
                                            , Attr.value d.deleteConfirmDraft
                                            , Events.onInput HostAdminWikiDetailDeleteConfirmChanged
                                            , Attr.disabled busy
                                            , Attr.autocomplete False
                                            , UI.formTextInputAttr
                                            ]
                                            []
                                        ]
                                    , UI.Button.dangerButton
                                        [ Attr.id "host-admin-delete-wiki-submit"
                                        , Attr.type_ "button"
                                        , Events.onClick HostAdminWikiDetailDeleteSubmitted
                                        , Attr.disabled busy
                                        ]
                                        [ Html.text "Delete wiki permanently" ]
                                    ]
                                , viewHostAdminWikiDetailDeleteFeedback d.lastDeleteResult
                                ]
                            ]
                        ]
                    ]
        ]


documentTitle : Model -> String
documentTitle ({ store, route } as model) =
    case route of
        Route.WikiList ->
            "SortOfWiki | Wikis"

        Route.HostAdmin _ ->
            "Host admin — SortOfWiki"

        Route.HostAdminWikis ->
            "Host wikis — SortOfWiki"

        Route.HostAdminWikiNew ->
            "Create hosted wiki — SortOfWiki"

        Route.HostAdminWikiDetail _ ->
            "Edit hosted wiki — SortOfWiki"

        Route.HostAdminAudit ->
            "Platform audit log — SortOfWiki"

        Route.HostAdminAuditDiff _ _ ->
            "Platform audit diff — SortOfWiki"

        Route.HostAdminBackup ->
            "Backup and restore — SortOfWiki"

        Route.WikiHome slug ->
            case Store.get slug store.wikiCatalog of
                RemoteData.Success summary ->
                    summary.name ++ " — SortOfWiki"

                RemoteData.Failure _ ->
                    "404 — SortOfWiki"

                RemoteData.Loading ->
                    "Loading - SortOfWiki"

                RemoteData.NotAsked ->
                    "Loading - SortOfWiki"

        Route.WikiTodos wikiSlug ->
            case Store.get wikiSlug store.wikiCatalog of
                RemoteData.Success summary ->
                    "TODOs — " ++ summary.name ++ " — SortOfWiki"

                RemoteData.Failure _ ->
                    "404 — SortOfWiki"

                RemoteData.Loading ->
                    "Loading - SortOfWiki"

                RemoteData.NotAsked ->
                    "Loading - SortOfWiki"

        Route.WikiGraph wikiSlug ->
            case Store.get wikiSlug store.wikiCatalog of
                RemoteData.Success summary ->
                    "Graph — " ++ summary.name ++ " — SortOfWiki"

                RemoteData.Failure _ ->
                    "404 — SortOfWiki"

                RemoteData.Loading ->
                    "Loading - SortOfWiki"

                RemoteData.NotAsked ->
                    "Loading - SortOfWiki"

        Route.WikiSearch wikiSlug ->
            case Store.get wikiSlug store.wikiCatalog of
                RemoteData.Success summary ->
                    "Search — " ++ summary.name ++ " — SortOfWiki"

                RemoteData.Failure _ ->
                    "404 — SortOfWiki"

                RemoteData.Loading ->
                    "Loading - SortOfWiki"

                RemoteData.NotAsked ->
                    "Loading - SortOfWiki"

        Route.WikiPage wikiSlug pageSlug ->
            case Store.get wikiSlug store.wikiCatalog of
                RemoteData.Success summary ->
                    let
                        baseTitle : String
                        baseTitle =
                            pageSlug ++ " — " ++ summary.name ++ " — SortOfWiki"
                    in
                    case Store.get_ ( wikiSlug, pageSlug ) store.publishedPages of
                        RemoteData.Loading ->
                            "Loading " ++ baseTitle

                        RemoteData.NotAsked ->
                            "Loading " ++ baseTitle

                        RemoteData.Success _ ->
                            baseTitle

                        RemoteData.Failure _ ->
                            baseTitle

                RemoteData.Failure _ ->
                    "404 — SortOfWiki"

                RemoteData.Loading ->
                    "Loading - SortOfWiki"

                RemoteData.NotAsked ->
                    "Loading - SortOfWiki"

        Route.WikiPageGraph wikiSlug pageSlug ->
            case Store.get wikiSlug store.wikiCatalog of
                RemoteData.Success summary ->
                    "Graph — " ++ pageSlug ++ " — " ++ summary.name ++ " — SortOfWiki"

                RemoteData.Failure _ ->
                    "404 — SortOfWiki"

                RemoteData.Loading ->
                    "Loading - SortOfWiki"

                RemoteData.NotAsked ->
                    "Loading - SortOfWiki"

        Route.WikiRegister slug ->
            case Store.get slug store.wikiCatalog of
                RemoteData.Success summary ->
                    "Register — " ++ summary.name ++ " — SortOfWiki"

                RemoteData.Failure _ ->
                    "404 — SortOfWiki"

                RemoteData.Loading ->
                    "Loading - SortOfWiki"

                RemoteData.NotAsked ->
                    "Loading - SortOfWiki"

        Route.WikiLogin slug _ ->
            case Store.get slug store.wikiCatalog of
                RemoteData.Success summary ->
                    "Log in — " ++ summary.name ++ " — SortOfWiki"

                RemoteData.Failure _ ->
                    "404 — SortOfWiki"

                RemoteData.Loading ->
                    "Loading - SortOfWiki"

                RemoteData.NotAsked ->
                    "Loading - SortOfWiki"

        Route.WikiSubmitNew slug ->
            case Store.get slug store.wikiCatalog of
                RemoteData.Success summary ->
                    let
                        pageSlug : String
                        pageSlug =
                            model.newPageSubmitDraft.pageSlug
                    in
                    if String.isEmpty pageSlug then
                        summary.name ++ " | Create page — SortOfWiki"

                    else
                        summary.name ++ " | Create [[" ++ pageSlug ++ "]] — SortOfWiki"

                RemoteData.Failure _ ->
                    "404 — SortOfWiki"

                RemoteData.Loading ->
                    "Loading - SortOfWiki"

                RemoteData.NotAsked ->
                    "Loading - SortOfWiki"

        Route.WikiSubmitEdit wikiSlug pageSlug ->
            case Store.get wikiSlug store.wikiCatalog of
                RemoteData.Success summary ->
                    let
                        docPrefix : String
                        docPrefix =
                            if wikiSessionTrustedOnWiki wikiSlug model then
                                "Edit "

                            else
                                "Propose edit "
                    in
                    docPrefix ++ "[[" ++ pageSlug ++ "]] — " ++ summary.name ++ " — SortOfWiki"

                RemoteData.Failure _ ->
                    "404 — SortOfWiki"

                RemoteData.Loading ->
                    "Loading - SortOfWiki"

                RemoteData.NotAsked ->
                    "Loading - SortOfWiki"

        Route.WikiSubmitDelete wikiSlug pageSlug ->
            case Store.get wikiSlug store.wikiCatalog of
                RemoteData.Success summary ->
                    (if wikiSessionTrustedOnWiki wikiSlug model then
                        "Delete [[" ++ pageSlug ++ "]]"

                     else
                        "Request deletion"
                    )
                        ++ " — "
                        ++ pageSlug
                        ++ " — "
                        ++ summary.name
                        ++ " — SortOfWiki"

                RemoteData.Failure _ ->
                    "404 — SortOfWiki"

                RemoteData.Loading ->
                    "Loading - SortOfWiki"

                RemoteData.NotAsked ->
                    "Loading - SortOfWiki"

        Route.WikiSubmissionDetail slug _ ->
            case Store.get slug store.wikiCatalog of
                RemoteData.Success summary ->
                    "Submission — " ++ summary.name ++ " — SortOfWiki"

                RemoteData.Failure _ ->
                    "404 — SortOfWiki"

                RemoteData.Loading ->
                    "Loading - SortOfWiki"

                RemoteData.NotAsked ->
                    "Loading - SortOfWiki"

        Route.WikiMySubmissions slug ->
            case Store.get slug store.wikiCatalog of
                RemoteData.Success summary ->
                    "My submissions — " ++ summary.name ++ " — SortOfWiki"

                RemoteData.Failure _ ->
                    "404 — SortOfWiki"

                RemoteData.Loading ->
                    "Loading - SortOfWiki"

                RemoteData.NotAsked ->
                    "Loading - SortOfWiki"

        Route.WikiReview slug ->
            case Store.get slug store.wikiCatalog of
                RemoteData.Success summary ->
                    "Review queue — " ++ summary.name ++ " — SortOfWiki"

                RemoteData.Failure _ ->
                    "404 — SortOfWiki"

                RemoteData.Loading ->
                    "Loading - SortOfWiki"

                RemoteData.NotAsked ->
                    "Loading - SortOfWiki"

        Route.WikiReviewDetail slug _ ->
            case Store.get slug store.wikiCatalog of
                RemoteData.Success summary ->
                    "Review submission — " ++ summary.name ++ " — SortOfWiki"

                RemoteData.Failure _ ->
                    "404 — SortOfWiki"

                RemoteData.Loading ->
                    "Loading - SortOfWiki"

                RemoteData.NotAsked ->
                    "Loading - SortOfWiki"

        Route.WikiAdminUsers slug ->
            case Store.get slug store.wikiCatalog of
                RemoteData.Success summary ->
                    "Admin users — " ++ summary.name ++ " — SortOfWiki"

                RemoteData.Failure _ ->
                    "404 — SortOfWiki"

                RemoteData.Loading ->
                    "Loading - SortOfWiki"

                RemoteData.NotAsked ->
                    "Loading - SortOfWiki"

        Route.WikiAdminAudit slug ->
            case Store.get slug store.wikiCatalog of
                RemoteData.Success summary ->
                    "Admin audit — " ++ summary.name ++ " — SortOfWiki"

                RemoteData.Failure _ ->
                    "404 — SortOfWiki"

                RemoteData.Loading ->
                    "Loading - SortOfWiki"

                RemoteData.NotAsked ->
                    "Loading - SortOfWiki"

        Route.WikiAdminAuditDiff slug _ ->
            case Store.get slug store.wikiCatalog of
                RemoteData.Success summary ->
                    "Admin audit diff — " ++ summary.name ++ " — SortOfWiki"

                RemoteData.Failure _ ->
                    "404 — SortOfWiki"

                RemoteData.Loading ->
                    "Loading - SortOfWiki"

                RemoteData.NotAsked ->
                    "Loading - SortOfWiki"

        Route.NotFound _ ->
            "404 — SortOfWiki"


viewWikiHomeRoute : Model -> Wiki.Slug -> Html Msg
viewWikiHomeRoute { store } slug =
    case Store.get_ slug store.wikiDetails of
        RemoteData.Success details ->
            case Store.get slug store.wikiCatalog of
                RemoteData.Success summary ->
                    viewWikiHome slug summary details

                RemoteData.Failure _ ->
                    viewNotFound

                RemoteData.Loading ->
                    viewWikiHomeLoading

                RemoteData.NotAsked ->
                    viewWikiHomeLoading

        RemoteData.Failure _ ->
            viewWikiNotFound slug

        RemoteData.Loading ->
            viewWikiHomeLoading

        RemoteData.NotAsked ->
            viewWikiHomeLoading


viewRegisterFeedback : Maybe (Result ContributorAccount.RegisterContributorError ()) -> Html Msg
viewRegisterFeedback maybeResult =
    UI.ResultNotice.fromMaybeResult
        { id = "wiki-register"
        , okText = "Registration complete."
        , errToText = ContributorAccount.registerErrorToUserText
        }
        maybeResult


viewLoginFeedback : Maybe (Result ContributorAccount.LoginContributorError ()) -> Html Msg
viewLoginFeedback maybeResult =
    UI.ResultNotice.fromMaybeResult
        { id = "wiki-login"
        , okText = "You are logged in."
        , errToText = ContributorAccount.loginErrorToUserText
        }
        maybeResult


viewRegisterLoaded : Wiki.Slug -> RegisterDraft -> Html Msg
viewRegisterLoaded wikiSlug draft =
    Html.div
        [ Attr.id "wiki-register-page"
        , Attr.attribute "data-wiki-slug" wikiSlug
        , UI.formCenteredCardAttr
        ]
        [ Html.form
            [ Attr.id "wiki-register-form"
            , Events.onSubmit RegisterFormSubmitted
            ]
            [ Html.div []
                [ UI.contentLabel [ Attr.for "wiki-register-username" ]
                    [ Html.text "Username" ]
                , Html.input
                    [ Attr.id "wiki-register-username"
                    , Attr.type_ "text"
                    , Attr.value draft.username
                    , Events.onInput RegisterFormUsernameChanged
                    , Attr.disabled draft.inFlight
                    , UI.formTextInputAttr
                    ]
                    []
                ]
            , Html.div []
                [ UI.contentLabel [ Attr.for "wiki-register-password" ]
                    [ Html.text "Password" ]
                , Html.input
                    [ Attr.id "wiki-register-password"
                    , Attr.type_ "password"
                    , Attr.value draft.password
                    , Events.onInput RegisterFormPasswordChanged
                    , Attr.disabled draft.inFlight
                    , UI.formTextInputAttr
                    ]
                    []
                ]
            , UI.Button.button
                [ Attr.id "wiki-register-submit"
                , Attr.type_ "submit"
                , Attr.disabled draft.inFlight
                ]
                [ Html.text "Create account" ]
            ]
        , UI.contentParagraph []
            [ Html.text "Already have an account? "
            , UI.Link.contentLink
                [ Attr.id "wiki-register-login-link"
                , Attr.href (Wiki.loginUrlPath wikiSlug)
                ]
                [ Html.text "Log in" ]
            ]
        , viewRegisterFeedback draft.lastResult
        ]


viewRegisterRoute : Model -> Wiki.Slug -> Html Msg
viewRegisterRoute model wikiSlug =
    case Store.get_ wikiSlug model.store.wikiDetails of
        RemoteData.Success _ ->
            case Store.get wikiSlug model.store.wikiCatalog of
                RemoteData.Success _ ->
                    viewRegisterLoaded wikiSlug model.registerDraft

                RemoteData.Failure _ ->
                    viewNotFound

                RemoteData.Loading ->
                    viewWikiRegisterLoading

                RemoteData.NotAsked ->
                    viewWikiRegisterLoading

        RemoteData.Failure _ ->
            viewNotFound

        RemoteData.Loading ->
            viewWikiRegisterLoading

        RemoteData.NotAsked ->
            viewWikiRegisterLoading


viewLoginLoaded : Wiki.Slug -> String -> LoginDraft -> Html Msg
viewLoginLoaded wikiSlug wikiName draft =
    Html.div
        [ Attr.id "wiki-login-page"
        , Attr.attribute "data-wiki-slug" wikiSlug
        , UI.formCenteredCardAttr
        ]
        [ Html.div [ Attr.class "login-shell-bg" ] []
        , Html.main_
            [ Attr.class "login-shell-main" ]
            [ Html.div [ Attr.class "login-shell-brand" ]
                [ Html.h1 [ Attr.class "m-0 text-[2.2rem] leading-[1.2] text-[var(--auth-card-heading)] [font-family:var(--font-serif)]" ]
                    [ Html.text wikiName ]
                , Html.p [ Attr.class "m-0 text-[var(--auth-card-fg-muted)] [font-family:var(--font-ui)]" ]
                    [ Html.text "Part of SortOfWiki" ]
                ]
            , Html.div [ Attr.class "login-shell-card" ]
                [ Html.form
                    [ Attr.id "wiki-login-form"
                    , Attr.class "flex flex-col"
                    , Events.onSubmit LoginFormSubmitted
                    ]
                    [ Html.div [ Attr.class "mb-2" ]
                        [ UI.contentLabel
                            [ Attr.for "wiki-login-username"
                            , Attr.class "ml-[0.15rem] text-[0.92rem]"
                            , Attr.style "color" "var(--auth-card-fg-muted)"
                            ]
                            [ Html.text "Username" ]
                        , Html.input
                            [ Attr.id "wiki-login-username"
                            , Attr.type_ "text"
                            , Attr.value draft.username
                            , Events.onInput LoginFormUsernameChanged
                            , Attr.disabled draft.inFlight
                            , UI.classAttr (UI.formTextInputClass ++ " w-full")
                            ]
                            []
                        ]
                    , Html.div [ Attr.class "mb-2" ]
                        [ UI.contentLabel
                            [ Attr.for "wiki-login-password"
                            , Attr.class "ml-[0.15rem] text-[0.92rem]"
                            , Attr.style "color" "var(--auth-card-fg-muted)"
                            ]
                            [ Html.text "Password" ]
                        , Html.input
                            [ Attr.id "wiki-login-password"
                            , Attr.type_ "password"
                            , Attr.value draft.password
                            , Events.onInput LoginFormPasswordChanged
                            , Attr.disabled draft.inFlight
                            , UI.classAttr (UI.formTextInputClass ++ " w-full")
                            ]
                            []
                        ]
                    , UI.Button.button
                        [ Attr.id "wiki-login-submit"
                        , Attr.type_ "submit"
                        , Attr.disabled draft.inFlight
                        , Attr.class "w-full mt-1"
                        ]
                        [ Html.text "Log in" ]
                    ]
                , Html.div [ Attr.class "mt-3" ] [ viewLoginFeedback draft.lastResult ]
                ]
            , Html.footer [ Attr.class "mt-4 text-[0.78rem] text-[var(--auth-card-fg-muted)] [font-family:var(--font-ui)]" ]
                [ Html.div [ Attr.class "flex items-center justify-between gap-3 px-1" ]
                    [ Html.div []
                        [ Html.text "Need an account? "
                        , UI.Link.subtleLink
                            [ Attr.id "wiki-login-register-link"
                            , Attr.href (Wiki.registerUrlPath wikiSlug)
                            ]
                            [ Html.text "Register" ]
                        ]
                    , Html.a [ Attr.class "text-[var(--link)] no-underline hover:underline", Attr.href "https://github.com/janiczek/sortofwiki" ]
                        [ Html.text "Source" ]
                    ]
                ]
            ]
        ]


viewLoginRoute : Model -> Wiki.Slug -> Html Msg
viewLoginRoute model wikiSlug =
    case Store.get_ wikiSlug model.store.wikiDetails of
        RemoteData.Success _ ->
            case Store.get wikiSlug model.store.wikiCatalog of
                RemoteData.Success catalogEntry ->
                    viewLoginLoaded wikiSlug catalogEntry.name model.loginDraft

                RemoteData.Failure _ ->
                    viewNotFound

                RemoteData.Loading ->
                    viewWikiLoginLoading

                RemoteData.NotAsked ->
                    viewWikiLoginLoading

        RemoteData.Failure _ ->
            viewNotFound

        RemoteData.Loading ->
            viewWikiLoginLoading

        RemoteData.NotAsked ->
            viewWikiLoginLoading


viewWikiSubmitNewLoading : Html Msg
viewWikiSubmitNewLoading =
    Html.div
        [ Attr.id "wiki-submit-new-loading"
        ]
        [ UI.AsyncState.loading "Loading…" ]


viewNewPageSaveDraftFeedback : NewPageSubmitDraft -> Html Msg
viewNewPageSaveDraftFeedback draft =
    UI.ResultNotice.fromMaybeResult
        { id = "wiki-submit-new-save-draft"
        , okText = "Draft saved."
        , errToText = Submission.saveNewPageDraftErrorToUserText
        }
        draft.lastSaveDraftResult


viewNewPageSubmitFeedback : Wiki.Slug -> NewPageSubmitDraft -> Html Msg
viewNewPageSubmitFeedback wikiSlug draft =
    Html.div []
        [ viewNewPageSaveDraftFeedback draft
        , case draft.lastResult of
            Nothing ->
                Html.text ""

            Just (Ok success) ->
                case success of
                    Submission.NewPagePublishedImmediately ->
                        Html.text ""

                    Submission.NewPageSubmittedForReview submissionId ->
                        let
                            idStr : String
                            idStr =
                                Submission.idToString submissionId
                        in
                        Html.div
                            [ Attr.id "wiki-submit-new-success"
                            , Attr.attribute "data-submission-id" idStr
                            ]
                            [ UI.contentParagraph []
                                [ Html.text "Submitted for review." ]
                            , UI.Link.contentLink
                                [ Attr.id "wiki-submit-new-success-link"
                                , Attr.href (Wiki.submissionDetailUrlPath wikiSlug idStr)
                                ]
                                [ Html.text "Open submission" ]
                            ]

            Just (Err e) ->
                Html.div
                    [ Attr.id "wiki-submit-new-error" ]
                    [ Html.span
                        [ Attr.id "wiki-submit-new-error-text" ]
                        [ Html.text (Submission.submitNewPageErrorToUserText e) ]
                    ]
        ]


viewSubmitNewLoaded : Wiki.Slug -> (Page.Slug -> Bool) -> Bool -> NewPageSubmitDraft -> Html Msg
viewSubmitNewLoaded wikiSlug publishedSlugExists showUntrustedContributorDisclaimer draft =
    let
        formBusy : Bool
        formBusy =
            draft.inFlight || draft.saveDraftInFlight
    in
    Html.div
        [ Attr.id "wiki-submit-new-page"
        , Attr.attribute "data-wiki-slug" wikiSlug
        , Attr.attribute "data-page-slug" draft.pageSlug
        , Attr.class "h-full min-h-0 flex flex-col"
        ]
        [ Html.form
            [ Attr.id "wiki-submit-new-form"
            , Events.onSubmit NewPageSubmitFormSubmitted
            , Attr.class "h-full min-h-0 flex-1 flex flex-col overflow-hidden"
            ]
            [ UI.EditorShell.view
                { containerAttrs = [ Attr.class "flex-1 min-h-0" ]
                , controlsAttrs = []
                , controlsChildren =
                    [ Html.div [ Attr.class "shrink-0" ]
                        [ UI.contentLabel [ Attr.for "slug-input" ] [ Html.text "Page slug" ]
                        , Html.input
                            ([ Attr.id "slug-input"
                             , Attr.type_ "text"
                             , Attr.value draft.pageSlug
                             , Attr.disabled formBusy
                             , UI.formTextInputAttr
                             ]
                                ++ (if draft.pageSlugLockedFromQuery then
                                        [ Attr.readonly True
                                        , Attr.style "background-color" "var(--chrome-bg)"
                                        , Attr.style "color" "var(--fg-muted)"
                                        , Attr.style "cursor" "not-allowed"
                                        ]

                                    else
                                        [ Events.onInput NewPageSubmitSlugChanged ]
                                   )
                            )
                            []
                        ]
                    , Html.div [ Attr.class "shrink-0" ]
                        [ UI.contentLabel [ Attr.for "tags-input" ] [ Html.text "Tags (comma-separated page slugs)" ]
                        , Html.input
                            [ Attr.id "tags-input"
                            , Attr.type_ "text"
                            , Attr.value draft.tagsInput
                            , Events.onInput NewPageSubmitTagsChanged
                            , Attr.disabled formBusy
                            , UI.formTextInputAttr
                            ]
                            []
                        ]
                    ]
                , contentAttrs = []
                , contentChildren =
                    [ Html.section [ Attr.class "min-w-0 min-h-0 flex flex-col bg-[var(--input-bg)]" ]
                        [ UI.PanelHeader.view { kind = UI.PanelHeader.Primary, text = "EDITOR" }
                        , Html.div [ Attr.class "min-h-0 flex-1" ]
                            [ Html.textarea
                                (UI.Textarea.markdownEditableCell
                                    [ Attr.id "content-markdown-textarea"
                                    , Attr.value draft.markdownBody
                                    , Events.onInput NewPageSubmitMarkdownChanged
                                    , Attr.disabled formBusy
                                    , Attr.rows 12
                                    , Attr.class "h-full max-h-none"
                                    ]
                                )
                                []
                            ]
                        ]
                    , Html.section [ Attr.class "min-w-0 min-h-0 flex flex-col bg-[var(--bg)]" ]
                        [ UI.PanelHeader.view { kind = UI.PanelHeader.Secondary, text = "LIVE PREVIEW" }
                        , Html.div [ Attr.class "min-h-0 flex-1 p-3" ]
                            [ Html.div
                                [ Attr.class "h-full max-h-none"
                                , UI.markdownPreviewScrollMinFlexFullHeightAttr
                                ]
                                [ PageMarkdown.viewPreview "content-preview" wikiSlug publishedSlugExists draft.markdownBody ]
                            ]
                        ]
                    ]
                }
            , UI.FormActionFooter.sticky
                { align = UI.FormActionFooter.AlignEnd
                , left = []
                , right =
                    UI.SubmissionActions.primaryPairButtons
                        { saveDraftAttrs =
                            [ Attr.id "wiki-submit-new-save-draft"
                            , Attr.type_ "button"
                            , Events.onClick NewPageSaveDraftClicked
                            , Attr.disabled formBusy
                            ]
                        , submitAttrs =
                            [ Attr.id "wiki-submit-new-submit"
                            , Attr.type_ "submit"
                            , Attr.disabled formBusy
                            ]
                        , submitLabel =
                            if showUntrustedContributorDisclaimer then
                                "Submit for review"

                            else
                                "Create"
                        }
                }
            ]
        , viewNewPageSubmitFeedback wikiSlug draft
        ]


viewSubmitNewRoute : Model -> Wiki.Slug -> Html Msg
viewSubmitNewRoute model wikiSlug =
    case Store.get_ wikiSlug model.store.wikiDetails of
        RemoteData.Success wikiDetails ->
            case Store.get wikiSlug model.store.wikiCatalog of
                RemoteData.Success _ ->
                    viewSubmitNewLoaded wikiSlug
                        (publishedSlugExistsFromWikiDetails wikiDetails)
                        (contributorLoggedInOnWikiSlug wikiSlug model && not (wikiSessionTrustedOnWiki wikiSlug model))
                        model.newPageSubmitDraft

                RemoteData.Failure _ ->
                    viewNotFound

                RemoteData.Loading ->
                    viewWikiSubmitNewLoading

                RemoteData.NotAsked ->
                    viewWikiSubmitNewLoading

        RemoteData.Failure _ ->
            viewNotFound

        RemoteData.Loading ->
            viewWikiSubmitNewLoading

        RemoteData.NotAsked ->
            viewWikiSubmitNewLoading


viewPageEditSaveDraftFeedback : PageEditSubmitDraft -> Html Msg
viewPageEditSaveDraftFeedback draft =
    UI.ResultNotice.fromMaybeResult
        { id = "wiki-submit-edit-save-draft"
        , okText = "Draft saved."
        , errToText = Submission.savePageEditDraftErrorToUserText
        }
        draft.lastSaveDraftResult


viewPageEditSubmitFeedback : Wiki.Slug -> Page.Slug -> PageEditSubmitDraft -> Html Msg
viewPageEditSubmitFeedback wikiSlug pageSlug draft =
    Html.div []
        [ viewPageEditSaveDraftFeedback draft
        , case draft.lastResult of
            Nothing ->
                Html.text ""

            Just (Ok success) ->
                case success of
                    Submission.EditPublishedImmediately ->
                        Html.div
                            [ Attr.id "wiki-submit-edit-success" ]
                            [ UI.contentParagraph []
                                [ Html.text "Published. Your edit is live. " ]
                            , UI.Link.contentLink
                                [ Attr.id "wiki-submit-edit-success-published-link"
                                , Attr.href (Wiki.publishedPageUrlPath wikiSlug pageSlug)
                                ]
                                [ Html.text "Open page" ]
                            ]

                    Submission.EditSubmittedForReview submissionId ->
                        let
                            idStr : String
                            idStr =
                                Submission.idToString submissionId
                        in
                        Html.div
                            [ Attr.id "wiki-submit-edit-success"
                            , Attr.attribute "data-submission-id" idStr
                            ]
                            [ UI.contentParagraph []
                                [ Html.text "Submitted for review." ]
                            , UI.Link.contentLink
                                [ Attr.id "wiki-submit-edit-success-link"
                                , Attr.href (Wiki.submissionDetailUrlPath wikiSlug idStr)
                                ]
                                [ Html.text "Open submission" ]
                            ]

            Just (Err e) ->
                Html.div
                    [ Attr.id "wiki-submit-edit-error" ]
                    [ Html.span
                        [ Attr.id "wiki-submit-edit-error-text" ]
                        [ Html.text (Submission.submitPageEditErrorToUserText e) ]
                    ]
        ]


viewSubmitEditLoaded :
    Wiki.Slug
    -> Page.Slug
    -> Bool
    -> (Page.Slug -> Bool)
    -> Page.FrontendDetails
    -> PageEditSubmitDraft
    -> Html Msg
viewSubmitEditLoaded wikiSlug pageSlug showUntrustedContributorDisclaimer publishedSlugExists pageDetails draft =
    let
        formBusy : Bool
        formBusy =
            draft.inFlight || draft.saveDraftInFlight

        originalMarkdown : String
        originalMarkdown =
            pageDetails.maybeMarkdownSource |> Maybe.withDefault ""

        submitEditReadonlyTextarea : String -> String -> String -> Html Msg
        submitEditReadonlyTextarea elementId markdown extraClass =
            Html.textarea
                ([ Attr.id elementId
                 , Attr.readonly True
                 , Attr.rows 12
                 , Attr.value markdown
                 ]
                    |> UI.Textarea.markdownReadonlyWithExtra extraClass
                )
                []
    in
    Html.div
        [ Attr.id "wiki-submit-edit-page"
        , Attr.attribute "data-wiki-slug" wikiSlug
        , Attr.attribute "data-page-slug" pageSlug
        , Attr.class "h-full min-h-0 flex flex-col"
        ]
        [ Html.form
            [ Attr.id "wiki-submit-edit-form"
            , Events.onSubmit PageEditSubmitFormSubmitted
            , Attr.class "h-full min-h-0 flex-1 flex flex-col overflow-hidden"
            ]
            [ UI.EditorShell.view
                { containerAttrs = [ Attr.class "flex-1 min-h-0" ]
                , controlsAttrs = []
                , controlsChildren =
                    [ Html.div [ Attr.class "min-w-[14rem] flex-1" ]
                        [ UI.contentLabel [ Attr.for "wiki-submit-edit-tags" ] [ Html.text "Tags (comma-separated page slugs)" ]
                        , Html.input
                            [ Attr.id "wiki-submit-edit-tags"
                            , Attr.type_ "text"
                            , Attr.value draft.tagsInput
                            , Events.onInput PageEditSubmitTagsChanged
                            , Attr.disabled formBusy
                            , UI.formTextInputAttr
                            ]
                            []
                        ]
                    ]
                , contentAttrs = []
                , contentChildren =
                    [ Html.section [ Attr.class "min-w-0 min-h-0 flex flex-col bg-[var(--input-bg)]" ]
                        [ UI.PanelHeader.view { kind = UI.PanelHeader.Primary, text = "EDITOR" }
                        , Html.div [ Attr.class "min-h-0 flex-1 grid grid-rows-2 gap-3" ]
                            [ Html.div [ UI.newPageEditorMarkdownPreviewCellAttr ]
                                [ UI.Heading.panelHeadingSecondary [ Attr.class "px-4 py-1 mb-2 border-b border-[var(--border-subtle)]" ] [ Html.text "Published" ]
                                , submitEditReadonlyTextarea "wiki-submit-edit-original-markdown" originalMarkdown " h-full max-h-none px-4"
                                ]
                            , Html.div [ UI.newPageEditorMarkdownPreviewCellAttr, Attr.class "border-t border-[var(--border-subtle)]" ]
                                [ UI.Heading.panelHeadingSecondary [ Attr.class "px-4 py-1 mb-2 border-b border-[var(--border-subtle)]" ] [ Html.text "Your edit" ]
                                , Html.textarea
                                    (UI.Textarea.markdownEditableCell
                                        [ Attr.id "wiki-submit-edit-markdown"
                                        , Attr.value draft.markdownBody
                                        , Events.onInput PageEditSubmitMarkdownChanged
                                        , Attr.disabled formBusy
                                        , Attr.rows 12
                                        , Attr.class "h-full max-h-none px-4"
                                        ]
                                    )
                                    []
                                ]
                            ]
                        ]
                    , Html.section [ Attr.class "min-w-0 min-h-0 flex flex-col bg-[var(--bg)]" ]
                        [ UI.PanelHeader.view { kind = UI.PanelHeader.Secondary, text = "LIVE PREVIEW" }
                        , Html.div [ Attr.class "min-h-0 flex-1 grid grid-rows-2 gap-3" ]
                            [ Html.div [ UI.newPageEditorMarkdownPreviewCellAttr ]
                                [ UI.Heading.panelHeadingSecondary [ Attr.class "px-4 py-1 mb-2 border-b border-[var(--border-subtle)]" ] [ Html.text "Published preview" ]
                                , Html.div
                                    [ Attr.class "h-full max-h-none opacity-75"
                                    , UI.markdownPreviewScrollMinFlexFullHeightAttr
                                    , Attr.class "px-4 pt-2"
                                    ]
                                    [ PageMarkdown.viewPreview "wiki-submit-edit-original-preview" wikiSlug publishedSlugExists originalMarkdown ]
                                ]
                            , Html.div [ UI.newPageEditorMarkdownPreviewCellAttr, Attr.class "border-t border-[var(--border-subtle)]" ]
                                [ UI.Heading.panelHeadingSecondary [ Attr.class "px-4 py-1 mb-2 border-b border-[var(--border-subtle)]" ] [ Html.text "Your preview" ]
                                , Html.div
                                    [ Attr.class "h-full max-h-none"
                                    , UI.markdownPreviewScrollMinFlexFullHeightAttr
                                    , Attr.class "px-4 pt-2"
                                    ]
                                    [ PageMarkdown.viewPreview "wiki-submit-edit-new-preview" wikiSlug publishedSlugExists draft.markdownBody ]
                                ]
                            ]
                        ]
                    ]
                }
            , UI.FormActionFooter.sticky
                { align = UI.FormActionFooter.AlignBetween
                , left =
                    [ if showUntrustedContributorDisclaimer then
                        Html.p [ Attr.class "m-0 text-[0.84rem] text-[var(--fg-muted)]" ]
                            [ Html.text "Published content stays unchanged until a reviewer approves this proposal." ]

                      else
                        Html.span [] []
                    ]
                , right =
                    [ UI.SubmissionActions.primaryPairRow
                        { saveDraftAttrs =
                            [ Attr.id "wiki-submit-edit-save-draft"
                            , Attr.type_ "button"
                            , Events.onClick PageEditSaveDraftClicked
                            , Attr.disabled formBusy
                            ]
                        , submitAttrs =
                            [ Attr.id "wiki-submit-edit-submit"
                            , Attr.type_ "submit"
                            , Attr.disabled formBusy
                            ]
                        , submitLabel =
                            if showUntrustedContributorDisclaimer then
                                "Submit for review"

                            else
                                "Save"
                        }
                    ]
                }
            ]
        , viewPageEditSubmitFeedback wikiSlug pageSlug draft
        ]


viewSubmitEditRoute : Model -> Wiki.Slug -> Page.Slug -> Html Msg
viewSubmitEditRoute model wikiSlug pageSlug =
    case Store.get_ wikiSlug model.store.wikiDetails of
        RemoteData.NotAsked ->
            viewWikiSubmitNewLoading

        RemoteData.Loading ->
            viewWikiSubmitNewLoading

        RemoteData.Failure _ ->
            viewNotFound

        RemoteData.Success wikiDetails ->
            case Store.get wikiSlug model.store.wikiCatalog of
                RemoteData.NotAsked ->
                    viewWikiSubmitNewLoading

                RemoteData.Loading ->
                    viewWikiSubmitNewLoading

                RemoteData.Failure _ ->
                    viewNotFound

                RemoteData.Success _ ->
                    case Store.get_ ( wikiSlug, pageSlug ) model.store.publishedPages of
                        RemoteData.NotAsked ->
                            viewWikiSubmitNewLoading

                        RemoteData.Loading ->
                            viewWikiSubmitNewLoading

                        RemoteData.Failure _ ->
                            viewNotFound

                        RemoteData.Success pageDetails ->
                            case pageDetails.maybeMarkdownSource of
                                Nothing ->
                                    viewNotFound

                                Just _ ->
                                    viewSubmitEditLoaded wikiSlug
                                        pageSlug
                                        (contributorLoggedInOnWikiSlug wikiSlug model && not (wikiSessionTrustedOnWiki wikiSlug model))
                                        (publishedSlugExistsFromWikiDetails wikiDetails)
                                        pageDetails
                                        model.pageEditSubmitDraft


viewPageDeleteSaveDraftFeedback : PageDeleteSubmitDraft -> Html Msg
viewPageDeleteSaveDraftFeedback draft =
    UI.ResultNotice.fromMaybeResult
        { id = "wiki-submit-delete-save-draft"
        , okText = "Draft saved."
        , errToText = Submission.savePageDeleteDraftErrorToUserText
        }
        draft.lastSaveDraftResult


viewPageDeleteSubmitFeedback : Wiki.Slug -> Page.Slug -> PageDeleteSubmitDraft -> Html Msg
viewPageDeleteSubmitFeedback wikiSlug pageSlug draft =
    Html.div []
        [ viewPageDeleteSaveDraftFeedback draft
        , case draft.lastResult of
            Nothing ->
                Html.text ""

            Just (Ok success) ->
                case success of
                    Submission.DeletePublishedImmediately ->
                        Html.div
                            [ Attr.id "wiki-submit-delete-success" ]
                            [ UI.contentParagraph []
                                [ Html.text ("Published. Page \"" ++ pageSlug ++ "\" was removed.") ]
                            ]

                    Submission.DeleteSubmittedForReview submissionId ->
                        let
                            idStr : String
                            idStr =
                                Submission.idToString submissionId
                        in
                        Html.div
                            [ Attr.id "wiki-submit-delete-success"
                            , Attr.attribute "data-submission-id" idStr
                            ]
                            [ UI.contentParagraph []
                                [ Html.text "Submitted for review." ]
                            , UI.Link.contentLink
                                [ Attr.id "wiki-submit-delete-success-link"
                                , Attr.href (Wiki.submissionDetailUrlPath wikiSlug idStr)
                                ]
                                [ Html.text "Open submission" ]
                            ]

            Just (Err e) ->
                Html.div
                    [ Attr.id "wiki-submit-delete-error" ]
                    [ Html.span
                        [ Attr.id "wiki-submit-delete-error-text" ]
                        [ Html.text (Submission.pageDeleteFormErrorToUserText e) ]
                    ]
        ]


viewSubmitDeleteLoaded : Bool -> Msg -> Wiki.Slug -> Page.Slug -> PageDeleteSubmitDraft -> Html Msg
viewSubmitDeleteLoaded trustedModeratorSession submitMsg wikiSlug pageSlug draft =
    let
        formBusy : Bool
        formBusy =
            draft.inFlight || draft.saveDraftInFlight

        intro : Html Msg
        intro =
            UI.contentParagraph []
                [ Html.text
                    (if trustedModeratorSession then
                        "This removes the page from the wiki immediately."

                     else
                        "The page stays published until a reviewer approves this removal."
                    )
                ]

        actionButtons : List (Html Msg)
        actionButtons =
            if trustedModeratorSession then
                [ UI.Button.button
                    [ Attr.id "wiki-submit-delete-submit"
                    , Attr.type_ "button"
                    , Events.onClick submitMsg
                    , Attr.disabled formBusy
                    ]
                    [ Html.text "Delete page" ]
                ]

            else
                UI.SubmissionActions.primaryPairButtons
                    { saveDraftAttrs =
                        [ Attr.id "wiki-submit-delete-save-draft"
                        , Attr.type_ "button"
                        , Events.onClick PageDeleteSaveDraftClicked
                        , Attr.disabled formBusy
                        ]
                    , submitAttrs =
                        [ Attr.id "wiki-submit-delete-submit"
                        , Attr.type_ "button"
                        , Events.onClick submitMsg
                        , Attr.disabled formBusy
                        ]
                    , submitLabel = "Submit for review"
                    }
    in
    Html.div
        [ Attr.id "wiki-submit-delete-page"
        , Attr.attribute "data-wiki-slug" wikiSlug
        , Attr.attribute "data-page-slug" pageSlug
        ]
        [ intro
        , Html.form
            [ Attr.id "wiki-submit-delete-form"
            , Events.onSubmit submitMsg
            ]
            [ Html.div []
                [ UI.contentLabel [ Attr.for "wiki-submit-delete-reason" ]
                    [ Html.text "Reason for deletion (required)" ]
                , Html.textarea
                    (UI.Textarea.form
                        [ Attr.id "wiki-submit-delete-reason"
                        , Attr.value draft.reasonText
                        , Events.onInput PageDeleteSubmitReasonChanged
                        , Attr.disabled formBusy
                        , Attr.rows 4
                        , Attr.placeholder "Explain why this page is being removed"
                        ]
                    )
                    []
                ]
            , Html.div
                [ UI.flexWrapGap2Attr ]
                actionButtons
            ]
        , viewPageDeleteSubmitFeedback wikiSlug pageSlug draft
        ]


viewSubmitDeleteRoute : Model -> Wiki.Slug -> Page.Slug -> Html Msg
viewSubmitDeleteRoute model wikiSlug pageSlug =
    case model.pageDeleteSubmitDraft.lastResult of
        Just (Ok Submission.DeletePublishedImmediately) ->
            Html.div
                [ Attr.id "wiki-submit-delete-page"
                , Attr.attribute "data-wiki-slug" wikiSlug
                , Attr.attribute "data-page-slug" pageSlug
                ]
                [ viewPageDeleteSubmitFeedback wikiSlug pageSlug model.pageDeleteSubmitDraft ]

        _ ->
            case Store.get_ wikiSlug model.store.wikiDetails of
                RemoteData.NotAsked ->
                    viewWikiSubmitNewLoading

                RemoteData.Loading ->
                    viewWikiSubmitNewLoading

                RemoteData.Failure _ ->
                    viewNotFound

                RemoteData.Success _ ->
                    case Store.get wikiSlug model.store.wikiCatalog of
                        RemoteData.NotAsked ->
                            viewWikiSubmitNewLoading

                        RemoteData.Loading ->
                            viewWikiSubmitNewLoading

                        RemoteData.Failure _ ->
                            viewNotFound

                        RemoteData.Success _ ->
                            case Store.get_ ( wikiSlug, pageSlug ) model.store.publishedPages of
                                RemoteData.NotAsked ->
                                    viewWikiSubmitNewLoading

                                RemoteData.Loading ->
                                    viewWikiSubmitNewLoading

                                RemoteData.Failure _ ->
                                    viewNotFound

                                RemoteData.Success _ ->
                                    viewSubmitDeleteLoaded
                                        (wikiSessionTrustedOnWiki wikiSlug model)
                                        (if wikiSessionTrustedOnWiki wikiSlug model then
                                            PageDeletePublishedImmediatelySubmitted

                                         else
                                            PageDeleteRequestDeletionSubmitted
                                        )
                                        wikiSlug
                                        pageSlug
                                        model.pageDeleteSubmitDraft


viewSubmissionDetailBody :
    Wiki.Slug
    -> (Page.Slug -> Bool)
    -> SubmissionDetailEditDraft
    -> RemoteData () (Result Submission.DetailsError Submission.ContributorView)
    -> Html Msg
viewSubmissionDetailBody wikiSlug publishedSlugExists interaction remote =
    case remote of
        RemoteData.NotAsked ->
            viewWikiSubmitNewLoading

        RemoteData.Loading ->
            viewWikiSubmitNewLoading

        RemoteData.Failure _ ->
            Html.div
                [ Attr.id "wiki-submission-detail-error" ]
                [ UI.contentParagraph [] [ Html.text "Could not load submission details." ] ]

        RemoteData.Success (Err e) ->
            Html.div
                [ Attr.id "wiki-submission-detail-error" ]
                [ UI.contentParagraph []
                    [ Html.text (Submission.detailsErrorToUserText e) ]
                ]

        RemoteData.Success (Ok detail) ->
            let
                anyBusy : Bool
                anyBusy =
                    interaction.saveDraftInFlight
                        || interaction.submitForReviewInFlight
                        || interaction.withdrawInFlight
                        || interaction.deleteInFlight

                newMarkdownForPreview : String
                newMarkdownForPreview =
                    if detail.status == Submission.Draft then
                        interaction.markdownBody

                    else
                        detail.compareNewMarkdown

                comparePreview : String -> String -> Html Msg
                comparePreview previewId markdown =
                    Html.div
                        [ UI.classAttr UI.markdownPreviewScrollClass ]
                        [ PageMarkdown.viewPreview previewId wikiSlug publishedSlugExists markdown ]

                newPageSlugField : Html Msg
                newPageSlugField =
                    if detail.status == Submission.Draft && detail.contributionKind == Submission.ContributorKindNewPage then
                        Html.div
                            [ UI.mb2Attr ]
                            [ UI.contentLabel
                                [ Attr.for "wiki-submission-detail-new-page-slug" ]
                                [ Html.text "Page slug" ]
                            , Html.input
                                [ Attr.id "wiki-submission-detail-new-page-slug"
                                , Attr.type_ "text"
                                , Attr.value interaction.newPageSlug
                                , Events.onInput SubmissionDetailNewPageSlugChanged
                                , Attr.disabled anyBusy
                                , UI.formTextInputAttr
                                ]
                                []
                            ]

                    else
                        Html.text ""

                newMarkdownField : Html Msg
                newMarkdownField =
                    if detail.status == Submission.Draft then
                        Html.textarea
                            ([ Attr.id "new-markdown-editable-textarea"
                             , Attr.value interaction.markdownBody
                             , Events.onInput SubmissionDetailNewMarkdownChanged
                             , Attr.readonly anyBusy
                             , Attr.rows 14
                             ]
                                |> UI.Textarea.markdownEditableCell
                            )
                            []

                    else
                        Html.textarea
                            ([ Attr.id "new-markdown-readonly-textarea"
                             , Attr.readonly True
                             , Attr.rows 14
                             , Attr.value detail.compareNewMarkdown
                             ]
                                |> UI.Textarea.markdownReadonlyCell
                            )
                            []

                withdrawDeleteRow : Html Msg
                withdrawDeleteRow =
                    case detail.status of
                        Submission.Pending ->
                            Html.div
                                [ UI.flexWrapGap2Mt3Attr ]
                                [ UI.Button.button
                                    [ Attr.id "wiki-submission-detail-withdraw"
                                    , Attr.type_ "button"
                                    , Attr.disabled (anyBusy || interaction.withdrawInFlight)
                                    , Events.onClick SubmissionDetailWithdrawClicked
                                    ]
                                    [ Html.text "Withdraw (edit)" ]
                                , UI.Button.button
                                    [ Attr.id "wiki-submission-detail-delete"
                                    , Attr.type_ "button"
                                    , Attr.disabled (anyBusy || interaction.deleteInFlight)
                                    , Events.onClick SubmissionDetailDeleteClicked
                                    ]
                                    [ Html.text "Delete" ]
                                ]

                        Submission.NeedsRevision ->
                            Html.div
                                [ UI.flexWrapGap2Mt3Attr ]
                                [ UI.Button.button
                                    [ Attr.id "wiki-submission-detail-withdraw"
                                    , Attr.type_ "button"
                                    , Attr.disabled (anyBusy || interaction.withdrawInFlight)
                                    , Events.onClick SubmissionDetailWithdrawClicked
                                    ]
                                    [ Html.text "Withdraw (edit)" ]
                                , UI.Button.button
                                    [ Attr.id "wiki-submission-detail-delete"
                                    , Attr.type_ "button"
                                    , Attr.disabled (anyBusy || interaction.deleteInFlight)
                                    , Events.onClick SubmissionDetailDeleteClicked
                                    ]
                                    [ Html.text "Delete" ]
                                ]

                        Submission.Rejected ->
                            Html.div
                                [ UI.flexWrapGap2Mt3Attr ]
                                [ UI.Button.button
                                    [ Attr.id "wiki-submission-detail-delete"
                                    , Attr.type_ "button"
                                    , Attr.disabled (anyBusy || interaction.deleteInFlight)
                                    , Events.onClick SubmissionDetailDeleteClicked
                                    ]
                                    [ Html.text "Delete" ]
                                ]

                        Submission.Draft ->
                            Html.div
                                [ UI.flexWrapGap2Mt3Attr ]
                                (UI.SubmissionActions.primaryPairButtons
                                    { saveDraftAttrs =
                                        [ Attr.id "wiki-submission-detail-save-draft"
                                        , Attr.type_ "button"
                                        , Attr.disabled (anyBusy || interaction.saveDraftInFlight)
                                        , Events.onClick SubmissionDetailSaveDraftClicked
                                        ]
                                    , submitAttrs =
                                        [ Attr.id "wiki-submission-detail-submit-for-review"
                                        , Attr.type_ "button"
                                        , Attr.disabled (anyBusy || interaction.submitForReviewInFlight)
                                        , Events.onClick SubmissionDetailSubmitForReviewClicked
                                        ]
                                    , submitLabel = "Submit for review"
                                    }
                                    ++ [ UI.Button.button
                                            [ Attr.id "wiki-submission-detail-delete"
                                            , Attr.type_ "button"
                                            , Attr.disabled (anyBusy || interaction.deleteInFlight)
                                            , Events.onClick SubmissionDetailDeleteClicked
                                            ]
                                            [ Html.text "Delete" ]
                                       ]
                                )

                        Submission.Approved ->
                            Html.text ""

                actionFeedback : Html Msg
                actionFeedback =
                    case interaction.lastError of
                        Nothing ->
                            Html.text ""

                        Just errText ->
                            Html.p
                                [ Attr.id "wiki-submission-detail-action-error"
                                , UI.submissionStatusDangerLineAttr
                                ]
                                [ Html.text errText ]
            in
            Html.div []
                [ UI.contentParagraph []
                    [ Html.span
                        [ Attr.id "wiki-submission-detail-status"
                        , Attr.attribute "data-submission-status" (Submission.statusLabelUserText detail.status)
                        ]
                        [ Html.text (Submission.statusLabelUserText detail.status) ]
                    ]
                , UI.contentParagraph
                    [ Attr.id "wiki-submission-detail-kind-summary" ]
                    [ Html.text detail.kindSummary ]
                , case detail.reviewerNote of
                    Nothing ->
                        Html.text ""

                    Just noteText ->
                        Html.section
                            [ Attr.id "wiki-submission-detail-reviewer-note"
                            , Attr.attribute "data-has-reviewer-note" "true"
                            ]
                            [ UI.Heading.contentHeading2 [] [ Html.text "Reviewer note" ]
                            , UI.contentParagraph [] [ Html.text noteText ]
                            ]
                , Html.section
                    [ Attr.id "wiki-submission-detail-next-steps"
                    , UI.submitActionsBarAttr
                    ]
                    [ UI.contentParagraph [ UI.submitSummaryParagraphAttr ]
                        [ Html.text (submissionDetailNextStepsText detail.status) ]
                    ]
                , newPageSlugField
                , Html.div
                    [ UI.submissionGridTight2ColAttr ]
                    [ Html.label
                        [ Attr.for "original-markdown-readonly-textarea"
                        , UI.classAttr "m-0 !mt-0 !mb-0 shrink-0 text-sm font-semibold leading-tight text-[var(--fg)] col-start-1 row-start-1"
                        ]
                        [ Html.text "Original" ]
                    , Html.textarea
                        ([ Attr.id "original-markdown-readonly-textarea"
                         , Attr.readonly True
                         , Attr.rows 14
                         , Attr.value detail.compareOriginalMarkdown
                         ]
                            |> UI.Textarea.markdownReadonlyCol1Row2
                        )
                        []
                    , Html.div
                        ([ Attr.id "original-preview" ]
                            |> UI.Textarea.positionedGridCol1Row3
                        )
                        [ comparePreview "original-preview-inner" detail.compareOriginalMarkdown ]
                    , Html.label
                        [ Attr.for
                            (if detail.status == Submission.Draft then
                                "new-markdown-editable-textarea"

                             else
                                "new-markdown-readonly-textarea"
                            )
                        , UI.classAttr "m-0 !mt-0 !mb-0 shrink-0 text-sm font-semibold leading-tight text-[var(--fg)] col-start-2 row-start-1"
                        ]
                        [ Html.text
                            (if detail.contributionKind == Submission.ContributorKindDeletePage then
                                "Reason for deletion (required)"

                             else
                                "Proposed"
                            )
                        ]
                    , Html.div
                        [ UI.gridCellCol2Row2Attr ]
                        [ newMarkdownField ]
                    , Html.div
                        ([ Attr.id "new-preview" ]
                            |> UI.Textarea.positionedGridCol2Row3
                        )
                        [ comparePreview "new-preview-inner" newMarkdownForPreview ]
                    ]
                , withdrawDeleteRow
                , actionFeedback
                ]


viewWikiReviewQueueLoading : Html Msg
viewWikiReviewQueueLoading =
    Html.div
        [ Attr.id "wiki-review-queue-loading"
        ]
        [ UI.AsyncState.loading "Loading…" ]


viewReviewQueueBody :
    Wiki.Slug
    -> RemoteData () (Result Submission.ReviewQueueError (List Submission.ReviewQueueItem))
    -> Html Msg
viewReviewQueueBody wikiSlug remote =
    case remote of
        RemoteData.NotAsked ->
            viewWikiReviewQueueLoading

        RemoteData.Loading ->
            viewWikiReviewQueueLoading

        RemoteData.Failure _ ->
            Html.div
                [ Attr.id "wiki-review-queue-error" ]
                [ UI.contentParagraph [] [ Html.text "Could not load the review queue." ] ]

        RemoteData.Success (Err e) ->
            Html.div
                [ Attr.id "wiki-review-queue-error" ]
                [ UI.contentParagraph [] [ Html.text (Submission.reviewQueueErrorToUserText e) ] ]

        RemoteData.Success (Ok items) ->
            if List.isEmpty items then
                UI.EmptyState.paragraph { id = "wiki-review-queue-empty", text = "No pending submissions." }

            else
                UI.table UI.TableFullMax72
                    []
                    { theadAttrs = []
                    , headerRowAttrs = []
                    , headerAlign = UI.TableAlignTop
                    , headers =
                        [ UI.tableHeaderText "Submission"
                        , UI.tableHeaderText "Kind"
                        , UI.tableHeaderText "Author"
                        , UI.tableHeaderText "Page"
                        ]
                    , tbodyAttrs = [ Attr.id "wiki-review-queue-list" ]
                    , rows =
                        items
                            |> List.map
                                (\item ->
                                    let
                                        idStr : String
                                        idStr =
                                            Submission.idToString item.id
                                    in
                                    UI.trStriped
                                        [ Attr.attribute "data-review-queue-item" idStr
                                        ]
                                        [ UI.tableTd UI.TableAlignTop
                                            []
                                            [ UI.Link.contentLink
                                                [ Attr.href (Wiki.reviewDetailUrlPath wikiSlug idStr)
                                                , Attr.attribute "data-submission-id" idStr
                                                ]
                                                [ Html.text item.kindLabel
                                                , Html.text " — "
                                                , Html.text item.authorDisplay
                                                , case item.maybePageSlug of
                                                    Nothing ->
                                                        Html.text ""

                                                    Just pageSlug ->
                                                        Html.span
                                                            [ Attr.attribute "data-page-slug" pageSlug
                                                            ]
                                                            [ Html.text (" (" ++ pageSlug ++ ")") ]
                                                ]
                                            ]
                                        , UI.tableTd UI.TableAlignTop [] [ Html.text item.kindLabel ]
                                        , UI.tableTd UI.TableAlignTop [] [ Html.text item.authorDisplay ]
                                        , UI.tableTd UI.TableAlignTop
                                            []
                                            [ case item.maybePageSlug of
                                                Nothing ->
                                                    Html.text ""

                                                Just pageSlug ->
                                                    Html.span
                                                        [ Attr.attribute "data-page-slug" pageSlug
                                                        ]
                                                        [ Html.text pageSlug ]
                                            ]
                                        ]
                                )
                    }


viewReviewQueueLoaded : Wiki.Slug -> Store -> Html Msg
viewReviewQueueLoaded wikiSlug store =
    Html.div
        [ Attr.id "wiki-review-queue-page"
        , Attr.attribute "data-wiki-slug" wikiSlug
        ]
        [ viewReviewQueueBody wikiSlug (Store.get_ wikiSlug store.reviewQueues)
        ]


viewReviewQueueRoute : Model -> Wiki.Slug -> Html Msg
viewReviewQueueRoute model wikiSlug =
    case Store.get_ wikiSlug model.store.wikiDetails of
        RemoteData.Success _ ->
            case Store.get wikiSlug model.store.wikiCatalog of
                RemoteData.Success _ ->
                    viewReviewQueueLoaded wikiSlug model.store

                RemoteData.Failure _ ->
                    viewNotFound

                RemoteData.Loading ->
                    viewWikiReviewQueueLoading

                RemoteData.NotAsked ->
                    viewWikiReviewQueueLoading

        RemoteData.Failure _ ->
            viewNotFound

        RemoteData.Loading ->
            viewWikiReviewQueueLoading

        RemoteData.NotAsked ->
            viewWikiReviewQueueLoading


viewWikiMySubmissionsLoading : Html Msg
viewWikiMySubmissionsLoading =
    Html.div
        [ Attr.id "wiki-my-submissions-loading"
        ]
        [ UI.AsyncState.loading "Loading…" ]


viewMySubmissionsBody :
    Wiki.Slug
    -> RemoteData () (Result Submission.MyPendingSubmissionsError (List Submission.MyPendingSubmissionListItem))
    -> Html Msg
viewMySubmissionsBody wikiSlug remote =
    case remote of
        RemoteData.NotAsked ->
            viewWikiMySubmissionsLoading

        RemoteData.Loading ->
            viewWikiMySubmissionsLoading

        RemoteData.Failure _ ->
            Html.div
                [ Attr.id "wiki-my-submissions-error" ]
                [ UI.contentParagraph [] [ Html.text "Could not load your submissions." ] ]

        RemoteData.Success (Err e) ->
            Html.div
                [ Attr.id "wiki-my-submissions-error" ]
                [ UI.contentParagraph [] [ Html.text (Submission.myPendingSubmissionsErrorToUserText e) ] ]

        RemoteData.Success (Ok items) ->
            if List.isEmpty items then
                UI.EmptyState.paragraph { id = "wiki-my-submissions-empty", text = "No submissions to show here yet." }

            else
                UI.table UI.TableFullMax72
                    []
                    { theadAttrs = []
                    , headerRowAttrs = []
                    , headerAlign = UI.TableAlignTop
                    , headers =
                        [ UI.tableHeaderText "Submission"
                        , UI.tableHeaderText "Status"
                        , UI.tableHeaderText "Kind"
                        , UI.tableHeaderText "Page"
                        ]
                    , tbodyAttrs = [ Attr.id "wiki-my-submissions-list" ]
                    , rows =
                        items
                            |> List.map
                                (\item ->
                                    let
                                        idStr : String
                                        idStr =
                                            Submission.idToString item.id
                                    in
                                    UI.trStriped
                                        [ Attr.attribute "data-my-submissions-item" idStr
                                        ]
                                        [ UI.tableTd UI.TableAlignTop
                                            []
                                            [ UI.Link.contentLink
                                                [ Attr.href (Wiki.submissionDetailUrlPath wikiSlug idStr)
                                                , Attr.attribute "data-submission-id" idStr
                                                ]
                                                [ Html.text idStr ]
                                            ]
                                        , UI.tableTd UI.TableAlignTop
                                            []
                                            [ Html.span
                                                [ Attr.attribute "data-submission-status" item.statusLabel ]
                                                [ Html.text item.statusLabel ]
                                            ]
                                        , UI.tableTd UI.TableAlignTop [] [ Html.text item.kindLabel ]
                                        , UI.tableTd UI.TableAlignTop
                                            []
                                            [ case item.maybePageSlug of
                                                Nothing ->
                                                    Html.text ""

                                                Just pageSlug ->
                                                    Html.span
                                                        [ Attr.attribute "data-page-slug" pageSlug
                                                        ]
                                                        [ Html.text pageSlug ]
                                            ]
                                        ]
                                )
                    }


viewMySubmissionsLoaded : Wiki.Slug -> Store -> Html Msg
viewMySubmissionsLoaded wikiSlug store =
    Html.div
        [ Attr.id "wiki-my-submissions-page"
        , Attr.attribute "data-wiki-slug" wikiSlug
        ]
        [ viewMySubmissionsBody wikiSlug (Store.get_ wikiSlug store.myPendingSubmissions)
        ]


viewMySubmissionsRoute : Model -> Wiki.Slug -> Html Msg
viewMySubmissionsRoute model wikiSlug =
    case Store.get_ wikiSlug model.store.wikiDetails of
        RemoteData.Success _ ->
            case Store.get wikiSlug model.store.wikiCatalog of
                RemoteData.Success _ ->
                    viewMySubmissionsLoaded wikiSlug model.store

                RemoteData.Failure _ ->
                    viewNotFound

                RemoteData.Loading ->
                    viewWikiMySubmissionsLoading

                RemoteData.NotAsked ->
                    viewWikiMySubmissionsLoading

        RemoteData.Failure _ ->
            viewNotFound

        RemoteData.Loading ->
            viewWikiMySubmissionsLoading

        RemoteData.NotAsked ->
            viewWikiMySubmissionsLoading


viewWikiAdminUsersLoading : Html Msg
viewWikiAdminUsersLoading =
    Html.div
        [ Attr.id "wiki-admin-users-loading"
        ]
        [ UI.AsyncState.loading "Loading…" ]


viewWikiAdminUsersBody :
    Wiki.Slug
    -> Maybe String
    -> RemoteData () (Result WikiAdminUsers.Error (List WikiAdminUsers.ListedUser))
    -> Html Msg
viewWikiAdminUsersBody wikiSlug maybeSelfUsername remote =
    case remote of
        RemoteData.NotAsked ->
            viewWikiAdminUsersLoading

        RemoteData.Loading ->
            viewWikiAdminUsersLoading

        RemoteData.Failure _ ->
            Html.div
                [ Attr.id "wiki-admin-users-error" ]
                [ UI.contentParagraph [] [ Html.text "Could not load wiki users." ] ]

        RemoteData.Success (Err e) ->
            Html.div
                [ Attr.id "wiki-admin-users-error" ]
                [ UI.contentParagraph [] [ Html.text (WikiAdminUsers.errorToUserText e) ] ]

        RemoteData.Success (Ok users) ->
            UI.table UI.TableFullMax72
                [ Attr.id "wiki-admin-users-table" ]
                { theadAttrs = []
                , headerRowAttrs = []
                , headerAlign = UI.TableAlignMiddle
                , headers =
                    [ UI.tableHeaderText "Username"
                    , UI.tableHeaderText "Role"
                    , UI.tableHeaderText "Actions"
                    ]
                , tbodyAttrs = [ Attr.id "wiki-admin-users-tbody" ]
                , rows =
                    users
                        |> List.map
                            (\u ->
                                UI.trStriped
                                    [ Attr.attribute "data-admin-user" u.username
                                    , Attr.attribute "data-wiki-slug" wikiSlug
                                    ]
                                    [ UI.tableTd UI.TableAlignMiddle [] [ Html.text u.username ]
                                    , UI.tableTd UI.TableAlignMiddle
                                        [ Attr.attribute "data-user-role" (WikiRole.label u.role)
                                        ]
                                        [ Html.text (WikiRole.label u.role) ]
                                    , UI.tableTd UI.TableAlignMiddle
                                        []
                                        [ viewWikiAdminUsersPromoteCell u
                                        , viewWikiAdminUsersDemoteCell u
                                        , viewWikiAdminUsersGrantAdminCell u
                                        , viewWikiAdminUsersRevokeAdminCell maybeSelfUsername u
                                        ]
                                    ]
                            )
                }


viewWikiAdminUsersPromoteCell : WikiAdminUsers.ListedUser -> Html Msg
viewWikiAdminUsersPromoteCell u =
    case u.role of
        WikiRole.UntrustedContributor _ ->
            UI.Button.button
                [ Attr.type_ "button"
                , Attr.attribute "data-context" "wiki-admin-promote-trusted"
                , Attr.id ("wiki-admin-promote-trusted-" ++ u.username)
                , Attr.attribute "data-target-username" u.username
                , Events.onClick (WikiAdminPromoteToTrustedClicked u.username)
                ]
                [ Html.text "Promote" ]

        WikiRole.TrustedContributor ->
            Html.text ""

        WikiRole.Admin ->
            Html.text ""


viewWikiAdminUsersDemoteCell : WikiAdminUsers.ListedUser -> Html Msg
viewWikiAdminUsersDemoteCell u =
    case u.role of
        WikiRole.UntrustedContributor _ ->
            Html.text ""

        WikiRole.TrustedContributor ->
            UI.Button.button
                [ Attr.type_ "button"
                , Attr.attribute "data-context" "wiki-admin-demote-trusted"
                , Attr.id ("wiki-admin-demote-trusted-" ++ u.username)
                , Attr.attribute "data-target-username" u.username
                , Events.onClick (WikiAdminDemoteToContributorClicked u.username)
                ]
                [ Html.text "Demote" ]

        WikiRole.Admin ->
            Html.text ""


viewWikiAdminUsersGrantAdminCell : WikiAdminUsers.ListedUser -> Html Msg
viewWikiAdminUsersGrantAdminCell u =
    case u.role of
        WikiRole.UntrustedContributor _ ->
            Html.text ""

        WikiRole.TrustedContributor ->
            UI.Button.button
                [ Attr.type_ "button"
                , Attr.attribute "data-context" "wiki-admin-grant-admin"
                , Attr.id ("wiki-admin-grant-admin-" ++ u.username)
                , Attr.attribute "data-target-username" u.username
                , Events.onClick (WikiAdminGrantAdminClicked u.username)
                ]
                [ Html.text "Make admin" ]

        WikiRole.Admin ->
            Html.text ""


viewWikiAdminUsersRevokeAdminCell : Maybe String -> WikiAdminUsers.ListedUser -> Html Msg
viewWikiAdminUsersRevokeAdminCell maybeSelfUsername u =
    case u.role of
        WikiRole.UntrustedContributor _ ->
            Html.text ""

        WikiRole.TrustedContributor ->
            Html.text ""

        WikiRole.Admin ->
            if maybeSelfUsername == Just u.username then
                Html.text ""

            else
                UI.Button.button
                    [ Attr.type_ "button"
                    , Attr.attribute "data-context" "wiki-admin-revoke-admin"
                    , Attr.id ("wiki-admin-revoke-admin-" ++ u.username)
                    , Attr.attribute "data-target-username" u.username
                    , Events.onClick (WikiAdminRevokeAdminClicked u.username)
                    ]
                    [ Html.text "Revoke admin" ]


viewWikiAdminUsersLoaded :
    Wiki.Slug
    -> Store
    -> Maybe String
    -> Maybe String
    -> Maybe String
    -> Maybe String
    -> Maybe String
    -> Html Msg
viewWikiAdminUsersLoaded wikiSlug store promoteError demoteError grantAdminError revokeAdminError maybeSelfUsername =
    Html.div
        [ Attr.id "wiki-admin-users-page"
        , Attr.attribute "data-wiki-slug" wikiSlug
        ]
        [ viewWikiAdminUsersPromoteFeedback promoteError
        , viewWikiAdminUsersDemoteFeedback demoteError
        , viewWikiAdminUsersGrantAdminFeedback grantAdminError
        , viewWikiAdminUsersRevokeAdminFeedback revokeAdminError
        , viewWikiAdminUsersBody wikiSlug maybeSelfUsername (Store.get_ wikiSlug store.wikiUsers)
        ]


viewWikiAdminUsersPromoteFeedback : Maybe String -> Html Msg
viewWikiAdminUsersPromoteFeedback maybeText =
    case maybeText of
        Nothing ->
            Html.text ""

        Just text ->
            Html.div
                [ Attr.id "wiki-admin-promote-error" ]
                [ UI.contentParagraph [] [ Html.text text ] ]


viewWikiAdminUsersDemoteFeedback : Maybe String -> Html Msg
viewWikiAdminUsersDemoteFeedback maybeText =
    case maybeText of
        Nothing ->
            Html.text ""

        Just text ->
            Html.div
                [ Attr.id "wiki-admin-demote-error" ]
                [ UI.contentParagraph [] [ Html.text text ] ]


viewWikiAdminUsersGrantAdminFeedback : Maybe String -> Html Msg
viewWikiAdminUsersGrantAdminFeedback maybeText =
    case maybeText of
        Nothing ->
            Html.text ""

        Just text ->
            Html.div
                [ Attr.id "wiki-admin-grant-admin-error" ]
                [ UI.contentParagraph [] [ Html.text text ] ]


viewWikiAdminUsersRevokeAdminFeedback : Maybe String -> Html Msg
viewWikiAdminUsersRevokeAdminFeedback maybeText =
    case maybeText of
        Nothing ->
            Html.text ""

        Just text ->
            Html.div
                [ Attr.id "wiki-admin-revoke-admin-error" ]
                [ UI.contentParagraph [] [ Html.text text ] ]


wikiAdminUsersSelfUsernameOnPage : Model -> Wiki.Slug -> Maybe String
wikiAdminUsersSelfUsernameOnPage model wikiSlug =
    model.contributorWikiSessions
        |> Dict.get wikiSlug
        |> Maybe.map .displayUsername


viewWikiAdminUsersRoute : Model -> Wiki.Slug -> Html Msg
viewWikiAdminUsersRoute model wikiSlug =
    case Store.get_ wikiSlug model.store.wikiDetails of
        RemoteData.Success _ ->
            case Store.get wikiSlug model.store.wikiCatalog of
                RemoteData.Success _ ->
                    viewWikiAdminUsersLoaded wikiSlug model.store model.adminPromoteError model.adminDemoteError model.adminGrantAdminError model.adminRevokeAdminError (wikiAdminUsersSelfUsernameOnPage model wikiSlug)

                RemoteData.Failure _ ->
                    viewNotFound

                RemoteData.Loading ->
                    viewWikiAdminUsersLoading

                RemoteData.NotAsked ->
                    viewWikiAdminUsersLoading

        RemoteData.Failure _ ->
            viewNotFound

        RemoteData.Loading ->
            viewWikiAdminUsersLoading

        RemoteData.NotAsked ->
            viewWikiAdminUsersLoading


viewWikiAdminAuditLoading : Html Msg
viewWikiAdminAuditLoading =
    viewAuditLoading "wiki-admin-audit-loading"


viewWikiAdminAuditBody :
    Wiki.Slug
    -> RemoteData () (Result WikiAuditLog.Error (List WikiAuditLog.AuditEvent))
    -> Html Msg
viewWikiAdminAuditBody wikiSlug remote =
    case remote of
        RemoteData.NotAsked ->
            viewWikiAdminAuditLoading

        RemoteData.Loading ->
            viewWikiAdminAuditLoading

        RemoteData.Failure _ ->
            viewAuditError "wiki-admin-audit-error" "Could not load audit log."

        RemoteData.Success (Err e) ->
            viewAuditError "wiki-admin-audit-error" (WikiAuditLog.errorToUserText e)

        RemoteData.Success (Ok events) ->
            viewAuditEventsTable
                { tableId = "wiki-admin-audit-list"
                , tbodyId = "wiki-admin-audit-tbody"
                , columnClasses =
                    [ "w-[calc(19ch+1.1rem)]"
                    , "w-auto"
                    , "w-full"
                    ]
                , headers =
                    [ "Time (UTC)"
                    , "Actor"
                    , "Event"
                    ]
                , includeWikiColumn = False
                , isHostAuditView = False
                }
                (events
                    |> List.map
                        (\ev ->
                            { wikiSlug = wikiSlug
                            , at = ev.at
                            , actorUsername = ev.actorUsername
                            , kind = ev.kind
                            , utcTimestamp = WikiAuditLog.eventUtcTimestampString ev
                            }
                        )
                )


viewWikiAdminAuditFilters : Model -> Html Msg
viewWikiAdminAuditFilters model =
    viewAuditFilters
        { context = "wiki-admin-audit-filters"
        , gridAttr = UI.wikiAdminAuditFiltersGridAttr
        , maybeWikiFilter = Nothing
        , actorInputId = "wiki-admin-audit-filter-actor"
        , actorValue = model.wikiAdminAuditFilterActorDraft
        , actorOnInput = WikiAdminAuditFilterActorChanged
        , pageInputId = "wiki-admin-audit-filter-page"
        , pageValue = model.wikiAdminAuditFilterPageDraft
        , pageOnInput = WikiAdminAuditFilterPageChanged
        , kindFilterGroupId = "wiki-admin-audit-filter-type"
        , kindFilterLegendId = "wiki-admin-audit-filter-type-legend"
        , kindChipView = viewWikiAdminAuditKindChip model
        }


viewWikiAdminAuditKindChip : Model -> ( WikiAuditLog.AuditEventKindFilterTag, String ) -> Html Msg
viewWikiAdminAuditKindChip model ( tag, labelText ) =
    viewAuditKindChip
        { idPrefix = "wiki-admin-audit-filter-type-"
        , selectedTags = model.wikiAdminAuditFilterSelectedKindTags
        , onToggle = WikiAdminAuditFilterTypeTagToggled
        }
        ( tag, labelText )


viewWikiAdminAuditLoaded : Wiki.Slug -> Model -> Html Msg
viewWikiAdminAuditLoaded wikiSlug model =
    Html.div
        [ Attr.id "wiki-admin-audit-page"
        , Attr.attribute "data-wiki-slug" wikiSlug
        , UI.wikiAdminAuditPageShellAttr
        ]
        [ viewWikiAdminAuditFilters model
        , Html.div
            [ Attr.id "wiki-admin-audit-table-region"
            , UI.flexRowMin0Attr
            ]
            [ viewWikiAdminAuditBody wikiSlug (Store.getWikiAuditLog wikiSlug model.wikiAdminAuditAppliedFilter model.store) ]
        ]


viewWikiAdminAuditRoute : Model -> Wiki.Slug -> Html Msg
viewWikiAdminAuditRoute model wikiSlug =
    case Store.get_ wikiSlug model.store.wikiDetails of
        RemoteData.Success wikiDetails ->
            case Store.get wikiSlug model.store.wikiCatalog of
                RemoteData.Success _ ->
                    viewWikiAdminAuditLoaded wikiSlug model

                RemoteData.Failure _ ->
                    viewNotFound

                RemoteData.Loading ->
                    viewWikiAdminAuditLoading

                RemoteData.NotAsked ->
                    viewWikiAdminAuditLoading

        RemoteData.Failure _ ->
            viewNotFound

        RemoteData.Loading ->
            viewWikiAdminAuditLoading

        RemoteData.NotAsked ->
            viewWikiAdminAuditLoading


type alias TrustedAuditEditDiffBody =
    { pageSlug : Page.Slug
    , beforeMarkdown : String
    , afterMarkdown : String
    }


type TrustedAuditDiffBody
    = TrustedAuditNewPageDiffBody
        { pageSlug : Page.Slug
        , markdown : String
        }
    | TrustedAuditEditDiffBody_ TrustedAuditEditDiffBody


trustedAuditDiffFromEvent : WikiAuditLog.AuditEvent -> Maybe TrustedAuditDiffBody
trustedAuditDiffFromEvent ev =
    case ev.kind of
        WikiAuditLog.TrustedPublishedNewPage { pageSlug, markdown } ->
            Just
                (TrustedAuditNewPageDiffBody
                    { pageSlug = pageSlug
                    , markdown = markdown
                    }
                )

        WikiAuditLog.TrustedPublishedPageEdit { pageSlug, beforeMarkdown, afterMarkdown } ->
            Just
                (TrustedAuditEditDiffBody_
                    { pageSlug = pageSlug
                    , beforeMarkdown = beforeMarkdown
                    , afterMarkdown = afterMarkdown
                    }
                )

        _ ->
            Nothing


trustedAuditDiffFromScopedEvent : WikiAuditLog.ScopedAuditEvent -> Maybe TrustedAuditDiffBody
trustedAuditDiffFromScopedEvent ev =
    trustedAuditDiffFromEvent
        { at = ev.at
        , actorUsername = ev.actorUsername
        , kind = ev.kind
        }


findWikiAuditDiffByIndex : Model -> Wiki.Slug -> Int -> Maybe TrustedAuditDiffBody
findWikiAuditDiffByIndex model wikiSlug eventIndex =
    case Store.getWikiAuditLog wikiSlug model.wikiAdminAuditAppliedFilter model.store of
        Success (Ok events) ->
            events
                |> List.drop eventIndex
                |> List.head
                |> Maybe.andThen trustedAuditDiffFromEvent

        _ ->
            Nothing


findHostAuditDiffByIndex : Model -> Int -> Maybe ( Wiki.Slug, TrustedAuditDiffBody )
findHostAuditDiffByIndex model eventIndex =
    case model.hostAdminAuditLog of
        Success (Ok scopedEvents) ->
            scopedEvents
                |> List.drop eventIndex
                |> List.head
                |> Maybe.andThen
                    (\ev ->
                        trustedAuditDiffFromScopedEvent ev
                            |> Maybe.map (\body -> ( ev.wikiSlug, body ))
                    )

        _ ->
            Nothing


viewWikiAdminAuditDiffRoute : Wiki.Slug -> Wiki.FrontendDetails -> Int -> Model -> Html Msg
viewWikiAdminAuditDiffRoute wikiSlug wikiDetails eventIndex model =
    let
        maybeDiffBody : Maybe TrustedAuditDiffBody
        maybeDiffBody =
            findWikiAuditDiffByIndex model wikiSlug eventIndex
    in
    case maybeDiffBody of
        Just (TrustedAuditNewPageDiffBody diffBody) ->
            Html.div
                [ Attr.id "wiki-admin-audit-diff-page"
                , UI.hostAdminAuditDiffPageShellAttr
                ]
                [ viewAuditLogDiffReadonly
                    wikiSlug
                    (publishedSlugExistsFromWikiDetails wikiDetails)
                    (SubmissionReviewDetail.NewPageDiff
                        { pageSlug = diffBody.pageSlug
                        , proposedMarkdown = diffBody.markdown
                        }
                    )
                ]

        Just (TrustedAuditEditDiffBody_ diffBody) ->
            Html.div
                [ Attr.id "wiki-admin-audit-diff-page"
                , UI.hostAdminAuditDiffPageShellAttr
                ]
                [ UI.contentParagraph []
                    [ UI.Link.subtleLink [ Attr.href (Wiki.adminAuditUrlPath wikiSlug) ] [ Html.text "Back to audit log" ] ]
                , viewAuditLogDiffReadonly
                    wikiSlug
                    (publishedSlugExistsFromWikiDetails wikiDetails)
                    (SubmissionReviewDetail.EditPageDiff diffBody)
                ]

        Nothing ->
            Html.div
                [ Attr.id "wiki-admin-audit-diff-missing" ]
                [ UI.contentParagraph []
                    [ Html.text "Diff details not available for this audit event." ]
                ]


viewHostAdminAuditDiffRoute : Wiki.Slug -> Int -> Model -> Html Msg
viewHostAdminAuditDiffRoute _ eventIndex model =
    let
        maybeDiffBody : Maybe ( Wiki.Slug, TrustedAuditDiffBody )
        maybeDiffBody =
            findHostAuditDiffByIndex model eventIndex
    in
    case maybeDiffBody of
        Just ( wikiSlug, TrustedAuditNewPageDiffBody diffBody ) ->
            let
                publishedSlugExists : Page.Slug -> Bool
                publishedSlugExists =
                    case Store.get_ wikiSlug model.store.wikiDetails of
                        Success wikiDetails ->
                            publishedSlugExistsFromWikiDetails wikiDetails

                        _ ->
                            \_ -> False
            in
            Html.div
                [ Attr.id "host-admin-audit-diff-page"
                , UI.hostAdminAuditDiffPageShellAttr
                ]
                [ viewAuditLogDiffReadonly
                    wikiSlug
                    publishedSlugExists
                    (SubmissionReviewDetail.NewPageDiff
                        { pageSlug = diffBody.pageSlug
                        , proposedMarkdown = diffBody.markdown
                        }
                    )
                ]

        Just ( wikiSlug, TrustedAuditEditDiffBody_ diffBody ) ->
            let
                publishedSlugExists : Page.Slug -> Bool
                publishedSlugExists =
                    case Store.get_ wikiSlug model.store.wikiDetails of
                        Success wikiDetails ->
                            publishedSlugExistsFromWikiDetails wikiDetails

                        _ ->
                            \_ -> False
            in
            Html.div
                [ Attr.id "host-admin-audit-diff-page"
                , UI.hostAdminAuditDiffPageShellAttr
                ]
                [ viewAuditLogDiffReadonly
                    wikiSlug
                    publishedSlugExists
                    (SubmissionReviewDetail.EditPageDiff diffBody)
                ]

        Nothing ->
            Html.div
                [ Attr.id "host-admin-audit-diff-missing" ]
                [ UI.contentParagraph []
                    [ Html.text "Diff details not available for this audit event." ]
                ]


viewSubmissionReviewDiff :
    Wiki.Slug
    -> (Page.Slug -> Bool)
    -> SubmissionReviewDetail.SubmissionReviewDetail
    -> Html Msg
viewSubmissionReviewDiff wikiSlug publishedSlugExists detail =
    let
        reviewPreview : String -> String -> Html Msg
        reviewPreview previewId markdown =
            Html.div
                [ UI.classAttr UI.markdownPreviewScrollClass ]
                [ PageMarkdown.viewPreview previewId wikiSlug publishedSlugExists markdown ]

        reviewPreviewInDiffCell : String -> String -> Html Msg
        reviewPreviewInDiffCell previewId markdown =
            Html.div
                [ UI.markdownPreviewScrollMinFlexFullHeightAttr ]
                [ PageMarkdown.viewPreview previewId wikiSlug publishedSlugExists markdown ]

        reviewReadonlyTextarea : String -> String -> List (Attribute Msg) -> Html Msg
        reviewReadonlyTextarea elementId markdown extraAttrs =
            Html.textarea
                ([ Attr.id elementId
                 , Attr.readonly True
                 , Attr.rows 12
                 , Attr.value markdown
                 ]
                    ++ extraAttrs
                )
                []
    in
    case detail of
        SubmissionReviewDetail.NewPageDiff body ->
            Html.div
                [ Attr.id "wiki-review-diff-summary"
                , UI.gridTwoByTwoDiffStrAttr
                ]
                [ Html.h3
                    [ UI.classAttr "m-0 !mt-0 !mb-0 shrink-0 text-sm font-semibold leading-tight text-[var(--fg)] col-start-1 row-start-1" ]
                    [ Html.text "Proposed markdown" ]
                , reviewReadonlyTextarea "wiki-review-diff-new"
                    body.proposedMarkdown
                    (UI.Textarea.markdownReadonlyCol1Row2 [])
                , Html.h3
                    [ UI.classAttr "m-0 !mt-0 !mb-0 shrink-0 text-sm font-semibold leading-tight text-[var(--fg-muted)] col-start-2 row-start-1" ]
                    [ Html.text "Preview" ]
                , Html.div
                    [ UI.reviewDiffNewPagePreviewColShellAttr ]
                    [ reviewPreviewInDiffCell "wiki-review-diff-new-preview" body.proposedMarkdown ]
                ]

        SubmissionReviewDetail.EditPageDiff body ->
            Html.div
                [ Attr.id "wiki-review-diff-summary"
                , UI.gridTwoByTwoDiffStrAttr
                ]
                [ Html.h2
                    [ UI.classAttr "m-0 !mt-0 !mb-0 shrink-0 text-sm font-semibold leading-tight text-[var(--fg)] col-start-1 row-start-1" ]
                    [ Html.text "Before (published)" ]
                , reviewReadonlyTextarea "wiki-review-diff-old"
                    body.beforeMarkdown
                    (UI.Textarea.markdownReadonlyCol1Row2 [])
                , Html.div
                    [ UI.gridCellStackCol1Row3Attr ]
                    [ Html.h3
                        [ UI.classAttr "m-0 !mt-0 !mb-0 shrink-0 text-sm font-semibold leading-tight text-[var(--fg-muted)]" ]
                        [ Html.text "Preview" ]
                    , reviewPreviewInDiffCell "wiki-review-diff-old-preview" body.beforeMarkdown
                    ]
                , Html.h2
                    [ UI.classAttr "m-0 !mt-0 !mb-0 shrink-0 text-sm font-semibold leading-tight text-[var(--fg)] col-start-2 row-start-1 border-t border-[var(--border-subtle)] pt-3" ]
                    [ Html.text "After (proposed)" ]
                , reviewReadonlyTextarea "wiki-review-diff-new"
                    body.afterMarkdown
                    (UI.Textarea.markdownReadonlyGridCol2Row2 [ Attr.class "border-t border-[var(--border-subtle)] pt-3" ])
                , Html.div
                    [ UI.gridCellStackCol2Row3Attr, Attr.class "border-t border-[var(--border-subtle)] pt-3" ]
                    [ Html.h3
                        [ UI.classAttr "m-0 !mt-0 !mb-0 shrink-0 text-sm font-semibold leading-tight text-[var(--fg-muted)]" ]
                        [ Html.text "Preview" ]
                    , reviewPreviewInDiffCell "wiki-review-diff-new-preview" body.afterMarkdown
                    ]
                ]

        SubmissionReviewDetail.DeletePageDiff body ->
            Html.div
                [ Attr.id "wiki-review-diff-summary" ]
                [ reviewReadonlyTextarea "wiki-review-diff-published"
                    body.publishedSnapshotMarkdown
                    (UI.Textarea.markdownReadonly [])
                , Html.h3
                    [ UI.reviewDeletePagePreviewTitleAttr ]
                    [ Html.text "Preview" ]
                , reviewPreview "wiki-review-diff-published-preview" body.publishedSnapshotMarkdown
                , case body.reason of
                    Nothing ->
                        Html.text ""

                    Just r ->
                        Html.div
                            [ Attr.id "wiki-review-diff-reason" ]
                            [ Html.text r ]
                ]


viewAuditLogDiffReadonly :
    Wiki.Slug
    -> (Page.Slug -> Bool)
    -> SubmissionReviewDetail.SubmissionReviewDetail
    -> Html Msg
viewAuditLogDiffReadonly wikiSlug publishedSlugExists detail =
    let
        readonlyTextarea : String -> String -> String -> Html Msg
        readonlyTextarea elementId markdown extraClass =
            Html.textarea
                ([ Attr.id elementId
                 , Attr.readonly True
                 , Attr.rows 12
                 , Attr.value markdown
                 ]
                    |> UI.Textarea.markdownReadonlyWithExtra extraClass
                )
                []

        previewBox : String -> String -> Bool -> Html Msg
        previewBox previewId markdown faded =
            Html.div
                [ Attr.class
                    (if faded then
                        "h-full max-h-none opacity-75"

                     else
                        "h-full max-h-none"
                    )
                , UI.markdownPreviewScrollMinFlexFullHeightAttr
                , Attr.class "px-4 pt-2"
                ]
                [ PageMarkdown.viewPreview previewId wikiSlug publishedSlugExists markdown ]

        sectionCell : String -> Html Msg -> Html Msg
        sectionCell heading body =
            Html.div [ UI.newPageEditorMarkdownPreviewCellAttr ]
                [ UI.Heading.panelHeadingSecondary
                    [ Attr.class "px-4 py-1 mb-2 border-b border-[var(--border-subtle)] min-h-7 leading-5" ]
                    [ Html.text
                        (if String.isEmpty heading then
                            " "

                         else
                            heading
                        )
                    ]
                , body
                ]

        sectionCellWithTopBorder : String -> Html Msg -> Html Msg
        sectionCellWithTopBorder heading body =
            Html.div [ UI.newPageEditorMarkdownPreviewCellAttr, Attr.class "border-t border-[var(--border-subtle)]" ]
                [ UI.Heading.panelHeadingSecondary
                    [ Attr.class "px-4 py-1 mb-2 border-b border-[var(--border-subtle)] min-h-7 leading-5" ]
                    [ Html.text
                        (if String.isEmpty heading then
                            " "

                         else
                            heading
                        )
                    ]
                , body
                ]
    in
    case detail of
        SubmissionReviewDetail.NewPageDiff body ->
            UI.EditorShell.view
                { containerAttrs = [ Attr.id "wiki-review-diff-summary", Attr.class "min-h-[28rem]" ]
                , controlsAttrs = [ Attr.class "justify-between" ]
                , controlsChildren =
                    [ Html.div [ Attr.class "min-w-[14rem] flex-1" ]
                        [ UI.contentLabel [ Attr.for "wiki-review-diff-new" ] [ Html.text "Page" ]
                        , Html.input
                            [ Attr.type_ "text"
                            , Attr.readonly True
                            , Attr.value body.pageSlug
                            , UI.formTextInputAttr
                            , Attr.style "background-color" "var(--chrome-bg)"
                            , Attr.style "color" "var(--fg-muted)"
                            , Attr.style "cursor" "not-allowed"
                            ]
                            []
                        ]
                    ]
                , contentAttrs = []
                , contentChildren =
                    [ Html.section [ Attr.class "min-w-0 min-h-0 flex flex-col bg-[var(--input-bg)]" ]
                        [ UI.PanelHeader.view { kind = UI.PanelHeader.Primary, text = "MARKDOWN" }
                        , Html.div [ Attr.class "min-h-0 flex-1" ]
                            [ sectionCell "After"
                                (readonlyTextarea "wiki-review-diff-new" body.proposedMarkdown " h-full max-h-none px-4")
                            ]
                        ]
                    , Html.section [ Attr.class "min-w-0 min-h-0 flex flex-col bg-[var(--bg)]" ]
                        [ UI.PanelHeader.view { kind = UI.PanelHeader.Secondary, text = "LIVE PREVIEW" }
                        , Html.div [ Attr.class "min-h-0 flex-1" ]
                            [ sectionCell ""
                                (previewBox "wiki-review-diff-new-preview" body.proposedMarkdown False)
                            ]
                        ]
                    ]
                }

        SubmissionReviewDetail.EditPageDiff body ->
            UI.EditorShell.view
                { containerAttrs = [ Attr.id "wiki-review-diff-summary", Attr.class "min-h-[28rem]" ]
                , controlsAttrs = [ Attr.class "justify-between" ]
                , controlsChildren = []
                , contentAttrs = []
                , contentChildren =
                    [ Html.section [ Attr.class "min-w-0 min-h-0 flex flex-col bg-[var(--input-bg)]" ]
                        [ UI.PanelHeader.view { kind = UI.PanelHeader.Primary, text = "EDITOR" }
                        , Html.div [ Attr.class "min-h-0 flex-1 grid grid-rows-2 gap-3" ]
                            [ sectionCell "Before"
                                (readonlyTextarea "wiki-review-diff-old" body.beforeMarkdown " h-full max-h-none px-4")
                            , sectionCellWithTopBorder "After"
                                (readonlyTextarea "wiki-review-diff-new" body.afterMarkdown " h-full max-h-none px-4")
                            ]
                        ]
                    , Html.section [ Attr.class "min-w-0 min-h-0 flex flex-col bg-[var(--bg)]" ]
                        [ UI.PanelHeader.view { kind = UI.PanelHeader.Secondary, text = "LIVE PREVIEW" }
                        , Html.div [ Attr.class "min-h-0 flex-1 grid grid-rows-2 gap-3" ]
                            [ sectionCell ""
                                (previewBox "wiki-review-diff-old-preview" body.beforeMarkdown True)
                            , sectionCellWithTopBorder ""
                                (previewBox "wiki-review-diff-new-preview" body.afterMarkdown False)
                            ]
                        ]
                    ]
                }

        SubmissionReviewDetail.DeletePageDiff body ->
            UI.EditorShell.view
                { containerAttrs = [ Attr.id "wiki-review-diff-summary", Attr.class "min-h-[28rem]" ]
                , controlsAttrs = []
                , controlsChildren =
                    [ case body.reason of
                        Nothing ->
                            Html.span [] []

                        Just r ->
                            Html.div [ Attr.class "min-w-[14rem] flex-1" ]
                                [ UI.contentLabel [] [ Html.text "Deletion reason" ]
                                , Html.div [ Attr.id "wiki-review-diff-reason", Attr.class "text-sm text-[var(--fg-muted)]" ] [ Html.text r ]
                                ]
                    ]
                , contentAttrs = []
                , contentChildren =
                    [ Html.section [ Attr.class "min-w-0 min-h-0 flex flex-col bg-[var(--input-bg)]" ]
                        [ UI.PanelHeader.view { kind = UI.PanelHeader.Primary, text = "MARKDOWN" }
                        , Html.div [ Attr.class "min-h-0 flex-1" ]
                            [ sectionCell "Before"
                                (readonlyTextarea "wiki-review-diff-published" body.publishedSnapshotMarkdown " h-full max-h-none px-4")
                            ]
                        ]
                    , Html.section [ Attr.class "min-w-0 min-h-0 flex flex-col bg-[var(--bg)]" ]
                        [ UI.PanelHeader.view { kind = UI.PanelHeader.Secondary, text = "LIVE PREVIEW" }
                        , Html.div [ Attr.class "min-h-0 flex-1" ]
                            [ sectionCell ""
                                (previewBox "wiki-review-diff-published-preview" body.publishedSnapshotMarkdown True)
                            ]
                        ]
                    ]
                }


viewReviewSubmissionDetailBody :
    Wiki.Slug
    -> (Page.Slug -> Bool)
    -> RemoteData () (Result SubmissionReviewDetail.ReviewSubmissionDetailError SubmissionReviewDetail.SubmissionReviewDetail)
    -> Html Msg
viewReviewSubmissionDetailBody wikiSlug publishedSlugExists remote =
    case remote of
        RemoteData.NotAsked ->
            viewWikiReviewQueueLoading

        RemoteData.Loading ->
            viewWikiReviewQueueLoading

        RemoteData.Failure _ ->
            Html.div
                [ Attr.id "wiki-review-detail-error" ]
                [ UI.contentParagraph [] [ Html.text "Could not load submission review details." ] ]

        RemoteData.Success (Err e) ->
            Html.div
                [ Attr.id "wiki-review-detail-error" ]
                [ UI.contentParagraph []
                    [ Html.text (SubmissionReviewDetail.reviewSubmissionDetailErrorToUserText e) ]
                ]

        RemoteData.Success (Ok d) ->
            viewSubmissionReviewDiff wikiSlug publishedSlugExists d


viewReviewDecisionForm : Model -> Wiki.Slug -> String -> Html Msg
viewReviewDecisionForm model wikiSlug submissionId =
    case Store.get_ ( wikiSlug, submissionId ) model.store.reviewSubmissionDetails of
        RemoteData.Success (Ok _) ->
            let
                busy : Bool
                busy =
                    model.reviewApproveDraft.inFlight
                        || model.reviewRejectDraft.inFlight
                        || model.reviewRequestChangesDraft.inFlight

                rejectDraft : ReviewRejectDraft
                rejectDraft =
                    model.reviewRejectDraft

                requestDraft : ReviewRequestChangesDraft
                requestDraft =
                    model.reviewRequestChangesDraft

                decision : ReviewDecision
                decision =
                    model.reviewDecision

                radio : String -> ReviewDecision -> Html Msg
                radio inputId option =
                    Html.input
                        [ Attr.type_ "radio"
                        , Attr.name "wiki-review-decision"
                        , Attr.id inputId
                        , Attr.checked (decision == option)
                        , Events.onClick (ReviewDecisionChanged option)
                        , Attr.disabled busy
                        ]
                        []

                requestSelected : Bool
                requestSelected =
                    decision == ReviewDecisionRequestChanges

                rejectSelected : Bool
                rejectSelected =
                    decision == ReviewDecisionReject
            in
            Html.fieldset
                [ Attr.id "wiki-review-decision"
                , UI.reviewFieldsetAttr
                ]
                [ Html.legend
                    [ UI.reviewLegendAttr ]
                    [ Html.text "Decision" ]
                , Html.div
                    [ UI.reviewRadioColumnAttr ]
                    [ Html.label
                        [ UI.reviewRadioRowAttr ]
                        [ radio "wiki-review-decision-approve" ReviewDecisionApprove
                        , Html.span [ UI.reviewOptionLabelStrongAttr ] [ Html.text "Approve" ]
                        ]
                    , Html.div
                        [ UI.reviewNestedNoteColumnAttr ]
                        [ Html.label
                            [ UI.reviewRadioRowAttr ]
                            [ radio "wiki-review-decision-request-changes" ReviewDecisionRequestChanges
                            , Html.span [ UI.reviewOptionLabelStrongAttr ] [ Html.text "Request changes" ]
                            ]
                        , Html.textarea
                            (UI.Textarea.formCompact
                                [ Attr.id "wiki-review-request-changes-note"
                                , Events.onInput ReviewRequestChangesNoteChanged
                                , Attr.disabled (busy || not requestSelected)
                                , Attr.value requestDraft.guidanceText
                                , Attr.placeholder "Guidance for the contributor (required for this action)"
                                ]
                            )
                            []
                        ]
                    , Html.div
                        [ UI.reviewNestedNoteColumnAttr ]
                        [ Html.label
                            [ UI.reviewRadioRowAttr ]
                            [ radio "wiki-review-decision-reject" ReviewDecisionReject
                            , Html.span [ UI.reviewOptionLabelStrongAttr ] [ Html.text "Reject" ]
                            ]
                        , Html.textarea
                            (UI.Textarea.formCompact
                                [ Attr.id "wiki-review-reject-reason"
                                , Events.onInput ReviewRejectReasonChanged
                                , Attr.disabled (busy || not rejectSelected)
                                , Attr.value rejectDraft.reasonText
                                , Attr.placeholder "Rejection reason (required for this action)"
                                ]
                            )
                            []
                        ]
                    ]
                , UI.Button.button
                    [ Attr.id "wiki-review-decision-submit"
                    , Attr.type_ "button"
                    , Events.onClick ReviewDecisionSubmitted
                    , Attr.disabled busy
                    ]
                    [ Html.text "Submit" ]
                , case model.reviewApproveDraft.lastResult of
                    Nothing ->
                        Html.text ""

                    Just (Ok ()) ->
                        Html.div
                            [ Attr.id "wiki-review-approve-success" ]
                            [ Html.text "Submission approved and published." ]

                    Just (Err e) ->
                        Html.div
                            [ Attr.id "wiki-review-approve-error" ]
                            [ Html.text (Submission.approveSubmissionErrorToUserText e) ]
                , case rejectDraft.lastResult of
                    Nothing ->
                        Html.text ""

                    Just (Ok ()) ->
                        Html.div
                            [ Attr.id "wiki-review-reject-success" ]
                            [ Html.text "Submission rejected." ]

                    Just (Err e) ->
                        Html.div
                            [ Attr.id "wiki-review-reject-error" ]
                            [ Html.text (Submission.rejectSubmissionErrorToUserText e) ]
                , case requestDraft.lastResult of
                    Nothing ->
                        Html.text ""

                    Just (Ok ()) ->
                        Html.div
                            [ Attr.id "wiki-review-request-changes-success" ]
                            [ Html.text "Revision requested." ]

                    Just (Err e) ->
                        Html.div
                            [ Attr.id "wiki-review-request-changes-error" ]
                            [ Html.text (Submission.requestChangesSubmissionErrorToUserText e) ]
                ]

        _ ->
            Html.text ""


viewReviewDetailRoute : Model -> Wiki.Slug -> String -> Html Msg
viewReviewDetailRoute model wikiSlug submissionId =
    case Store.get_ wikiSlug model.store.wikiDetails of
        RemoteData.Success wikiDetails ->
            case Store.get wikiSlug model.store.wikiCatalog of
                RemoteData.Success _ ->
                    Html.div
                        [ Attr.id "wiki-review-detail-page"
                        , Attr.attribute "data-wiki-slug" wikiSlug
                        , Attr.attribute "data-submission-id" submissionId
                        ]
                        [ viewReviewSubmissionDetailBody
                            wikiSlug
                            (publishedSlugExistsFromWikiDetails wikiDetails)
                            (Store.get_ ( wikiSlug, submissionId ) model.store.reviewSubmissionDetails)
                        , viewReviewDecisionForm model wikiSlug submissionId
                        ]

                RemoteData.Failure _ ->
                    viewNotFound

                RemoteData.Loading ->
                    viewWikiReviewQueueLoading

                RemoteData.NotAsked ->
                    viewWikiReviewQueueLoading

        RemoteData.Failure _ ->
            viewNotFound

        RemoteData.Loading ->
            viewWikiReviewQueueLoading

        RemoteData.NotAsked ->
            viewWikiReviewQueueLoading


viewSubmissionDetailRoute : Model -> Wiki.Slug -> String -> Html Msg
viewSubmissionDetailRoute model wikiSlug submissionId =
    case Store.get_ wikiSlug model.store.wikiDetails of
        RemoteData.Success wikiDetails ->
            case Store.get wikiSlug model.store.wikiCatalog of
                RemoteData.Success _ ->
                    Html.div
                        [ Attr.id "wiki-submission-detail-page"
                        , Attr.attribute "data-wiki-slug" wikiSlug
                        , Attr.attribute "data-submission-id" submissionId
                        ]
                        [ viewSubmissionDetailBody
                            wikiSlug
                            (publishedSlugExistsFromWikiDetails wikiDetails)
                            model.submissionDetailEditDraft
                            (Store.get_ ( wikiSlug, submissionId ) model.store.submissionDetails)
                        ]

                RemoteData.Failure _ ->
                    viewNotFound

                RemoteData.Loading ->
                    viewWikiSubmitNewLoading

                RemoteData.NotAsked ->
                    viewWikiSubmitNewLoading

        RemoteData.Failure _ ->
            viewNotFound

        RemoteData.Loading ->
            viewWikiSubmitNewLoading

        RemoteData.NotAsked ->
            viewWikiSubmitNewLoading


viewBacklinks : Wiki.Slug -> List Page.Slug -> Html Msg
viewBacklinks wikiSlug backlinks =
    UI.SidebarSection.section
        { id = "page-backlinks"
        , title = "Backlinks"
        , body =
            if List.isEmpty backlinks then
                Html.p
                    [ Attr.id "page-backlinks-empty"
                    , UI.sidebarM0Attr
                    ]
                    [ Html.text "No backlinks." ]

            else
                Html.ul
                    [ Attr.id "page-backlinks-list"
                    , UI.backlinksListAttr
                    , UI.sidebarNavHorizontalIndentAttr
                    ]
                    (backlinks
                        |> List.map
                            (\slug ->
                                UI.Link.listItemTight []
                                    [ UI.Link.sidebarLink
                                        [ Attr.href (Wiki.publishedPageUrlPath wikiSlug slug)
                                        , Attr.attribute "data-backlink-page-slug" slug
                                        ]
                                        [ UI.Link.breakAllSpan [] [ Html.text slug ] ]
                                    ]
                            )
                    )
        }


viewPageTags : Wiki.Slug -> (Page.Slug -> Bool) -> List Page.Slug -> Html Msg
viewPageTags wikiSlug publishedSlugExists tags =
    UI.SidebarSection.section
        { id = "page-tags"
        , title = "Tags"
        , body =
            if List.isEmpty tags then
                Html.p
                    [ Attr.id "page-tags-empty"
                    , UI.sidebarM0Attr
                    ]
                    [ Html.text "No tags." ]

            else
                Html.ul
                    [ Attr.id "page-tags-list"
                    , UI.tagPillsListAttr
                    ]
                    (tags
                        |> List.map
                            (\slug ->
                                let
                                    exists : Bool
                                    exists =
                                        publishedSlugExists slug
                                in
                                UI.Link.listItemTight []
                                    [ Html.a
                                        [ Attr.href (Wiki.publishedPageUrlPath wikiSlug slug)
                                        , Attr.attribute "data-tag-page-slug" slug
                                        , UI.tagPillAttr exists
                                        ]
                                        [ Html.text slug ]
                                    ]
                            )
                    )
        }


viewPageTodos : List String -> Html Msg
viewPageTodos todoTexts =
    UI.SidebarSection.section
        { id = "page-todos"
        , title = "TODOs:"
        , body =
            Html.ul
                [ Attr.id "page-todos-list"
                , UI.todosListDiscAttr
                ]
                (todoTexts
                    |> List.indexedMap
                        (\index todoText ->
                            Html.li
                                [ Attr.attribute "data-page-todo-index" (String.fromInt index)
                                , Attr.attribute "data-todo-text" todoText
                                , UI.classAttr "m-0 leading-[1.3]"
                                ]
                                [ Html.text todoText ]
                        )
                )
        }


maybeMySubmissionForMissingPublishedPage :
    Page.Slug
    -> RemoteData () (Result Submission.MyPendingSubmissionsError (List Submission.MyPendingSubmissionListItem))
    -> Maybe { id : Submission.Id, status : Submission.Status }
maybeMySubmissionForMissingPublishedPage pageSlug remote =
    case remote of
        Success (Ok items) ->
            items
                |> List.filter (\item -> item.maybePageSlug == Just pageSlug)
                |> List.head
                |> Maybe.map (\item -> { id = item.id, status = item.status })

        NotAsked ->
            Nothing

        Loading ->
            Nothing

        Failure _ ->
            Nothing

        Success (Err _) ->
            Nothing


missingPublishedPageNoticeLines : Submission.Status -> ( String, String )
missingPublishedPageNoticeLines status =
    case status of
        Submission.Draft ->
            ( "You have a saved draft for this page."
            , "It is not on the public index until you submit it for review and a reviewer approves it."
            )

        Submission.Pending ->
            ( "You submitted this page for review."
            , "It is not on the public index yet; it becomes visible after a reviewer approves it."
            )

        Submission.NeedsRevision ->
            ( "You submitted this page for review."
            , "It is not on the public index yet; it becomes visible after a reviewer approves it."
            )

        Submission.Rejected ->
            ( "You have a submission for this page that was rejected."
            , "Open the submission below to revise or delete it."
            )

        Submission.Approved ->
            ( "", "" )


viewMissingPublishedPage :
    Wiki.Slug
    -> Page.Slug
    -> List Page.Slug
    -> Maybe Wiki.Slug
    -> RemoteData () (Result Submission.MyPendingSubmissionsError (List Submission.MyPendingSubmissionListItem))
    -> Wiki.FrontendDetails
    -> Html Msg
viewMissingPublishedPage wikiSlug pageSlug taggedPageSlugs maybeContributorWiki myPendingRemote wikiDetails =
    let
        maybeMyRow : Maybe { id : Submission.Id, status : Submission.Status }
        maybeMyRow =
            case maybeContributorWiki of
                Just sessionWiki ->
                    if sessionWiki == wikiSlug then
                        maybeMySubmissionForMissingPublishedPage pageSlug myPendingRemote

                    else
                        Nothing

                Nothing ->
                    Nothing

        pendingSection : Html Msg
        pendingSection =
            case maybeContributorWiki of
                Just sessionWiki ->
                    if sessionWiki /= wikiSlug then
                        Html.text ""

                    else
                        case myPendingRemote of
                            Loading ->
                                UI.contentParagraph
                                    [ Attr.id "wiki-missing-published-pending-loading" ]
                                    [ Html.text "Loading your submission status…" ]

                            Success (Ok _) ->
                                case maybeMyRow of
                                    Just row ->
                                        let
                                            idStr : String
                                            idStr =
                                                Submission.idToString row.id

                                            ( line1, line2 ) =
                                                missingPublishedPageNoticeLines row.status
                                        in
                                        Html.div
                                            [ Attr.id "wiki-missing-published-pending-notice"
                                            , Attr.attribute "data-pending-submission-id" idStr
                                            , Attr.attribute "data-missing-page-submission-status" (Submission.statusLabelUserText row.status)
                                            ]
                                            (List.concat
                                                [ if String.isEmpty line1 then
                                                    []

                                                  else
                                                    [ UI.contentParagraph [] [ Html.text line1 ] ]
                                                , if String.isEmpty line2 then
                                                    []

                                                  else
                                                    [ UI.contentParagraph [] [ Html.text line2 ] ]
                                                , [ UI.contentParagraph []
                                                        [ UI.Link.contentLink
                                                            [ Attr.id "wiki-missing-published-open-submission-link"
                                                            , Attr.href (Wiki.submissionDetailUrlPath wikiSlug idStr)
                                                            ]
                                                            [ Html.text "Open submission" ]
                                                        ]
                                                  ]
                                                ]
                                            )

                                    Nothing ->
                                        Html.text ""

                            Success (Err _) ->
                                Html.text ""

                            Failure _ ->
                                Html.text ""

                            NotAsked ->
                                Html.text ""

                Nothing ->
                    Html.text ""

        contributorCreateOrLogin : Html Msg
        contributorCreateOrLogin =
            case maybeContributorWiki of
                Just sessionWiki ->
                    if sessionWiki == wikiSlug then
                        if maybeMyRow /= Nothing then
                            Html.text ""

                        else
                            UI.contentParagraph []
                                [ UI.Link.contentLink
                                    [ Attr.id "wiki-missing-published-create-link"
                                    , Attr.href (Wiki.submitNewPageUrlPathWithSuggestedSlug wikiSlug pageSlug)
                                    ]
                                    [ Html.text "Create this page" ]
                                ]

                    else
                        UI.contentParagraph []
                            [ Html.text "Log in on this wiki to create it. "
                            , UI.Link.contentLink
                                [ Attr.id "wiki-missing-published-login-link"
                                , Attr.href (Wiki.loginUrlPath wikiSlug)
                                ]
                                [ Html.text "Log in" ]
                            ]

                Nothing ->
                    UI.contentParagraph []
                        [ UI.Link.contentLink
                            [ Attr.id "wiki-missing-published-login-link"
                            , Attr.href
                                (Wiki.loginUrlPathWithRedirect wikiSlug
                                    (Wiki.submitNewPageUrlPathWithSuggestedSlug wikiSlug pageSlug)
                                )
                            ]
                            [ Html.text "Log in to create this page" ]
                        ]

        taggedSection : Html Msg
        taggedSection =
            viewTaggedPagesWithTag wikiSlug taggedPageSlugs

        graphSection : Html Msg
        graphSection =
            Html.div
                [ Attr.id "wiki-missing-published-page-graph"
                , UI.wikiRightRailTocNudgeAttr
                ]
                [ immediatePublishedPageGraphviz "wiki-missing-published-graphviz" wikiSlug pageSlug wikiDetails
                ]
    in
    Html.div
        [ Attr.id "wiki-missing-published-page"
        , Attr.attribute "data-wiki-slug" wikiSlug
        , Attr.attribute "data-page-slug" pageSlug
        ]
        [ Html.h1
            [ UI.classAttr "m-0 mb-[0.75rem] [font-family:var(--font-serif)] text-[2rem] leading-[1.2] font-semibold text-[var(--fg)] break-words" ]
            [ Html.text pageSlug ]
        , UI.contentParagraph []
            [ Html.text "This page does not exist yet." ]
        , contributorCreateOrLogin
        , graphSection
        , pendingSection
        , taggedSection
        ]


viewTaggedPagesWithTag : Wiki.Slug -> List Page.Slug -> Html Msg
viewTaggedPagesWithTag wikiSlug taggedPageSlugs =
    if List.isEmpty taggedPageSlugs then
        Html.text ""

    else
        Html.section
            [ Attr.id "page-tagged-pages"
            , UI.pageActionsTopBorderBlockAttr
            ]
            [ UI.contentParagraph
                [ UI.sidebarTocListRootAttr ]
                [ Html.text "Pages with this tag: "
                , Html.span []
                    (taggedPageSlugs
                        |> List.map
                            (\slug ->
                                UI.Link.contentLink
                                    [ Attr.href (Wiki.publishedPageUrlPath wikiSlug slug)
                                    , Attr.attribute "data-tagged-page-slug" slug
                                    ]
                                    [ Html.text slug ]
                            )
                        |> List.intersperse (Html.text ", ")
                    )
                ]
            ]


viewPublishedPage : Wiki.Slug -> Page.Slug -> Page.FrontendDetails -> (Page.Slug -> Bool) -> Html Msg
viewPublishedPage wikiSlug pageSlug pageDetails publishedSlugExists =
    Html.div
        [ Attr.id "page-published-page"
        , Attr.attribute "data-wiki-slug" wikiSlug
        , Attr.attribute "data-page-slug" pageSlug
        ]
        [ PageMarkdown.view wikiSlug publishedSlugExists pageDetails
        , viewTaggedPagesWithTag wikiSlug pageDetails.taggedPageSlugs
        ]


viewPublishedPageRoute : Model -> Wiki.Slug -> Page.Slug -> Html Msg
viewPublishedPageRoute model wikiSlug pageSlug =
    case Store.get_ wikiSlug model.store.wikiDetails of
        RemoteData.NotAsked ->
            viewWikiHomeLoading

        RemoteData.Loading ->
            viewWikiHomeLoading

        RemoteData.Failure _ ->
            viewNotFound

        RemoteData.Success wikiDetails ->
            case Store.get wikiSlug model.store.wikiCatalog of
                RemoteData.NotAsked ->
                    viewWikiHomeLoading

                RemoteData.Loading ->
                    viewWikiHomeLoading

                RemoteData.Failure _ ->
                    viewNotFound

                RemoteData.Success _ ->
                    case Store.get_ ( wikiSlug, pageSlug ) model.store.publishedPages of
                        RemoteData.NotAsked ->
                            viewWikiHomeLoading

                        RemoteData.Loading ->
                            viewWikiHomeLoading

                        RemoteData.Success pageDetails ->
                            case pageDetails.maybeMarkdownSource of
                                Just _ ->
                                    viewPublishedPage wikiSlug pageSlug pageDetails (publishedSlugExistsFromWikiDetails wikiDetails)

                                Nothing ->
                                    viewMissingPublishedPage wikiSlug
                                        pageSlug
                                        pageDetails.taggedPageSlugs
                                        (if Dict.member wikiSlug model.contributorWikiSessions then
                                            Just wikiSlug

                                         else
                                            Nothing
                                        )
                                        (if Dict.member wikiSlug model.contributorWikiSessions then
                                            Store.get_ wikiSlug model.store.myPendingSubmissions

                                         else
                                            NotAsked
                                        )
                                        wikiDetails

                        RemoteData.Failure _ ->
                            viewMissingPublishedPage wikiSlug
                                pageSlug
                                []
                                (if Dict.member wikiSlug model.contributorWikiSessions then
                                    Just wikiSlug

                                 else
                                    Nothing
                                )
                                (if Dict.member wikiSlug model.contributorWikiSessions then
                                    Store.get_ wikiSlug model.store.myPendingSubmissions

                                 else
                                    NotAsked
                                )
                                wikiDetails


viewWikiTodosRoute : Model -> Wiki.Slug -> Html Msg
viewWikiTodosRoute model wikiSlug =
    case Store.get_ wikiSlug model.store.wikiDetails of
        RemoteData.NotAsked ->
            viewWikiHomeLoading

        RemoteData.Loading ->
            viewWikiHomeLoading

        RemoteData.Failure _ ->
            viewNotFound

        RemoteData.Success wikiDetails ->
            case Store.get wikiSlug model.store.wikiCatalog of
                RemoteData.NotAsked ->
                    viewWikiHomeLoading

                RemoteData.Loading ->
                    viewWikiHomeLoading

                RemoteData.Failure _ ->
                    viewNotFound

                RemoteData.Success _ ->
                    viewWikiTodosPage wikiSlug wikiDetails


viewWikiTodosPage : Wiki.Slug -> Wiki.FrontendDetails -> Html Msg
viewWikiTodosPage wikiSlug wikiDetails =
    let
        todoSummary : WikiTodos.Summary
        todoSummary =
            WikiTodos.summary wikiSlug wikiDetails.publishedPageMarkdownSources

        combinedRows :
            List
                { itemText : String
                , usedInPageSlugs : List Page.Slug
                , maybeTodoText : Maybe String
                , maybeMissingPageSlug : Maybe Page.Slug
                }
        combinedRows =
            List.concat
                [ todoSummary.todos
                    |> List.map
                        (\row ->
                            { itemText = row.todoText
                            , usedInPageSlugs = [ row.pageSlug ]
                            , maybeTodoText = Just row.todoText
                            , maybeMissingPageSlug = Nothing
                            }
                        )
                , todoSummary.missingPages
                    |> List.sortBy
                        (\row ->
                            ( negate (List.length row.linkedFromPageSlugs)
                            , String.toLower row.missingPageSlug
                            )
                        )
                    |> List.map
                        (\row ->
                            { itemText = row.missingPageSlug
                            , usedInPageSlugs = row.linkedFromPageSlugs
                            , maybeTodoText = Nothing
                            , maybeMissingPageSlug = Just row.missingPageSlug
                            }
                        )
                ]

        pageLink : Page.Slug -> Html Msg
        pageLink pageSlug =
            UI.Link.contentLink
                [ Attr.href (Wiki.publishedPageUrlPath wikiSlug pageSlug) ]
                [ Html.text pageSlug ]

        commaSeparatedPageLinks : List Page.Slug -> List (Html Msg)
        commaSeparatedPageLinks pageSlugs =
            pageSlugs
                |> List.map pageLink
                |> List.intersperse (Html.text ", ")
    in
    Html.div
        [ Attr.id "wiki-todos-page"
        , Attr.attribute "data-wiki-slug" wikiSlug
        ]
        [ if List.isEmpty combinedRows then
            UI.contentParagraph
                [ Attr.id "wiki-todos-empty" ]
                [ Html.text "No TODOs or missing linked pages found." ]

          else
            UI.table UI.TableFullMax72
                [ Attr.id "wiki-todos-table" ]
                { theadAttrs = []
                , headerRowAttrs = []
                , headerAlign = UI.TableAlignMiddle
                , headers =
                    [ UI.tableHeaderText "Item"
                    , UI.tableHeaderText "Used in"
                    ]
                , tbodyAttrs = [ Attr.id "wiki-todos-tbody" ]
                , rows =
                    combinedRows
                        |> List.map
                            (\row ->
                                UI.trStriped
                                    (List.concat
                                        [ [ Attr.attribute "data-item-text" row.itemText ]
                                        , row.maybeTodoText
                                            |> Maybe.map (\todoText -> [ Attr.attribute "data-todo-text" todoText ])
                                            |> Maybe.withDefault []
                                        , row.maybeMissingPageSlug
                                            |> Maybe.map (\missingPageSlug -> [ Attr.attribute "data-missing-page-slug" missingPageSlug ])
                                            |> Maybe.withDefault []
                                        ]
                                    )
                                    [ UI.tableTdSerif UI.TableAlignMiddle
                                        []
                                        [ case row.maybeMissingPageSlug of
                                            Just missingPageSlug ->
                                                UI.Link.missingLink
                                                    [ Attr.href (Wiki.publishedPageUrlPath wikiSlug missingPageSlug) ]
                                                    [ Html.text row.itemText ]

                                            Nothing ->
                                                Html.text row.itemText
                                        ]
                                    , UI.tableTd UI.TableAlignMiddle
                                        []
                                        [ Html.span
                                            [ Attr.attribute "data-used-in" row.itemText ]
                                            (commaSeparatedPageLinks row.usedInPageSlugs)
                                        ]
                                    ]
                            )
                }
        ]


type alias SearchExcerpt =
    { before : String
    , match : String
    , after : String
    }


excerptFromMarkdown : String -> String -> SearchExcerpt
excerptFromMarkdown rawQuery markdown =
    let
        query : String
        query =
            String.trim rawQuery |> String.toLower

        plainText : String
        plainText =
            markdownToPlainText markdown

        lowerPlainText : String
        lowerPlainText =
            String.toLower plainText
    in
    if String.isEmpty query then
        if String.length plainText > 140 then
            { before = String.left 140 plainText ++ "…"
            , match = ""
            , after = ""
            }

        else
            { before = plainText
            , match = ""
            , after = ""
            }

    else
        case String.indexes query lowerPlainText |> List.head of
            Just start ->
                let
                    prefixStart : Int
                    prefixStart =
                        Basics.max 0 (start - 55)

                    endPos : Int
                    endPos =
                        Basics.min (String.length plainText) (start + String.length query + 85)

                    prefix : String
                    prefix =
                        if prefixStart > 0 then
                            "…"

                        else
                            ""

                    suffix : String
                    suffix =
                        if endPos < String.length plainText then
                            "…"

                        else
                            ""
                in
                { before = prefix ++ String.slice prefixStart start plainText
                , match = String.slice start (start + String.length query) plainText
                , after = String.slice (start + String.length query) endPos plainText ++ suffix
                }

            Nothing ->
                if String.length plainText > 140 then
                    { before = String.left 140 plainText ++ "…"
                    , match = ""
                    , after = ""
                    }

                else
                    { before = plainText
                    , match = ""
                    , after = ""
                    }


markdownToPlainText : String -> String
markdownToPlainText markdown =
    case
        MarkdownParser.parse markdown
            |> Result.mapError (List.map MarkdownParser.deadEndToString >> String.join "\n")
            |> Result.andThen (MarkdownRenderer.render plainTextRenderer)
    of
        Ok lines ->
            lines
                |> String.join ""
                |> String.words
                |> String.join " "

        Err _ ->
            markdown
                |> String.words
                |> String.join " "


plainTextRenderer : MarkdownRenderer.Renderer String
plainTextRenderer =
    { heading = \{ children } -> String.join "" children ++ " "
    , paragraph = \children -> String.join "" children ++ " "
    , blockQuote = \children -> String.join "" children ++ " "
    , codeSpan = identity
    , link = \_ children -> String.join "" children
    , unorderedList =
        \items ->
            items
                |> List.map
                    (\item ->
                        case item of
                            Block.ListItem _ children ->
                                String.join "" children
                    )
                |> String.join " "
                |> (\s -> s ++ " ")
    , orderedList =
        \_ items ->
            items
                |> List.map (String.join "")
                |> String.join " "
                |> (\s -> s ++ " ")
    , table =
        \children ->
            String.join " " children ++ " "
    , tableHeader = String.join " "
    , tableBody = String.join " "
    , tableRow = String.join " "
    , tableHeaderCell =
        \_ children ->
            String.join "" children
    , tableCell =
        \_ children ->
            String.join "" children
    , codeBlock =
        \{ body } ->
            body ++ " "
    , html = Markdown.Html.oneOf []
    , thematicBreak = " "
    , text = identity
    , strong = String.join ""
    , emphasis = String.join ""
    , strikethrough = String.join ""
    , hardLineBreak = " "
    , image = \image -> image.alt
    }


viewSearchExcerpt : SearchExcerpt -> Html Msg
viewSearchExcerpt excerpt =
    Html.span []
        [ Html.text excerpt.before
        , if String.isEmpty excerpt.match then
            Html.text ""

          else
            Html.mark
                [ Attr.class "bg-yellow-200 text-[inherit] px-[0.05rem] rounded-[0.1rem]" ]
                [ Html.text excerpt.match ]
        , Html.text excerpt.after
        ]


viewHighlightedText : String -> String -> Html Msg
viewHighlightedText rawQuery text =
    let
        query : String
        query =
            String.trim rawQuery |> String.toLower

        lowerText : String
        lowerText =
            String.toLower text
    in
    if String.isEmpty query then
        Html.text text

    else
        case String.indexes query lowerText |> List.head of
            Just start ->
                let
                    endPos : Int
                    endPos =
                        start + String.length query
                in
                Html.span []
                    [ Html.text (String.slice 0 start text)
                    , Html.mark
                        [ Attr.class "bg-yellow-200 text-[inherit] px-[0.05rem] rounded-[0.1rem]" ]
                        [ Html.text (String.slice start endPos text) ]
                    , Html.text (String.slice endPos (String.length text) text)
                    ]

            Nothing ->
                Html.text text


viewWikiSearchRoute : Model -> Wiki.Slug -> Html Msg
viewWikiSearchRoute model wikiSlug =
    case Store.get_ wikiSlug model.store.wikiDetails of
        RemoteData.NotAsked ->
            viewWikiHomeLoading

        RemoteData.Loading ->
            viewWikiHomeLoading

        RemoteData.Failure _ ->
            viewNotFound

        RemoteData.Success wikiDetails ->
            case Store.get wikiSlug model.store.wikiCatalog of
                RemoteData.NotAsked ->
                    viewWikiHomeLoading

                RemoteData.Loading ->
                    viewWikiHomeLoading

                RemoteData.Failure _ ->
                    viewNotFound

                RemoteData.Success _ ->
                    let
                        query : String
                        query =
                            String.trim model.wikiSearchPageQuery

                        results : List WikiSearch.ResultItem
                        results =
                            WikiSearch.search query wikiDetails.publishedPageMarkdownSources
                    in
                    Html.div
                        [ Attr.id "wiki-search-page"
                        , Attr.attribute "data-wiki-slug" wikiSlug
                        ]
                        [ if String.isEmpty query then
                            Html.div [ Attr.class "space-y-3" ]
                                [ Html.input
                                    [ Attr.id "wiki-search-input"
                                    , Attr.type_ "search"
                                    , Attr.placeholder "Search this wiki..."
                                    , Attr.value model.wikiSearchPageQuery
                                    , Events.onInput WikiSearchPageQueryChanged
                                    , Attr.class "w-full max-w-[28rem] rounded-md border border-[var(--border-subtle)] bg-[var(--bg)] px-3 py-2 text-[0.8125rem] text-[var(--fg)]"
                                    ]
                                    []
                                ]

                          else if List.isEmpty results then
                            Html.div [ Attr.class "space-y-3" ]
                                [ Html.input
                                    [ Attr.id "wiki-search-input"
                                    , Attr.type_ "search"
                                    , Attr.placeholder "Search this wiki..."
                                    , Attr.value model.wikiSearchPageQuery
                                    , Events.onInput WikiSearchPageQueryChanged
                                    , Attr.class "w-full max-w-[28rem] rounded-md border border-[var(--border-subtle)] bg-[var(--bg)] px-3 py-2 text-[0.8125rem] text-[var(--fg)]"
                                    ]
                                    []
                                , UI.contentParagraph
                                    [ Attr.id "wiki-search-no-results"
                                    , Attr.class "[font-family:var(--font-ui)] text-[0.8125rem]"
                                    ]
                                    [ Html.text "No matching pages found." ]
                                ]

                          else
                            Html.div [ Attr.class "space-y-3" ]
                                [ Html.input
                                    [ Attr.id "wiki-search-input"
                                    , Attr.type_ "search"
                                    , Attr.placeholder "Search this wiki..."
                                    , Attr.value model.wikiSearchPageQuery
                                    , Events.onInput WikiSearchPageQueryChanged
                                    , Attr.class "w-full max-w-[28rem] rounded-md border border-[var(--border-subtle)] bg-[var(--bg)] px-3 py-2 text-[0.8125rem] text-[var(--fg)]"
                                    ]
                                    []
                                , Html.p
                                    [ Attr.id "wiki-search-count"
                                    , UI.formFeedbackTextSmAttr
                                    ]
                                    [ Html.text
                                        ("Found " ++ String.fromInt (List.length results) ++ " matching pages.")
                                    ]
                                , Html.ul
                                    [ Attr.id "wiki-search-results"
                                    , UI.markdownUnorderedListAttr
                                    ]
                                    (results
                                        |> List.map
                                            (\result ->
                                                let
                                                    markdown : String
                                                    markdown =
                                                        Dict.get result.pageSlug wikiDetails.publishedPageMarkdownSources
                                                            |> Maybe.withDefault ""
                                                in
                                                Html.li
                                                    [ Attr.attribute "data-search-page-slug" result.pageSlug
                                                    , Attr.class "pb-3 mb-3 border-b border-[var(--border-subtle)] last:mb-0 last:pb-0 last:border-b-0"
                                                    ]
                                                    [ UI.Link.contentLink
                                                        [ Attr.href (Wiki.publishedPageUrlPath wikiSlug result.pageSlug) ]
                                                        [ Html.span [ Attr.class "text-[0.8125rem]" ] [ viewHighlightedText query result.pageSlug ] ]
                                                    , Html.p
                                                        [ Attr.class "m-0 text-[0.85rem] text-[var(--fg-muted)]" ]
                                                        [ excerptFromMarkdown query
                                                            markdown
                                                            |> viewSearchExcerpt
                                                        ]
                                                    ]
                                            )
                                    )
                                ]
                        ]


viewWikiGraphRoute : Model -> Wiki.Slug -> Html Msg
viewWikiGraphRoute model wikiSlug =
    case Store.get_ wikiSlug model.store.wikiDetails of
        RemoteData.NotAsked ->
            viewWikiHomeLoading

        RemoteData.Loading ->
            viewWikiHomeLoading

        RemoteData.Failure _ ->
            viewNotFound

        RemoteData.Success wikiDetails ->
            case Store.get wikiSlug model.store.wikiCatalog of
                RemoteData.NotAsked ->
                    viewWikiHomeLoading

                RemoteData.Loading ->
                    viewWikiHomeLoading

                RemoteData.Failure _ ->
                    viewNotFound

                RemoteData.Success _ ->
                    viewWikiGraphPage wikiSlug wikiDetails


viewWikiGraphPage : Wiki.Slug -> Wiki.FrontendDetails -> Html Msg
viewWikiGraphPage wikiSlug wikiDetails =
    let
        graphSummary : WikiGraph.Summary
        graphSummary =
            WikiGraph.summary wikiSlug wikiDetails.publishedPageMarkdownSources wikiDetails.publishedPageTags
    in
    Html.div
        [ Attr.id "wiki-graph-page"
        , Attr.attribute "data-wiki-slug" wikiSlug
        ]
        [ if List.isEmpty graphSummary.publishedPageSlugs then
            UI.contentParagraph
                [ Attr.id "wiki-graph-empty" ]
                [ Html.text "No published pages to graph yet." ]

          else
            let
                graphData =
                    WikiGraph.graph wikiSlug wikiDetails.publishedPageMarkdownSources wikiDetails.publishedPageTags
            in
            UI.Graph.view
                { id = "wiki-graphviz"
                , graph = graphData
                , attrs =
                    [ Attr.attribute "data-graphviz-pages" (String.fromInt (List.length graphSummary.publishedPageSlugs))
                    , Attr.attribute "data-graphviz-edges" (String.fromInt (List.length graphSummary.edges))
                    ]
                }
        ]


viewPublishedPageGraphRoute : Model -> Wiki.Slug -> Page.Slug -> Html Msg
viewPublishedPageGraphRoute model wikiSlug pageSlug =
    case Store.get_ wikiSlug model.store.wikiDetails of
        RemoteData.NotAsked ->
            viewWikiHomeLoading

        RemoteData.Loading ->
            viewWikiHomeLoading

        RemoteData.Failure _ ->
            viewNotFound

        RemoteData.Success wikiDetails ->
            case Store.get wikiSlug model.store.wikiCatalog of
                RemoteData.NotAsked ->
                    viewWikiHomeLoading

                RemoteData.Loading ->
                    viewWikiHomeLoading

                RemoteData.Failure _ ->
                    viewNotFound

                RemoteData.Success _ ->
                    case Store.get_ ( wikiSlug, pageSlug ) model.store.publishedPages of
                        RemoteData.NotAsked ->
                            viewWikiHomeLoading

                        RemoteData.Loading ->
                            viewWikiHomeLoading

                        RemoteData.Failure _ ->
                            viewMissingPublishedPage wikiSlug pageSlug [] Nothing NotAsked wikiDetails

                        RemoteData.Success _ ->
                            viewPublishedPageGraphPage wikiSlug pageSlug wikiDetails


{-| Shared copy under `WikiPageGraph` (`/pg/`) and missing published page (`/p/`).
-}
immediatePublishedPageGraphDescription : Html Msg
immediatePublishedPageGraphDescription =
    UI.contentParagraph []
        [ Html.text "Legend: Red pages are missing; tag edges are purple dashed." ]


immediatePublishedPageGraphviz : String -> Wiki.Slug -> Page.Slug -> Wiki.FrontendDetails -> Html Msg
immediatePublishedPageGraphviz graphvizId wikiSlug pageSlug wikiDetails =
    let
        graphData =
            PageGraph.graph wikiSlug pageSlug wikiDetails.publishedPageMarkdownSources wikiDetails.publishedPageTags
    in
    UI.Graph.view
        { id = graphvizId
        , graph = graphData
        , attrs = []
        }


viewPublishedPageGraphPage : Wiki.Slug -> Page.Slug -> Wiki.FrontendDetails -> Html Msg
viewPublishedPageGraphPage wikiSlug pageSlug wikiDetails =
    Html.div
        [ Attr.id "page-immediate-graph-page"
        , Attr.attribute "data-wiki-slug" wikiSlug
        , Attr.attribute "data-page-slug" pageSlug
        ]
        [ Html.h1
            [ UI.classAttr "m-0 mb-[0.75rem] [font-family:var(--font-serif)] text-[2rem] leading-[1.2] font-semibold text-[var(--fg)] break-words" ]
            [ Html.text pageSlug ]
        , immediatePublishedPageGraphDescription
        , immediatePublishedPageGraphviz "page-immediate-graphviz" wikiSlug pageSlug wikiDetails
        ]


viewBody : Model -> Html Msg
viewBody model =
    case model.route of
        Route.WikiList ->
            viewWikiListBody model.store

        Route.HostAdmin _ ->
            viewHostAdminLogin model

        Route.HostAdminWikis ->
            viewHostAdminWikis model

        Route.HostAdminWikiNew ->
            viewHostAdminCreateWiki model

        Route.HostAdminWikiDetail _ ->
            viewHostAdminWikiDetail model

        Route.HostAdminAudit ->
            viewHostAdminAudit model

        Route.HostAdminAuditDiff wikiSlug atMillis ->
            viewHostAdminAuditDiffRoute wikiSlug atMillis model

        Route.HostAdminBackup ->
            viewHostAdminBackupPage model

        Route.WikiHome slug ->
            viewWikiHomeRoute model slug

        Route.WikiTodos wikiSlug ->
            viewWikiTodosRoute model wikiSlug

        Route.WikiGraph wikiSlug ->
            viewWikiGraphRoute model wikiSlug

        Route.WikiSearch wikiSlug ->
            viewWikiSearchRoute model wikiSlug

        Route.WikiPage wikiSlug pageSlug ->
            viewPublishedPageRoute model wikiSlug pageSlug

        Route.WikiPageGraph wikiSlug pageSlug ->
            viewPublishedPageGraphRoute model wikiSlug pageSlug

        Route.WikiRegister slug ->
            viewRegisterRoute model slug

        Route.WikiLogin slug _ ->
            viewLoginRoute model slug

        Route.WikiSubmitNew slug ->
            viewSubmitNewRoute model slug

        Route.WikiSubmitEdit wikiSlug pageSlug ->
            viewSubmitEditRoute model wikiSlug pageSlug

        Route.WikiSubmitDelete wikiSlug pageSlug ->
            viewSubmitDeleteRoute model wikiSlug pageSlug

        Route.WikiSubmissionDetail wikiSlug submissionId ->
            viewSubmissionDetailRoute model wikiSlug submissionId

        Route.WikiMySubmissions wikiSlug ->
            viewMySubmissionsRoute model wikiSlug

        Route.WikiReview wikiSlug ->
            viewReviewQueueRoute model wikiSlug

        Route.WikiReviewDetail wikiSlug submissionId ->
            viewReviewDetailRoute model wikiSlug submissionId

        Route.WikiAdminUsers wikiSlug ->
            viewWikiAdminUsersRoute model wikiSlug

        Route.WikiAdminAudit wikiSlug ->
            viewWikiAdminAuditRoute model wikiSlug

        Route.WikiAdminAuditDiff wikiSlug atMillis ->
            case Store.get_ wikiSlug model.store.wikiDetails of
                RemoteData.Success wikiDetails ->
                    viewWikiAdminAuditDiffRoute wikiSlug wikiDetails atMillis model

                RemoteData.Failure _ ->
                    viewNotFound

                RemoteData.Loading ->
                    viewWikiAdminAuditLoading

                RemoteData.NotAsked ->
                    viewWikiAdminAuditLoading

        Route.NotFound _ ->
            viewNotFound


articleTocEntries : Model -> List PageToc.Entry
articleTocEntries model =
    case model.route of
        Route.WikiPage wikiSlug pageSlug ->
            case
                ( Store.get_ wikiSlug model.store.wikiDetails
                , Store.get wikiSlug model.store.wikiCatalog
                , Store.get_ ( wikiSlug, pageSlug ) model.store.publishedPages
                )
            of
                ( Success wikiDetails, Success _, Success pageDetails ) ->
                    PageToc.entries wikiSlug (publishedSlugExistsFromWikiDetails wikiDetails) pageDetails

                _ ->
                    []

        _ ->
            []


publishedPageTodos : Model -> Maybe (Html Msg)
publishedPageTodos model =
    case model.route of
        Route.WikiPage wikiSlug pageSlug ->
            case
                ( Store.get_ wikiSlug model.store.wikiDetails
                , Store.get wikiSlug model.store.wikiCatalog
                , Store.get_ ( wikiSlug, pageSlug ) model.store.publishedPages
                )
            of
                ( Success _, Success _, Success pageDetails ) ->
                    case pageDetails.maybeMarkdownSource of
                        Nothing ->
                            Nothing

                        Just markdownSource ->
                            let
                                todoTexts : List String
                                todoTexts =
                                    PageTodos.todoTexts markdownSource
                            in
                            if List.isEmpty todoTexts then
                                Nothing

                            else
                                Just (viewPageTodos todoTexts)

                _ ->
                    Nothing

        _ ->
            Nothing


publishedPageTags : Model -> Maybe (Html Msg)
publishedPageTags model =
    case model.route of
        Route.WikiPage wikiSlug pageSlug ->
            case
                ( Store.get_ wikiSlug model.store.wikiDetails
                , Store.get wikiSlug model.store.wikiCatalog
                , Store.get_ ( wikiSlug, pageSlug ) model.store.publishedPages
                )
            of
                ( Success wikiDetails, Success _, Success pageDetails ) ->
                    if List.isEmpty pageDetails.tags then
                        Nothing

                    else
                        Just (viewPageTags wikiSlug (publishedSlugExistsFromWikiDetails wikiDetails) pageDetails.tags)

                _ ->
                    Nothing

        _ ->
            Nothing


publishedPageBacklinks : Model -> Maybe (Html Msg)
publishedPageBacklinks model =
    case model.route of
        Route.WikiPage wikiSlug pageSlug ->
            case
                ( Store.get_ wikiSlug model.store.wikiDetails
                , Store.get wikiSlug model.store.wikiCatalog
                , Store.get_ ( wikiSlug, pageSlug ) model.store.publishedPages
                )
            of
                ( Success _, Success _, Success pageDetails ) ->
                    if List.isEmpty pageDetails.backlinks then
                        Nothing

                    else
                        Just (viewBacklinks wikiSlug pageDetails.backlinks)

                _ ->
                    Nothing

        _ ->
            Nothing


publishedPageImmediateGraphLink : Model -> Maybe (Html Msg)
publishedPageImmediateGraphLink model =
    case model.route of
        Route.WikiPage wikiSlug pageSlug ->
            case
                ( Store.get_ wikiSlug model.store.wikiDetails
                , Store.get wikiSlug model.store.wikiCatalog
                , Store.get_ ( wikiSlug, pageSlug ) model.store.publishedPages
                )
            of
                ( Success _, Success _, Success _ ) ->
                    Just
                        (Html.div [ UI.sidebarDesktopOnlyAttr ]
                            [ Html.div
                                [ UI.sidebarNavSectionBodyAttr
                                , UI.sidebarTocListIndentAttr
                                ]
                                [ UI.Link.sidebarLink
                                    [ Attr.id "page-immediate-graph-link"
                                    , Attr.href (Wiki.pageGraphUrlPath wikiSlug pageSlug)
                                    ]
                                    [ Html.text "Page graph" ]
                                ]
                            ]
                        )

                _ ->
                    Nothing

        _ ->
            Nothing


pageGraphPublishedPageLink : Model -> Maybe (Html Msg)
pageGraphPublishedPageLink model =
    case model.route of
        Route.WikiPageGraph wikiSlug pageSlug ->
            case
                ( Store.get_ wikiSlug model.store.wikiDetails
                , Store.get wikiSlug model.store.wikiCatalog
                )
            of
                ( Success _, Success _ ) ->
                    Just
                        (Html.div [ UI.sidebarDesktopOnlyAttr ]
                            [ Html.div
                                [ UI.sidebarNavSectionBodyAttr
                                , UI.sidebarTocListIndentAttr
                                ]
                                [ UI.Link.sidebarLink
                                    [ Attr.id "page-graph-page-link"
                                    , Attr.href (Wiki.publishedPageUrlPath wikiSlug pageSlug)
                                    ]
                                    [ Html.text "Page" ]
                                ]
                            ]
                        )

                _ ->
                    Nothing

        _ ->
            Nothing


publishedPageEditLink : Model -> Maybe (Html Msg)
publishedPageEditLink model =
    let
        sidebarPageActionLink : String -> String -> String -> Html Msg
        sidebarPageActionLink label hrefPath linkId =
            Html.div [ UI.sidebarDesktopOnlyAttr ]
                [ Html.div [ UI.sidebarNavSectionBodyAttr ]
                    [ UI.Link.sidebarLink
                        [ Attr.href hrefPath
                        , Attr.id linkId
                        ]
                        [ Html.text label ]
                    ]
                ]

        contributorPublishedPageActions : Wiki.Slug -> Page.Slug -> Html Msg
        contributorPublishedPageActions wikiSlug pageSlug =
            let
                proposeOrEditLabel : String
                proposeOrEditLabel =
                    if wikiSessionTrustedOnWiki wikiSlug model then
                        "Edit page"

                    else
                        "Propose edit"
            in
            Html.div
                [ UI.sidebarNavSectionBodyAttr
                , UI.sidebarTocListIndentAttr
                ]
                [ UI.Link.sidebarLink
                    [ Attr.href (Wiki.submitEditUrlPath wikiSlug pageSlug)
                    , Attr.id "wiki-page-propose-edit"
                    ]
                    [ Html.text proposeOrEditLabel ]
                , UI.Link.sidebarLink
                    [ Attr.href (Wiki.submitDeleteUrlPath wikiSlug pageSlug)
                    , Attr.id
                        (if wikiSessionTrustedOnWiki wikiSlug model then
                            "wiki-page-delete-published"

                         else
                            "wiki-page-request-deletion"
                        )
                    ]
                    [ Html.text
                        (if wikiSessionTrustedOnWiki wikiSlug model then
                            "Delete page"

                         else
                            "Request deletion"
                        )
                    ]
                ]
    in
    case model.route of
        Route.WikiPage wikiSlug pageSlug ->
            case
                ( Store.get_ wikiSlug model.store.wikiDetails
                , Store.get wikiSlug model.store.wikiCatalog
                , Store.get_ ( wikiSlug, pageSlug ) model.store.publishedPages
                )
            of
                ( Success _, Success _, Success pageDetails ) ->
                    case pageDetails.maybeMarkdownSource of
                        Just _ ->
                            if contributorLoggedInOnWikiSlug wikiSlug model then
                                Just (contributorPublishedPageActions wikiSlug pageSlug)

                            else
                                Just
                                    (sidebarPageActionLink
                                        "Edit page"
                                        (Wiki.submitEditUrlPath wikiSlug pageSlug)
                                        "page-edit-link"
                                    )

                        Nothing ->
                            Just
                                (sidebarPageActionLink
                                    "Create page"
                                    (Wiki.submitNewPageUrlPathWithSuggestedSlug wikiSlug pageSlug)
                                    "page-create-link"
                                )

                _ ->
                    Nothing

        _ ->
            Nothing


routeUsesAuthShell : Route -> Bool
routeUsesAuthShell route =
    case route of
        Route.WikiLogin _ _ ->
            True

        Route.HostAdmin _ ->
            True

        _ ->
            False


viewWikiRightRail : Model -> { hasRightColumn : Bool, sections : List (Html Msg) }
viewWikiRightRail model =
    let
        tocEntries : List PageToc.Entry
        tocEntries =
            articleTocEntries model

        maybeBacklinks : Maybe (Html Msg)
        maybeBacklinks =
            publishedPageBacklinks model

        maybeTags : Maybe (Html Msg)
        maybeTags =
            publishedPageTags model

        maybeTodos : Maybe (Html Msg)
        maybeTodos =
            publishedPageTodos model

        maybeTopActionLinks : Maybe (Html Msg)
        maybeTopActionLinks =
            let
                maybePageGraphLink : Maybe (Html Msg)
                maybePageGraphLink =
                    publishedPageImmediateGraphLink model

                maybePageFromGraphLink : Maybe (Html Msg)
                maybePageFromGraphLink =
                    pageGraphPublishedPageLink model

                maybeEditLink : Maybe (Html Msg)
                maybeEditLink =
                    publishedPageEditLink model

                actionLinks : List (Html Msg)
                actionLinks =
                    [ maybeEditLink
                    , maybePageGraphLink
                    , maybePageFromGraphLink
                    ]
                        |> List.filterMap identity
            in
            if List.isEmpty actionLinks then
                Nothing

            else
                Just
                    (Html.div [ UI.pageActionsSidebarStackAttr ]
                        actionLinks
                    )

        maybeTocSection : Maybe (Html Msg)
        maybeTocSection =
            if List.isEmpty tocEntries then
                Nothing

            else
                Just
                    (Html.div [ UI.sidebarDesktopOnlyAttr ]
                        [ PageToc.view tocEntries ]
                    )

        sections : List (Html Msg)
        sections =
            [ maybeTopActionLinks
            , maybeTocSection
            , maybeTags
            , maybeTodos
            , maybeBacklinks
            ]
                |> List.filterMap identity
    in
    { hasRightColumn = not (List.isEmpty sections)
    , sections = sections
    }


viewMainColumnBody : Model -> Html Msg
viewMainColumnBody model =
    if routeUsesAuditLogFillLayout model.route then
        Html.div
            [ UI.auditMainColumnBodyInnerAttr ]
            [ viewBody model ]

    else if routeUsesMainContentPadding model.route then
        Html.div
            [ UI.mainContentPaddingAttr ]
            [ viewBody model ]

    else
        viewBody model


routeUsesMainContentPadding : Route -> Bool
routeUsesMainContentPadding route =
    case route of
        Route.WikiSubmitNew _ ->
            False

        Route.WikiSubmitEdit _ _ ->
            False

        Route.HostAdminAudit ->
            False

        Route.HostAdminAuditDiff _ _ ->
            False

        Route.WikiAdminAudit _ ->
            False

        Route.WikiAdminAuditDiff _ _ ->
            False

        _ ->
            True


viewMainAppBody : Model -> List (Html Msg)
viewMainAppBody model =
    let
        rightRail : { hasRightColumn : Bool, sections : List (Html Msg) }
        rightRail =
            viewWikiRightRail model
    in
    case model.route of
        Route.WikiList ->
            [ viewAppHeader model
            , Html.div
                [ Attr.class "flex min-h-0 min-w-0 flex-1 flex-col bg-[var(--chrome-bg)]" ]
                [ Html.main_
                    [ Attr.id UI.appMainScrollRegionId
                    , Attr.class "flex-1 min-h-0 min-w-0 overflow-y-auto overscroll-contain bg-[var(--chrome-bg)] px-0 border-r-0 py-0"
                    ]
                    [ viewMainColumnBody model ]
                , viewWikiListBottomSiteAdminLink model
                ]
            ]

        _ ->
            [ viewAppHeader model
            , UI.holyGrailLayout
                { hasRightColumn = rightRail.hasRightColumn
                , trimHorizontalGutter = True
                , leftNav = viewRouteSideNav model
                , mainAttributes =
                    [ Attr.id UI.appMainScrollRegionId
                    , UI.layoutMainColumnForRouteAttr
                        { hasRightColumn = rightRail.hasRightColumn
                        , auditFill = routeUsesAuditLogFillLayout model.route
                        , trimRightPadding = True
                        , trimVerticalPadding = True
                        }
                    ]
                , mainBody = viewMainColumnBody model
                , rightRailSections = rightRail.sections
                }
            ]


view : Model -> Effect.Browser.Document Msg
view model =
    { title = documentTitle model
    , body =
        [ Html.div
            [ UI.appRootClassAttr
                { isDark =
                    case ColorTheme.effectiveColorTheme model.colorThemePreference model.systemColorTheme of
                        ColorTheme.Light ->
                            False

                        ColorTheme.Dark ->
                            True
                , trimHorizontalPadding = True
                }
            ]
            (if routeUsesAuthShell model.route then
                [ viewBody model ]

             else
                viewMainAppBody model
            )
        ]
    }

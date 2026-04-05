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
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Json.Decode
import Lamdera
import Page
import PageMarkdown
import PageToc
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
import TW
import Types exposing (FrontendModel, FrontendMsg(..), HostAdminCreateWikiDraft, HostAdminLoginDraft, HostAdminWikiDetailDraft, LoginDraft, NewPageSubmitDraft, PageDeleteSubmitDraft, PageEditSubmitDraft, RegisterDraft, ReviewApproveDraft, ReviewDecision(..), ReviewRejectDraft, ReviewRequestChangesDraft, SubmissionDetailEditDraft, ToBackend(..), ToFrontend(..), emptySubmissionDetailEditDraft)
import UI
import Url exposing (Url)
import Wiki
import WikiAdminUsers
import WikiAuditLog
import WikiRole exposing (WikiRole)


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
wikiLoadedHeaderTitle summary secondary =
    { primary = summary.name
    , primaryHref = Just (Wiki.catalogUrlPath summary)
    , secondary = secondary
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
    maybeQuery
        |> Maybe.andThen
            (\q ->
                q
                    |> String.split "&"
                    |> List.filterMap
                        (\pair ->
                            case splitQueryPair pair of
                                Just ( k, v ) ->
                                    if k == "page" then
                                        Url.percentDecode v

                                    else
                                        Nothing

                                Nothing ->
                                    Nothing
                        )
                    |> List.head
            )


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


submissionDetailMarkdownTextareaBaseClass : String
submissionDetailMarkdownTextareaBaseClass =
    UI.markdownTextareaClass
        ++ " box-border m-0 min-h-[12rem] max-h-[24rem] w-full flex-1 overflow-auto rounded border border-[var(--border)] bg-[var(--input-bg)] p-2 whitespace-pre-wrap break-words"


submissionDetailMarkdownTextareaReadonlyClass : String
submissionDetailMarkdownTextareaReadonlyClass =
    submissionDetailMarkdownTextareaBaseClass
        ++ " cursor-default resize-none text-[color:color-mix(in_srgb,var(--fg)_50%,transparent)]"


submissionDetailMarkdownTextareaEditableClass : String
submissionDetailMarkdownTextareaEditableClass =
    submissionDetailMarkdownTextareaBaseClass ++ " resize-y text-[var(--fg)]"


submissionDetailMarkdownTextareaDiffCellClass : String
submissionDetailMarkdownTextareaDiffCellClass =
    " h-full min-h-0 flex-1"


markdownPreviewScrollClass : String
markdownPreviewScrollClass =
    "max-h-[24rem] min-w-0 overflow-auto rounded border border-[var(--border)] bg-[var(--bg)] p-2"


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
                    { emptyPageEditSubmitDraft | markdownBody = details.markdownSource }

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
    Subscription.fromJs "colorThemeFromJs" Ports.colorThemeFromJs ColorThemeFromJs


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

                Route.WikiHome _ ->
                    Command.none

                Route.WikiPage _ _ ->
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
                [ Html.a
                    [ Attr.href (Route.navUrlPath link.linkRoute)
                    , TW.cls UI.sideNavPublicAdminLinkClass
                    ]
                    [ Html.text link.linkLabel ]
                ]

        _ ->
            Html.li []
                [ Html.a [ Attr.href (Route.navUrlPath link.linkRoute) ]
                    [ Html.text link.linkLabel ]
                ]


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
                    [ UI.sidebarHeading section.heading
                    , Html.div [ TW.cls UI.sidebarNavSectionBodyClass ]
                        [ Html.ul [ TW.cls UI.sideNavListClass ] section.items ]
                    ]
            )


viewSideNav : String -> List (SideNavSection Msg) -> Html Msg
viewSideNav ariaLabel sections =
    Html.nav
        [ TW.cls UI.sideNavNavClass
        , Attr.attribute "aria-label" ariaLabel
        ]
        [ Html.div [ TW.cls UI.sideNavStackClass ] (viewSideNavSections sections)
        ]


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

        Route.HostAdminBackup ->
            False

        Route.WikiHome _ ->
            False

        Route.WikiPage _ _ ->
            False

        Route.WikiLogin _ _ ->
            False

        Route.WikiRegister _ ->
            False

        Route.WikiSubmitNew _ ->
            False

        Route.WikiSubmitEdit _ _ ->
            False

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

        Route.HostAdminBackup ->
            ( model, Command.none )

        Route.WikiHome _ ->
            ( model, Command.none )

        Route.WikiPage _ _ ->
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
afterTrustedNewPagePublishedImmediately : Wiki.Slug -> Page.Slug -> Store -> Store
afterTrustedNewPagePublishedImmediately wikiSlug pageSlug store =
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
                                    if List.member pageSlug details.pageSlugs then
                                        details.pageSlugs

                                    else
                                        pageSlug :: details.pageSlugs |> List.sort
                            }
                        )
                        store.wikiDetails

                _ ->
                    Dict.remove wikiSlug store.wikiDetails
    in
    { store | publishedPages = publishedPagesNext, wikiDetails = wikiDetailsNext }


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

        ColorThemeFromJs value ->
            case Json.Decode.decodeValue ColorTheme.incomingDecoder value of
                Ok (ColorTheme.Sync preference systemTheme) ->
                    ( { model
                        | colorThemePreference = preference
                        , systemColorTheme = systemTheme
                      }
                    , Command.none
                    )

                Ok (ColorTheme.System systemTheme) ->
                    ( { model | systemColorTheme = systemTheme }
                    , Command.none
                    )

                Err _ ->
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

                                Route.WikiHome _ ->
                                    RemoteData.NotAsked

                                Route.WikiPage _ _ ->
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

                        Route.HostAdminAudit ->
                            { baseNext
                                | hostAdminAuditFilterWikiDraft = ""
                                , hostAdminAuditFilterActorDraft = ""
                                , hostAdminAuditFilterPageDraft = ""
                                , hostAdminAuditFilterSelectedKindTags = []
                                , hostAdminAuditAppliedFilter = WikiAuditLog.emptyHostAuditLogFilter
                            }

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

                Route.HostAdminAudit ->
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
            case model.route of
                Route.WikiList ->
                    ( model, Command.none )

                Route.WikiHome _ ->
                    ( model, Command.none )

                Route.WikiPage _ _ ->
                    ( model, Command.none )

                Route.WikiLogin wikiSlug _ ->
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

                Route.HostAdminAudit ->
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

        NewPageSubmitFormSubmitted ->
            case model.route of
                Route.WikiList ->
                    ( model, Command.none )

                Route.WikiHome _ ->
                    ( model, Command.none )

                Route.WikiPage _ _ ->
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
                    case Submission.validateNewPageFields d.pageSlug d.markdownBody of
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
                                    (SubmitNewPage wikiSlug { rawPageSlug = d.pageSlug, rawMarkdown = d.markdownBody })
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
                                            (SubmitNewPage wikiSlug { rawPageSlug = d.pageSlug, rawMarkdown = d.markdownBody })
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

                Route.HostAdminAudit ->
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
                    case Submission.validateNewPageDraftFields d.pageSlug d.markdownBody of
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

        PageEditSubmitFormSubmitted ->
            case model.route of
                Route.WikiList ->
                    ( model, Command.none )

                Route.WikiHome _ ->
                    ( model, Command.none )

                Route.WikiPage _ _ ->
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
                            case Submission.validateEditMarkdown d.markdownBody of
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
                            case Submission.validateEditMarkdown d.markdownBody of
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
                                        (SubmitPageEdit wikiSlug pageSlug d.markdownBody)
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

                Route.HostAdminAudit ->
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
                    case Submission.validateEditMarkdownDraft d.markdownBody of
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

                Route.HostAdminAudit ->
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

                Route.HostAdminAudit ->
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

                Route.HostAdminAudit ->
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

                Route.HostAdminAudit ->
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

                Route.HostAdminAudit ->
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

                Route.HostAdminAudit ->
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

                Route.HostAdminAudit ->
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

                Route.HostAdminAudit ->
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

                Route.HostAdminAudit ->
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

                Route.WikiHome _ ->
                    ( model, Command.none )

                Route.WikiPage _ _ ->
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

        WikiFrontendDetailsResponse wikiSlug maybeDetails ->
            let
                store : Store
                store =
                    model.store

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
            in
            ( { model | store = newStore }, Command.none )
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
                                { dEdit | markdownBody = details.markdownSource }

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
                        ( Nothing, Route.WikiPage rs rp ) ->
                            if rs == wikiSlug && rp == pageSlug && contributorLoggedInOnWikiSlug wikiSlug model then
                                runStoreActions nextStore [ Store.AskForMyPendingSubmissions wikiSlug ]

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

                validatedNewPagePayload : Maybe { pageSlug : Page.Slug, markdown : String }
                validatedNewPagePayload =
                    Submission.validateNewPageFields d.pageSlug d.markdownBody
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
                                    afterTrustedNewPagePublishedImmediately wikiSlug payload.pageSlug store0

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
                        , hostAdminBackupNotice = Just "Import completed. Reloading lists…"
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
                        in
                        ( { model
                            | hostAdminWikiImportInFlightSlug = Nothing
                            , hostAdminWikisNotice = Just "Wiki import completed. Reloading lists…"
                            , store = { store0 | wikiCatalog = RemoteData.NotAsked }
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
            [ TW.cls UI.wikiCatalogGridClass
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
                [ Html.p [] [ Html.text "Could not load the wiki catalog." ] ]

        RemoteData.Loading ->
            viewWikiListLoading

        RemoteData.NotAsked ->
            viewWikiListLoading


viewWikiListEmpty : Html Msg
viewWikiListEmpty =
    Html.div
        [ Attr.id "catalog-page"
        ]
        [ Html.div
            [ Attr.id "catalog-empty"
            , Attr.attribute "role" "status"
            ]
            [ Html.p [] [ Html.text "There are no wikis yet." ] ]
        ]


viewWikiListLoading : Html Msg
viewWikiListLoading =
    Html.div
        [ Attr.id "catalog-loading"
        ]
        [ Html.p [] [ Html.text "Loading…" ] ]


viewWikiRow : Wiki.CatalogEntry -> Html Msg
viewWikiRow entry =
    Html.article
        [ TW.cls UI.wikiCatalogCardClass
        , Attr.attribute "data-wiki-slug" entry.slug
        ]
        [ Html.h3
            [ TW.cls UI.wikiCatalogCardTitleClass
            ]
            [ Html.a
                [ Attr.href (Wiki.catalogUrlPath entry)
                , TW.cls UI.wikiCatalogCardTitleLinkClass
                ]
                [ Html.text entry.name ]
            , Html.text " "
            , Html.em
                [ TW.cls UI.wikiCatalogCardSlugEmClass
                ]
                [ Html.text ("/w/" ++ entry.slug) ]
            ]
        , Html.p
            [ TW.cls UI.wikiCatalogCardSummaryClass
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
        [ Html.p [] [ Html.text "Loading…" ]
        ]


viewWikiRegisterLoading : Html Msg
viewWikiRegisterLoading =
    Html.div
        [ Attr.id "wiki-register-loading"
        ]
        [ Html.p [] [ Html.text "Loading…" ] ]


viewWikiLoginLoading : Html Msg
viewWikiLoginLoading =
    Html.div
        [ Attr.id "wiki-login-loading"
        ]
        [ Html.p [] [ Html.text "Loading…" ] ]


viewWikiPublishedSlugList : String -> Wiki.Slug -> List Page.Slug -> Html Msg
viewWikiPublishedSlugList listId wikiSlug pageSlugs =
    Html.ul
        [ Attr.id listId
        , TW.cls UI.markdownUnorderedListClass
        ]
        (pageSlugs
            |> List.sort
            |> List.map
                (\pageSlug ->
                    Html.li []
                        [ Html.a
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
            Html.p [] [ Html.text summary.summary ]
        , Html.h2 [] [ Html.text "Pages" ]
        , if List.isEmpty details.pageSlugs then
            Html.p
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
        [ Html.p [] [ Html.text "This URL is not part of SortOfWiki yet." ]
        ]


viewWikiNotFound : Wiki.Slug -> Html Msg
viewWikiNotFound slug =
    Html.div
        [ Attr.id "wiki-not-found-page"
        , Attr.attribute "data-wiki-slug" slug
        ]
        [ Html.p []
            [ Html.text "The wiki "
            , Html.code [ TW.cls UI.markdownCodeSpanClass ] [ Html.text slug ]
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


viewThemeToggle : Model -> Html Msg
viewThemeToggle model =
    let
        effective : ColorTheme.ColorTheme
        effective =
            ColorTheme.effectiveColorTheme model.colorThemePreference model.systemColorTheme

        nextPreference : ColorTheme.ColorThemePreference
        nextPreference =
            ColorTheme.cyclePreference model.colorThemePreference

        ariaLabel : String
        ariaLabel =
            case nextPreference of
                ColorTheme.FollowSystem ->
                    "Match system color theme"

                ColorTheme.Fixed ColorTheme.Light ->
                    "Use light theme"

                ColorTheme.Fixed ColorTheme.Dark ->
                    "Use dark theme"
    in
    Html.button
        [ Attr.type_ "button"
        , Attr.id "color-theme-toggle"
        , TW.cls UI.themeToggleButtonClass
        , Events.onClick ColorThemeToggled
        , Attr.attribute "aria-label" ariaLabel
        ]
        [ case effective of
            ColorTheme.Light ->
                themeToggleIconMoon

            ColorTheme.Dark ->
                themeToggleIconSun
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

        authChrome : List (Html Msg)
        authChrome =
            case maybeCw of
                Just cw ->
                    [ Html.li []
                        [ Html.span []
                            [ Html.text ("Logged in as " ++ cw.displayUsername) ]
                        ]
                    , Html.li []
                        [ Html.button
                            [ Attr.type_ "button"
                            , Attr.id "wiki-logout-button"
                            , TW.cls "text-left underline"
                            , Events.onClick (ContributorLogoutWiki wikiSlug)
                            ]
                            [ Html.text "Log out" ]
                        ]
                    ]

                Nothing ->
                    []
    in
    List.concat
        [ authChrome
        , SideNavMenu.wikiNavLinks wikiSlug maybeRole |> List.map sideNavLinkLi
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

        Route.HostAdminBackup ->
            sortOfWikiAppHeaderTitle (Just (AppHeaderSecondaryPlain "Admin: Backup"))

        Route.WikiHome slug ->
            wikiScopeHeaderTitle store slug <|
                \summary ->
                    wikiLoadedHeaderTitle summary Nothing

        Route.WikiPage wikiSlug pageSlug ->
            wikiScopeHeaderTitle store wikiSlug <|
                \summary ->
                    wikiLoadedHeaderTitle summary <|
                        case Store.get_ ( wikiSlug, pageSlug ) store.publishedPages of
                            RemoteData.Success _ ->
                                Just (AppHeaderSecondaryWikiLink pageSlug)

                            RemoteData.Failure _ ->
                                Just
                                    (AppHeaderSecondaryWikiLinkThenPlain
                                        { wikiLabel = pageSlug
                                        , plainSuffix = ": Create?"
                                        }
                                    )

                            RemoteData.Loading ->
                                Just
                                    (AppHeaderSecondaryPlainThenWikiLink
                                        { plainPrefix = "Loading "
                                        , wikiLabel = pageSlug
                                        }
                                    )

                            RemoteData.NotAsked ->
                                Just
                                    (AppHeaderSecondaryPlainThenWikiLink
                                        { plainPrefix = "Loading "
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
            Html.span [ TW.cls UI.appHeaderSecondaryMetaClass ]
                [ Html.text label
                ]

        AppHeaderSecondaryWikiLink label ->
            Html.span [ TW.cls UI.appHeaderSecondaryWikiWrapClass ]
                [ Html.span [ TW.cls UI.appHeaderSecondaryBracketClass ] [ Html.text "[[" ]
                , Html.span [ TW.cls UI.appHeaderSecondaryWikiLabelEmClass ] [ Html.text label ]
                , Html.span [ TW.cls UI.appHeaderSecondaryBracketClass ] [ Html.text "]]" ]
                ]

        AppHeaderSecondaryPlainThenWikiLink { plainPrefix, wikiLabel } ->
            Html.span [ TW.cls UI.appHeaderSecondaryMetaClass ]
                [ Html.text plainPrefix
                , viewAppHeaderSecondary (AppHeaderSecondaryWikiLink wikiLabel)
                ]

        AppHeaderSecondaryWikiLinkThenPlain { wikiLabel, plainSuffix } ->
            Html.span [ TW.cls UI.appHeaderSecondaryMetaClass ]
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
                    Html.a
                        [ Attr.href href
                        , TW.cls UI.appHeaderPrimaryLinkClass
                        ]
                        [ Html.text t.primary ]

                Nothing ->
                    Html.span [ TW.cls UI.appHeaderPrimaryPlainClass ]
                        [ Html.text t.primary ]
    in
    case t.secondary of
        Nothing ->
            primaryEl

        Just sec ->
            Html.span [ TW.cls UI.appHeaderTitleRowClass ]
                [ primaryEl
                , Html.span
                    [ TW.cls UI.appHeaderDividerClass
                    , Attr.attribute "aria-hidden" "true"
                    ]
                    []
                , Html.span [ TW.cls UI.appHeaderSecondaryAfterDividerClass ]
                    [ viewAppHeaderSecondary sec ]
                ]


viewAppHeader : Model -> Html Msg
viewAppHeader model =
    Html.header
        [ TW.cls UI.appHeaderBarClass
        , Attr.attribute "data-context" "layout-header"
        ]
        [ Html.h1 [ TW.cls UI.appHeaderH1Class ]
            [ viewAppHeaderTitleInner (appHeaderTitle model) ]
        , viewThemeToggle model
        ]


viewHostAdminLoginFeedback : Maybe (Result HostAdmin.LoginError ()) -> Html Msg
viewHostAdminLoginFeedback maybeResult =
    case maybeResult of
        Nothing ->
            Html.text ""

        Just (Ok ()) ->
            Html.div
                [ Attr.id "host-admin-login-success" ]
                [ Html.p [] [ Html.text "Signed in as platform host admin." ] ]

        Just (Err e) ->
            Html.div
                [ Attr.id "host-admin-login-error" ]
                [ Html.p [] [ Html.text (HostAdmin.loginErrorToUserText e) ] ]


viewHostAdminLogin : Model -> Html Msg
viewHostAdminLogin model =
    let
        draft : HostAdminLoginDraft
        draft =
            model.hostAdminLoginDraft
    in
    Html.div
        [ Attr.id "host-admin-login-page" ]
        [ Html.form
            [ Attr.id "host-admin-login-form"
            , Events.onSubmit HostAdminLoginSubmitted
            ]
            [ Html.div []
                [ Html.label [ Attr.for "host-admin-login-password" ]
                    [ Html.text "Password" ]
                , Html.input
                    [ Attr.id "host-admin-login-password"
                    , Attr.type_ "password"
                    , Attr.value draft.password
                    , Events.onInput HostAdminLoginPasswordChanged
                    , Attr.disabled draft.inFlight
                    , TW.cls UI.formTextInputClass
                    ]
                    []
                ]
            , UI.button
                [ Attr.id "host-admin-login-submit"
                , Attr.type_ "submit"
                , Attr.disabled draft.inFlight
                ]
                [ Html.text "Sign in" ]
            ]
        , viewHostAdminLoginFeedback draft.lastResult
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
                    , TW.cls "mb-3 text-sm"
                    ]
                    [ Html.text noticeText ]
        , case model.hostAdminWikis of
            RemoteData.NotAsked ->
                Html.p [] [ Html.text "…" ]

            RemoteData.Loading ->
                Html.p
                    [ Attr.id "host-admin-wikis-loading" ]
                    [ Html.text "Loading…" ]

            RemoteData.Failure () ->
                Html.p [] [ Html.text "Could not load." ]

            RemoteData.Success (Err HostAdmin.NotHostAuthenticated) ->
                Html.div
                    [ Attr.id "host-admin-wikis-forbidden" ]
                    [ Html.p [] [ Html.text "Redirecting to host admin sign-in…" ] ]

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
                UI.table UI.TableAuto
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
                    Html.p
                        [ Attr.id "host-admin-backup-notice"
                        , Attr.attribute "role" "status"
                        ]
                        [ Html.text text ]
    in
    Html.section
        [ Attr.id "host-admin-backup-panel"
        , Attr.attribute "data-context" "host-admin-backup"
        , TW.cls "mb-8 max-w-3xl rounded border border-[var(--border-subtle)] p-4"
        ]
        [ Html.h2 [ TW.cls "text-lg font-semibold mb-2" ] [ Html.text "Backup and restore" ]
        , Html.p [ TW.cls "text-sm mb-3" ]
            [ Html.text
                "Export all wiki data as JSON, or import a file from a previous export. Import replaces all server-side data except your current host admin sign-in. Contributor sign-ins are not included in the backup; contributors must sign in again after import."
            ]
        , notice
        , Html.div [ TW.cls "flex flex-wrap gap-2" ]
            [ UI.button
                [ Attr.id "host-admin-export-json"
                , Attr.type_ "button"
                , Events.onClick HostAdminDataExportClicked
                , Attr.disabled (model.hostAdminExportInFlight || model.hostAdminImportInFlight)
                ]
                [ Html.text
                    (if model.hostAdminExportInFlight then
                        "Exporting…"

                     else
                        "Download JSON export"
                    )
                ]
            , UI.button
                [ Attr.id "host-admin-import-json"
                , Attr.type_ "button"
                , Events.onClick HostAdminDataImportPickRequested
                , Attr.disabled (model.hostAdminExportInFlight || model.hostAdminImportInFlight)
                ]
                [ Html.text
                    (if model.hostAdminImportInFlight then
                        "Importing…"

                     else
                        "Import JSON…"
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
            [ Html.a
                [ Attr.href (Wiki.hostAdminWikiDetailUrlPath summary.slug) ]
                [ Html.text summary.name ]
            ]
        , UI.tableTd UI.TableAlignMiddle [] [ Html.text summary.slug ]
        , UI.tableTd UI.TableAlignMiddle
            []
            [ Html.span
                [ Attr.attribute "data-context" "host-admin-wiki-status" ]
                [ Html.text
                    (if summary.active then
                        "Active"

                     else
                        "Deactivated"
                    )
                ]
            ]
        , UI.tableTd UI.TableAlignMiddle
            []
            [ Html.div
                [ TW.cls "flex flex-wrap gap-1" ]
                [ UI.button
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
                , UI.button
                    [ Attr.id ("host-admin-wiki-import-" ++ summary.slug)
                    , Attr.type_ "button"
                    , Events.onClick (HostAdminWikiDataImportPickRequested summary.slug)
                    , Attr.disabled wikiTableIoBusy
                    ]
                    [ Html.text
                        (if thisRowImporting then
                            "Importing…"

                         else
                            "Import JSON…"
                        )
                    ]
                ]
            ]
        ]


viewHostAdminAuditLoading : Html Msg
viewHostAdminAuditLoading =
    Html.div
        [ Attr.id "host-admin-audit-loading" ]
        [ Html.text "Loading audit log…" ]


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
            Html.div
                [ Attr.id "host-admin-audit-error" ]
                [ Html.p [] [ Html.text "Could not load audit log." ] ]

        RemoteData.Success (Err HostAdmin.NotHostAuthenticated) ->
            Html.div
                [ Attr.id "host-admin-audit-forbidden" ]
                [ Html.p [] [ Html.text "Redirecting to host admin sign-in…" ] ]

        RemoteData.Success (Ok events) ->
            if List.isEmpty events then
                Html.p
                    [ Attr.id "host-admin-audit-empty" ]
                    [ Html.text "No audit events yet." ]

            else
                UI.table UI.TableFull
                    [ Attr.id "host-admin-audit-list" ]
                    { theadAttrs = []
                    , headerRowAttrs = []
                    , headerAlign = UI.TableAlignTop
                    , headers =
                        [ { extraAttrs = [ Attr.scope "col" ], children = [ Html.text "Time (UTC)" ] }
                        , { extraAttrs = [ Attr.scope "col" ], children = [ Html.text "Wiki" ] }
                        , { extraAttrs = [ Attr.scope "col" ], children = [ Html.text "Actor" ] }
                        , { extraAttrs = [ Attr.scope "col" ], children = [ Html.text "Event" ] }
                        ]
                    , tbodyAttrs = [ Attr.id "host-admin-audit-tbody" ]
                    , rows =
                        events
                            |> List.indexedMap
                                (\i ev ->
                                    UI.trStriped
                                        [ Attr.attribute "data-audit-event" (String.fromInt i)
                                        , Attr.attribute "data-wiki-slug" ev.wikiSlug
                                        ]
                                        [ UI.tableTd UI.TableAlignTop
                                            [ TW.cls "[font-family:var(--font-mono)] whitespace-nowrap text-[0.9rem]" ]
                                            [ Html.text (WikiAuditLog.eventUtcTimestampStringScoped ev) ]
                                        , UI.tableTd UI.TableAlignTop [] [ Html.text ev.wikiSlug ]
                                        , UI.tableTd UI.TableAlignTop [] [ Html.text ev.actorUsername ]
                                        , UI.tableTd UI.TableAlignTop [] [ Html.text (WikiAuditLog.eventKindUserText ev.kind) ]
                                        ]
                                )
                    }


viewHostAdminAuditKindChip : Model -> ( WikiAuditLog.AuditEventKindFilterTag, String ) -> Html Msg
viewHostAdminAuditKindChip model ( tag, labelText ) =
    let
        isOn : Bool
        isOn =
            List.member tag model.hostAdminAuditFilterSelectedKindTags
    in
    UI.togglableChip
        [ Attr.id ("host-admin-audit-filter-type-" ++ WikiAuditLog.eventKindFilterTagToString tag) ]
        { pressed = isOn
        , onClick = HostAdminAuditFilterTypeTagToggled tag (not isOn)
        , label = labelText
        }


viewHostAdminAuditFilters : Model -> Html Msg
viewHostAdminAuditFilters model =
    Html.div
        [ Attr.attribute "data-context" "host-admin-audit-filters"
        , TW.cls "shrink-0 rounded-md border border-[var(--border)] bg-[var(--chrome-bg)] p-3"
        ]
        [ Html.div
            [ TW.cls "grid grid-cols-3 gap-3" ]
            [ Html.div [ TW.cls "min-w-0" ]
                [ Html.label
                    [ Attr.for "host-admin-audit-filter-wiki"
                    , TW.cls "block text-[0.82rem] font-medium text-[var(--fg-muted)]"
                    ]
                    [ Html.text "Wiki slug contains" ]
                , Html.input
                    [ Attr.id "host-admin-audit-filter-wiki"
                    , Attr.type_ "text"
                    , Attr.value model.hostAdminAuditFilterWikiDraft
                    , Events.onInput HostAdminAuditFilterWikiChanged
                    , TW.cls (UI.formTextInputClass ++ " mt-0 w-full max-w-full")
                    ]
                    []
                ]
            , Html.div [ TW.cls "min-w-0" ]
                [ Html.label
                    [ Attr.for "host-admin-audit-filter-actor"
                    , TW.cls "block text-[0.82rem] font-medium text-[var(--fg-muted)]"
                    ]
                    [ Html.text "Actor contains" ]
                , Html.input
                    [ Attr.id "host-admin-audit-filter-actor"
                    , Attr.type_ "text"
                    , Attr.value model.hostAdminAuditFilterActorDraft
                    , Events.onInput HostAdminAuditFilterActorChanged
                    , TW.cls (UI.formTextInputClass ++ " mt-0 w-full max-w-full")
                    ]
                    []
                ]
            , Html.div [ TW.cls "min-w-0" ]
                [ Html.label
                    [ Attr.for "host-admin-audit-filter-page"
                    , TW.cls "block text-[0.82rem] font-medium text-[var(--fg-muted)]"
                    ]
                    [ Html.text "Page slug contains" ]
                , Html.input
                    [ Attr.id "host-admin-audit-filter-page"
                    , Attr.type_ "text"
                    , Attr.value model.hostAdminAuditFilterPageDraft
                    , Events.onInput HostAdminAuditFilterPageChanged
                    , TW.cls (UI.formTextInputClass ++ " mt-0 w-full max-w-full")
                    ]
                    []
                ]
            ]
        , Html.div
            [ Attr.id "host-admin-audit-filter-type"
            , Attr.attribute "role" "group"
            , Attr.attribute "aria-labelledby" "host-admin-audit-filter-type-legend"
            , TW.cls "mt-3 border-t border-dashed border-[var(--border-dash)] pt-3"
            ]
            [ Html.p
                [ Attr.id "host-admin-audit-filter-type-legend"
                , TW.cls "m-0 mb-2 text-[0.82rem] text-[var(--fg-muted)]"
                ]
                [ Html.text "Event types — none selected means all" ]
            , Html.div
                [ TW.cls "flex flex-wrap gap-2" ]
                (List.map (viewHostAdminAuditKindChip model) WikiAuditLog.eventKindFilterTagOptions)
            ]
        ]


viewHostAdminAudit : Model -> Html Msg
viewHostAdminAudit model =
    Html.div
        [ Attr.id "host-admin-audit-page"
        , TW.cls "flex min-h-0 flex-1 flex-col gap-3"
        ]
        [ viewHostAdminAuditFilters model
        , Html.div
            [ Attr.id "host-admin-audit-table-region"
            , TW.cls "flex min-h-0 min-w-0 flex-1 flex-col overflow-auto"
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
                [ Html.p [] [ Html.text (HostAdmin.createHostedWikiErrorToUserText e) ] ]


viewHostAdminCreateWiki : Model -> Html Msg
viewHostAdminCreateWiki model =
    Html.div
        [ Attr.id "host-admin-create-wiki-page" ]
        [ case model.hostAdminWikis of
            RemoteData.Success (Err HostAdmin.NotHostAuthenticated) ->
                Html.p
                    [ Attr.id "host-admin-create-wiki-sign-in-needed" ]
                    [ Html.text "Redirecting to host admin sign-in…" ]

            RemoteData.Success (Ok _) ->
                let
                    draft : HostAdminCreateWikiDraft
                    draft =
                        model.hostAdminCreateWikiDraft

                    formBody : List (Html Msg)
                    formBody =
                        [ Html.p []
                            [ Html.a
                                [ Attr.href Wiki.hostAdminWikisUrlPath ]
                                [ Html.text "Back to wiki list" ]
                            ]
                        , Html.form
                            [ Attr.id "host-admin-create-wiki-form"
                            , Events.onSubmit HostAdminCreateWikiSubmitted
                            ]
                            [ Html.div []
                                [ Html.label [ Attr.for "host-admin-create-wiki-slug" ]
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
                                    , TW.cls UI.formTextInputClass
                                    ]
                                    []
                                ]
                            , Html.div []
                                [ Html.label [ Attr.for "host-admin-create-wiki-name" ]
                                    [ Html.text "Wiki name" ]
                                , Html.input
                                    [ Attr.id "host-admin-create-wiki-name"
                                    , Attr.type_ "text"
                                    , Attr.value draft.name
                                    , Events.onInput HostAdminCreateWikiNameChanged
                                    , Attr.disabled draft.inFlight
                                    , TW.cls UI.formTextInputClass
                                    ]
                                    []
                                ]
                            , Html.div []
                                [ Html.label [ Attr.for "host-admin-create-wiki-initial-admin-username" ]
                                    [ Html.text "Initial wiki admin username" ]
                                , Html.input
                                    [ Attr.id "host-admin-create-wiki-initial-admin-username"
                                    , Attr.type_ "text"
                                    , Attr.value draft.initialAdminUsername
                                    , Events.onInput HostAdminCreateWikiInitialAdminUsernameChanged
                                    , Attr.disabled draft.inFlight
                                    , TW.cls UI.formTextInputClass
                                    ]
                                    []
                                ]
                            , Html.div []
                                [ Html.label [ Attr.for "host-admin-create-wiki-initial-admin-password" ]
                                    [ Html.text "Initial wiki admin password" ]
                                , Html.input
                                    [ Attr.id "host-admin-create-wiki-initial-admin-password"
                                    , Attr.type_ "password"
                                    , Attr.value draft.initialAdminPassword
                                    , Events.onInput HostAdminCreateWikiInitialAdminPasswordChanged
                                    , Attr.disabled draft.inFlight
                                    , TW.cls UI.formTextInputClass
                                    ]
                                    []
                                ]
                            , UI.button
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
                Html.p
                    [ Attr.id "host-admin-create-wiki-session-loading" ]
                    [ Html.text "Loading…" ]

            RemoteData.NotAsked ->
                Html.p
                    [ Attr.id "host-admin-create-wiki-session-loading" ]
                    [ Html.text "Loading…" ]

            RemoteData.Failure () ->
                Html.p [] [ Html.text "Could not verify host session." ]
        ]


viewHostAdminWikiDetailSaveFeedback : Maybe (Result HostAdmin.UpdateHostedWikiMetadataError ()) -> Html Msg
viewHostAdminWikiDetailSaveFeedback maybeResult =
    case maybeResult of
        Nothing ->
            Html.text ""

        Just (Ok ()) ->
            Html.div
                [ Attr.id "host-admin-wiki-detail-save-success" ]
                [ Html.p [] [ Html.text "Saved." ] ]

        Just (Err e) ->
            Html.div
                [ Attr.id "host-admin-wiki-detail-save-error" ]
                [ Html.p [] [ Html.text (HostAdmin.updateHostedWikiMetadataErrorToUserText e) ] ]


viewHostAdminWikiDetailLifecycleFeedback : Maybe (Result HostAdmin.WikiLifecycleError ()) -> Html Msg
viewHostAdminWikiDetailLifecycleFeedback maybeResult =
    case maybeResult of
        Nothing ->
            Html.text ""

        Just (Ok ()) ->
            Html.div
                [ Attr.id "host-admin-wiki-detail-lifecycle-success" ]
                [ Html.p [] [ Html.text "Updated." ] ]

        Just (Err e) ->
            Html.div
                [ Attr.id "host-admin-wiki-detail-lifecycle-error" ]
                [ Html.p [] [ Html.text (HostAdmin.wikiLifecycleErrorToUserText e) ] ]


viewHostAdminWikiDetailDeleteFeedback : Maybe (Result HostAdmin.DeleteHostedWikiError ()) -> Html Msg
viewHostAdminWikiDetailDeleteFeedback maybeResult =
    case maybeResult of
        Nothing ->
            Html.text ""

        Just (Err e) ->
            Html.div
                [ Attr.id "host-admin-delete-wiki-error" ]
                [ Html.p [] [ Html.text (HostAdmin.deleteHostedWikiErrorToUserText e) ] ]

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
                Html.p [] [ Html.text "…" ]

            RemoteData.Loading ->
                Html.p
                    [ Attr.id "host-admin-wiki-detail-loading" ]
                    [ Html.text "Loading…" ]

            RemoteData.Failure _ ->
                Html.p [] [ Html.text "Could not load." ]

            RemoteData.Success (Err e) ->
                Html.div
                    [ Attr.id "host-admin-wiki-detail-error" ]
                    [ Html.p [] [ Html.text (HostAdmin.hostWikiDetailErrorToUserText e) ] ]

            RemoteData.Success (Ok entry) ->
                let
                    busy : Bool
                    busy =
                        d.saveInFlight || d.lifecycleInFlight || d.deleteInFlight
                in
                Html.div [ TW.cls UI.hostAdminWikiDetailShellClass ]
                    [ Html.div [ TW.cls UI.hostAdminWikiDetailGridClass ]
                        [ Html.div [ TW.cls UI.hostAdminWikiDetailMainStackClass ]
                            [ Html.div [ TW.cls UI.hostAdminWikiDetailCardClass ]
                                [ Html.h1 [ TW.cls UI.hostAdminWikiDetailPageTitleClass ]
                                    [ Html.text entry.name ]
                                , Html.form
                                    [ Attr.id "host-admin-wiki-detail-form"
                                    , Events.onSubmit HostAdminWikiDetailSaveClicked
                                    , TW.cls "mt-1.5 flex flex-col gap-1 min-w-0"
                                    ]
                                    [ Html.div []
                                        [ Html.label [ Attr.for "host-admin-wiki-detail-slug" ]
                                            [ Html.text "Wiki slug" ]
                                        , Html.input
                                            [ Attr.id "host-admin-wiki-detail-slug"
                                            , Attr.type_ "text"
                                            , Attr.value d.slugDraft
                                            , Events.onInput HostAdminWikiDetailSlugChanged
                                            , Attr.disabled busy
                                            , Attr.spellcheck False
                                            , Attr.autocomplete False
                                            , TW.cls (UI.formTextInputClass ++ " " ++ UI.hostAdminWikiSlugClass ++ " w-full max-w-full")
                                            ]
                                            []
                                        ]
                                    , Html.div []
                                        [ Html.label [ Attr.for "host-admin-wiki-detail-name" ]
                                            [ Html.text "Wiki name" ]
                                        , Html.input
                                            [ Attr.id "host-admin-wiki-detail-name"
                                            , Attr.type_ "text"
                                            , Attr.value d.nameDraft
                                            , Events.onInput HostAdminWikiDetailNameChanged
                                            , Attr.disabled busy
                                            , TW.cls UI.formTextInputClass
                                            ]
                                            []
                                        ]
                                    , Html.div []
                                        [ Html.label [ Attr.for "host-admin-wiki-detail-summary" ]
                                            [ Html.text "Public summary" ]
                                        , Html.textarea
                                            [ Attr.id "host-admin-wiki-detail-summary"
                                            , Attr.value d.summaryDraft
                                            , Events.onInput HostAdminWikiDetailSummaryChanged
                                            , Attr.disabled busy
                                            , TW.cls UI.formTextareaClass
                                            ]
                                            []
                                        ]
                                    , UI.button
                                        [ Attr.id "host-admin-wiki-detail-save"
                                        , Attr.type_ "submit"
                                        , Attr.disabled busy
                                        ]
                                        [ Html.text "Save" ]
                                    ]
                                , viewHostAdminWikiDetailSaveFeedback d.lastSaveResult
                                ]
                            ]
                        , Html.div [ TW.cls UI.hostAdminWikiDetailSideStackClass ]
                            [ Html.div [ TW.cls UI.hostAdminWikiDetailCardClass ]
                                [ Html.h2 [ TW.cls "m-0 mb-2 text-[1rem] font-semibold text-[var(--fg)]" ]
                                    [ Html.text "Lifecycle" ]
                                , Html.p [ TW.cls "m-0 mb-1.5" ]
                                    [ Html.span
                                        [ Attr.id "host-admin-wiki-detail-status"
                                        , Attr.attribute "data-wiki-active"
                                            (if entry.active then
                                                "true"

                                             else
                                                "false"
                                            )
                                        , TW.cls
                                            (if entry.active then
                                                UI.hostAdminWikiStatusBadgeActiveClass

                                             else
                                                UI.hostAdminWikiStatusBadgeInactiveClass
                                            )
                                        ]
                                        [ Html.text
                                            (if entry.active then
                                                "Active"

                                             else
                                                "Deactivated"
                                            )
                                        ]
                                    ]
                                , if entry.active then
                                    UI.button
                                        [ Attr.id "host-admin-wiki-detail-deactivate"
                                        , Attr.type_ "button"
                                        , Events.onClick HostAdminWikiDetailDeactivateClicked
                                        , Attr.disabled busy
                                        ]
                                        [ Html.text "Deactivate wiki" ]

                                  else
                                    UI.button
                                        [ Attr.id "host-admin-wiki-detail-reactivate"
                                        , Attr.type_ "button"
                                        , Events.onClick HostAdminWikiDetailReactivateClicked
                                        , Attr.disabled busy
                                        ]
                                        [ Html.text "Reactivate wiki" ]
                                , viewHostAdminWikiDetailLifecycleFeedback d.lastLifecycleResult
                                ]
                            , Html.div [ TW.cls UI.hostAdminWikiDetailDangerCardClass ]
                                [ Html.h2 [ TW.cls "m-0 mb-1.5 text-[1rem] font-semibold text-[var(--danger)]" ]
                                    [ Html.text "Delete wiki" ]
                                , Html.p [ TW.cls "m-0 mb-2 text-[0.95rem] leading-[1.4] text-[var(--fg)]" ]
                                    [ Html.text
                                        ("This permanently removes the wiki, its pages, submissions, and audit log. Type the slug "
                                            ++ d.wikiSlug
                                            ++ " below to confirm."
                                        )
                                    ]
                                , Html.div
                                    [ Attr.id "host-admin-delete-wiki-form"
                                    , TW.cls "flex flex-col gap-1.5 min-w-0"
                                    ]
                                    [ Html.div []
                                        [ Html.label [ Attr.for "host-admin-delete-wiki-confirm" ]
                                            [ Html.text "Confirm wiki slug" ]
                                        , Html.input
                                            [ Attr.id "host-admin-delete-wiki-confirm"
                                            , Attr.type_ "text"
                                            , Attr.value d.deleteConfirmDraft
                                            , Events.onInput HostAdminWikiDetailDeleteConfirmChanged
                                            , Attr.disabled busy
                                            , Attr.autocomplete False
                                            , TW.cls UI.formTextInputClass
                                            ]
                                            []
                                        ]
                                    , UI.dangerButton
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
    case maybeResult of
        Nothing ->
            Html.text ""

        Just (Ok ()) ->
            Html.div
                [ Attr.id "wiki-register-success" ]
                [ Html.text "Registration complete." ]

        Just (Err e) ->
            Html.div
                [ Attr.id "wiki-register-error" ]
                [ Html.span
                    [ Attr.id "wiki-register-error-text" ]
                    [ Html.text (ContributorAccount.registerErrorToUserText e) ]
                ]


viewLoginFeedback : Maybe (Result ContributorAccount.LoginContributorError ()) -> Html Msg
viewLoginFeedback maybeResult =
    case maybeResult of
        Nothing ->
            Html.text ""

        Just (Ok ()) ->
            Html.div
                [ Attr.id "wiki-login-success" ]
                [ Html.text "You are logged in." ]

        Just (Err e) ->
            Html.div
                [ Attr.id "wiki-login-error" ]
                [ Html.span
                    [ Attr.id "wiki-login-error-text" ]
                    [ Html.text (ContributorAccount.loginErrorToUserText e) ]
                ]


viewRegisterLoaded : Wiki.Slug -> RegisterDraft -> Html Msg
viewRegisterLoaded wikiSlug draft =
    Html.div
        [ Attr.id "wiki-register-page"
        , Attr.attribute "data-wiki-slug" wikiSlug
        ]
        [ Html.form
            [ Attr.id "wiki-register-form"
            , Events.onSubmit RegisterFormSubmitted
            ]
            [ Html.div []
                [ Html.label [ Attr.for "wiki-register-username" ]
                    [ Html.text "Username" ]
                , Html.input
                    [ Attr.id "wiki-register-username"
                    , Attr.type_ "text"
                    , Attr.value draft.username
                    , Events.onInput RegisterFormUsernameChanged
                    , Attr.disabled draft.inFlight
                    , TW.cls UI.formTextInputClass
                    ]
                    []
                ]
            , Html.div []
                [ Html.label [ Attr.for "wiki-register-password" ]
                    [ Html.text "Password" ]
                , Html.input
                    [ Attr.id "wiki-register-password"
                    , Attr.type_ "password"
                    , Attr.value draft.password
                    , Events.onInput RegisterFormPasswordChanged
                    , Attr.disabled draft.inFlight
                    , TW.cls UI.formTextInputClass
                    ]
                    []
                ]
            , UI.button
                [ Attr.id "wiki-register-submit"
                , Attr.type_ "submit"
                , Attr.disabled draft.inFlight
                ]
                [ Html.text "Create account" ]
            ]
        , Html.p []
            [ Html.text "Already have an account? "
            , Html.a
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


viewLoginLoaded : Wiki.Slug -> LoginDraft -> Html Msg
viewLoginLoaded wikiSlug draft =
    Html.div
        [ Attr.id "wiki-login-page"
        , Attr.attribute "data-wiki-slug" wikiSlug
        ]
        [ Html.form
            [ Attr.id "wiki-login-form"
            , Events.onSubmit LoginFormSubmitted
            ]
            [ Html.div []
                [ Html.label [ Attr.for "wiki-login-username" ]
                    [ Html.text "Username" ]
                , Html.input
                    [ Attr.id "wiki-login-username"
                    , Attr.type_ "text"
                    , Attr.value draft.username
                    , Events.onInput LoginFormUsernameChanged
                    , Attr.disabled draft.inFlight
                    , TW.cls UI.formTextInputClass
                    ]
                    []
                ]
            , Html.div []
                [ Html.label [ Attr.for "wiki-login-password" ]
                    [ Html.text "Password" ]
                , Html.input
                    [ Attr.id "wiki-login-password"
                    , Attr.type_ "password"
                    , Attr.value draft.password
                    , Events.onInput LoginFormPasswordChanged
                    , Attr.disabled draft.inFlight
                    , TW.cls UI.formTextInputClass
                    ]
                    []
                ]
            , UI.button
                [ Attr.id "wiki-login-submit"
                , Attr.type_ "submit"
                , Attr.disabled draft.inFlight
                ]
                [ Html.text "Log in" ]
            ]
        , Html.p []
            [ Html.text "Need an account? "
            , Html.a
                [ Attr.id "wiki-login-register-link"
                , Attr.href (Wiki.registerUrlPath wikiSlug)
                ]
                [ Html.text "Register" ]
            ]
        , viewLoginFeedback draft.lastResult
        ]


viewLoginRoute : Model -> Wiki.Slug -> Html Msg
viewLoginRoute model wikiSlug =
    case Store.get_ wikiSlug model.store.wikiDetails of
        RemoteData.Success _ ->
            case Store.get wikiSlug model.store.wikiCatalog of
                RemoteData.Success _ ->
                    viewLoginLoaded wikiSlug model.loginDraft

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
        [ Html.p [] [ Html.text "Loading…" ] ]


viewNewPageSaveDraftFeedback : NewPageSubmitDraft -> Html Msg
viewNewPageSaveDraftFeedback draft =
    case draft.lastSaveDraftResult of
        Nothing ->
            Html.text ""

        Just (Ok _) ->
            Html.div
                [ Attr.id "wiki-submit-new-save-draft-success" ]
                [ Html.text "Draft saved." ]

        Just (Err e) ->
            Html.div
                [ Attr.id "wiki-submit-new-save-draft-error" ]
                [ Html.span
                    [ Attr.id "wiki-submit-new-save-draft-error-text" ]
                    [ Html.text (Submission.saveNewPageDraftErrorToUserText e) ]
                ]


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
                            [ Html.p []
                                [ Html.text "Submitted for review." ]
                            , Html.a
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

        newPageMarkdownHeadingClass : String
        newPageMarkdownHeadingClass =
            "m-0 !mt-0 !mb-0 shrink-0 text-sm font-semibold leading-tight text-[var(--fg)]"

        newPagePreviewHeadingClass : String
        newPagePreviewHeadingClass =
            "m-0 !mt-0 !mb-0 shrink-0 text-sm font-semibold leading-tight text-[var(--fg-muted)]"

        newPageMarkdownPreviewCellClass : String
        newPageMarkdownPreviewCellClass =
            "flex min-h-0 min-w-0 flex-col gap-1 h-full"
    in
    Html.div
        [ Attr.id "wiki-submit-new-page"
        , Attr.attribute "data-wiki-slug" wikiSlug
        , Attr.attribute "data-page-slug" draft.pageSlug
        ]
        [ Html.form
            [ Attr.id "wiki-submit-new-form"
            , Events.onSubmit NewPageSubmitFormSubmitted
            ]
            [ Html.div []
                [ Html.label [ Attr.for "slug-input" ]
                    [ Html.text "Page slug" ]
                , Html.input
                    ([ Attr.id "slug-input"
                     , Attr.type_ "text"
                     , Attr.value draft.pageSlug
                     , Attr.disabled formBusy
                     , TW.cls UI.formTextInputClass
                     ]
                        ++ (if draft.pageSlugLockedFromQuery then
                                [ Attr.readonly True ]

                            else
                                [ Events.onInput NewPageSubmitSlugChanged ]
                           )
                    )
                    []
                ]
            , Html.div
                [ TW.cls "grid min-w-0 grid-cols-2 gap-4 items-stretch" ]
                [ Html.div
                    [ TW.cls newPageMarkdownPreviewCellClass ]
                    [ Html.h2
                        [ TW.cls newPageMarkdownHeadingClass ]
                        [ Html.text "Markdown body" ]
                    , Html.textarea
                        [ Attr.id "content-markdown-textarea"
                        , Attr.value draft.markdownBody
                        , Events.onInput NewPageSubmitMarkdownChanged
                        , Attr.disabled formBusy
                        , Attr.rows 12
                        , TW.cls (submissionDetailMarkdownTextareaEditableClass ++ submissionDetailMarkdownTextareaDiffCellClass)
                        ]
                        []
                    ]
                , Html.div
                    [ TW.cls newPageMarkdownPreviewCellClass ]
                    [ Html.h3
                        [ TW.cls newPagePreviewHeadingClass ]
                        [ Html.text "Preview" ]
                    , Html.div
                        [ TW.cls (markdownPreviewScrollClass ++ " min-h-0 flex-1") ]
                        [ PageMarkdown.viewPreview "content-preview" wikiSlug publishedSlugExists draft.markdownBody ]
                    ]
                ]
            , Html.div
                [ TW.cls "flex flex-wrap gap-2" ]
                [ UI.button
                    [ Attr.id "wiki-submit-new-save-draft"
                    , Attr.type_ "button"
                    , Events.onClick NewPageSaveDraftClicked
                    , Attr.disabled formBusy
                    ]
                    [ Html.text "Save draft" ]
                , UI.button
                    [ Attr.id "wiki-submit-new-submit"
                    , Attr.type_ "submit"
                    , Attr.disabled formBusy
                    ]
                    [ Html.text
                        (if showUntrustedContributorDisclaimer then
                            "Submit for review"

                         else
                            "Create"
                        )
                    ]
                ]
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
    case draft.lastSaveDraftResult of
        Nothing ->
            Html.text ""

        Just (Ok _) ->
            Html.div
                [ Attr.id "wiki-submit-edit-save-draft-success" ]
                [ Html.text "Draft saved." ]

        Just (Err e) ->
            Html.div
                [ Attr.id "wiki-submit-edit-save-draft-error" ]
                [ Html.span
                    [ Attr.id "wiki-submit-edit-save-draft-error-text" ]
                    [ Html.text (Submission.savePageEditDraftErrorToUserText e) ]
                ]


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
                            [ Html.p []
                                [ Html.text "Published. Your edit is live. " ]
                            , Html.a
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
                            [ Html.p []
                                [ Html.text "Submitted for review." ]
                            , Html.a
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
            pageDetails.markdownSource

        submitEditDiffCellShellClass : String
        submitEditDiffCellShellClass =
            "flex min-h-0 min-w-0 flex-col gap-1 h-full"

        submitEditMarkdownHeadingClass : String
        submitEditMarkdownHeadingClass =
            "m-0 !mt-0 !mb-0 shrink-0 text-sm font-semibold leading-tight text-[var(--fg)]"

        submitEditPreviewHeadingClass : String
        submitEditPreviewHeadingClass =
            "m-0 !mt-0 !mb-0 shrink-0 text-sm font-semibold leading-tight text-[var(--fg-muted)]"

        submitEditReadonlyTextarea : String -> String -> String -> Html Msg
        submitEditReadonlyTextarea elementId markdown extraClass =
            Html.textarea
                [ Attr.id elementId
                , Attr.readonly True
                , Attr.rows 12
                , Attr.value markdown
                , TW.cls (submissionDetailMarkdownTextareaReadonlyClass ++ extraClass)
                ]
                []

        submitEditPreviewInCell : String -> String -> Html Msg
        submitEditPreviewInCell previewId markdown =
            Html.div
                [ TW.cls (markdownPreviewScrollClass ++ " min-h-0 flex-1") ]
                [ PageMarkdown.viewPreview previewId wikiSlug publishedSlugExists markdown ]
    in
    Html.div
        [ Attr.id "wiki-submit-edit-page"
        , Attr.attribute "data-wiki-slug" wikiSlug
        , Attr.attribute "data-page-slug" pageSlug
        ]
        (List.concat
            [ if showUntrustedContributorDisclaimer then
                [ Html.p []
                    [ Html.text "Published content stays unchanged until a reviewer approves this proposal." ]
                ]

              else
                []
            , [ Html.form
                    [ Attr.id "wiki-submit-edit-form"
                    , Events.onSubmit PageEditSubmitFormSubmitted
                    ]
                    [ Html.div
                        [ TW.cls "grid min-w-0 grid-cols-2 grid-rows-2 gap-4 items-stretch" ]
                        [ Html.div
                            [ TW.cls submitEditDiffCellShellClass ]
                            [ Html.h2
                                [ TW.cls submitEditMarkdownHeadingClass ]
                                [ Html.text "Published" ]
                            , submitEditReadonlyTextarea "wiki-submit-edit-original-markdown" originalMarkdown submissionDetailMarkdownTextareaDiffCellClass
                            ]
                        , Html.div
                            [ TW.cls submitEditDiffCellShellClass ]
                            [ Html.h2
                                [ TW.cls submitEditMarkdownHeadingClass ]
                                [ Html.text "Your edit" ]
                            , Html.textarea
                                [ Attr.id "wiki-submit-edit-markdown"
                                , Attr.value draft.markdownBody
                                , Events.onInput PageEditSubmitMarkdownChanged
                                , Attr.disabled formBusy
                                , Attr.rows 12
                                , TW.cls (submissionDetailMarkdownTextareaEditableClass ++ submissionDetailMarkdownTextareaDiffCellClass)
                                ]
                                []
                            ]
                        , Html.div
                            [ TW.cls submitEditDiffCellShellClass ]
                            [ Html.h3
                                [ TW.cls submitEditPreviewHeadingClass ]
                                [ Html.text "Preview" ]
                            , submitEditPreviewInCell "wiki-submit-edit-original-preview" originalMarkdown
                            ]
                        , Html.div
                            [ TW.cls submitEditDiffCellShellClass ]
                            [ Html.h3
                                [ TW.cls submitEditPreviewHeadingClass ]
                                [ Html.text "Preview" ]
                            , submitEditPreviewInCell "wiki-submit-edit-new-preview" draft.markdownBody
                            ]
                        ]
                    , Html.div
                        [ TW.cls "flex flex-wrap gap-2" ]
                        [ UI.button
                            [ Attr.id "wiki-submit-edit-save-draft"
                            , Attr.type_ "button"
                            , Events.onClick PageEditSaveDraftClicked
                            , Attr.disabled formBusy
                            ]
                            [ Html.text "Save draft" ]
                        , UI.button
                            [ Attr.id "wiki-submit-edit-submit"
                            , Attr.type_ "submit"
                            , Attr.disabled formBusy
                            ]
                            [ Html.text
                                (if showUntrustedContributorDisclaimer then
                                    "Submit for review"

                                 else
                                    "Save"
                                )
                            ]
                        ]
                    ]
              , viewPageEditSubmitFeedback wikiSlug pageSlug draft
              ]
            ]
        )


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
                            viewSubmitEditLoaded wikiSlug
                                pageSlug
                                (contributorLoggedInOnWikiSlug wikiSlug model && not (wikiSessionTrustedOnWiki wikiSlug model))
                                (publishedSlugExistsFromWikiDetails wikiDetails)
                                pageDetails
                                model.pageEditSubmitDraft


viewPageDeleteSaveDraftFeedback : PageDeleteSubmitDraft -> Html Msg
viewPageDeleteSaveDraftFeedback draft =
    case draft.lastSaveDraftResult of
        Nothing ->
            Html.text ""

        Just (Ok _) ->
            Html.div
                [ Attr.id "wiki-submit-delete-save-draft-success" ]
                [ Html.text "Draft saved." ]

        Just (Err e) ->
            Html.div
                [ Attr.id "wiki-submit-delete-save-draft-error" ]
                [ Html.span
                    [ Attr.id "wiki-submit-delete-save-draft-error-text" ]
                    [ Html.text (Submission.savePageDeleteDraftErrorToUserText e) ]
                ]


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
                            [ Html.p []
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
                            [ Html.p []
                                [ Html.text "Submitted for review." ]
                            , Html.a
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
            Html.p []
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
                [ UI.button
                    [ Attr.id "wiki-submit-delete-submit"
                    , Attr.type_ "button"
                    , Events.onClick submitMsg
                    , Attr.disabled formBusy
                    ]
                    [ Html.text "Delete page" ]
                ]

            else
                [ UI.button
                    [ Attr.id "wiki-submit-delete-save-draft"
                    , Attr.type_ "button"
                    , Events.onClick PageDeleteSaveDraftClicked
                    , Attr.disabled formBusy
                    ]
                    [ Html.text "Save draft" ]
                , UI.button
                    [ Attr.id "wiki-submit-delete-submit"
                    , Attr.type_ "button"
                    , Events.onClick submitMsg
                    , Attr.disabled formBusy
                    ]
                    [ Html.text "Submit for review" ]
                ]
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
                [ Html.label [ Attr.for "wiki-submit-delete-reason" ]
                    [ Html.text "Reason for deletion (required)" ]
                , Html.textarea
                    [ Attr.id "wiki-submit-delete-reason"
                    , Attr.value draft.reasonText
                    , Events.onInput PageDeleteSubmitReasonChanged
                    , Attr.disabled formBusy
                    , Attr.rows 4
                    , Attr.placeholder "Explain why this page is being removed"
                    , TW.cls UI.formTextareaClass
                    ]
                    []
                ]
            , Html.div
                [ TW.cls "flex flex-wrap gap-2" ]
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
                [ Html.p [] [ Html.text "Could not load submission details." ] ]

        RemoteData.Success (Err e) ->
            Html.div
                [ Attr.id "wiki-submission-detail-error" ]
                [ Html.p []
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
                        [ TW.cls markdownPreviewScrollClass ]
                        [ PageMarkdown.viewPreview previewId wikiSlug publishedSlugExists markdown ]

                newPageSlugField : Html Msg
                newPageSlugField =
                    if detail.status == Submission.Draft && detail.contributionKind == Submission.ContributorKindNewPage then
                        Html.div
                            [ TW.cls "mb-2" ]
                            [ Html.label
                                [ Attr.for "wiki-submission-detail-new-page-slug" ]
                                [ Html.text "Page slug" ]
                            , Html.input
                                [ Attr.id "wiki-submission-detail-new-page-slug"
                                , Attr.type_ "text"
                                , Attr.value interaction.newPageSlug
                                , Events.onInput SubmissionDetailNewPageSlugChanged
                                , Attr.disabled anyBusy
                                , TW.cls UI.formTextInputClass
                                ]
                                []
                            ]

                    else
                        Html.text ""

                newMarkdownField : Html Msg
                newMarkdownField =
                    if detail.status == Submission.Draft then
                        Html.textarea
                            [ Attr.id "new-markdown-editable-textarea"
                            , Attr.value interaction.markdownBody
                            , Events.onInput SubmissionDetailNewMarkdownChanged
                            , Attr.readonly anyBusy
                            , Attr.rows 14
                            , TW.cls (submissionDetailMarkdownTextareaEditableClass ++ submissionDetailMarkdownTextareaDiffCellClass)
                            ]
                            []

                    else
                        Html.textarea
                            [ Attr.id "new-markdown-readonly-textarea"
                            , Attr.readonly True
                            , Attr.rows 14
                            , Attr.value detail.compareNewMarkdown
                            , TW.cls (submissionDetailMarkdownTextareaReadonlyClass ++ submissionDetailMarkdownTextareaDiffCellClass)
                            ]
                            []

                withdrawDeleteRow : Html Msg
                withdrawDeleteRow =
                    case detail.status of
                        Submission.Pending ->
                            Html.div
                                [ TW.cls "flex flex-wrap gap-2 mt-3" ]
                                [ UI.button
                                    [ Attr.id "wiki-submission-detail-withdraw"
                                    , Attr.type_ "button"
                                    , Attr.disabled (anyBusy || interaction.withdrawInFlight)
                                    , Events.onClick SubmissionDetailWithdrawClicked
                                    ]
                                    [ Html.text "Withdraw (edit)" ]
                                , UI.button
                                    [ Attr.id "wiki-submission-detail-delete"
                                    , Attr.type_ "button"
                                    , Attr.disabled (anyBusy || interaction.deleteInFlight)
                                    , Events.onClick SubmissionDetailDeleteClicked
                                    ]
                                    [ Html.text "Delete" ]
                                ]

                        Submission.NeedsRevision ->
                            Html.div
                                [ TW.cls "flex flex-wrap gap-2 mt-3" ]
                                [ UI.button
                                    [ Attr.id "wiki-submission-detail-withdraw"
                                    , Attr.type_ "button"
                                    , Attr.disabled (anyBusy || interaction.withdrawInFlight)
                                    , Events.onClick SubmissionDetailWithdrawClicked
                                    ]
                                    [ Html.text "Withdraw (edit)" ]
                                , UI.button
                                    [ Attr.id "wiki-submission-detail-delete"
                                    , Attr.type_ "button"
                                    , Attr.disabled (anyBusy || interaction.deleteInFlight)
                                    , Events.onClick SubmissionDetailDeleteClicked
                                    ]
                                    [ Html.text "Delete" ]
                                ]

                        Submission.Rejected ->
                            Html.div
                                [ TW.cls "flex flex-wrap gap-2 mt-3" ]
                                [ UI.button
                                    [ Attr.id "wiki-submission-detail-delete"
                                    , Attr.type_ "button"
                                    , Attr.disabled (anyBusy || interaction.deleteInFlight)
                                    , Events.onClick SubmissionDetailDeleteClicked
                                    ]
                                    [ Html.text "Delete" ]
                                ]

                        Submission.Draft ->
                            Html.div
                                [ TW.cls "flex flex-wrap gap-2 mt-3" ]
                                [ UI.button
                                    [ Attr.id "wiki-submission-detail-save-draft"
                                    , Attr.type_ "button"
                                    , Attr.disabled (anyBusy || interaction.saveDraftInFlight)
                                    , Events.onClick SubmissionDetailSaveDraftClicked
                                    ]
                                    [ Html.text "Save draft" ]
                                , UI.button
                                    [ Attr.id "wiki-submission-detail-submit-for-review"
                                    , Attr.type_ "button"
                                    , Attr.disabled (anyBusy || interaction.submitForReviewInFlight)
                                    , Events.onClick SubmissionDetailSubmitForReviewClicked
                                    ]
                                    [ Html.text "Submit for review" ]
                                , UI.button
                                    [ Attr.id "wiki-submission-detail-delete"
                                    , Attr.type_ "button"
                                    , Attr.disabled (anyBusy || interaction.deleteInFlight)
                                    , Events.onClick SubmissionDetailDeleteClicked
                                    ]
                                    [ Html.text "Delete" ]
                                ]

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
                                , TW.cls "text-[var(--danger)] m-0 mt-2"
                                ]
                                [ Html.text errText ]
            in
            Html.div []
                [ Html.p []
                    [ Html.span
                        [ Attr.id "wiki-submission-detail-status"
                        , Attr.attribute "data-submission-status" (Submission.statusLabelUserText detail.status)
                        ]
                        [ Html.text (Submission.statusLabelUserText detail.status) ]
                    ]
                , Html.p
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
                            [ Html.h2 [] [ Html.text "Reviewer note" ]
                            , Html.p [] [ Html.text noteText ]
                            ]
                , Html.section
                    [ Attr.id "wiki-submission-detail-next-steps"
                    , TW.cls "mt-3 mb-3"
                    ]
                    [ Html.p [ TW.cls "m-0 text-[0.95rem] leading-[1.45]" ]
                        [ Html.text (submissionDetailNextStepsText detail.status) ]
                    ]
                , newPageSlugField
                , Html.div
                    [ TW.cls "grid min-w-0 grid-cols-2 gap-x-3 gap-y-2" ]
                    [ Html.label
                        [ Attr.for "original-markdown-readonly-textarea"
                        , TW.cls "col-start-1 row-start-1"
                        ]
                        [ Html.text "Original" ]
                    , Html.textarea
                        [ Attr.id "original-markdown-readonly-textarea"
                        , Attr.readonly True
                        , Attr.rows 14
                        , Attr.value detail.compareOriginalMarkdown
                        , TW.cls
                            (submissionDetailMarkdownTextareaReadonlyClass
                                ++ submissionDetailMarkdownTextareaDiffCellClass
                                ++ " min-w-0 col-start-1 row-start-2"
                            )
                        ]
                        []
                    , Html.div
                        [ Attr.id "original-preview"
                        , TW.cls "min-h-0 min-w-0 col-start-1 row-start-3"
                        ]
                        [ comparePreview "original-preview-inner" detail.compareOriginalMarkdown ]
                    , Html.label
                        [ Attr.for
                            (if detail.status == Submission.Draft then
                                "new-markdown-editable-textarea"

                             else
                                "new-markdown-readonly-textarea"
                            )
                        , TW.cls "col-start-2 row-start-1"
                        ]
                        [ Html.text
                            (if detail.contributionKind == Submission.ContributorKindDeletePage then
                                "Reason for deletion (required)"

                             else
                                "Proposed"
                            )
                        ]
                    , Html.div
                        [ TW.cls "min-w-0 col-start-2 row-start-2" ]
                        [ newMarkdownField ]
                    , Html.div
                        [ Attr.id "new-preview"
                        , TW.cls "min-h-0 min-w-0 col-start-2 row-start-3"
                        ]
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
        [ Html.p [] [ Html.text "Loading…" ] ]


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
                [ Html.p [] [ Html.text "Could not load the review queue." ] ]

        RemoteData.Success (Err e) ->
            Html.div
                [ Attr.id "wiki-review-queue-error" ]
                [ Html.p [] [ Html.text (Submission.reviewQueueErrorToUserText e) ] ]

        RemoteData.Success (Ok items) ->
            if List.isEmpty items then
                Html.p
                    [ Attr.id "wiki-review-queue-empty" ]
                    [ Html.text "No pending submissions." ]

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
                                            [ Html.a
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
        [ Html.p [] [ Html.text "Loading…" ] ]


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
                [ Html.p [] [ Html.text "Could not load your submissions." ] ]

        RemoteData.Success (Err e) ->
            Html.div
                [ Attr.id "wiki-my-submissions-error" ]
                [ Html.p [] [ Html.text (Submission.myPendingSubmissionsErrorToUserText e) ] ]

        RemoteData.Success (Ok items) ->
            if List.isEmpty items then
                Html.p
                    [ Attr.id "wiki-my-submissions-empty" ]
                    [ Html.text "No submissions to show here yet." ]

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
                                            [ Html.a
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
        [ Html.p [] [ Html.text "Loading…" ] ]


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
                [ Html.p [] [ Html.text "Could not load wiki users." ] ]

        RemoteData.Success (Err e) ->
            Html.div
                [ Attr.id "wiki-admin-users-error" ]
                [ Html.p [] [ Html.text (WikiAdminUsers.errorToUserText e) ] ]

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
            UI.button
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
            UI.button
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
            UI.button
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
                UI.button
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
                [ Html.p [] [ Html.text text ] ]


viewWikiAdminUsersDemoteFeedback : Maybe String -> Html Msg
viewWikiAdminUsersDemoteFeedback maybeText =
    case maybeText of
        Nothing ->
            Html.text ""

        Just text ->
            Html.div
                [ Attr.id "wiki-admin-demote-error" ]
                [ Html.p [] [ Html.text text ] ]


viewWikiAdminUsersGrantAdminFeedback : Maybe String -> Html Msg
viewWikiAdminUsersGrantAdminFeedback maybeText =
    case maybeText of
        Nothing ->
            Html.text ""

        Just text ->
            Html.div
                [ Attr.id "wiki-admin-grant-admin-error" ]
                [ Html.p [] [ Html.text text ] ]


viewWikiAdminUsersRevokeAdminFeedback : Maybe String -> Html Msg
viewWikiAdminUsersRevokeAdminFeedback maybeText =
    case maybeText of
        Nothing ->
            Html.text ""

        Just text ->
            Html.div
                [ Attr.id "wiki-admin-revoke-admin-error" ]
                [ Html.p [] [ Html.text text ] ]


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
    Html.div
        [ Attr.id "wiki-admin-audit-loading" ]
        [ Html.text "Loading audit log…" ]


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
            Html.div
                [ Attr.id "wiki-admin-audit-error" ]
                [ Html.p [] [ Html.text "Could not load audit log." ] ]

        RemoteData.Success (Err e) ->
            Html.div
                [ Attr.id "wiki-admin-audit-error" ]
                [ Html.p [] [ Html.text (WikiAuditLog.errorToUserText e) ] ]

        RemoteData.Success (Ok events) ->
            if List.isEmpty events then
                Html.p
                    [ Attr.id "wiki-admin-audit-empty" ]
                    [ Html.text "No audit events yet." ]

            else
                UI.table UI.TableFull
                    [ Attr.id "wiki-admin-audit-list" ]
                    { theadAttrs = []
                    , headerRowAttrs = []
                    , headerAlign = UI.TableAlignTop
                    , headers =
                        [ { extraAttrs = [ Attr.scope "col" ], children = [ Html.text "Time (UTC)" ] }
                        , { extraAttrs = [ Attr.scope "col" ], children = [ Html.text "Actor" ] }
                        , { extraAttrs = [ Attr.scope "col" ], children = [ Html.text "Event" ] }
                        ]
                    , tbodyAttrs = [ Attr.id "wiki-admin-audit-tbody" ]
                    , rows =
                        events
                            |> List.indexedMap
                                (\i ev ->
                                    UI.trStriped
                                        [ Attr.attribute "data-audit-event" (String.fromInt i)
                                        , Attr.attribute "data-wiki-slug" wikiSlug
                                        ]
                                        [ Html.td
                                            [ TW.cls
                                                (UI.tableCellClass
                                                    ++ " [font-family:var(--font-mono)] whitespace-nowrap text-[0.9rem]"
                                                )
                                            ]
                                            [ Html.text (WikiAuditLog.eventUtcTimestampString ev) ]
                                        , UI.tableTd UI.TableAlignTop [] [ Html.text ev.actorUsername ]
                                        , UI.tableTd UI.TableAlignTop [] [ Html.text (WikiAuditLog.eventKindUserText ev.kind) ]
                                        ]
                                )
                    }


viewWikiAdminAuditFilters : Model -> Html Msg
viewWikiAdminAuditFilters model =
    Html.div
        [ Attr.attribute "data-context" "wiki-admin-audit-filters"
        , TW.cls "shrink-0 rounded-md border border-[var(--border)] bg-[var(--chrome-bg)] p-3"
        ]
        [ Html.div
            [ TW.cls "grid grid-cols-2 gap-3" ]
            [ Html.div [ TW.cls "min-w-0" ]
                [ Html.label
                    [ Attr.for "wiki-admin-audit-filter-actor"
                    , TW.cls "block text-[0.82rem] font-medium text-[var(--fg-muted)]"
                    ]
                    [ Html.text "Actor contains" ]
                , Html.input
                    [ Attr.id "wiki-admin-audit-filter-actor"
                    , Attr.type_ "text"
                    , Attr.value model.wikiAdminAuditFilterActorDraft
                    , Events.onInput WikiAdminAuditFilterActorChanged
                    , TW.cls (UI.formTextInputClass ++ " mt-0 w-full max-w-full")
                    ]
                    []
                ]
            , Html.div [ TW.cls "min-w-0" ]
                [ Html.label
                    [ Attr.for "wiki-admin-audit-filter-page"
                    , TW.cls "block text-[0.82rem] font-medium text-[var(--fg-muted)]"
                    ]
                    [ Html.text "Page slug contains" ]
                , Html.input
                    [ Attr.id "wiki-admin-audit-filter-page"
                    , Attr.type_ "text"
                    , Attr.value model.wikiAdminAuditFilterPageDraft
                    , Events.onInput WikiAdminAuditFilterPageChanged
                    , TW.cls (UI.formTextInputClass ++ " mt-0 w-full max-w-full")
                    ]
                    []
                ]
            ]
        , Html.div
            [ Attr.id "wiki-admin-audit-filter-type"
            , Attr.attribute "role" "group"
            , Attr.attribute "aria-labelledby" "wiki-admin-audit-filter-type-legend"
            , TW.cls "mt-3 border-t border-dashed border-[var(--border-dash)] pt-3"
            ]
            [ Html.p
                [ Attr.id "wiki-admin-audit-filter-type-legend"
                , TW.cls "m-0 mb-2 text-[0.82rem] text-[var(--fg-muted)]"
                ]
                [ Html.text "Event types — none selected means all" ]
            , Html.div
                [ TW.cls "flex flex-wrap gap-2" ]
                (List.map (viewWikiAdminAuditKindChip model) WikiAuditLog.eventKindFilterTagOptions)
            ]
        ]


viewWikiAdminAuditKindChip : Model -> ( WikiAuditLog.AuditEventKindFilterTag, String ) -> Html Msg
viewWikiAdminAuditKindChip model ( tag, labelText ) =
    let
        isOn : Bool
        isOn =
            List.member tag model.wikiAdminAuditFilterSelectedKindTags
    in
    UI.togglableChip
        [ Attr.id ("wiki-admin-audit-filter-type-" ++ WikiAuditLog.eventKindFilterTagToString tag) ]
        { pressed = isOn
        , onClick = WikiAdminAuditFilterTypeTagToggled tag (not isOn)
        , label = labelText
        }


viewWikiAdminAuditLoaded : Wiki.Slug -> Model -> Html Msg
viewWikiAdminAuditLoaded wikiSlug model =
    Html.div
        [ Attr.id "wiki-admin-audit-page"
        , Attr.attribute "data-wiki-slug" wikiSlug
        , TW.cls "flex min-h-0 flex-1 flex-col gap-3"
        ]
        [ viewWikiAdminAuditFilters model
        , Html.div
            [ Attr.id "wiki-admin-audit-table-region"
            , TW.cls "flex min-h-0 min-w-0 flex-1 flex-col overflow-auto"
            ]
            [ viewWikiAdminAuditBody wikiSlug (Store.getWikiAuditLog wikiSlug model.wikiAdminAuditAppliedFilter model.store) ]
        ]


viewWikiAdminAuditRoute : Model -> Wiki.Slug -> Html Msg
viewWikiAdminAuditRoute model wikiSlug =
    case Store.get_ wikiSlug model.store.wikiDetails of
        RemoteData.Success _ ->
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
                [ TW.cls markdownPreviewScrollClass ]
                [ PageMarkdown.viewPreview previewId wikiSlug publishedSlugExists markdown ]

        reviewPreviewInDiffCell : String -> String -> Html Msg
        reviewPreviewInDiffCell previewId markdown =
            Html.div
                [ TW.cls (markdownPreviewScrollClass ++ " min-h-0 flex-1") ]
                [ PageMarkdown.viewPreview previewId wikiSlug publishedSlugExists markdown ]

        reviewReadonlyTextarea : String -> String -> String -> Html Msg
        reviewReadonlyTextarea elementId markdown extraClass =
            Html.textarea
                [ Attr.id elementId
                , Attr.readonly True
                , Attr.rows 12
                , Attr.value markdown
                , TW.cls (submissionDetailMarkdownTextareaReadonlyClass ++ extraClass)
                ]
                []
    in
    case detail of
        SubmissionReviewDetail.NewPageDiff body ->
            Html.div
                [ Attr.id "wiki-review-diff-summary"
                , TW.cls "grid min-w-0 grid-cols-2 gap-x-4 gap-y-2"
                ]
                [ Html.h3
                    [ TW.cls "m-0 !mt-0 !mb-0 shrink-0 text-sm font-semibold leading-tight text-[var(--fg)] col-start-1 row-start-1" ]
                    [ Html.text "Proposed markdown" ]
                , reviewReadonlyTextarea "wiki-review-diff-new" body.proposedMarkdown
                    (submissionDetailMarkdownTextareaDiffCellClass ++ " min-w-0 col-start-1 row-start-2")
                , Html.h3
                    [ TW.cls "m-0 !mt-0 !mb-0 shrink-0 text-sm font-semibold leading-tight text-[var(--fg-muted)] col-start-2 row-start-1" ]
                    [ Html.text "Preview" ]
                , Html.div
                    [ TW.cls "min-h-0 min-w-0 col-start-2 row-start-2" ]
                    [ reviewPreviewInDiffCell "wiki-review-diff-new-preview" body.proposedMarkdown ]
                ]

        SubmissionReviewDetail.EditPageDiff body ->
            let
                reviewDiffCellHeadingClass : String
                reviewDiffCellHeadingClass =
                    "m-0 !mt-0 !mb-0 shrink-0 text-sm font-semibold leading-tight text-[var(--fg)]"

                reviewDiffCellPreviewHeadingClass : String
                reviewDiffCellPreviewHeadingClass =
                    "m-0 !mt-0 !mb-0 shrink-0 text-sm font-semibold leading-tight text-[var(--fg-muted)]"
            in
            Html.div
                [ Attr.id "wiki-review-diff-summary"
                , TW.cls "grid min-w-0 grid-cols-2 gap-x-4 gap-y-2"
                ]
                [ Html.h2
                    [ TW.cls (reviewDiffCellHeadingClass ++ " col-start-1 row-start-1") ]
                    [ Html.text "Before (published)" ]
                , reviewReadonlyTextarea "wiki-review-diff-old" body.beforeMarkdown
                    (submissionDetailMarkdownTextareaDiffCellClass ++ " min-w-0 col-start-1 row-start-2")
                , Html.div
                    [ TW.cls "flex min-h-0 min-w-0 flex-col gap-1 col-start-1 row-start-3" ]
                    [ Html.h3
                        [ TW.cls reviewDiffCellPreviewHeadingClass ]
                        [ Html.text "Preview" ]
                    , reviewPreviewInDiffCell "wiki-review-diff-old-preview" body.beforeMarkdown
                    ]
                , Html.h2
                    [ TW.cls (reviewDiffCellHeadingClass ++ " col-start-2 row-start-1") ]
                    [ Html.text "After (proposed)" ]
                , reviewReadonlyTextarea "wiki-review-diff-new" body.afterMarkdown
                    (submissionDetailMarkdownTextareaDiffCellClass ++ " min-w-0 col-start-2 row-start-2")
                , Html.div
                    [ TW.cls "flex min-h-0 min-w-0 flex-col gap-1 col-start-2 row-start-3" ]
                    [ Html.h3
                        [ TW.cls reviewDiffCellPreviewHeadingClass ]
                        [ Html.text "Preview" ]
                    , reviewPreviewInDiffCell "wiki-review-diff-new-preview" body.afterMarkdown
                    ]
                ]

        SubmissionReviewDetail.DeletePageDiff body ->
            Html.div
                [ Attr.id "wiki-review-diff-summary" ]
                [ reviewReadonlyTextarea "wiki-review-diff-published" body.publishedSnapshotMarkdown ""
                , Html.h3
                    [ TW.cls "m-0 text-sm font-semibold text-[var(--fg-muted)]" ]
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
                [ Html.p [] [ Html.text "Could not load submission review details." ] ]

        RemoteData.Success (Err e) ->
            Html.div
                [ Attr.id "wiki-review-detail-error" ]
                [ Html.p []
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
                , TW.cls "mt-4 flex flex-col gap-3 border border-dashed border-[var(--border-dash)] p-3 max-w-[42rem]"
                ]
                [ Html.legend
                    [ TW.cls "px-1 text-[var(--fg)]" ]
                    [ Html.text "Decision" ]
                , Html.div
                    [ TW.cls "flex flex-col gap-3" ]
                    [ Html.label
                        [ TW.cls "flex items-start gap-2 cursor-pointer" ]
                        [ radio "wiki-review-decision-approve" ReviewDecisionApprove
                        , Html.span [ TW.cls "font-medium" ] [ Html.text "Approve" ]
                        ]
                    , Html.div
                        [ TW.cls "flex flex-col gap-1.5" ]
                        [ Html.label
                            [ TW.cls "flex items-start gap-2 cursor-pointer" ]
                            [ radio "wiki-review-decision-request-changes" ReviewDecisionRequestChanges
                            , Html.span [ TW.cls "font-medium" ] [ Html.text "Request changes" ]
                            ]
                        , Html.textarea
                            [ Attr.id "wiki-review-request-changes-note"
                            , Events.onInput ReviewRequestChangesNoteChanged
                            , Attr.disabled (busy || not requestSelected)
                            , Attr.value requestDraft.guidanceText
                            , Attr.placeholder "Guidance for the contributor (required for this action)"
                            , TW.cls UI.formTextareaCompactClass
                            ]
                            []
                        ]
                    , Html.div
                        [ TW.cls "flex flex-col gap-1.5" ]
                        [ Html.label
                            [ TW.cls "flex items-start gap-2 cursor-pointer" ]
                            [ radio "wiki-review-decision-reject" ReviewDecisionReject
                            , Html.span [ TW.cls "font-medium" ] [ Html.text "Reject" ]
                            ]
                        , Html.textarea
                            [ Attr.id "wiki-review-reject-reason"
                            , Events.onInput ReviewRejectReasonChanged
                            , Attr.disabled (busy || not rejectSelected)
                            , Attr.value rejectDraft.reasonText
                            , Attr.placeholder "Rejection reason (required for this action)"
                            , TW.cls UI.formTextareaCompactClass
                            ]
                            []
                        ]
                    ]
                , UI.button
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
    Html.section
        [ Attr.id "page-backlinks"
        , TW.cls UI.backlinksSectionClass
        ]
        [ UI.sidebarHeading "Backlinks"
        , Html.div [ TW.cls UI.sidebarNavSectionBodyClass ]
            [ if List.isEmpty backlinks then
                Html.p
                    [ Attr.id "page-backlinks-empty"
                    , TW.cls "m-0"
                    ]
                    [ Html.text "No backlinks." ]

              else
                Html.ul
                    [ Attr.id "page-backlinks-list"
                    , TW.cls UI.backlinksListClass
                    ]
                    (backlinks
                        |> List.map
                            (\slug ->
                                Html.li [ TW.cls "m-0 leading-[1.3]" ]
                                    [ UI.sidebarLink
                                        [ Attr.href (Wiki.publishedPageUrlPath wikiSlug slug)
                                        , Attr.attribute "data-backlink-page-slug" slug
                                        ]
                                        [ Html.text slug ]
                                    ]
                            )
                    )
            ]
        ]


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
    -> Maybe Wiki.Slug
    -> RemoteData () (Result Submission.MyPendingSubmissionsError (List Submission.MyPendingSubmissionListItem))
    -> Html Msg
viewMissingPublishedPage wikiSlug pageSlug maybeContributorWiki myPendingRemote =
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
                                Html.p
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
                                                    [ Html.p [] [ Html.text line1 ] ]
                                                , if String.isEmpty line2 then
                                                    []

                                                  else
                                                    [ Html.p [] [ Html.text line2 ] ]
                                                , [ Html.p []
                                                        [ Html.a
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
                            Html.p []
                                [ Html.a
                                    [ Attr.id "wiki-missing-published-create-link"
                                    , Attr.href (Wiki.submitNewPageUrlPathWithSuggestedSlug wikiSlug pageSlug)
                                    ]
                                    [ Html.text "Create this page" ]
                                ]

                    else
                        Html.p []
                            [ Html.text "Log in on this wiki to create it. "
                            , Html.a
                                [ Attr.id "wiki-missing-published-login-link"
                                , Attr.href (Wiki.loginUrlPath wikiSlug)
                                ]
                                [ Html.text "Log in" ]
                            ]

                Nothing ->
                    Html.p []
                        [ Html.a
                            [ Attr.id "wiki-missing-published-login-link"
                            , Attr.href
                                (Wiki.loginUrlPathWithRedirect wikiSlug
                                    (Wiki.submitNewPageUrlPathWithSuggestedSlug wikiSlug pageSlug)
                                )
                            ]
                            [ Html.text "Log in to create this page" ]
                        ]
    in
    Html.div
        [ Attr.id "wiki-missing-published-page"
        , Attr.attribute "data-wiki-slug" wikiSlug
        , Attr.attribute "data-page-slug" pageSlug
        ]
        [ Html.p []
            [ Html.text ("The page \"" ++ pageSlug ++ "\" does not exist yet.") ]
        , pendingSection
        , contributorCreateOrLogin
        ]


viewPublishedPage : Wiki.Slug -> Page.Slug -> Page.FrontendDetails -> (Page.Slug -> Bool) -> Html Msg
viewPublishedPage wikiSlug pageSlug pageDetails publishedSlugExists =
    Html.div
        [ Attr.id "page-published-page"
        , Attr.attribute "data-wiki-slug" wikiSlug
        , Attr.attribute "data-page-slug" pageSlug
        ]
        [ PageMarkdown.view wikiSlug publishedSlugExists pageDetails
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

                        RemoteData.Failure _ ->
                            viewMissingPublishedPage wikiSlug
                                pageSlug
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

                        RemoteData.Success pageDetails ->
                            viewPublishedPage wikiSlug pageSlug pageDetails (publishedSlugExistsFromWikiDetails wikiDetails)


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

        Route.HostAdminBackup ->
            viewHostAdminBackupPage model

        Route.WikiHome slug ->
            viewWikiHomeRoute model slug

        Route.WikiPage wikiSlug pageSlug ->
            viewPublishedPageRoute model wikiSlug pageSlug

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
                    Just (viewBacklinks wikiSlug pageDetails.backlinks)

                _ ->
                    Nothing

        _ ->
            Nothing


publishedPageEditLink : Model -> Maybe (Html Msg)
publishedPageEditLink model =
    let
        sidebarPageActionLink : String -> String -> String -> Html Msg
        sidebarPageActionLink label hrefPath linkId =
            Html.div [ TW.cls UI.sidebarDesktopOnlyClass ]
                [ Html.div [ TW.cls UI.sidebarNavSectionBodyClass ]
                    [ UI.sidebarLink
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
                        "Edit"

                    else
                        "Propose edit"
            in
            Html.div
                [ TW.cls UI.sidebarNavSectionBodyClass
                , TW.cls "flex flex-col gap-[0.25rem]"
                ]
                [ UI.sidebarLink
                    [ Attr.href (Wiki.submitEditUrlPath wikiSlug pageSlug)
                    , Attr.id "wiki-page-propose-edit"
                    ]
                    [ Html.text proposeOrEditLabel ]
                , UI.sidebarLink
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
                ( Success _, Success _, Success _ ) ->
                    if contributorLoggedInOnWikiSlug wikiSlug model then
                        Just (contributorPublishedPageActions wikiSlug pageSlug)

                    else
                        Just
                            (sidebarPageActionLink
                                "Edit page"
                                (Wiki.submitEditUrlPath wikiSlug pageSlug)
                                "page-edit-link"
                            )

                ( Success _, Success _, Failure _ ) ->
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


view : Model -> Effect.Browser.Document Msg
view model =
    let
        tocEntries : List PageToc.Entry
        tocEntries =
            articleTocEntries model

        maybeBacklinks : Maybe (Html Msg)
        maybeBacklinks =
            publishedPageBacklinks model

        maybeEditLink : Maybe (Html Msg)
        maybeEditLink =
            publishedPageEditLink model

        hasRightColumn : Bool
        hasRightColumn =
            (case maybeEditLink of
                Just _ ->
                    True

                Nothing ->
                    False
            )
                || not (List.isEmpty tocEntries)
                || (case maybeBacklinks of
                        Just _ ->
                            True

                        Nothing ->
                            False
                   )

        rightColumnSections : List (Html Msg)
        rightColumnSections =
            [ maybeEditLink
            , if List.isEmpty tocEntries then
                Nothing

              else
                Just
                    (Html.div [ TW.cls UI.sidebarDesktopOnlyClass ]
                        [ PageToc.view tocEntries ]
                    )
            , maybeBacklinks
            ]
                |> List.filterMap identity

        mainColumnClass : String
        mainColumnClass =
            if routeUsesAuditLogFillLayout model.route then
                UI.layoutMainColumnClassAuditFill hasRightColumn

            else
                UI.layoutMainColumnClass hasRightColumn

        mainColumnBody : Html Msg
        mainColumnBody =
            if routeUsesAuditLogFillLayout model.route then
                Html.div
                    [ TW.cls "flex min-h-0 min-w-0 flex-1 flex-col" ]
                    [ viewBody model ]

            else
                viewBody model

        mainColumns : List (Html Msg)
        mainColumns =
            List.concat
                [ [ Html.aside [ TW.cls UI.layoutLeftNavAsideClass ]
                        [ viewRouteSideNav model ]
                  , Html.main_
                        [ Attr.id UI.appMainScrollRegionId
                        , TW.cls mainColumnClass
                        ]
                        [ mainColumnBody ]
                  ]
                , if List.isEmpty rightColumnSections then
                    []

                  else
                    [ Html.aside [ TW.cls UI.sidebarContainerClass ]
                        rightColumnSections
                    ]
                ]
    in
    { title = documentTitle model
    , body =
        [ Html.div
            [ TW.cls <|
                case ColorTheme.effectiveColorTheme model.colorThemePreference model.systemColorTheme of
                    ColorTheme.Light ->
                        UI.appRootClass

                    ColorTheme.Dark ->
                        UI.appRootClass ++ " dark"
            ]
            [ viewAppHeader model
            , Html.div [ TW.cls (UI.layoutHolyGrailClass hasRightColumn) ] mainColumns
            ]
        ]
    }

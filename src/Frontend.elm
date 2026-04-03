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
import Dict exposing (Dict)
import Effect.Browser exposing (UrlRequest)
import Effect.Browser.Dom
import Effect.Browser.Navigation
import Effect.Command as Command exposing (Command, FrontendOnly)
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
import Store exposing (Store)
import Submission
import SubmissionReviewDetail
import Svg
import Svg.Attributes as SvgAttr
import TW
import Types exposing (FrontendModel, FrontendMsg(..), HostAdminCreateWikiDraft, HostAdminLoginDraft, HostAdminWikiDetailDraft, LoginDraft, NewPageSubmitDraft, PageDeleteSubmitDraft, PageEditSubmitDraft, RegisterDraft, ReviewApproveDraft, ReviewRejectDraft, ReviewRequestChangesDraft, ToBackend(..), ToFrontend(..))
import UI
import Url exposing (Url)
import Wiki
import WikiAdminUsers
import WikiAuditLog
import WikiRole


type alias Model =
    FrontendModel


type alias Msg =
    FrontendMsg


type AppHeaderSecondary
    = AppHeaderSecondaryPlain String
    | AppHeaderSecondaryWikiLink String


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


storeConfig : Store.Config ToBackend
storeConfig =
    { requestWikiCatalog = RequestWikiCatalog
    , requestWikiFrontendDetails = RequestWikiFrontendDetails
    , requestPageFrontendDetails = RequestPageFrontendDetails
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
    , markdownBody = ""
    , inFlight = False
    , lastResult = Nothing
    }


emptyPageEditSubmitDraft : PageEditSubmitDraft
emptyPageEditSubmitDraft =
    { markdownBody = ""
    , inFlight = False
    , lastResult = Nothing
    , lastResubmitResult = Nothing
    }


emptyPageDeleteSubmitDraft : PageDeleteSubmitDraft
emptyPageDeleteSubmitDraft =
    { reasonText = ""
    , inFlight = False
    , lastResult = Nothing
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

                Route.WikiList ->
                    Command.none

                Route.HostAdmin _ ->
                    Command.none

                Route.HostAdminWikiNew ->
                    Effect.Lamdera.sendToBackend RequestHostWikiList

                Route.HostAdminWikiDetail slug ->
                    Effect.Lamdera.sendToBackend (RequestHostWikiDetail slug)

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


gatedWikiRoute : Model -> Url -> ( Route, Maybe String )
gatedWikiRoute model url =
    let
        parsed : Route
        parsed =
            Route.fromUrl url
    in
    case
        RouteAccess.contributorForcedRedirect
            { contributorWikiSession = model.contributorWikiSession
            , contributorWikiRole = model.contributorWikiRole
            }
            url
            parsed
    of
        Just ( wikiSlug, ret ) ->
            ( Route.WikiLogin wikiSlug (Just ret)
            , Just (Wiki.loginUrlPathWithRedirect wikiSlug ret)
            )

        Nothing ->
            ( parsed, Nothing )


wikiSessionTrustedOnWiki : Wiki.Slug -> Model -> Bool
wikiSessionTrustedOnWiki wikiSlug model =
    model.contributorWikiSession
        == Just wikiSlug
        && (model.contributorWikiRole
                |> Maybe.map WikiRole.isTrustedModerator
                |> Maybe.withDefault False
           )


wikiSessionWikiAdminOnWiki : Wiki.Slug -> Model -> Bool
wikiSessionWikiAdminOnWiki wikiSlug model =
    model.contributorWikiSession
        == Just wikiSlug
        && (model.contributorWikiRole
                |> Maybe.map WikiRole.canAccessWikiAdminUsers
                |> Maybe.withDefault False
           )


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

        Route.HostAdmin _ ->
            case model.hostAdminLoginDraft.lastResult of
                Just (Ok ()) ->
                    True

                _ ->
                    False

        _ ->
            False


appChromeMainNavItems : Model -> List (Html Msg)
appChromeMainNavItems model =
    let
        allWikisLi : Html Msg
        allWikisLi =
            Html.li [] [ Html.a [ Attr.href "/" ] [ Html.text "All wikis" ] ]
    in
    if hostAdminAuthenticated model && hostAdminSectionNavVisible model then
        [ allWikisLi ]

    else
        let
            preLoginHostAdminExtras : List (Html Msg)
            preLoginHostAdminExtras =
                if hostAdminSectionNavVisible model then
                    [ Html.li [] [ Html.a [ Attr.href Wiki.hostAdminWikisUrlPath ] [ Html.text "Hosted wikis" ] ]
                    , Html.li [] [ Html.a [ Attr.href Wiki.hostAdminNewWikiUrlPath ] [ Html.text "Add wiki" ] ]
                    ]

                else
                    []
        in
        List.concat
            [ [ allWikisLi
              , if hostAdminAuthenticated model then
                    Html.li []
                        [ Html.a [ Attr.href Wiki.hostAdminWikisUrlPath ] [ Html.text "Admin" ] ]

                else
                    Html.li []
                        [ Html.a
                            [ Attr.href "/admin"
                            , TW.cls UI.sideNavPublicAdminLinkClass
                            ]
                            [ Html.text "Admin" ]
                        ]
              ]
            , preLoginHostAdminExtras
            ]


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


appChromeHostAdminSection : Model -> List (SideNavSection Msg)
appChromeHostAdminSection model =
    if hostAdminAuthenticated model && hostAdminSectionNavVisible model then
        [ { heading = "Host admin"
          , items =
                [ Html.li [] [ Html.a [ Attr.href Wiki.hostAdminWikisUrlPath ] [ Html.text "Hosted wikis" ] ]
                , Html.li [] [ Html.a [ Attr.href Wiki.hostAdminNewWikiUrlPath ] [ Html.text "Add wiki" ] ]
                ]
          }
        ]

    else
        []


viewSortOfWikiSideNavSections : Model -> List (SideNavSection Msg)
viewSortOfWikiSideNavSections model =
    List.concat
        [ [ { heading = "SortOfWiki"
            , items = appChromeMainNavItems model
            }
          ]
        , appChromeHostAdminSection model
        ]


wikiNavReviewLis : Wiki.Slug -> Model -> List (Html Msg)
wikiNavReviewLis wikiSlug model =
    if wikiSessionTrustedOnWiki wikiSlug model then
        [ Html.li []
            [ Html.a [ Attr.href (Wiki.reviewQueueUrlPath wikiSlug) ] [ Html.text "Review" ] ]
        ]

    else
        []


wikiNavWikiAdminLis : Wiki.Slug -> Model -> List (Html Msg)
wikiNavWikiAdminLis wikiSlug model =
    if wikiSessionWikiAdminOnWiki wikiSlug model then
        let
            wikiLabel : String
            wikiLabel =
                case Store.get wikiSlug model.store.wikiCatalog of
                    RemoteData.Success summary ->
                        summary.name

                    RemoteData.Failure _ ->
                        wikiSlug

                    RemoteData.Loading ->
                        wikiSlug

                    RemoteData.NotAsked ->
                        wikiSlug
        in
        [ Html.li []
            [ Html.a [ Attr.href (Wiki.adminUsersUrlPath wikiSlug) ]
                [ Html.text ("Admin (wiki " ++ wikiLabel ++ ")") ]
            ]
        , Html.li []
            [ Html.a [ Attr.href (Wiki.adminAuditUrlPath wikiSlug) ] [ Html.text "Audit log" ] ]
        ]

    else
        []


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
            , contributorWikiSession = Nothing
            , contributorWikiRole = Nothing
            , contributorDisplayUsername = Nothing
            , registerDraft = emptyRegisterDraft
            , loginDraft = emptyLoginDraft
            , newPageSubmitDraft = emptyNewPageSubmitDraft
            , pageEditSubmitDraft = emptyPageEditSubmitDraft
            , pageDeleteSubmitDraft = emptyPageDeleteSubmitDraft
            , reviewApproveDraft = emptyReviewApproveDraft
            , reviewRejectDraft = emptyReviewRejectDraft
            , reviewRequestChangesDraft = emptyReviewRequestChangesDraft
            , adminPromoteError = Nothing
            , adminDemoteError = Nothing
            , adminGrantAdminError = Nothing
            , adminRevokeAdminError = Nothing
            , wikiAdminAuditFilterActorDraft = ""
            , wikiAdminAuditFilterPageDraft = ""
            , wikiAdminAuditFilterSelectedKindTags = []
            , wikiAdminAuditAppliedFilter = WikiAuditLog.emptyAuditLogFilter
            , hostAdminLoginDraft = emptyHostAdminLoginDraft
            , hostAdminCreateWikiDraft = emptyHostAdminCreateWikiDraft
            , hostAdminWikiDetailDraft = emptyHostAdminWikiDetailDraft
            , hostAdminWikis = RemoteData.NotAsked
            , hostAdminSessionAuthenticated = False
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
            , contributorWikiSession = Nothing
            , contributorWikiRole = Nothing
            , contributorDisplayUsername = Nothing
            , registerDraft = emptyRegisterDraft
            , loginDraft = emptyLoginDraft
            , newPageSubmitDraft = emptyNewPageSubmitDraft
            , pageEditSubmitDraft = emptyPageEditSubmitDraft
            , pageDeleteSubmitDraft = emptyPageDeleteSubmitDraft
            , reviewApproveDraft = emptyReviewApproveDraft
            , reviewRejectDraft = emptyReviewRejectDraft
            , reviewRequestChangesDraft = emptyReviewRequestChangesDraft
            , adminPromoteError = Nothing
            , adminDemoteError = Nothing
            , adminGrantAdminError = Nothing
            , adminRevokeAdminError = Nothing
            , wikiAdminAuditFilterActorDraft = ""
            , wikiAdminAuditFilterPageDraft = ""
            , wikiAdminAuditFilterSelectedKindTags = []
            , wikiAdminAuditAppliedFilter = WikiAuditLog.emptyAuditLogFilter
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

                    Route.HostAdminWikiNew ->
                        RemoteData.Loading

                    _ ->
                        RemoteData.NotAsked
            , hostAdminSessionAuthenticated = False
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


{-| Story 14: after trusted direct publish, drop cached wiki index and page payloads so the next fetch sees server state.
-}
invalidateWikiPublishedCaches : Wiki.Slug -> Store -> Store
invalidateWikiPublishedCaches wikiSlug store =
    { store
        | wikiDetails = Dict.remove wikiSlug store.wikiDetails
        , publishedPages =
            store.publishedPages
                |> Dict.filter (\( w, _ ) _ -> w /= wikiSlug)
    }


{-| After a successful approve (story 17), drop cached wiki/page/review data so the next fetch matches the server.
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
        , reviewSubmissionDetails =
            Dict.remove ( wikiSlug, submissionId ) base.reviewSubmissionDetails
    }


{-| After a successful reject (story 18): review caches + contributor submission detail; wiki pages unchanged.
-}
afterRejectSubmissionCaches : Wiki.Slug -> String -> Store -> Store
afterRejectSubmissionCaches wikiSlug submissionId store =
    { store
        | reviewQueues = Dict.remove wikiSlug store.reviewQueues
        , reviewSubmissionDetails =
            Dict.remove ( wikiSlug, submissionId ) store.reviewSubmissionDetails
        , submissionDetails =
            Dict.remove ( wikiSlug, submissionId ) store.submissionDetails
    }


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
                    , Effect.Browser.Navigation.pushUrl model.key (Url.toString url)
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
                        , newPageSubmitDraft = emptyNewPageSubmitDraft
                        , pageEditSubmitDraft = emptyPageEditSubmitDraft
                        , pageDeleteSubmitDraft = emptyPageDeleteSubmitDraft
                        , reviewApproveDraft = emptyReviewApproveDraft
                        , reviewRejectDraft = emptyReviewRejectDraft
                        , reviewRequestChangesDraft = emptyReviewRequestChangesDraft
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

                                Route.WikiList ->
                                    RemoteData.NotAsked

                                Route.HostAdmin _ ->
                                    RemoteData.NotAsked

                                Route.HostAdminWikiNew ->
                                    RemoteData.Loading

                                Route.HostAdminWikiDetail _ ->
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

                        _ ->
                            baseNext
            in
            ( next, navCmd )
                |> runRouteStoreActions
                |> batchScrollAfterUrlChange url.fragment

        UrlFragmentScrollDone ->
            ( model, Command.none )

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

                Route.WikiReview _ ->
                    ( model, Command.none )

                Route.WikiReviewDetail _ _ ->
                    ( model, Command.none )

                Route.WikiAdminUsers _ ->
                    ( model, Command.none )

                Route.WikiAdminAudit _ ->
                    ( model, Command.none )

                Route.HostAdmin _ ->
                    ( model, Command.none )

                Route.HostAdminWikis ->
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
                                (RegisterContributor wikiSlug d.username d.password)
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
                                (LoginContributor wikiSlug d.username d.password)
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

                Route.WikiReview _ ->
                    ( model, Command.none )

                Route.WikiReviewDetail _ _ ->
                    ( model, Command.none )

                Route.WikiAdminUsers _ ->
                    ( model, Command.none )

                Route.WikiAdminAudit _ ->
                    ( model, Command.none )

                Route.HostAdmin _ ->
                    ( model, Command.none )

                Route.HostAdminWikis ->
                    ( model, Command.none )

                Route.HostAdminWikiNew ->
                    ( model, Command.none )

                Route.HostAdminWikiDetail _ ->
                    ( model, Command.none )

                Route.NotFound _ ->
                    ( model, Command.none )

        NewPageSubmitSlugChanged value ->
            let
                d : NewPageSubmitDraft
                d =
                    model.newPageSubmitDraft
            in
            ( { model | newPageSubmitDraft = { d | pageSlug = value } }
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
                            ( { model
                                | newPageSubmitDraft =
                                    { d
                                        | inFlight = True
                                        , lastResult = Nothing
                                    }
                              }
                            , Effect.Lamdera.sendToBackend
                                (SubmitNewPage wikiSlug d.pageSlug d.markdownBody)
                            )

                Route.WikiSubmitEdit _ _ ->
                    ( model, Command.none )

                Route.WikiSubmitDelete _ _ ->
                    ( model, Command.none )

                Route.WikiSubmissionDetail _ _ ->
                    ( model, Command.none )

                Route.WikiReview _ ->
                    ( model, Command.none )

                Route.WikiReviewDetail _ _ ->
                    ( model, Command.none )

                Route.WikiAdminUsers _ ->
                    ( model, Command.none )

                Route.WikiAdminAudit _ ->
                    ( model, Command.none )

                Route.HostAdmin _ ->
                    ( model, Command.none )

                Route.HostAdminWikis ->
                    ( model, Command.none )

                Route.HostAdminWikiNew ->
                    ( model, Command.none )

                Route.HostAdminWikiDetail _ ->
                    ( model, Command.none )

                Route.NotFound _ ->
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
                    case Submission.validateEditMarkdown d.markdownBody of
                        Err ve ->
                            ( { model
                                | pageEditSubmitDraft =
                                    { d
                                        | lastResult = Just (Err (Submission.EditValidation ve))
                                        , lastResubmitResult = Nothing
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
                                        , lastResubmitResult = Nothing
                                    }
                              }
                            , Effect.Lamdera.sendToBackend
                                (SubmitPageEdit wikiSlug pageSlug d.markdownBody)
                            )

                Route.WikiSubmitDelete _ _ ->
                    ( model, Command.none )

                Route.WikiSubmissionDetail _ _ ->
                    ( model, Command.none )

                Route.WikiReview _ ->
                    ( model, Command.none )

                Route.WikiReviewDetail _ _ ->
                    ( model, Command.none )

                Route.WikiAdminUsers _ ->
                    ( model, Command.none )

                Route.WikiAdminAudit _ ->
                    ( model, Command.none )

                Route.HostAdmin _ ->
                    ( model, Command.none )

                Route.HostAdminWikis ->
                    ( model, Command.none )

                Route.HostAdminWikiNew ->
                    ( model, Command.none )

                Route.HostAdminWikiDetail _ ->
                    ( model, Command.none )

                Route.NotFound _ ->
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

        PageDeleteSubmitFormSubmitted ->
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
                    in
                    case Submission.validateDeleteReason d.reasonText of
                        Err ve ->
                            ( { model
                                | pageDeleteSubmitDraft =
                                    { d
                                        | lastResult = Just (Err (Submission.DeleteValidation ve))
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
                            , Effect.Lamdera.sendToBackend
                                (SubmitPageDelete wikiSlug pageSlug d.reasonText)
                            )

                Route.WikiSubmissionDetail _ _ ->
                    ( model, Command.none )

                Route.WikiReview _ ->
                    ( model, Command.none )

                Route.WikiReviewDetail _ _ ->
                    ( model, Command.none )

                Route.WikiAdminUsers _ ->
                    ( model, Command.none )

                Route.WikiAdminAudit _ ->
                    ( model, Command.none )

                Route.HostAdmin _ ->
                    ( model, Command.none )

                Route.HostAdminWikis ->
                    ( model, Command.none )

                Route.HostAdminWikiNew ->
                    ( model, Command.none )

                Route.HostAdminWikiDetail _ ->
                    ( model, Command.none )

                Route.NotFound _ ->
                    ( model, Command.none )

        SubmissionConflictResubmitMarkdownChanged value ->
            let
                d : PageEditSubmitDraft
                d =
                    model.pageEditSubmitDraft
            in
            ( { model | pageEditSubmitDraft = { d | markdownBody = value } }
            , Command.none
            )

        SubmissionConflictResubmitSubmitted ->
            case model.route of
                Route.WikiSubmissionDetail wikiSlug submissionId ->
                    let
                        d : PageEditSubmitDraft
                        d =
                            model.pageEditSubmitDraft
                    in
                    case Submission.validateEditMarkdown d.markdownBody of
                        Err ve ->
                            ( { model
                                | pageEditSubmitDraft =
                                    { d
                                        | lastResubmitResult = Just (Err (Submission.ResubmitEditValidation ve))
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
                                        , lastResubmitResult = Nothing
                                    }
                              }
                            , Effect.Lamdera.sendToBackend
                                (ResubmitPageEdit wikiSlug submissionId d.markdownBody)
                            )

                _ ->
                    ( model, Command.none )

        ReviewApproveSubmitted ->
            case model.route of
                Route.WikiReviewDetail wikiSlug submissionId ->
                    ( { model
                        | reviewApproveDraft =
                            { inFlight = True
                            , lastResult = Nothing
                            }
                      }
                    , Effect.Lamdera.sendToBackend (ApproveSubmission wikiSlug submissionId)
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

                Route.WikiReview _ ->
                    ( model, Command.none )

                Route.WikiAdminUsers _ ->
                    ( model, Command.none )

                Route.WikiAdminAudit _ ->
                    ( model, Command.none )

                Route.HostAdmin _ ->
                    ( model, Command.none )

                Route.HostAdminWikis ->
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

        ReviewRejectSubmitted ->
            case model.route of
                Route.WikiReviewDetail wikiSlug submissionId ->
                    ( { model
                        | reviewRejectDraft =
                            { reasonText = model.reviewRejectDraft.reasonText
                            , inFlight = True
                            , lastResult = Nothing
                            }
                      }
                    , Effect.Lamdera.sendToBackend
                        (RejectSubmission wikiSlug submissionId model.reviewRejectDraft.reasonText)
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

                Route.WikiReview _ ->
                    ( model, Command.none )

                Route.WikiAdminUsers _ ->
                    ( model, Command.none )

                Route.WikiAdminAudit _ ->
                    ( model, Command.none )

                Route.HostAdmin _ ->
                    ( model, Command.none )

                Route.HostAdminWikis ->
                    ( model, Command.none )

                Route.HostAdminWikiNew ->
                    ( model, Command.none )

                Route.HostAdminWikiDetail _ ->
                    ( model, Command.none )

                Route.NotFound _ ->
                    ( model, Command.none )

        ReviewRequestChangesNoteChanged value ->
            let
                d : ReviewRequestChangesDraft
                d =
                    model.reviewRequestChangesDraft
            in
            ( { model | reviewRequestChangesDraft = { d | guidanceText = value } }
            , Command.none
            )

        ReviewRequestChangesSubmitted ->
            case model.route of
                Route.WikiReviewDetail wikiSlug submissionId ->
                    ( { model
                        | reviewRequestChangesDraft =
                            { guidanceText = model.reviewRequestChangesDraft.guidanceText
                            , inFlight = True
                            , lastResult = Nothing
                            }
                      }
                    , Effect.Lamdera.sendToBackend
                        (RequestSubmissionChanges wikiSlug submissionId model.reviewRequestChangesDraft.guidanceText)
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

                Route.WikiReview _ ->
                    ( model, Command.none )

                Route.WikiAdminUsers _ ->
                    ( model, Command.none )

                Route.WikiAdminAudit _ ->
                    ( model, Command.none )

                Route.HostAdmin _ ->
                    ( model, Command.none )

                Route.HostAdminWikis ->
                    ( model, Command.none )

                Route.HostAdminWikiNew ->
                    ( model, Command.none )

                Route.HostAdminWikiDetail _ ->
                    ( model, Command.none )

                Route.NotFound _ ->
                    ( model, Command.none )

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

                Route.WikiReview _ ->
                    ( model, Command.none )

                Route.WikiReviewDetail _ _ ->
                    ( model, Command.none )

                Route.WikiAdminAudit _ ->
                    ( model, Command.none )

                Route.HostAdmin _ ->
                    ( model, Command.none )

                Route.HostAdminWikis ->
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

                Route.WikiReview _ ->
                    ( model, Command.none )

                Route.WikiReviewDetail _ _ ->
                    ( model, Command.none )

                Route.WikiAdminAudit _ ->
                    ( model, Command.none )

                Route.HostAdmin _ ->
                    ( model, Command.none )

                Route.HostAdminWikis ->
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

                Route.WikiReview _ ->
                    ( model, Command.none )

                Route.WikiReviewDetail _ _ ->
                    ( model, Command.none )

                Route.WikiAdminAudit _ ->
                    ( model, Command.none )

                Route.HostAdmin _ ->
                    ( model, Command.none )

                Route.HostAdminWikis ->
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

                Route.WikiReview _ ->
                    ( model, Command.none )

                Route.WikiReviewDetail _ _ ->
                    ( model, Command.none )

                Route.WikiAdminAudit _ ->
                    ( model, Command.none )

                Route.HostAdmin _ ->
                    ( model, Command.none )

                Route.HostAdminWikis ->
                    ( model, Command.none )

                Route.HostAdminWikiNew ->
                    ( model, Command.none )

                Route.HostAdminWikiDetail _ ->
                    ( model, Command.none )

                Route.NotFound _ ->
                    ( model, Command.none )

        WikiAdminAuditFilterActorChanged value ->
            ( { model | wikiAdminAuditFilterActorDraft = value }
            , Command.none
            )

        WikiAdminAuditFilterPageChanged value ->
            ( { model | wikiAdminAuditFilterPageDraft = value }
            , Command.none
            )

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
            ( { model | wikiAdminAuditFilterSelectedKindTags = nextTags }
            , Command.none
            )

        WikiAdminAuditFilterApplyClicked ->
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

                        store : Store
                        store =
                            withApplied.store

                        performed : ( Store, Command FrontendOnly ToBackend Msg )
                        performed =
                            Store.perform storeConfig (Store.RefreshWikiAuditLog wikiSlug applied) store
                    in
                    storeInModel ( withApplied, Command.none ) performed

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

                Route.WikiReview _ ->
                    ( model, Command.none )

                Route.WikiReviewDetail _ _ ->
                    ( model, Command.none )

                Route.WikiAdminUsers _ ->
                    ( model, Command.none )

                Route.HostAdmin _ ->
                    ( model, Command.none )

                Route.HostAdminWikis ->
                    ( model, Command.none )

                Route.HostAdminWikiNew ->
                    ( model, Command.none )

                Route.HostAdminWikiDetail _ ->
                    ( model, Command.none )

                Route.NotFound _ ->
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

        HostAdminCreateWikiSubmitted ->
            case model.route of
                Route.HostAdminWikiNew ->
                    let
                        d : HostAdminCreateWikiDraft
                        d =
                            model.hostAdminCreateWikiDraft
                    in
                    case Submission.validatePageSlug d.slug of
                        Err ve ->
                            ( { model
                                | hostAdminCreateWikiDraft =
                                    { d
                                        | lastResult = Just (Err (HostAdmin.CreateSlugInvalid ve))
                                        , inFlight = False
                                    }
                              }
                            , Command.none
                            )

                        Ok _ ->
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
                                    ( { model
                                        | hostAdminCreateWikiDraft =
                                            { d
                                                | inFlight = True
                                                , lastResult = Nothing
                                            }
                                      }
                                    , Effect.Lamdera.sendToBackend (CreateHostedWiki d.slug d.name)
                                    )

                Route.WikiList ->
                    ( model, Command.none )

                Route.HostAdmin _ ->
                    ( model, Command.none )

                Route.HostAdminWikis ->
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
                                                            (UpdateHostedWikiMetadata d.wikiSlug name summaryText slugText)
                                                        )

                                            _ ->
                                                ( model, Command.none )

                Route.WikiList ->
                    ( model, Command.none )

                Route.HostAdmin _ ->
                    ( model, Command.none )

                Route.HostAdminWikis ->
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

                Route.HostAdminWikiNew ->
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
            in
            ( { model | store = nextStore }, Command.none )
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

                nextContributorWikiRole : Maybe WikiRole.WikiRole
                nextContributorWikiRole =
                    case result of
                        Ok users ->
                            if model.contributorWikiSession == Just wikiSlug then
                                model.contributorDisplayUsername
                                    |> Maybe.andThen
                                        (\uname ->
                                            users
                                                |> List.filter (\u -> u.username == uname)
                                                |> List.head
                                                |> Maybe.map .role
                                        )
                                    |> (\found ->
                                            case found of
                                                Just r ->
                                                    Just r

                                                Nothing ->
                                                    model.contributorWikiRole
                                       )

                            else
                                model.contributorWikiRole

                        Err _ ->
                            model.contributorWikiRole
            in
            ( { model | store = nextStore, contributorWikiRole = nextContributorWikiRole }
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

                nextContributorWiki : Maybe Wiki.Slug
                nextContributorWiki =
                    if d.inFlight then
                        case result of
                            Ok _ ->
                                Just wikiSlug

                            Err _ ->
                                model.contributorWikiSession

                    else
                        model.contributorWikiSession

                nextContributorWikiRole : Maybe WikiRole.WikiRole
                nextContributorWikiRole =
                    if d.inFlight then
                        case result of
                            Ok role ->
                                Just role

                            Err _ ->
                                model.contributorWikiRole

                    else
                        model.contributorWikiRole

                nextContributorDisplayUsername : Maybe String
                nextContributorDisplayUsername =
                    if d.inFlight then
                        case result of
                            Ok _ ->
                                Just (ContributorAccount.normalizeUsername d.username)

                            Err _ ->
                                model.contributorDisplayUsername

                    else
                        model.contributorDisplayUsername

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
                                }

                            Err _ ->
                                store

                    else
                        store

                nextModel : Model
                nextModel =
                    { model
                        | registerDraft = nextDraft
                        , contributorWikiSession = nextContributorWiki
                        , contributorWikiRole = nextContributorWikiRole
                        , contributorDisplayUsername = nextContributorDisplayUsername
                        , store = nextStore
                    }

                afterRegisterCmd : Command FrontendOnly ToBackend Msg
                afterRegisterCmd =
                    case ( nextModel.route, result ) of
                        ( Route.WikiLogin _ (Just path), Ok _ ) ->
                            Effect.Browser.Navigation.pushUrl nextModel.key path

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

                nextContributorWiki : Maybe Wiki.Slug
                nextContributorWiki =
                    if d.inFlight then
                        case result of
                            Ok _ ->
                                Just wikiSlug

                            Err _ ->
                                model.contributorWikiSession

                    else
                        model.contributorWikiSession

                nextContributorWikiRole : Maybe WikiRole.WikiRole
                nextContributorWikiRole =
                    if d.inFlight then
                        case result of
                            Ok role ->
                                Just role

                            Err _ ->
                                model.contributorWikiRole

                    else
                        model.contributorWikiRole

                nextContributorDisplayUsername : Maybe String
                nextContributorDisplayUsername =
                    if d.inFlight then
                        case result of
                            Ok _ ->
                                Just (ContributorAccount.normalizeUsername d.username)

                            Err _ ->
                                model.contributorDisplayUsername

                    else
                        model.contributorDisplayUsername

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
                                }

                            Err _ ->
                                store

                    else
                        store

                nextModel : Model
                nextModel =
                    { model
                        | loginDraft = nextDraft
                        , contributorWikiSession = nextContributorWiki
                        , contributorWikiRole = nextContributorWikiRole
                        , contributorDisplayUsername = nextContributorDisplayUsername
                        , store = nextStore
                    }

                afterLoginCmd : Command FrontendOnly ToBackend Msg
                afterLoginCmd =
                    case ( nextModel.route, result ) of
                        ( Route.WikiLogin _ (Just path), Ok _ ) ->
                            Effect.Browser.Navigation.pushUrl nextModel.key path

                        _ ->
                            Command.none
            in
            ( nextModel, afterLoginCmd )
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

                nextStore : Store
                nextStore =
                    case result of
                        Ok Submission.NewPagePublishedImmediately ->
                            invalidateWikiPublishedCaches wikiSlug model.store

                        Ok (Submission.NewPageSubmittedForReview _) ->
                            model.store

                        Err _ ->
                            model.store
            in
            ( { model | newPageSubmitDraft = nextDraft, store = nextStore }, Command.none )
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
                    case result of
                        Ok Submission.EditPublishedImmediately ->
                            invalidateWikiPublishedCaches wikiSlug model.store

                        Ok (Submission.EditSubmittedForReview _) ->
                            model.store

                        Err _ ->
                            model.store
            in
            ( { model | pageEditSubmitDraft = nextDraft, store = nextStore }, Command.none )
                |> runRouteStoreActions

        SubmitPageDeleteResponse wikiSlug result ->
            let
                d : PageDeleteSubmitDraft
                d =
                    model.pageDeleteSubmitDraft

                nextDraft : PageDeleteSubmitDraft
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
                    case result of
                        Ok Submission.DeletePublishedImmediately ->
                            invalidateWikiPublishedCaches wikiSlug model.store

                        Ok (Submission.DeleteSubmittedForReview _) ->
                            model.store

                        Err _ ->
                            model.store
            in
            ( { model | pageDeleteSubmitDraft = nextDraft, store = nextStore }, Command.none )
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

                d : PageEditSubmitDraft
                d =
                    model.pageEditSubmitDraft

                nextPageEditSubmitDraft : PageEditSubmitDraft
                nextPageEditSubmitDraft =
                    case result of
                        Ok detail ->
                            case detail.conflictContext of
                                Just ctx ->
                                    if detail.status == Submission.NeedsRevision then
                                        { d
                                            | markdownBody = ctx.proposedMarkdown
                                            , inFlight = False
                                        }

                                    else
                                        d

                                Nothing ->
                                    d

                        Err _ ->
                            d
            in
            ( { model | store = nextStore, pageEditSubmitDraft = nextPageEditSubmitDraft }, Command.none )
                |> runRouteStoreActions

        ResubmitPageEditResponse wikiSlug submissionId result ->
            let
                d : PageEditSubmitDraft
                d =
                    model.pageEditSubmitDraft

                nextDraft : PageEditSubmitDraft
                nextDraft =
                    if d.inFlight then
                        case result of
                            Ok () ->
                                { d
                                    | inFlight = False
                                    , lastResubmitResult = Just (Ok (Submission.EditSubmittedForReview (Submission.idFromKey submissionId)))
                                }

                            Err err ->
                                { d
                                    | inFlight = False
                                    , lastResubmitResult = Just (Err err)
                                }

                    else
                        d

                nextStore : Store
                nextStore =
                    case result of
                        Ok () ->
                            let
                                store : Store
                                store =
                                    model.store
                            in
                            { store
                                | submissionDetails =
                                    Dict.insert
                                        ( wikiSlug, submissionId )
                                        RemoteData.Loading
                                        store.submissionDetails
                            }

                        Err _ ->
                            model.store
            in
            ( { model | pageEditSubmitDraft = nextDraft, store = nextStore }
            , case result of
                Ok () ->
                    Effect.Lamdera.sendToBackend (RequestSubmissionDetails wikiSlug submissionId)

                Err _ ->
                    Command.none
            )
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
        , viewWikiPublishedSlugList "wiki-home-page-slugs" wikiSlug details.pageSlugs
        ]


viewNotFound : Html Msg
viewNotFound =
    Html.div
        [ Attr.id "not-found-page"
        ]
        [ Html.p [] [ Html.text "This URL is not part of SortOfWiki yet." ]
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
        authItems : List (Html Msg)
        authItems =
            case model.contributorWikiSession of
                Just sessionWiki ->
                    if sessionWiki /= wikiSlug then
                        [ Html.li [] [ Html.a [ Attr.href (Wiki.loginUrlPath wikiSlug) ] [ Html.text "Log in" ] ]
                        , Html.li [] [ Html.a [ Attr.href (Wiki.registerUrlPath wikiSlug) ] [ Html.text "Register" ] ]
                        ]

                    else
                        [ Html.li []
                            [ Html.span []
                                [ Html.text
                                    ("Logged in"
                                        ++ (model.contributorDisplayUsername
                                                |> Maybe.map (\u -> " as " ++ u)
                                                |> Maybe.withDefault ""
                                           )
                                    )
                                ]
                            ]
                        , Html.li [] [ Html.a [ Attr.href (Wiki.submitNewPageUrlPath wikiSlug) ] [ Html.text "Submit page" ] ]
                        ]

                Nothing ->
                    [ Html.li [] [ Html.a [ Attr.href (Wiki.loginUrlPath wikiSlug) ] [ Html.text "Log in" ] ]
                    , Html.li [] [ Html.a [ Attr.href (Wiki.registerUrlPath wikiSlug) ] [ Html.text "Register" ] ]
                    ]
    in
    List.concat
        [ authItems
        , wikiNavReviewLis wikiSlug model
        , wikiNavWikiAdminLis wikiSlug model
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
    case model.route of
        Route.WikiList ->
            viewAppChromeSideNav model

        Route.NotFound _ ->
            viewAppChromeSideNav model

        Route.HostAdmin _ ->
            viewAppChromeSideNav model

        Route.HostAdminWikis ->
            viewAppChromeSideNav model

        Route.HostAdminWikiNew ->
            viewAppChromeSideNav model

        Route.HostAdminWikiDetail _ ->
            viewAppChromeSideNav model

        Route.WikiHome slug ->
            viewWikiSideNav slug model

        Route.WikiPage slug _ ->
            viewWikiSideNav slug model

        Route.WikiRegister slug ->
            viewWikiSideNav slug model

        Route.WikiLogin slug _ ->
            viewWikiSideNav slug model

        Route.WikiSubmitNew slug ->
            viewWikiSideNav slug model

        Route.WikiSubmitEdit slug _ ->
            viewWikiSideNav slug model

        Route.WikiSubmitDelete slug _ ->
            viewWikiSideNav slug model

        Route.WikiSubmissionDetail slug _ ->
            viewWikiSideNav slug model

        Route.WikiReview slug ->
            viewWikiSideNav slug model

        Route.WikiReviewDetail slug _ ->
            viewWikiSideNav slug model

        Route.WikiAdminUsers slug ->
            viewWikiSideNav slug model

        Route.WikiAdminAudit slug ->
            viewWikiSideNav slug model


wikiScopeHeaderTitle : Store -> Wiki.Slug -> (Wiki.CatalogEntry -> AppHeaderTitle) -> AppHeaderTitle
wikiScopeHeaderTitle store slug whenLoaded =
    case store.wikiCatalog of
        RemoteData.Success dict ->
            case Dict.get slug dict of
                Just summary ->
                    whenLoaded summary

                Nothing ->
                    { primary = "SortOfWiki"
                    , primaryHref = Nothing
                    , secondary = Just (AppHeaderSecondaryPlain "Page not found")
                    }

        RemoteData.Failure _ ->
            { primary = "SortOfWiki"
            , primaryHref = Nothing
            , secondary = Just (AppHeaderSecondaryPlain "Page not found")
            }

        RemoteData.Loading ->
            { primary = "SortOfWiki"
            , primaryHref = Nothing
            , secondary = Just (AppHeaderSecondaryPlain ("Loading wiki: " ++ slug))
            }

        RemoteData.NotAsked ->
            { primary = "SortOfWiki"
            , primaryHref = Nothing
            , secondary = Just (AppHeaderSecondaryPlain ("Loading wiki: " ++ slug))
            }


appHeaderTitle : Model -> AppHeaderTitle
appHeaderTitle { store, route } =
    case route of
        Route.WikiList ->
            { primary = "SortOfWiki"
            , primaryHref = Nothing
            , secondary = Nothing
            }

        Route.HostAdmin _ ->
            { primary = "SortOfWiki"
            , primaryHref = Nothing
            , secondary = Just (AppHeaderSecondaryPlain "Admin login")
            }

        Route.HostAdminWikis ->
            { primary = "SortOfWiki"
            , primaryHref = Nothing
            , secondary = Just (AppHeaderSecondaryPlain "Host wikis")
            }

        Route.HostAdminWikiNew ->
            { primary = "SortOfWiki"
            , primaryHref = Nothing
            , secondary = Just (AppHeaderSecondaryPlain "Create hosted wiki")
            }

        Route.HostAdminWikiDetail slug ->
            { primary = "SortOfWiki"
            , primaryHref = Nothing
            , secondary = Just (AppHeaderSecondaryPlain ("Wiki settings: " ++ slug))
            }

        Route.WikiHome slug ->
            wikiScopeHeaderTitle store slug <|
                \summary ->
                    wikiLoadedHeaderTitle summary Nothing

        Route.WikiPage wikiSlug pageSlug ->
            case store.wikiCatalog of
                RemoteData.Success dict ->
                    case Dict.get wikiSlug dict of
                        Just summary ->
                            wikiLoadedHeaderTitle summary <|
                                case Store.get_ ( wikiSlug, pageSlug ) store.publishedPages of
                                    RemoteData.Success _ ->
                                        Just (AppHeaderSecondaryWikiLink pageSlug)

                                    RemoteData.Failure _ ->
                                        Just (AppHeaderSecondaryPlain "Page not found")

                                    RemoteData.Loading ->
                                        Just (AppHeaderSecondaryWikiLink pageSlug)

                                    RemoteData.NotAsked ->
                                        Just (AppHeaderSecondaryWikiLink pageSlug)

                        Nothing ->
                            { primary = "SortOfWiki"
                            , primaryHref = Nothing
                            , secondary = Just (AppHeaderSecondaryPlain "Page not found")
                            }

                RemoteData.Failure _ ->
                    { primary = "SortOfWiki"
                    , primaryHref = Nothing
                    , secondary = Just (AppHeaderSecondaryPlain "Page not found")
                    }

                RemoteData.Loading ->
                    { primary = wikiSlug
                    , primaryHref = Nothing
                    , secondary = Just (AppHeaderSecondaryWikiLink pageSlug)
                    }

                RemoteData.NotAsked ->
                    { primary = wikiSlug
                    , primaryHref = Nothing
                    , secondary = Just (AppHeaderSecondaryWikiLink pageSlug)
                    }

        Route.WikiRegister slug ->
            wikiScopeHeaderTitle store slug <|
                \summary ->
                    wikiLoadedHeaderTitle summary (Just (AppHeaderSecondaryPlain "Register"))

        Route.WikiLogin slug _ ->
            wikiScopeHeaderTitle store slug <|
                \summary ->
                    wikiLoadedHeaderTitle summary (Just (AppHeaderSecondaryPlain "Log in"))

        Route.WikiSubmitNew slug ->
            wikiScopeHeaderTitle store slug <|
                \summary ->
                    wikiLoadedHeaderTitle summary (Just (AppHeaderSecondaryPlain "Submit page"))

        Route.WikiSubmitEdit wikiSlug _ ->
            wikiScopeHeaderTitle store wikiSlug <|
                \summary ->
                    wikiLoadedHeaderTitle summary (Just (AppHeaderSecondaryPlain "Propose edit"))

        Route.WikiSubmitDelete wikiSlug _ ->
            wikiScopeHeaderTitle store wikiSlug <|
                \summary ->
                    wikiLoadedHeaderTitle summary (Just (AppHeaderSecondaryPlain "Request deletion"))

        Route.WikiSubmissionDetail slug _ ->
            wikiScopeHeaderTitle store slug <|
                \summary ->
                    wikiLoadedHeaderTitle summary (Just (AppHeaderSecondaryPlain "Submission"))

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
            { primary = "SortOfWiki"
            , primaryHref = Nothing
            , secondary = Just (AppHeaderSecondaryPlain "Page not found")
            }


viewAppHeaderSecondary : AppHeaderSecondary -> Html Msg
viewAppHeaderSecondary secondary =
    case secondary of
        AppHeaderSecondaryPlain label ->
            Html.span [ TW.cls UI.appHeaderSecondaryMetaClass ]
                [ Html.em [] [ Html.text label ]
                ]

        AppHeaderSecondaryWikiLink label ->
            Html.span [ TW.cls UI.appHeaderSecondaryWikiWrapClass ]
                [ Html.span [ TW.cls UI.appHeaderSecondaryBracketClass ] [ Html.text "[[" ]
                , Html.em [ TW.cls UI.appHeaderSecondaryWikiLabelEmClass ] [ Html.text label ]
                , Html.span [ TW.cls UI.appHeaderSecondaryBracketClass ] [ Html.text "]]" ]
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
                , viewAppHeaderSecondary sec
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
                    ]
                    []
                ]
            , UI.button
                [ Attr.id "host-admin-login-submit"
                , Attr.type_ "button"
                , Events.onClick HostAdminLoginSubmitted
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
        [ case model.hostAdminWikis of
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
                Html.table
                    [ TW.cls UI.tableAutoClass ]
                    [ Html.thead []
                        [ Html.tr []
                            [ Html.th [ TW.cls UI.tableHeaderCellClass ] [ Html.text "Wiki" ]
                            , Html.th [ TW.cls UI.tableHeaderCellClass ] [ Html.text "Slug" ]
                            , Html.th [ TW.cls UI.tableHeaderCellClass ] [ Html.text "Status" ]
                            ]
                        ]
                    , Html.tbody
                        [ Attr.id "host-admin-wikis-list" ]
                        (summaries
                            |> List.map viewHostAdminWikiRow
                        )
                    ]
        ]


viewHostAdminWikiRow : Wiki.CatalogEntry -> Html Msg
viewHostAdminWikiRow summary =
    Html.tr
        [ TW.cls UI.tableStripedRowClass
        , Attr.attribute "data-context" "host-admin-wiki-row"
        , Attr.attribute "data-wiki-slug" summary.slug
        , Attr.attribute "data-wiki-active"
            (if summary.active then
                "true"

             else
                "false"
            )
        ]
        [ Html.td [ TW.cls UI.tableCellClass ]
            [ Html.a
                [ Attr.href (Wiki.hostAdminWikiDetailUrlPath summary.slug) ]
                [ Html.text summary.name ]
            ]
        , Html.td [ TW.cls UI.tableCellClass ] [ Html.text summary.slug ]
        , Html.td [ TW.cls UI.tableCellClass ]
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
                                    , Attr.type_ "text"
                                    , Attr.value draft.slug
                                    , Events.onInput HostAdminCreateWikiSlugChanged
                                    , Attr.disabled draft.inFlight
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
                                    ]
                                    []
                                ]
                            , UI.button
                                [ Attr.id "host-admin-create-wiki-submit"
                                , Attr.type_ "button"
                                , Events.onClick HostAdminCreateWikiSubmitted
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
                                            , TW.cls (UI.hostAdminWikiSlugClass ++ " w-full max-w-full")
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
                                            ]
                                            []
                                        ]
                                    , UI.button
                                        [ Attr.id "host-admin-wiki-detail-save"
                                        , Attr.type_ "button"
                                        , Events.onClick HostAdminWikiDetailSaveClicked
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
documentTitle ({ store } as model) =
    case model.route of
        Route.WikiList ->
            "SortOfWiki"

        Route.HostAdmin _ ->
            "Host admin — SortOfWiki"

        Route.HostAdminWikis ->
            "Host wikis — SortOfWiki"

        Route.HostAdminWikiNew ->
            "Create hosted wiki — SortOfWiki"

        Route.HostAdminWikiDetail _ ->
            "Edit hosted wiki — SortOfWiki"

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
                    case Store.get_ ( wikiSlug, pageSlug ) store.publishedPages of
                        RemoteData.Success pageDetails ->
                            Page.publishedPageTitle pageSlug pageDetails
                                ++ " — "
                                ++ summary.name
                                ++ " — SortOfWiki"

                        _ ->
                            pageSlug ++ " — " ++ summary.name ++ " — SortOfWiki"

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
                    "Submit new page — " ++ summary.name ++ " — SortOfWiki"

                RemoteData.Failure _ ->
                    "404 — SortOfWiki"

                RemoteData.Loading ->
                    "Loading - SortOfWiki"

                RemoteData.NotAsked ->
                    "Loading - SortOfWiki"

        Route.WikiSubmitEdit wikiSlug pageSlug ->
            case Store.get wikiSlug store.wikiCatalog of
                RemoteData.Success summary ->
                    "Propose edit — " ++ pageSlug ++ " — " ++ summary.name ++ " — SortOfWiki"

                RemoteData.Failure _ ->
                    "404 — SortOfWiki"

                RemoteData.Loading ->
                    "Loading - SortOfWiki"

                RemoteData.NotAsked ->
                    "Loading - SortOfWiki"

        Route.WikiSubmitDelete wikiSlug pageSlug ->
            case Store.get wikiSlug store.wikiCatalog of
                RemoteData.Success summary ->
                    "Request deletion — " ++ pageSlug ++ " — " ++ summary.name ++ " — SortOfWiki"

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
            viewNotFound

        RemoteData.Loading ->
            viewWikiHomeLoading

        RemoteData.NotAsked ->
            viewWikiHomeLoading


viewRegisterFeedback : Maybe (Result ContributorAccount.RegisterContributorError ()) -> Html Msg
viewRegisterFeedback maybeResult =
    case maybeResult of
        Nothing ->
            Html.div [] []

        Just (Ok ()) ->
            Html.div
                [ Attr.id "wiki-register-success" ]
                [ Html.text "Registration complete. You can submit page changes when editing is available." ]

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
            Html.div [] []

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
                    ]
                    []
                ]
            , UI.button
                [ Attr.id "wiki-register-submit"
                , Attr.type_ "button"
                , Events.onClick RegisterFormSubmitted
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
                    ]
                    []
                ]
            , UI.button
                [ Attr.id "wiki-login-submit"
                , Attr.type_ "button"
                , Events.onClick LoginFormSubmitted
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


viewNewPageSubmitFeedback : Wiki.Slug -> NewPageSubmitDraft -> Html Msg
viewNewPageSubmitFeedback wikiSlug draft =
    case draft.lastResult of
        Nothing ->
            Html.div [] []

        Just (Ok success) ->
            case success of
                Submission.NewPagePublishedImmediately ->
                    Html.div
                        [ Attr.id "wiki-submit-new-success" ]
                        [ Html.p []
                            [ Html.text "Published. The page is live now. " ]
                        , Html.a
                            [ Attr.id "wiki-submit-new-success-published-link"
                            , Attr.href (Wiki.publishedPageUrlPath wikiSlug draft.pageSlug)
                            ]
                            [ Html.text "Open page" ]
                        ]

                Submission.NewPageSubmittedForReview submissionId ->
                    let
                        idStr : String
                        idStr =
                            Submission.idToString submissionId
                    in
                    Html.div
                        [ Attr.id "wiki-submit-new-success" ]
                        [ Html.p []
                            [ Html.text ("Submitted for review. Id: " ++ idStr ++ ". ") ]
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


viewSubmitNewLoaded : Wiki.Slug -> NewPageSubmitDraft -> Html Msg
viewSubmitNewLoaded wikiSlug draft =
    Html.div
        [ Attr.id "wiki-submit-new-page"
        , Attr.attribute "data-wiki-slug" wikiSlug
        ]
        [ Html.p []
            [ Html.text "Requires an active contributor session (register or log in on this wiki)." ]
        , Html.form
            [ Attr.id "wiki-submit-new-form"
            , Events.onSubmit NewPageSubmitFormSubmitted
            ]
            [ Html.div []
                [ Html.label [ Attr.for "wiki-submit-new-slug" ]
                    [ Html.text "Page slug" ]
                , Html.input
                    [ Attr.id "wiki-submit-new-slug"
                    , Attr.type_ "text"
                    , Attr.value draft.pageSlug
                    , Events.onInput NewPageSubmitSlugChanged
                    , Attr.disabled draft.inFlight
                    ]
                    []
                ]
            , Html.div []
                [ Html.label [ Attr.for "wiki-submit-new-markdown" ]
                    [ Html.text "Markdown body" ]
                , Html.textarea
                    [ Attr.id "wiki-submit-new-markdown"
                    , Attr.value draft.markdownBody
                    , Events.onInput NewPageSubmitMarkdownChanged
                    , Attr.disabled draft.inFlight
                    , Attr.rows 12
                    ]
                    []
                ]
            , UI.button
                [ Attr.id "wiki-submit-new-submit"
                , Attr.type_ "button"
                , Events.onClick NewPageSubmitFormSubmitted
                , Attr.disabled draft.inFlight
                ]
                [ Html.text "Submit draft" ]
            ]
        , viewNewPageSubmitFeedback wikiSlug draft
        ]


viewSubmitNewRoute : Model -> Wiki.Slug -> Html Msg
viewSubmitNewRoute model wikiSlug =
    case Store.get_ wikiSlug model.store.wikiDetails of
        RemoteData.Success _ ->
            case Store.get wikiSlug model.store.wikiCatalog of
                RemoteData.Success _ ->
                    viewSubmitNewLoaded wikiSlug model.newPageSubmitDraft

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


viewPageEditSubmitFeedback : Wiki.Slug -> Page.Slug -> PageEditSubmitDraft -> Html Msg
viewPageEditSubmitFeedback wikiSlug pageSlug draft =
    case draft.lastResult of
        Nothing ->
            Html.div [] []

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
                        [ Attr.id "wiki-submit-edit-success" ]
                        [ Html.p []
                            [ Html.text ("Submitted for review. Id: " ++ idStr ++ ". ") ]
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


viewSubmitEditLoaded : Wiki.Slug -> Page.Slug -> PageEditSubmitDraft -> Html Msg
viewSubmitEditLoaded wikiSlug pageSlug draft =
    Html.div
        [ Attr.id "wiki-submit-edit-page"
        , Attr.attribute "data-wiki-slug" wikiSlug
        , Attr.attribute "data-page-slug" pageSlug
        ]
        [ Html.p []
            [ Html.text "Published content stays unchanged until a reviewer approves this proposal." ]
        , Html.p []
            [ Html.text "Requires an active contributor session (register or log in on this wiki)." ]
        , Html.form
            [ Attr.id "wiki-submit-edit-form"
            , Events.onSubmit PageEditSubmitFormSubmitted
            ]
            [ Html.div []
                [ Html.label [ Attr.for "wiki-submit-edit-markdown" ]
                    [ Html.text "Proposed markdown" ]
                , Html.textarea
                    [ Attr.id "wiki-submit-edit-markdown"
                    , Attr.value draft.markdownBody
                    , Events.onInput PageEditSubmitMarkdownChanged
                    , Attr.disabled draft.inFlight
                    , Attr.rows 12
                    ]
                    []
                ]
            , UI.button
                [ Attr.id "wiki-submit-edit-submit"
                , Attr.type_ "button"
                , Events.onClick PageEditSubmitFormSubmitted
                , Attr.disabled draft.inFlight
                ]
                [ Html.text "Submit edit proposal" ]
            ]
        , viewPageEditSubmitFeedback wikiSlug pageSlug draft
        ]


viewSubmitEditRoute : Model -> Wiki.Slug -> Page.Slug -> Html Msg
viewSubmitEditRoute model wikiSlug pageSlug =
    case
        ( Store.get_ wikiSlug model.store.wikiDetails
        , Store.get wikiSlug model.store.wikiCatalog
        , Store.get_ ( wikiSlug, pageSlug ) model.store.publishedPages
        )
    of
        ( RemoteData.Success _, RemoteData.Success _, RemoteData.Success _ ) ->
            viewSubmitEditLoaded wikiSlug pageSlug model.pageEditSubmitDraft

        ( _, _, RemoteData.Failure _ ) ->
            viewNotFound

        ( _, _, RemoteData.Loading ) ->
            viewWikiSubmitNewLoading

        ( _, _, RemoteData.NotAsked ) ->
            viewWikiSubmitNewLoading

        ( _, RemoteData.Failure _, _ ) ->
            viewNotFound

        ( _, RemoteData.Loading, _ ) ->
            viewWikiSubmitNewLoading

        ( _, RemoteData.NotAsked, _ ) ->
            viewWikiSubmitNewLoading

        ( RemoteData.Failure _, _, _ ) ->
            viewNotFound

        ( RemoteData.Loading, _, _ ) ->
            viewWikiSubmitNewLoading

        ( RemoteData.NotAsked, _, _ ) ->
            viewWikiSubmitNewLoading


viewPageDeleteSubmitFeedback : Wiki.Slug -> Page.Slug -> PageDeleteSubmitDraft -> Html Msg
viewPageDeleteSubmitFeedback wikiSlug pageSlug draft =
    case draft.lastResult of
        Nothing ->
            Html.div [] []

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
                        [ Attr.id "wiki-submit-delete-success" ]
                        [ Html.p []
                            [ Html.text ("Submitted for review. Id: " ++ idStr ++ ". ") ]
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
                    [ Html.text (Submission.submitPageDeleteErrorToUserText e) ]
                ]


viewSubmitDeleteLoaded : Wiki.Slug -> Page.Slug -> PageDeleteSubmitDraft -> Html Msg
viewSubmitDeleteLoaded wikiSlug pageSlug draft =
    Html.div
        [ Attr.id "wiki-submit-delete-page"
        , Attr.attribute "data-wiki-slug" wikiSlug
        , Attr.attribute "data-page-slug" pageSlug
        ]
        [ Html.p []
            [ Html.text "The page stays published until a reviewer approves this removal (story 17)." ]
        , Html.p []
            [ Html.text "Requires an active contributor session (register or log in on this wiki)." ]
        , Html.form
            [ Attr.id "wiki-submit-delete-form"
            , Events.onSubmit PageDeleteSubmitFormSubmitted
            ]
            [ Html.div []
                [ Html.label [ Attr.for "wiki-submit-delete-reason" ]
                    [ Html.text "Reason (optional)" ]
                , Html.textarea
                    [ Attr.id "wiki-submit-delete-reason"
                    , Attr.value draft.reasonText
                    , Events.onInput PageDeleteSubmitReasonChanged
                    , Attr.disabled draft.inFlight
                    , Attr.rows 4
                    ]
                    []
                ]
            , UI.button
                [ Attr.id "wiki-submit-delete-submit"
                , Attr.type_ "button"
                , Events.onClick PageDeleteSubmitFormSubmitted
                , Attr.disabled draft.inFlight
                ]
                [ Html.text "Submit deletion request" ]
            ]
        , viewPageDeleteSubmitFeedback wikiSlug pageSlug draft
        ]


viewSubmitDeleteRoute : Model -> Wiki.Slug -> Page.Slug -> Html Msg
viewSubmitDeleteRoute model wikiSlug pageSlug =
    case
        ( Store.get_ wikiSlug model.store.wikiDetails
        , Store.get wikiSlug model.store.wikiCatalog
        , Store.get_ ( wikiSlug, pageSlug ) model.store.publishedPages
        )
    of
        ( RemoteData.Success _, RemoteData.Success _, RemoteData.Success _ ) ->
            viewSubmitDeleteLoaded wikiSlug pageSlug model.pageDeleteSubmitDraft

        ( _, _, RemoteData.Failure _ ) ->
            viewNotFound

        ( _, _, RemoteData.Loading ) ->
            viewWikiSubmitNewLoading

        ( _, _, RemoteData.NotAsked ) ->
            viewWikiSubmitNewLoading

        ( _, RemoteData.Failure _, _ ) ->
            viewNotFound

        ( _, RemoteData.Loading, _ ) ->
            viewWikiSubmitNewLoading

        ( _, RemoteData.NotAsked, _ ) ->
            viewWikiSubmitNewLoading

        ( RemoteData.Failure _, _, _ ) ->
            viewNotFound

        ( RemoteData.Loading, _, _ ) ->
            viewWikiSubmitNewLoading

        ( RemoteData.NotAsked, _, _ ) ->
            viewWikiSubmitNewLoading


viewSubmissionDetailBody :
    Wiki.Slug
    -> String
    -> PageEditSubmitDraft
    -> RemoteData () (Result Submission.DetailsError Submission.ContributorView)
    -> Html Msg
viewSubmissionDetailBody wikiSlug submissionId editDraft remote =
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
                , case detail.conflictContext of
                    Nothing ->
                        Html.text ""

                    Just ctx ->
                        if detail.status /= Submission.NeedsRevision then
                            Html.text ""

                        else
                            Html.section
                                [ Attr.id "wiki-submission-detail-conflict"
                                , Attr.attribute "data-page-slug" ctx.pageSlug
                                ]
                                [ Html.h2 [] [ Html.text "Resolve conflict" ]
                                , Html.div []
                                    [ Html.h3 [] [ Html.text "Original published version" ]
                                    , Html.pre
                                        [ Attr.id "wiki-submission-detail-base-markdown" ]
                                        [ Html.text ctx.baseMarkdown ]
                                    ]
                                , Html.div []
                                    [ Html.h3 [] [ Html.text "Your previous proposed edit" ]
                                    , Html.pre
                                        [ Attr.id "wiki-submission-detail-proposed-markdown" ]
                                        [ Html.text ctx.proposedMarkdown ]
                                    ]
                                , Html.div []
                                    [ Html.h3 [] [ Html.text "Current published version" ]
                                    , Html.pre
                                        [ Attr.id "wiki-submission-detail-current-markdown" ]
                                        [ Html.text ctx.currentMarkdown ]
                                    ]
                                , Html.label [ Attr.for "wiki-submission-detail-resubmit-markdown" ]
                                    [ Html.text "Resolved markdown" ]
                                , Html.textarea
                                    [ Attr.id "wiki-submission-detail-resubmit-markdown"
                                    , Attr.value editDraft.markdownBody
                                    , Events.onInput SubmissionConflictResubmitMarkdownChanged
                                    , Attr.disabled editDraft.inFlight
                                    , Attr.rows 12
                                    ]
                                    []
                                , UI.button
                                    [ Attr.id "wiki-submission-detail-resubmit-submit"
                                    , Attr.type_ "button"
                                    , Attr.disabled editDraft.inFlight
                                    , Events.onClick SubmissionConflictResubmitSubmitted
                                    ]
                                    [ Html.text "Resubmit for review" ]
                                , case editDraft.lastResubmitResult of
                                    Just (Ok (Submission.EditSubmittedForReview submissionId_)) ->
                                        if Submission.idToString submissionId_ == submissionId then
                                            Html.div
                                                [ Attr.id "wiki-submission-detail-resubmit-success" ]
                                                [ Html.text "Resubmitted for review." ]

                                        else
                                            Html.text ""

                                    _ ->
                                        Html.text ""
                                , case editDraft.lastResubmitResult of
                                    Just (Err err) ->
                                        Html.div
                                            [ Attr.id "wiki-submission-detail-resubmit-error" ]
                                            [ Html.text (Submission.resubmitPageEditErrorToUserText err) ]

                                    _ ->
                                        Html.text ""
                                , Html.p []
                                    [ Html.text ("Submission: " ++ submissionId ++ " · Wiki: " ++ wikiSlug) ]
                                ]
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
                Html.table
                    [ TW.cls UI.tableFullWidthMax72Class ]
                    [ Html.thead []
                        [ Html.tr []
                            [ Html.th [ TW.cls UI.tableHeaderCellClass ] [ Html.text "Submission" ]
                            , Html.th [ TW.cls UI.tableHeaderCellClass ] [ Html.text "Kind" ]
                            , Html.th [ TW.cls UI.tableHeaderCellClass ] [ Html.text "Author" ]
                            , Html.th [ TW.cls UI.tableHeaderCellClass ] [ Html.text "Page" ]
                            ]
                        ]
                    , Html.tbody
                        [ Attr.id "wiki-review-queue-list" ]
                        (items
                            |> List.map
                                (\item ->
                                    let
                                        idStr : String
                                        idStr =
                                            Submission.idToString item.id
                                    in
                                    Html.tr
                                        [ TW.cls UI.tableStripedRowClass
                                        , Attr.attribute "data-review-queue-item" idStr
                                        ]
                                        [ Html.td [ TW.cls UI.tableCellClass ]
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
                                        , Html.td [ TW.cls UI.tableCellClass ] [ Html.text item.kindLabel ]
                                        , Html.td [ TW.cls UI.tableCellClass ] [ Html.text item.authorDisplay ]
                                        , Html.td [ TW.cls UI.tableCellClass ]
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
                        )
                    ]


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
            Html.table
                [ Attr.id "wiki-admin-users-table"
                , TW.cls UI.tableFullWidthMax72Class
                ]
                [ Html.thead []
                    [ Html.tr []
                        [ Html.th [ TW.cls UI.tableHeaderCellClass ] [ Html.text "Username" ]
                        , Html.th [ TW.cls UI.tableHeaderCellClass ] [ Html.text "Role" ]
                        , Html.th [ TW.cls UI.tableHeaderCellClass ] [ Html.text "Actions" ]
                        ]
                    ]
                , Html.tbody
                    [ Attr.id "wiki-admin-users-tbody" ]
                    (users
                        |> List.map
                            (\u ->
                                Html.tr
                                    [ TW.cls UI.tableStripedRowClass
                                    , Attr.attribute "data-admin-user" u.username
                                    , Attr.attribute "data-wiki-slug" wikiSlug
                                    ]
                                    [ Html.td [ TW.cls UI.tableCellClass ] [ Html.text u.username ]
                                    , Html.td
                                        [ TW.cls UI.tableCellClass
                                        , Attr.attribute "data-user-role" (WikiRole.label u.role)
                                        ]
                                        [ Html.text (WikiRole.label u.role) ]
                                    , Html.td [ TW.cls UI.tableCellClass ]
                                        [ viewWikiAdminUsersPromoteCell u
                                        , viewWikiAdminUsersDemoteCell u
                                        , viewWikiAdminUsersGrantAdminCell u
                                        , viewWikiAdminUsersRevokeAdminCell maybeSelfUsername u
                                        ]
                                    ]
                            )
                    )
                ]


viewWikiAdminUsersPromoteCell : WikiAdminUsers.ListedUser -> Html Msg
viewWikiAdminUsersPromoteCell u =
    case u.role of
        WikiRole.UntrustedContributor ->
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
        WikiRole.UntrustedContributor ->
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
        WikiRole.UntrustedContributor ->
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
        WikiRole.UntrustedContributor ->
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
    case model.contributorWikiSession of
        Just sessionWiki ->
            if sessionWiki == wikiSlug then
                model.contributorDisplayUsername

            else
                Nothing

        Nothing ->
            Nothing


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
                Html.ul
                    [ Attr.id "wiki-admin-audit-list" ]
                    (events
                        |> List.indexedMap
                            (\i ev ->
                                Html.li
                                    [ Attr.attribute "data-audit-event" (String.fromInt i)
                                    , Attr.attribute "data-wiki-slug" wikiSlug
                                    ]
                                    [ Html.text (WikiAuditLog.formatEventRowText ev) ]
                            )
                    )


viewWikiAdminAuditFilters : Model -> Html Msg
viewWikiAdminAuditFilters model =
    Html.div
        [ Attr.attribute "data-context" "wiki-admin-audit-filters" ]
        [ Html.div []
            [ Html.label []
                [ Html.text "Actor contains "
                , Html.input
                    [ Attr.id "wiki-admin-audit-filter-actor"
                    , Attr.type_ "text"
                    , Attr.value model.wikiAdminAuditFilterActorDraft
                    , Events.onInput WikiAdminAuditFilterActorChanged
                    ]
                    []
                ]
            ]
        , Html.div []
            [ Html.label []
                [ Html.text "Page slug contains "
                , Html.input
                    [ Attr.id "wiki-admin-audit-filter-page"
                    , Attr.type_ "text"
                    , Attr.value model.wikiAdminAuditFilterPageDraft
                    , Events.onInput WikiAdminAuditFilterPageChanged
                    ]
                    []
                ]
            ]
        , Html.fieldset
            [ Attr.id "wiki-admin-audit-filter-type" ]
            (Html.legend [] [ Html.text "Event types (none selected = all)" ]
                :: List.map (viewWikiAdminAuditKindCheckbox model) WikiAuditLog.eventKindFilterTagOptions
            )
        , UI.button
            [ Attr.id "wiki-admin-audit-filter-apply"
            , Attr.type_ "button"
            , Events.onClick WikiAdminAuditFilterApplyClicked
            ]
            [ Html.text "Apply filters" ]
        ]


viewWikiAdminAuditKindCheckbox : Model -> ( WikiAuditLog.AuditEventKindFilterTag, String ) -> Html Msg
viewWikiAdminAuditKindCheckbox model ( tag, labelText ) =
    let
        isOn : Bool
        isOn =
            List.member tag model.wikiAdminAuditFilterSelectedKindTags
    in
    Html.label []
        [ Html.input
            [ Attr.type_ "checkbox"
            , Attr.id ("wiki-admin-audit-filter-type-" ++ WikiAuditLog.eventKindFilterTagToString tag)
            , Attr.checked isOn
            , Events.onClick (WikiAdminAuditFilterTypeTagToggled tag (not isOn))
            , Events.onCheck (WikiAdminAuditFilterTypeTagToggled tag)
            ]
            []
        , Html.text (" " ++ labelText)
        ]


viewWikiAdminAuditLoaded : Wiki.Slug -> Model -> Html Msg
viewWikiAdminAuditLoaded wikiSlug model =
    Html.div
        [ Attr.id "wiki-admin-audit-page"
        , Attr.attribute "data-wiki-slug" wikiSlug
        ]
        [ viewWikiAdminAuditFilters model
        , viewWikiAdminAuditBody wikiSlug (Store.getWikiAuditLog wikiSlug model.wikiAdminAuditAppliedFilter model.store)
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


viewSubmissionReviewDiff : SubmissionReviewDetail.SubmissionReviewDetail -> Html Msg
viewSubmissionReviewDiff detail =
    case detail of
        SubmissionReviewDetail.NewPageDiff body ->
            Html.div
                [ Attr.id "wiki-review-diff-summary" ]
                [ Html.p
                    [ Attr.id "wiki-review-diff-marker" ]
                    [ Html.text "new file" ]
                , Html.pre
                    [ Attr.id "wiki-review-diff-new" ]
                    [ Html.text body.proposedMarkdown ]
                ]

        SubmissionReviewDetail.EditPageDiff body ->
            Html.div
                [ Attr.id "wiki-review-diff-summary" ]
                [ Html.div []
                    [ Html.h2 [] [ Html.text "Before (published)" ]
                    , Html.pre
                        [ Attr.id "wiki-review-diff-old" ]
                        [ Html.text body.beforeMarkdown ]
                    ]
                , Html.div []
                    [ Html.h2 [] [ Html.text "After (proposed)" ]
                    , Html.pre
                        [ Attr.id "wiki-review-diff-new" ]
                        [ Html.text body.afterMarkdown ]
                    ]
                ]

        SubmissionReviewDetail.DeletePageDiff body ->
            Html.div
                [ Attr.id "wiki-review-diff-summary" ]
                [ Html.pre
                    [ Attr.id "wiki-review-diff-published" ]
                    [ Html.text body.publishedSnapshotMarkdown ]
                , case body.reason of
                    Nothing ->
                        Html.text ""

                    Just r ->
                        Html.div
                            [ Attr.id "wiki-review-diff-reason" ]
                            [ Html.text r ]
                ]


viewReviewSubmissionDetailBody :
    RemoteData () (Result SubmissionReviewDetail.ReviewSubmissionDetailError SubmissionReviewDetail.SubmissionReviewDetail)
    -> Html Msg
viewReviewSubmissionDetailBody remote =
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
            viewSubmissionReviewDiff d


viewReviewApproveActions : Model -> Wiki.Slug -> String -> Html Msg
viewReviewApproveActions model wikiSlug submissionId =
    case Store.get_ ( wikiSlug, submissionId ) model.store.reviewSubmissionDetails of
        RemoteData.Success (Ok _) ->
            let
                busy : Bool
                busy =
                    model.reviewApproveDraft.inFlight
                        || model.reviewRejectDraft.inFlight
                        || model.reviewRequestChangesDraft.inFlight
            in
            Html.div
                [ Attr.id "wiki-review-approve-actions" ]
                [ UI.button
                    [ Attr.id "wiki-review-approve-submit"
                    , Events.onClick ReviewApproveSubmitted
                    , Attr.disabled busy
                    ]
                    [ Html.text "Approve" ]
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
                ]

        _ ->
            Html.text ""


viewReviewRejectActions : Model -> Wiki.Slug -> String -> Html Msg
viewReviewRejectActions model wikiSlug submissionId =
    case Store.get_ ( wikiSlug, submissionId ) model.store.reviewSubmissionDetails of
        RemoteData.Success (Ok _) ->
            let
                busy : Bool
                busy =
                    model.reviewApproveDraft.inFlight
                        || model.reviewRejectDraft.inFlight
                        || model.reviewRequestChangesDraft.inFlight

                d : ReviewRejectDraft
                d =
                    model.reviewRejectDraft
            in
            Html.div
                [ Attr.id "wiki-review-reject-actions" ]
                [ Html.label []
                    [ Html.text "Rejection reason (required)"
                    , Html.textarea
                        [ Attr.id "wiki-review-reject-reason"
                        , Events.onInput ReviewRejectReasonChanged
                        , Attr.disabled busy
                        , Attr.value d.reasonText
                        ]
                        []
                    ]
                , UI.button
                    [ Attr.id "wiki-review-reject-submit"
                    , Events.onClick ReviewRejectSubmitted
                    , Attr.disabled busy
                    ]
                    [ Html.text "Reject" ]
                , case d.lastResult of
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
                ]

        _ ->
            Html.text ""


viewReviewRequestChangesActions : Model -> Wiki.Slug -> String -> Html Msg
viewReviewRequestChangesActions model wikiSlug submissionId =
    case Store.get_ ( wikiSlug, submissionId ) model.store.reviewSubmissionDetails of
        RemoteData.Success (Ok _) ->
            let
                busy : Bool
                busy =
                    model.reviewApproveDraft.inFlight
                        || model.reviewRejectDraft.inFlight
                        || model.reviewRequestChangesDraft.inFlight

                d : ReviewRequestChangesDraft
                d =
                    model.reviewRequestChangesDraft
            in
            Html.div
                [ Attr.id "wiki-review-request-changes-actions" ]
                [ Html.label []
                    [ Html.text "Guidance for contributor (required)"
                    , Html.textarea
                        [ Attr.id "wiki-review-request-changes-note"
                        , Events.onInput ReviewRequestChangesNoteChanged
                        , Attr.disabled busy
                        , Attr.value d.guidanceText
                        ]
                        []
                    ]
                , UI.button
                    [ Attr.id "wiki-review-request-changes-submit"
                    , Events.onClick ReviewRequestChangesSubmitted
                    , Attr.disabled busy
                    ]
                    [ Html.text "Request changes" ]
                , case d.lastResult of
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
        RemoteData.Success _ ->
            case Store.get wikiSlug model.store.wikiCatalog of
                RemoteData.Success _ ->
                    Html.div
                        [ Attr.id "wiki-review-detail-page"
                        , Attr.attribute "data-wiki-slug" wikiSlug
                        , Attr.attribute "data-submission-id" submissionId
                        ]
                        [ viewReviewSubmissionDetailBody
                            (Store.get_ ( wikiSlug, submissionId ) model.store.reviewSubmissionDetails)
                        , viewReviewApproveActions model wikiSlug submissionId
                        , viewReviewRequestChangesActions model wikiSlug submissionId
                        , viewReviewRejectActions model wikiSlug submissionId
                        , Html.p []
                            [ Html.a
                                [ Attr.id "wiki-review-detail-back-to-queue"
                                , Attr.href (Wiki.reviewQueueUrlPath wikiSlug)
                                ]
                                [ Html.text "Back to review queue" ]
                            ]
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
        RemoteData.Success _ ->
            case Store.get wikiSlug model.store.wikiCatalog of
                RemoteData.Success _ ->
                    Html.div
                        [ Attr.id "wiki-submission-detail-page"
                        , Attr.attribute "data-wiki-slug" wikiSlug
                        , Attr.attribute "data-submission-id" submissionId
                        ]
                        [ viewSubmissionDetailBody
                            wikiSlug
                            submissionId
                            model.pageEditSubmitDraft
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


viewPublishedPage : Wiki.Slug -> Page.Slug -> Page.FrontendDetails -> Maybe Wiki.Slug -> Html Msg
viewPublishedPage wikiSlug pageSlug pageDetails maybeContributorWikiForThisWiki =
    Html.div
        [ Attr.id "page-published-page"
        , Attr.attribute "data-wiki-slug" wikiSlug
        , Attr.attribute "data-page-slug" pageSlug
        ]
        [ PageMarkdown.view wikiSlug pageDetails
        , case maybeContributorWikiForThisWiki of
            Just sessionWiki ->
                if sessionWiki /= wikiSlug then
                    Html.text ""

                else
                    Html.div
                        [ TW.cls UI.publishedPageContributorActionsClass ]
                        [ Html.a
                            [ Attr.id "wiki-page-propose-edit"
                            , Attr.href (Wiki.submitEditUrlPath wikiSlug pageSlug)
                            ]
                            [ Html.text "Propose edit" ]
                        , Html.text " · "
                        , Html.a
                            [ Attr.id "wiki-page-request-deletion"
                            , Attr.href (Wiki.submitDeleteUrlPath wikiSlug pageSlug)
                            ]
                            [ Html.text "Request deletion" ]
                        ]

            Nothing ->
                Html.text ""
        ]


viewPublishedPageRoute : Model -> Wiki.Slug -> Page.Slug -> Html Msg
viewPublishedPageRoute model wikiSlug pageSlug =
    case
        ( Store.get_ wikiSlug model.store.wikiDetails
        , Store.get wikiSlug model.store.wikiCatalog
        , Store.get_ ( wikiSlug, pageSlug ) model.store.publishedPages
        )
    of
        ( RemoteData.Success _, RemoteData.Success _, RemoteData.Success pageDetails ) ->
            viewPublishedPage wikiSlug pageSlug pageDetails model.contributorWikiSession

        ( _, _, RemoteData.Failure _ ) ->
            viewNotFound

        ( _, _, RemoteData.Loading ) ->
            viewWikiHomeLoading

        ( _, _, RemoteData.NotAsked ) ->
            viewWikiHomeLoading

        ( _, RemoteData.Failure _, _ ) ->
            viewNotFound

        ( _, RemoteData.Loading, _ ) ->
            viewWikiHomeLoading

        ( _, RemoteData.NotAsked, _ ) ->
            viewWikiHomeLoading

        ( RemoteData.Failure _, _, _ ) ->
            viewNotFound

        ( RemoteData.Loading, _, _ ) ->
            viewWikiHomeLoading

        ( RemoteData.NotAsked, _, _ ) ->
            viewWikiHomeLoading


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
                ( Success _, Success _, Success pageDetails ) ->
                    PageToc.entries wikiSlug pageDetails

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
    case model.route of
        Route.WikiPage wikiSlug pageSlug ->
            Just
                (Html.div [ TW.cls UI.sidebarDesktopOnlyClass ]
                    [ Html.div [ TW.cls UI.sidebarNavSectionBodyClass ]
                        [ UI.sidebarLink
                            [ Attr.href (Wiki.submitEditUrlPath wikiSlug pageSlug)
                            , Attr.id "page-edit-link"
                            ]
                            [ Html.text "Edit page" ]
                        ]
                    ]
                )

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

        mainColumns : List (Html Msg)
        mainColumns =
            List.concat
                [ [ Html.aside [ TW.cls UI.layoutLeftNavAsideClass ]
                        [ viewRouteSideNav model ]
                  , Html.main_
                        [ Attr.id UI.appMainScrollRegionId
                        , TW.cls (UI.layoutMainColumnClass hasRightColumn)
                        ]
                        [ viewBody model ]
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

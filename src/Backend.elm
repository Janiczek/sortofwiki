module Backend exposing (Model, Msg, app, app_, updateFromFrontendWithTime)

import BackendDataExport
import ContributorAccount
import Dict exposing (Dict)
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Lamdera exposing (ClientId, SessionId)
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Task
import Effect.Time
import Env
import HostAdmin
import Lamdera
import Page
import Set
import Submission
import SubmissionReviewDetail
import Time
import Types exposing (BackendModel, BackendMsg(..), ToBackend(..), ToFrontend(..))
import Wiki exposing (Wiki)
import WikiAdminUsers
import WikiAuditLog
import WikiContributors
import WikiRole
import WikiUser


type alias Model =
    BackendModel


type alias Msg =
    BackendMsg


{-| Point wiki data, contributors, sessions, submissions, and audit log at `newSlug` (hosted wiki slug rename).
-}
applyHostedWikiSlugRename : Wiki.Slug -> Wiki.Slug -> Wiki -> Model -> Model
applyHostedWikiSlugRename oldSlug newSlug nextWiki model =
    let
        nextAudit : Dict Wiki.Slug (List WikiAuditLog.AuditEvent)
        nextAudit =
            case Dict.get oldSlug model.wikiAuditEvents of
                Nothing ->
                    Dict.remove oldSlug model.wikiAuditEvents

                Just events ->
                    model.wikiAuditEvents
                        |> Dict.remove oldSlug
                        |> Dict.insert newSlug events
    in
    { model
        | wikis =
            model.wikis
                |> Dict.remove oldSlug
                |> Dict.insert newSlug nextWiki
        , contributors = WikiContributors.renameWikiSlug oldSlug newSlug model.contributors
        , contributorSessions = WikiUser.remapSessionsForWikiSlugRename oldSlug newSlug model.contributorSessions
        , submissions = Submission.remapWikiSlugInSubmissions oldSlug newSlug model.submissions
        , wikiAuditEvents = nextAudit
    }


{-| Append one audit row at `now`.
Uses the acting account id (moderator / admin), not submission authors.
-}
recordAudit : Time.Posix -> Wiki.Slug -> ContributorAccount.Id -> WikiAuditLog.AuditEventKind -> Model -> Model
recordAudit now wikiSlug actorId kind model =
    let
        actor : String
        actor =
            WikiContributors.displayUsernameForAccount wikiSlug actorId model.contributors
                |> Maybe.withDefault "unknown"
    in
    { model
        | wikiAuditEvents =
            WikiAuditLog.append wikiSlug now actor kind model.wikiAuditEvents
    }


init : ( Model, Command BackendOnly ToFrontend Msg )
init =
    ( { wikis = Dict.empty
      , contributors = WikiContributors.emptyRegistry
      , contributorSessions = WikiUser.emptySessions
      , hostSessions = Set.empty
      , submissions = Dict.empty
      , nextSubmissionCounter = 1
      , wikiAuditEvents = Dict.empty
      }
    , Command.none
    )


update : Msg -> Model -> ( Model, Command BackendOnly ToFrontend Msg )
update msg model =
    case msg of
        ToBackendGotTime sessionId clientId wrapped now ->
            updateFromFrontendWithTime sessionId clientId wrapped now model


{-| Client messages from Lamdera.

**Authorization:** privileged handlers consult `contributorSessions` and `hostSessions`
(and wiki binding) before changing state. Regression coverage: `tests/BackendAuthorizationTest.elm`
(per-message `Err` and no mutation where applicable; see program tests for backend authorization).

**Public:** `RequestWikiCatalog`, `RequestWikiFrontendDetails`, `RequestPageFrontendDetails`.
**Credential setup:** `RegisterContributor`, `LoginContributor`, `LogoutContributor`, `HostAdminLogin`.

Each `ToBackend` is handled after `Effect.Time.now` resolves (see `ToBackendGotTime`).

-}
updateFromFrontend :
    SessionId
    -> ClientId
    -> ToBackend
    -> Model
    -> ( Model, Command BackendOnly ToFrontend Msg )
updateFromFrontend sessionId clientId msg model =
    ( model
    , Effect.Task.perform (ToBackendGotTime sessionId clientId msg) Effect.Time.now
    )


{-| Handle `ToBackend` with a known time (tests and `ToBackendGotTime`).
-}
updateFromFrontendWithTime :
    SessionId
    -> ClientId
    -> ToBackend
    -> Time.Posix
    -> Model
    -> ( Model, Command BackendOnly ToFrontend Msg )
updateFromFrontendWithTime sessionId clientId msg now model =
    case msg of
        RequestWikiCatalog ->
            ( model
            , Effect.Lamdera.sendToFrontend clientId
                (WikiCatalogResponse (Wiki.publicCatalogDict model.wikis))
            )

        RequestWikiFrontendDetails slug ->
            ( model
            , Effect.Lamdera.sendToFrontend clientId
                (WikiFrontendDetailsResponse slug
                    (model.wikis
                        |> Dict.get slug
                        |> Maybe.andThen
                            (\w ->
                                if w.active then
                                    Just (Wiki.frontendDetails w)

                                else
                                    Nothing
                            )
                    )
                )
            )

        RequestPageFrontendDetails wikiSlug pageSlug ->
            ( model
            , Effect.Lamdera.sendToFrontend clientId
                (PageFrontendDetailsResponse wikiSlug
                    pageSlug
                    (model.wikis
                        |> Dict.get wikiSlug
                        |> Maybe.andThen
                            (\w ->
                                if w.active then
                                    Wiki.publishedPageFrontendDetails pageSlug w

                                else
                                    Nothing
                            )
                    )
                )
            )

        RequestReviewQueue wikiSlug ->
            let
                respond : Result Submission.ReviewQueueError (List Submission.ReviewQueueItem) -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (ReviewQueueResponse wikiSlug res)
                    )

                lookupAuthor : ContributorAccount.Id -> Maybe String
                lookupAuthor accountId =
                    WikiContributors.displayUsernameForAccount wikiSlug accountId model.contributors

                wikiPaused : Bool
                wikiPaused =
                    Dict.get wikiSlug model.wikis
                        |> Maybe.map (not << .active)
                        |> Maybe.withDefault False
            in
            if wikiPaused then
                respond (Err Submission.ReviewQueueWikiInactive)

            else
                let
                    sessionKey : String
                    sessionKey =
                        Effect.Lamdera.sessionIdToString sessionId
                in
                case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                    WikiUser.SessionNotLoggedIn ->
                        respond (Err Submission.ReviewQueueNotLoggedIn)

                    WikiUser.SessionWrongWiki ->
                        respond (Err Submission.ReviewQueueWrongWikiSession)

                    WikiUser.SessionHasAccount accountId ->
                        if not (WikiContributors.isTrustedForWiki wikiSlug accountId model.contributors) then
                            respond (Err Submission.ReviewQueueForbidden)

                        else
                            model.submissions
                                |> Submission.pendingSubmissionsForWiki wikiSlug
                                |> List.map (Submission.reviewQueueItemFromSubmission lookupAuthor)
                                |> Ok
                                |> respond

        RequestMyPendingSubmissions wikiSlug ->
            let
                respond : Result Submission.MyPendingSubmissionsError (List Submission.MyPendingSubmissionListItem) -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (MyPendingSubmissionsResponse wikiSlug res)
                    )

                wikiPaused : Bool
                wikiPaused =
                    Dict.get wikiSlug model.wikis
                        |> Maybe.map (not << .active)
                        |> Maybe.withDefault False
            in
            if wikiPaused then
                respond (Err Submission.MyPendingSubmissionsWikiInactive)

            else
                let
                    sessionKey : String
                    sessionKey =
                        Effect.Lamdera.sessionIdToString sessionId
                in
                case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                    WikiUser.SessionNotLoggedIn ->
                        respond (Err Submission.MyPendingSubmissionsNotLoggedIn)

                    WikiUser.SessionWrongWiki ->
                        respond (Err Submission.MyPendingSubmissionsWrongWikiSession)

                    WikiUser.SessionHasAccount accountId ->
                        if WikiContributors.isTrustedForWiki wikiSlug accountId model.contributors then
                            respond (Err Submission.MyPendingSubmissionsForbiddenTrustedModerator)

                        else
                            model.submissions
                                |> Submission.mySubmissionsForAuthorOnWiki wikiSlug accountId
                                |> List.map Submission.myPendingSubmissionListItemFromSubmission
                                |> Ok
                                |> respond

        RequestWikiUsers wikiSlug ->
            let
                respond : Result WikiAdminUsers.Error (List WikiAdminUsers.ListedUser) -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (WikiUsersResponse wikiSlug res)
                    )
            in
            case Dict.get wikiSlug model.wikis of
                Nothing ->
                    respond (Err WikiAdminUsers.WikiNotFound)

                Just w ->
                    if not w.active then
                        respond (Err WikiAdminUsers.WikiInactive)

                    else
                        let
                            sessionKey : String
                            sessionKey =
                                Effect.Lamdera.sessionIdToString sessionId
                        in
                        case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                            WikiUser.SessionNotLoggedIn ->
                                respond (Err WikiAdminUsers.NotLoggedIn)

                            WikiUser.SessionWrongWiki ->
                                respond (Err WikiAdminUsers.WrongWikiSession)

                            WikiUser.SessionHasAccount accountId ->
                                if not (WikiContributors.isAdminForWiki wikiSlug accountId model.contributors) then
                                    respond (Err WikiAdminUsers.Forbidden)

                                else
                                    WikiContributors.usersForWikiListing wikiSlug model.contributors
                                        |> Ok
                                        |> respond

        RequestWikiAuditLog wikiSlug filter ->
            let
                respond : Result WikiAuditLog.Error (List WikiAuditLog.AuditEvent) -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (WikiAuditLogResponse wikiSlug filter res)
                    )
            in
            case Dict.get wikiSlug model.wikis of
                Nothing ->
                    respond (Err WikiAuditLog.WikiNotFound)

                Just w ->
                    if not w.active then
                        respond (Err WikiAuditLog.WikiInactive)

                    else
                        let
                            sessionKey : String
                            sessionKey =
                                Effect.Lamdera.sessionIdToString sessionId
                        in
                        case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                            WikiUser.SessionNotLoggedIn ->
                                respond (Err WikiAuditLog.NotLoggedIn)

                            WikiUser.SessionWrongWiki ->
                                respond (Err WikiAuditLog.WrongWikiSession)

                            WikiUser.SessionHasAccount accountId ->
                                if not (WikiContributors.isAdminForWiki wikiSlug accountId model.contributors) then
                                    respond (Err WikiAuditLog.Forbidden)

                                else
                                    model.wikiAuditEvents
                                        |> Dict.get wikiSlug
                                        |> Maybe.withDefault []
                                        |> WikiAuditLog.filterEvents filter
                                        |> Ok
                                        |> respond

        PromoteContributorToTrusted wikiSlug rawTargetUsername ->
            let
                respond :
                    Result WikiAdminUsers.PromoteContributorError ()
                    -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (PromoteContributorToTrustedResponse wikiSlug res)
                    )
            in
            case Dict.get wikiSlug model.wikis of
                Nothing ->
                    respond (Err WikiAdminUsers.PromoteWikiNotFound)

                Just w ->
                    if not w.active then
                        respond (Err WikiAdminUsers.PromoteWikiInactive)

                    else
                        let
                            sessionKey : String
                            sessionKey =
                                Effect.Lamdera.sessionIdToString sessionId
                        in
                        case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                            WikiUser.SessionNotLoggedIn ->
                                respond (Err WikiAdminUsers.PromoteNotLoggedIn)

                            WikiUser.SessionWrongWiki ->
                                respond (Err WikiAdminUsers.PromoteWrongWikiSession)

                            WikiUser.SessionHasAccount accountId ->
                                if not (WikiContributors.isAdminForWiki wikiSlug accountId model.contributors) then
                                    respond (Err WikiAdminUsers.PromoteForbidden)

                                else
                                    let
                                        normalizedTarget : String
                                        normalizedTarget =
                                            ContributorAccount.normalizeUsername rawTargetUsername
                                    in
                                    if String.isEmpty normalizedTarget then
                                        respond (Err WikiAdminUsers.PromoteTargetNotFound)

                                    else
                                        case WikiContributors.promoteContributorToTrustedAtWiki wikiSlug normalizedTarget model.contributors of
                                            Err e ->
                                                respond (Err e)

                                            Ok nextContributors ->
                                                let
                                                    nextModel0 : Model
                                                    nextModel0 =
                                                        { model | contributors = nextContributors }
                                                in
                                                ( recordAudit now
                                                    wikiSlug
                                                    accountId
                                                    (WikiAuditLog.PromotedContributorToTrusted { targetUsername = normalizedTarget })
                                                    nextModel0
                                                , Effect.Lamdera.sendToFrontend clientId
                                                    (PromoteContributorToTrustedResponse wikiSlug (Ok ()))
                                                )

        DemoteTrustedToContributor wikiSlug rawTargetUsername ->
            let
                respond :
                    Result WikiAdminUsers.DemoteTrustedError ()
                    -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (DemoteTrustedToContributorResponse wikiSlug res)
                    )
            in
            case Dict.get wikiSlug model.wikis of
                Nothing ->
                    respond (Err WikiAdminUsers.DemoteWikiNotFound)

                Just w ->
                    if not w.active then
                        respond (Err WikiAdminUsers.DemoteWikiInactive)

                    else
                        let
                            sessionKey : String
                            sessionKey =
                                Effect.Lamdera.sessionIdToString sessionId
                        in
                        case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                            WikiUser.SessionNotLoggedIn ->
                                respond (Err WikiAdminUsers.DemoteNotLoggedIn)

                            WikiUser.SessionWrongWiki ->
                                respond (Err WikiAdminUsers.DemoteWrongWikiSession)

                            WikiUser.SessionHasAccount accountId ->
                                if not (WikiContributors.isAdminForWiki wikiSlug accountId model.contributors) then
                                    respond (Err WikiAdminUsers.DemoteForbidden)

                                else
                                    let
                                        normalizedTarget : String
                                        normalizedTarget =
                                            ContributorAccount.normalizeUsername rawTargetUsername
                                    in
                                    if String.isEmpty normalizedTarget then
                                        respond (Err WikiAdminUsers.DemoteTargetNotFound)

                                    else
                                        case WikiContributors.demoteTrustedToContributorAtWiki wikiSlug normalizedTarget model.contributors of
                                            Err e ->
                                                respond (Err e)

                                            Ok nextContributors ->
                                                let
                                                    nextModel0 : Model
                                                    nextModel0 =
                                                        { model | contributors = nextContributors }
                                                in
                                                ( recordAudit now
                                                    wikiSlug
                                                    accountId
                                                    (WikiAuditLog.DemotedTrustedToContributor { targetUsername = normalizedTarget })
                                                    nextModel0
                                                , Effect.Lamdera.sendToFrontend clientId
                                                    (DemoteTrustedToContributorResponse wikiSlug (Ok ()))
                                                )

        GrantWikiAdmin wikiSlug rawTargetUsername ->
            let
                respond :
                    Result WikiAdminUsers.GrantTrustedToAdminError ()
                    -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (GrantWikiAdminResponse wikiSlug res)
                    )
            in
            case Dict.get wikiSlug model.wikis of
                Nothing ->
                    respond (Err WikiAdminUsers.GrantTrustedWikiNotFound)

                Just w ->
                    if not w.active then
                        respond (Err WikiAdminUsers.GrantTrustedWikiInactive)

                    else
                        let
                            sessionKey : String
                            sessionKey =
                                Effect.Lamdera.sessionIdToString sessionId
                        in
                        case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                            WikiUser.SessionNotLoggedIn ->
                                respond (Err WikiAdminUsers.GrantTrustedNotLoggedIn)

                            WikiUser.SessionWrongWiki ->
                                respond (Err WikiAdminUsers.GrantTrustedWrongWikiSession)

                            WikiUser.SessionHasAccount accountId ->
                                if not (WikiContributors.isAdminForWiki wikiSlug accountId model.contributors) then
                                    respond (Err WikiAdminUsers.GrantTrustedForbidden)

                                else
                                    let
                                        normalizedTarget : String
                                        normalizedTarget =
                                            ContributorAccount.normalizeUsername rawTargetUsername
                                    in
                                    if String.isEmpty normalizedTarget then
                                        respond (Err WikiAdminUsers.GrantTrustedTargetNotFound)

                                    else
                                        case WikiContributors.grantTrustedToAdminAtWiki wikiSlug normalizedTarget model.contributors of
                                            Err e ->
                                                respond (Err e)

                                            Ok nextContributors ->
                                                let
                                                    nextModel0 : Model
                                                    nextModel0 =
                                                        { model | contributors = nextContributors }
                                                in
                                                ( recordAudit now
                                                    wikiSlug
                                                    accountId
                                                    (WikiAuditLog.GrantedWikiAdmin { targetUsername = normalizedTarget })
                                                    nextModel0
                                                , Effect.Lamdera.sendToFrontend clientId
                                                    (GrantWikiAdminResponse wikiSlug (Ok ()))
                                                )

        RevokeWikiAdmin wikiSlug rawTargetUsername ->
            let
                respond :
                    Result WikiAdminUsers.RevokeAdminError ()
                    -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (RevokeWikiAdminResponse wikiSlug res)
                    )
            in
            case Dict.get wikiSlug model.wikis of
                Nothing ->
                    respond (Err WikiAdminUsers.RevokeAdminWikiNotFound)

                Just w ->
                    if not w.active then
                        respond (Err WikiAdminUsers.RevokeAdminWikiInactive)

                    else
                        let
                            sessionKey : String
                            sessionKey =
                                Effect.Lamdera.sessionIdToString sessionId
                        in
                        case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                            WikiUser.SessionNotLoggedIn ->
                                respond (Err WikiAdminUsers.RevokeAdminNotLoggedIn)

                            WikiUser.SessionWrongWiki ->
                                respond (Err WikiAdminUsers.RevokeAdminWrongWikiSession)

                            WikiUser.SessionHasAccount accountId ->
                                if not (WikiContributors.isAdminForWiki wikiSlug accountId model.contributors) then
                                    respond (Err WikiAdminUsers.RevokeAdminForbidden)

                                else
                                    let
                                        normalizedTarget : String
                                        normalizedTarget =
                                            ContributorAccount.normalizeUsername rawTargetUsername
                                    in
                                    if String.isEmpty normalizedTarget then
                                        respond (Err WikiAdminUsers.RevokeAdminTargetNotFound)

                                    else
                                        case WikiContributors.revokeAdminToTrustedAtWiki wikiSlug accountId normalizedTarget model.contributors of
                                            Err e ->
                                                respond (Err e)

                                            Ok nextContributors ->
                                                let
                                                    nextModel0 : Model
                                                    nextModel0 =
                                                        { model | contributors = nextContributors }
                                                in
                                                ( recordAudit now
                                                    wikiSlug
                                                    accountId
                                                    (WikiAuditLog.RevokedWikiAdmin { targetUsername = normalizedTarget })
                                                    nextModel0
                                                , Effect.Lamdera.sendToFrontend clientId
                                                    (RevokeWikiAdminResponse wikiSlug (Ok ()))
                                                )

        RequestReviewSubmissionDetail wikiSlug submissionId ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respond :
                    Result SubmissionReviewDetail.ReviewSubmissionDetailError SubmissionReviewDetail.SubmissionReviewDetail
                    -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (ReviewSubmissionDetailResponse wikiSlug submissionId res)
                    )
            in
            case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                WikiUser.SessionNotLoggedIn ->
                    respond (Err SubmissionReviewDetail.ReviewSubmissionDetailNotLoggedIn)

                WikiUser.SessionWrongWiki ->
                    respond (Err SubmissionReviewDetail.ReviewSubmissionDetailWrongWikiSession)

                WikiUser.SessionHasAccount accountId ->
                    if not (WikiContributors.isTrustedForWiki wikiSlug accountId model.contributors) then
                        respond (Err SubmissionReviewDetail.ReviewSubmissionDetailForbidden)

                    else
                        case Dict.get wikiSlug model.wikis of
                            Nothing ->
                                respond (Err SubmissionReviewDetail.ReviewSubmissionDetailNotFound)

                            Just wiki ->
                                if not wiki.active then
                                    respond (Err SubmissionReviewDetail.ReviewSubmissionDetailWikiInactive)

                                else
                                    case Dict.get submissionId model.submissions of
                                        Nothing ->
                                            respond (Err SubmissionReviewDetail.ReviewSubmissionDetailNotFound)

                                        Just sub ->
                                            if sub.wikiSlug /= wikiSlug then
                                                respond (Err SubmissionReviewDetail.ReviewSubmissionDetailNotFound)

                                            else
                                                respond
                                                    (Ok (SubmissionReviewDetail.reviewDetailFromWikiAndSubmission wiki sub))

        RequestSubmissionDetails wikiSlug submissionId ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respond : Result Submission.DetailsError Submission.ContributorView -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (SubmissionDetailsResponse wikiSlug submissionId res)
                    )
            in
            case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                WikiUser.SessionNotLoggedIn ->
                    respond (Err Submission.DetailsNotLoggedIn)

                WikiUser.SessionWrongWiki ->
                    respond (Err Submission.DetailsWrongWikiSession)

                WikiUser.SessionHasAccount accountId ->
                    let
                        submissionBranch : ( Model, Command BackendOnly ToFrontend Msg )
                        submissionBranch =
                            case Dict.get submissionId model.submissions of
                                Nothing ->
                                    respond (Err Submission.DetailsNotFound)

                                Just sub ->
                                    if sub.wikiSlug /= wikiSlug then
                                        respond (Err Submission.DetailsNotFound)

                                    else if sub.authorId /= accountId then
                                        respond (Err Submission.DetailsForbidden)

                                    else
                                        respond (Ok (Submission.contributorViewFromSubmission (Dict.get wikiSlug model.wikis) sub))
                    in
                    case Dict.get wikiSlug model.wikis of
                        Just w ->
                            if not w.active then
                                respond (Err Submission.DetailsWikiInactive)

                            else
                                submissionBranch

                        Nothing ->
                            submissionBranch

        RegisterContributor wikiSlug cred ->
            case WikiContributors.attemptRegister wikiSlug cred.username cred.password model.wikis model.contributors of
                Err err ->
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (RegisterContributorResponse wikiSlug (Err err))
                    )

                Ok ( nextContributors, accountId ) ->
                    let
                        sessionKey : String
                        sessionKey =
                            Effect.Lamdera.sessionIdToString sessionId

                        nextSessions : WikiUser.SessionTable
                        nextSessions =
                            WikiUser.bindContributor sessionKey wikiSlug accountId model.contributorSessions
                    in
                    ( { model
                        | contributors = nextContributors
                        , contributorSessions = nextSessions
                      }
                    , Effect.Lamdera.sendToFrontend clientId
                        (RegisterContributorResponse wikiSlug (Ok (WikiRole.UntrustedContributor WikiRole.defaultUntrustedContributorCaps)))
                    )

        LoginContributor wikiSlug cred ->
            case WikiContributors.attemptLogin wikiSlug cred.username cred.password model.wikis model.contributors of
                Err err ->
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (LoginContributorResponse wikiSlug (Err err))
                    )

                Ok accountId ->
                    let
                        sessionKey : String
                        sessionKey =
                            Effect.Lamdera.sessionIdToString sessionId

                        nextSessions : WikiUser.SessionTable
                        nextSessions =
                            WikiUser.bindContributor sessionKey wikiSlug accountId model.contributorSessions

                        role : WikiRole.WikiRole
                        role =
                            WikiContributors.roleForAccount wikiSlug accountId model.contributors
                                |> Maybe.withDefault (WikiRole.UntrustedContributor WikiRole.defaultUntrustedContributorCaps)
                    in
                    ( { model | contributorSessions = nextSessions }
                    , Effect.Lamdera.sendToFrontend clientId
                        (LoginContributorResponse wikiSlug (Ok role))
                    )

        LogoutContributor wikiSlug ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                nextSessions : WikiUser.SessionTable
                nextSessions =
                    WikiUser.unbindContributor sessionKey wikiSlug model.contributorSessions
            in
            ( { model | contributorSessions = nextSessions }
            , Effect.Lamdera.sendToFrontend clientId (LogoutContributorResponse wikiSlug)
            )

        SubmitNewPage wikiSlug body ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respondErr : Submission.SubmitNewPageError -> ( Model, Command BackendOnly ToFrontend Msg )
                respondErr err =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (SubmitNewPageResponse wikiSlug (Err err))
                    )
            in
            case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                WikiUser.SessionNotLoggedIn ->
                    respondErr Submission.NotLoggedIn

                WikiUser.SessionWrongWiki ->
                    respondErr Submission.WrongWikiSession

                WikiUser.SessionHasAccount accountId ->
                    case Dict.get wikiSlug model.wikis of
                        Nothing ->
                            respondErr Submission.WikiNotFound

                        Just wiki ->
                            if not wiki.active then
                                respondErr Submission.WikiInactive

                            else
                                case Submission.validateNewPageFields body.rawPageSlug body.rawMarkdown body.rawTags of
                                    Err ve ->
                                        respondErr (Submission.Validation ve)

                                    Ok payload ->
                                        if Dict.member payload.pageSlug wiki.pages then
                                            respondErr Submission.SlugAlreadyInUse

                                        else if WikiContributors.isTrustedForWiki wikiSlug accountId model.contributors then
                                            if Submission.pendingNewPageSlugBlocksTrustedPublish accountId wikiSlug payload.pageSlug model.submissions then
                                                respondErr Submission.SlugAlreadyInUse

                                            else
                                                let
                                                    submissionsAfterDraftCleanup : Dict String Submission.Submission
                                                    submissionsAfterDraftCleanup =
                                                        Submission.removeAuthorDraftNewPageSubmissionsForSlug accountId wikiSlug payload.pageSlug model.submissions

                                                    nextWiki : Wiki
                                                    nextWiki =
                                                        Wiki.publishNewPageOnWiki payload wiki

                                                    nextModel0 : Model
                                                    nextModel0 =
                                                        { model
                                                            | wikis = Dict.insert wikiSlug nextWiki model.wikis
                                                            , submissions = submissionsAfterDraftCleanup
                                                        }

                                                    nextModel : Model
                                                    nextModel =
                                                        recordAudit now
                                                            wikiSlug
                                                            accountId
                                                            (WikiAuditLog.TrustedPublishedNewPage { pageSlug = payload.pageSlug })
                                                            nextModel0
                                                in
                                                ( nextModel
                                                , Effect.Lamdera.sendToFrontend clientId
                                                    (SubmitNewPageResponse wikiSlug (Ok Submission.NewPagePublishedImmediately))
                                                )

                                        else if Submission.pendingNewPageSlugInUse wikiSlug payload.pageSlug model.submissions then
                                            respondErr Submission.SlugAlreadyInUse

                                        else
                                            let
                                                submissionId : Submission.Id
                                                submissionId =
                                                    Submission.idFromCounter model.nextSubmissionCounter

                                                sub : Submission.Submission
                                                sub =
                                                    { id = submissionId
                                                    , wikiSlug = wikiSlug
                                                    , authorId = accountId
                                                    , kind =
                                                        Submission.NewPage
                                                            { pageSlug = payload.pageSlug
                                                            , markdown = payload.markdown
                                                            , tags = payload.tags
                                                            }
                                                    , status = Submission.Pending
                                                    , reviewerNote = Nothing
                                                    }

                                                nextModel : Model
                                                nextModel =
                                                    { model
                                                        | submissions =
                                                            Dict.insert (Submission.idToString submissionId) sub model.submissions
                                                        , nextSubmissionCounter = model.nextSubmissionCounter + 1
                                                    }
                                            in
                                            ( nextModel
                                            , Effect.Lamdera.sendToFrontend clientId
                                                (SubmitNewPageResponse wikiSlug (Ok (Submission.NewPageSubmittedForReview submissionId)))
                                            )

        SubmitPageEdit wikiSlug pageSlug rawMarkdown rawTags ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respondErr : Submission.SubmitPageEditError -> ( Model, Command BackendOnly ToFrontend Msg )
                respondErr err =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (SubmitPageEditResponse wikiSlug (Err err))
                    )
            in
            case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                WikiUser.SessionNotLoggedIn ->
                    respondErr Submission.EditNotLoggedIn

                WikiUser.SessionWrongWiki ->
                    respondErr Submission.EditWrongWikiSession

                WikiUser.SessionHasAccount accountId ->
                    case Dict.get wikiSlug model.wikis of
                        Nothing ->
                            respondErr Submission.EditWikiNotFound

                        Just wiki ->
                            if not wiki.active then
                                respondErr Submission.EditWikiInactive

                            else
                                case Submission.validateEditMarkdown rawMarkdown rawTags pageSlug of
                                    Err ve ->
                                        respondErr (Submission.EditValidation ve)

                                    Ok validEdit ->
                                        if not (Submission.wikiHasPublishedPage pageSlug wiki) then
                                            respondErr Submission.EditTargetPageNotPublished

                                        else if Submission.pendingEditForAuthorOnPageInUse wikiSlug accountId pageSlug model.submissions then
                                            respondErr Submission.EditAlreadyPendingForAuthor

                                        else if WikiContributors.isTrustedForWiki wikiSlug accountId model.contributors then
                                            let
                                                previousMarkdown : String
                                                previousMarkdown =
                                                    SubmissionReviewDetail.publishedMarkdownForSlug wiki pageSlug

                                                nextWiki : Wiki
                                                nextWiki =
                                                    Wiki.applyPublishedMarkdownEdit pageSlug validEdit.proposedMarkdown validEdit.tags wiki

                                                nextModel0 : Model
                                                nextModel0 =
                                                    { model
                                                        | wikis = Dict.insert wikiSlug nextWiki model.wikis
                                                    }

                                                nextModel : Model
                                                nextModel =
                                                    recordAudit now
                                                        wikiSlug
                                                        accountId
                                                        (WikiAuditLog.TrustedPublishedPageEdit
                                                            { pageSlug = pageSlug
                                                            , beforeMarkdown = previousMarkdown
                                                            , afterMarkdown = validEdit.proposedMarkdown
                                                            }
                                                        )
                                                        nextModel0
                                            in
                                            ( nextModel
                                            , Effect.Lamdera.sendToFrontend clientId
                                                (SubmitPageEditResponse wikiSlug (Ok Submission.EditPublishedImmediately))
                                            )

                                        else
                                            let
                                                baseMarkdown : String
                                                baseMarkdown =
                                                    SubmissionReviewDetail.publishedMarkdownForSlug wiki pageSlug

                                                baseRevision : Int
                                                baseRevision =
                                                    Submission.currentPublishedRevision wiki pageSlug
                                                        |> Maybe.withDefault 0

                                                submissionId : Submission.Id
                                                submissionId =
                                                    Submission.idFromCounter model.nextSubmissionCounter

                                                sub : Submission.Submission
                                                sub =
                                                    { id = submissionId
                                                    , wikiSlug = wikiSlug
                                                    , authorId = accountId
                                                    , kind =
                                                        Submission.EditPage
                                                            { pageSlug = pageSlug
                                                            , baseMarkdown = baseMarkdown
                                                            , baseRevision = baseRevision
                                                            , proposedMarkdown = validEdit.proposedMarkdown
                                                            , tags = validEdit.tags
                                                            }
                                                    , status = Submission.Pending
                                                    , reviewerNote = Nothing
                                                    }

                                                nextModel : Model
                                                nextModel =
                                                    { model
                                                        | submissions =
                                                            Dict.insert (Submission.idToString submissionId) sub model.submissions
                                                        , nextSubmissionCounter = model.nextSubmissionCounter + 1
                                                    }
                                            in
                                            ( nextModel
                                            , Effect.Lamdera.sendToFrontend clientId
                                                (SubmitPageEditResponse wikiSlug (Ok (Submission.EditSubmittedForReview submissionId)))
                                            )

        RequestPublishedPageDeletion wikiSlug pageSlug rawReason ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respondErr : Submission.RequestPublishedPageDeletionError -> ( Model, Command BackendOnly ToFrontend Msg )
                respondErr err =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (RequestPublishedPageDeletionResponse wikiSlug (Err err))
                    )
            in
            case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                WikiUser.SessionNotLoggedIn ->
                    respondErr (Submission.RequestPublishedPageDeletionPrecondition Submission.PageDeletionNotLoggedIn)

                WikiUser.SessionWrongWiki ->
                    respondErr (Submission.RequestPublishedPageDeletionPrecondition Submission.PageDeletionWrongWikiSession)

                WikiUser.SessionHasAccount accountId ->
                    if WikiContributors.isTrustedForWiki wikiSlug accountId model.contributors then
                        respondErr Submission.RequestPublishedPageDeletionForbiddenTrustedModerator

                    else
                        case Dict.get wikiSlug model.wikis of
                            Nothing ->
                                respondErr (Submission.RequestPublishedPageDeletionPrecondition Submission.PageDeletionWikiNotFound)

                            Just wiki ->
                                if not wiki.active then
                                    respondErr (Submission.RequestPublishedPageDeletionPrecondition Submission.PageDeletionWikiInactive)

                                else
                                    case Submission.validateDeleteReasonRequired rawReason of
                                        Err ve ->
                                            respondErr (Submission.RequestPublishedPageDeletionPrecondition (Submission.PageDeletionValidation ve))

                                        Ok deletionReason ->
                                            if not (Submission.wikiHasPublishedPage pageSlug wiki) then
                                                respondErr (Submission.RequestPublishedPageDeletionPrecondition Submission.PageDeletionTargetNotPublished)

                                            else
                                                let
                                                    submissionId : Submission.Id
                                                    submissionId =
                                                        Submission.idFromCounter model.nextSubmissionCounter

                                                    sub : Submission.Submission
                                                    sub =
                                                        { id = submissionId
                                                        , wikiSlug = wikiSlug
                                                        , authorId = accountId
                                                        , kind =
                                                            Submission.DeletePage
                                                                { pageSlug = pageSlug
                                                                , reason = Just deletionReason
                                                                }
                                                        , status = Submission.Pending
                                                        , reviewerNote = Nothing
                                                        }

                                                    nextModel : Model
                                                    nextModel =
                                                        { model
                                                            | submissions =
                                                                Dict.insert (Submission.idToString submissionId) sub model.submissions
                                                            , nextSubmissionCounter = model.nextSubmissionCounter + 1
                                                        }
                                                in
                                                ( nextModel
                                                , Effect.Lamdera.sendToFrontend clientId
                                                    (RequestPublishedPageDeletionResponse wikiSlug (Ok submissionId))
                                                )

        DeletePublishedPageImmediately wikiSlug pageSlug rawReason ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respondErr : Submission.DeletePublishedPageImmediatelyError -> ( Model, Command BackendOnly ToFrontend Msg )
                respondErr err =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (DeletePublishedPageImmediatelyResponse wikiSlug (Err err))
                    )
            in
            case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                WikiUser.SessionNotLoggedIn ->
                    respondErr (Submission.DeletePublishedPageImmediatelyPrecondition Submission.PageDeletionNotLoggedIn)

                WikiUser.SessionWrongWiki ->
                    respondErr (Submission.DeletePublishedPageImmediatelyPrecondition Submission.PageDeletionWrongWikiSession)

                WikiUser.SessionHasAccount accountId ->
                    if not (WikiContributors.isTrustedForWiki wikiSlug accountId model.contributors) then
                        respondErr Submission.DeletePublishedPageImmediatelyForbiddenUntrustedContributor

                    else
                        case Dict.get wikiSlug model.wikis of
                            Nothing ->
                                respondErr (Submission.DeletePublishedPageImmediatelyPrecondition Submission.PageDeletionWikiNotFound)

                            Just wiki ->
                                if not wiki.active then
                                    respondErr (Submission.DeletePublishedPageImmediatelyPrecondition Submission.PageDeletionWikiInactive)

                                else
                                    case Submission.validateDeleteReasonRequired rawReason of
                                        Err ve ->
                                            respondErr (Submission.DeletePublishedPageImmediatelyPrecondition (Submission.PageDeletionValidation ve))

                                        Ok deletionReason ->
                                            if not (Submission.wikiHasPublishedPage pageSlug wiki) then
                                                respondErr (Submission.DeletePublishedPageImmediatelyPrecondition Submission.PageDeletionTargetNotPublished)

                                            else
                                                let
                                                    nextWiki : Wiki
                                                    nextWiki =
                                                        Wiki.removePublishedPage pageSlug wiki

                                                    nextModel0 : Model
                                                    nextModel0 =
                                                        { model
                                                            | wikis = Dict.insert wikiSlug nextWiki model.wikis
                                                        }

                                                    nextModel : Model
                                                    nextModel =
                                                        recordAudit now
                                                            wikiSlug
                                                            accountId
                                                            (WikiAuditLog.TrustedPublishedPageDelete
                                                                { pageSlug = pageSlug
                                                                , reason = deletionReason
                                                                }
                                                            )
                                                            nextModel0
                                                in
                                                ( nextModel
                                                , Effect.Lamdera.sendToFrontend clientId
                                                    (DeletePublishedPageImmediatelyResponse wikiSlug (Ok ()))
                                                )

        SaveNewPageDraft wikiSlug payload ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respond : Result Submission.SaveNewPageDraftError Submission.Id -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (SaveNewPageDraftResponse wikiSlug res)
                    )
            in
            case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                WikiUser.SessionNotLoggedIn ->
                    respond (Err Submission.SaveNewPageDraftNotLoggedIn)

                WikiUser.SessionWrongWiki ->
                    respond (Err Submission.SaveNewPageDraftWrongWikiSession)

                WikiUser.SessionHasAccount accountId ->
                    case Dict.get wikiSlug model.wikis of
                        Nothing ->
                            respond (Err Submission.SaveNewPageDraftWikiNotFound)

                        Just wiki ->
                            if not wiki.active then
                                respond (Err Submission.SaveNewPageDraftWikiInactive)

                            else
                                case Submission.validateNewPageDraftFields payload.rawPageSlug payload.rawMarkdown payload.rawTags of
                                    Err ve ->
                                        respond (Err (Submission.SaveNewPageDraftValidation ve))

                                    Ok draftPayload ->
                                        case payload.maybeSubmissionId of
                                            Nothing ->
                                                if Submission.pendingNewPageSlugInUse wikiSlug draftPayload.pageSlug model.submissions then
                                                    respond (Err Submission.SaveNewPageDraftSlugReserved)

                                                else
                                                    let
                                                        submissionId : Submission.Id
                                                        submissionId =
                                                            Submission.idFromCounter model.nextSubmissionCounter

                                                        sub : Submission.Submission
                                                        sub =
                                                            { id = submissionId
                                                            , wikiSlug = wikiSlug
                                                            , authorId = accountId
                                                            , kind =
                                                                Submission.NewPage
                                                                    { pageSlug = draftPayload.pageSlug
                                                                    , markdown = draftPayload.markdown
                                                                    , tags = draftPayload.tags
                                                                    }
                                                            , status = Submission.Draft
                                                            , reviewerNote = Nothing
                                                            }

                                                        nextModel : Model
                                                        nextModel =
                                                            { model
                                                                | submissions =
                                                                    Dict.insert (Submission.idToString submissionId) sub model.submissions
                                                                , nextSubmissionCounter = model.nextSubmissionCounter + 1
                                                            }
                                                    in
                                                    ( nextModel
                                                    , Effect.Lamdera.sendToFrontend clientId
                                                        (SaveNewPageDraftResponse wikiSlug (Ok submissionId))
                                                    )

                                            Just sid ->
                                                case Dict.get sid model.submissions of
                                                    Nothing ->
                                                        respond (Err Submission.SaveNewPageDraftNotFound)

                                                    Just sub ->
                                                        if sub.wikiSlug /= wikiSlug then
                                                            respond (Err Submission.SaveNewPageDraftNotFound)

                                                        else if sub.authorId /= accountId then
                                                            respond (Err Submission.SaveNewPageDraftForbidden)

                                                        else if sub.status /= Submission.Draft then
                                                            respond (Err Submission.SaveNewPageDraftForbidden)

                                                        else
                                                            case sub.kind of
                                                                Submission.NewPage _ ->
                                                                    if Submission.pendingNewPageSlugInUseExcept (Just sub.id) wikiSlug draftPayload.pageSlug model.submissions then
                                                                        respond (Err Submission.SaveNewPageDraftSlugReserved)

                                                                    else
                                                                        let
                                                                            nextSub : Submission.Submission
                                                                            nextSub =
                                                                                { sub
                                                                                    | kind =
                                                                                        Submission.NewPage
                                                                                            { pageSlug = draftPayload.pageSlug
                                                                                            , markdown = draftPayload.markdown
                                                                                            , tags = draftPayload.tags
                                                                                            }
                                                                                }
                                                                        in
                                                                        ( { model
                                                                            | submissions =
                                                                                Dict.insert sid nextSub model.submissions
                                                                          }
                                                                        , Effect.Lamdera.sendToFrontend clientId
                                                                            (SaveNewPageDraftResponse wikiSlug (Ok sub.id))
                                                                        )

                                                                Submission.EditPage _ ->
                                                                    respond (Err Submission.SaveNewPageDraftForbidden)

                                                                Submission.DeletePage _ ->
                                                                    respond (Err Submission.SaveNewPageDraftForbidden)

        SavePageEditDraft wikiSlug payload ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respond : Result Submission.SavePageEditDraftError Submission.Id -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (SavePageEditDraftResponse wikiSlug res)
                    )
            in
            case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                WikiUser.SessionNotLoggedIn ->
                    respond (Err Submission.SavePageEditDraftNotLoggedIn)

                WikiUser.SessionWrongWiki ->
                    respond (Err Submission.SavePageEditDraftWrongWikiSession)

                WikiUser.SessionHasAccount accountId ->
                    case Dict.get wikiSlug model.wikis of
                        Nothing ->
                            respond (Err Submission.SavePageEditDraftWikiNotFound)

                        Just wiki ->
                            if not wiki.active then
                                respond (Err Submission.SavePageEditDraftWikiInactive)

                            else
                                case Submission.validateEditMarkdownDraft payload.rawMarkdown payload.rawTags payload.pageSlug of
                                    Err ve ->
                                        respond (Err (Submission.SavePageEditDraftValidation ve))

                                    Ok draftEdit ->
                                        let
                                            pageSlug : Page.Slug
                                            pageSlug =
                                                payload.pageSlug
                                        in
                                        if not (Submission.wikiHasPublishedPage pageSlug wiki) then
                                            respond (Err Submission.SavePageEditDraftTargetNotPublished)

                                        else
                                            let
                                                baseMarkdown : String
                                                baseMarkdown =
                                                    SubmissionReviewDetail.publishedMarkdownForSlug wiki pageSlug

                                                baseRevision : Int
                                                baseRevision =
                                                    Submission.currentPublishedRevision wiki pageSlug
                                                        |> Maybe.withDefault 0
                                            in
                                            case payload.maybeSubmissionId of
                                                Nothing ->
                                                    if Submission.pendingEditForAuthorOnPageInUse wikiSlug accountId pageSlug model.submissions then
                                                        respond (Err Submission.SavePageEditDraftAlreadyPendingEdit)

                                                    else
                                                        let
                                                            submissionId : Submission.Id
                                                            submissionId =
                                                                Submission.idFromCounter model.nextSubmissionCounter

                                                            sub : Submission.Submission
                                                            sub =
                                                                { id = submissionId
                                                                , wikiSlug = wikiSlug
                                                                , authorId = accountId
                                                                , kind =
                                                                    Submission.EditPage
                                                                        { pageSlug = pageSlug
                                                                        , baseMarkdown = baseMarkdown
                                                                        , baseRevision = baseRevision
                                                                        , proposedMarkdown = draftEdit.proposedMarkdown
                                                                        , tags = draftEdit.tags
                                                                        }
                                                                , status = Submission.Draft
                                                                , reviewerNote = Nothing
                                                                }

                                                            nextModel : Model
                                                            nextModel =
                                                                { model
                                                                    | submissions =
                                                                        Dict.insert (Submission.idToString submissionId) sub model.submissions
                                                                    , nextSubmissionCounter = model.nextSubmissionCounter + 1
                                                                }
                                                        in
                                                        ( nextModel
                                                        , Effect.Lamdera.sendToFrontend clientId
                                                            (SavePageEditDraftResponse wikiSlug (Ok submissionId))
                                                        )

                                                Just sid ->
                                                    case Dict.get sid model.submissions of
                                                        Nothing ->
                                                            respond (Err Submission.SavePageEditDraftNotFound)

                                                        Just sub ->
                                                            if sub.wikiSlug /= wikiSlug then
                                                                respond (Err Submission.SavePageEditDraftNotFound)

                                                            else if sub.authorId /= accountId then
                                                                respond (Err Submission.SavePageEditDraftForbidden)

                                                            else if sub.status /= Submission.Draft then
                                                                respond (Err Submission.SavePageEditDraftForbidden)

                                                            else
                                                                case sub.kind of
                                                                    Submission.EditPage body ->
                                                                        if body.pageSlug /= pageSlug then
                                                                            respond (Err Submission.SavePageEditDraftForbidden)

                                                                        else
                                                                            let
                                                                                nextSub : Submission.Submission
                                                                                nextSub =
                                                                                    { sub
                                                                                        | kind =
                                                                                            Submission.EditPage
                                                                                                { pageSlug = pageSlug
                                                                                                , baseMarkdown = baseMarkdown
                                                                                                , baseRevision = baseRevision
                                                                                                , proposedMarkdown = draftEdit.proposedMarkdown
                                                                                                , tags = draftEdit.tags
                                                                                                }
                                                                                    }
                                                                            in
                                                                            ( { model
                                                                                | submissions =
                                                                                    Dict.insert sid nextSub model.submissions
                                                                              }
                                                                            , Effect.Lamdera.sendToFrontend clientId
                                                                                (SavePageEditDraftResponse wikiSlug (Ok sub.id))
                                                                            )

                                                                    Submission.NewPage _ ->
                                                                        respond (Err Submission.SavePageEditDraftForbidden)

                                                                    Submission.DeletePage _ ->
                                                                        respond (Err Submission.SavePageEditDraftForbidden)

        SavePageDeleteDraft wikiSlug payload ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respond : Result Submission.SavePageDeleteDraftError Submission.Id -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (SavePageDeleteDraftResponse wikiSlug res)
                    )
            in
            case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                WikiUser.SessionNotLoggedIn ->
                    respond (Err Submission.SavePageDeleteDraftNotLoggedIn)

                WikiUser.SessionWrongWiki ->
                    respond (Err Submission.SavePageDeleteDraftWrongWikiSession)

                WikiUser.SessionHasAccount accountId ->
                    if WikiContributors.isTrustedForWiki wikiSlug accountId model.contributors then
                        respond (Err Submission.SavePageDeleteDraftForbiddenTrustedModerator)

                    else
                        case Dict.get wikiSlug model.wikis of
                            Nothing ->
                                respond (Err Submission.SavePageDeleteDraftWikiNotFound)

                            Just wiki ->
                                if not wiki.active then
                                    respond (Err Submission.SavePageDeleteDraftWikiInactive)

                                else
                                    case Submission.validateDeleteReasonRequired payload.rawReason of
                                        Err ve ->
                                            respond (Err (Submission.SavePageDeleteDraftReasonInvalid ve))

                                        Ok deletionReason ->
                                            let
                                                pageSlug : Page.Slug
                                                pageSlug =
                                                    payload.pageSlug
                                            in
                                            if not (Submission.wikiHasPublishedPage pageSlug wiki) then
                                                respond (Err Submission.SavePageDeleteDraftTargetNotPublished)

                                            else
                                                case payload.maybeSubmissionId of
                                                    Nothing ->
                                                        let
                                                            submissionId : Submission.Id
                                                            submissionId =
                                                                Submission.idFromCounter model.nextSubmissionCounter

                                                            sub : Submission.Submission
                                                            sub =
                                                                { id = submissionId
                                                                , wikiSlug = wikiSlug
                                                                , authorId = accountId
                                                                , kind =
                                                                    Submission.DeletePage
                                                                        { pageSlug = pageSlug
                                                                        , reason = Just deletionReason
                                                                        }
                                                                , status = Submission.Draft
                                                                , reviewerNote = Nothing
                                                                }

                                                            nextModel : Model
                                                            nextModel =
                                                                { model
                                                                    | submissions =
                                                                        Dict.insert (Submission.idToString submissionId) sub model.submissions
                                                                    , nextSubmissionCounter = model.nextSubmissionCounter + 1
                                                                }
                                                        in
                                                        ( nextModel
                                                        , Effect.Lamdera.sendToFrontend clientId
                                                            (SavePageDeleteDraftResponse wikiSlug (Ok submissionId))
                                                        )

                                                    Just sid ->
                                                        case Dict.get sid model.submissions of
                                                            Nothing ->
                                                                respond (Err Submission.SavePageDeleteDraftNotFound)

                                                            Just sub ->
                                                                if sub.wikiSlug /= wikiSlug then
                                                                    respond (Err Submission.SavePageDeleteDraftNotFound)

                                                                else if sub.authorId /= accountId then
                                                                    respond (Err Submission.SavePageDeleteDraftForbidden)

                                                                else if sub.status /= Submission.Draft then
                                                                    respond (Err Submission.SavePageDeleteDraftForbidden)

                                                                else
                                                                    case sub.kind of
                                                                        Submission.DeletePage body ->
                                                                            if body.pageSlug /= pageSlug then
                                                                                respond (Err Submission.SavePageDeleteDraftForbidden)

                                                                            else
                                                                                let
                                                                                    nextSub : Submission.Submission
                                                                                    nextSub =
                                                                                        { sub
                                                                                            | kind =
                                                                                                Submission.DeletePage
                                                                                                    { pageSlug = pageSlug
                                                                                                    , reason = Just deletionReason
                                                                                                    }
                                                                                        }
                                                                                in
                                                                                ( { model
                                                                                    | submissions =
                                                                                        Dict.insert sid nextSub model.submissions
                                                                                  }
                                                                                , Effect.Lamdera.sendToFrontend clientId
                                                                                    (SavePageDeleteDraftResponse wikiSlug (Ok sub.id))
                                                                                )

                                                                        Submission.NewPage _ ->
                                                                            respond (Err Submission.SavePageDeleteDraftForbidden)

                                                                        Submission.EditPage _ ->
                                                                            respond (Err Submission.SavePageDeleteDraftForbidden)

        SubmitDraftForReview wikiSlug submissionIdStr ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respond : Result Submission.SubmitDraftForReviewError () -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (SubmitDraftForReviewResponse wikiSlug submissionIdStr res)
                    )
            in
            case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                WikiUser.SessionNotLoggedIn ->
                    respond (Err Submission.SubmitDraftForReviewNotLoggedIn)

                WikiUser.SessionWrongWiki ->
                    respond (Err Submission.SubmitDraftForReviewWrongWikiSession)

                WikiUser.SessionHasAccount accountId ->
                    case Dict.get wikiSlug model.wikis of
                        Nothing ->
                            respond (Err Submission.SubmitDraftForReviewWikiNotFound)

                        Just wiki ->
                            if not wiki.active then
                                respond (Err Submission.SubmitDraftForReviewWikiInactive)

                            else
                                case Dict.get submissionIdStr model.submissions of
                                    Nothing ->
                                        respond (Err Submission.SubmitDraftForReviewNotFound)

                                    Just sub ->
                                        if sub.wikiSlug /= wikiSlug then
                                            respond (Err Submission.SubmitDraftForReviewNotFound)

                                        else if sub.authorId /= accountId then
                                            respond (Err Submission.SubmitDraftForReviewForbidden)

                                        else
                                            case ( sub.kind, WikiContributors.isTrustedForWiki wikiSlug accountId model.contributors ) of
                                                ( Submission.DeletePage _, True ) ->
                                                    respond (Err Submission.SubmitDraftForReviewDeleteForbiddenTrustedModerator)

                                                _ ->
                                                    case Submission.promoteDraftToPending wiki model.submissions sub of
                                                        Err e ->
                                                            respond (Err e)

                                                        Ok nextSub ->
                                                            ( { model
                                                                | submissions =
                                                                    Dict.insert submissionIdStr nextSub model.submissions
                                                              }
                                                            , Effect.Lamdera.sendToFrontend clientId
                                                                (SubmitDraftForReviewResponse wikiSlug submissionIdStr (Ok ()))
                                                            )

        WithdrawSubmission wikiSlug submissionIdStr ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respond : Result Submission.WithdrawSubmissionError () -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (WithdrawSubmissionResponse wikiSlug submissionIdStr res)
                    )
            in
            case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                WikiUser.SessionNotLoggedIn ->
                    respond (Err Submission.WithdrawSubmissionNotLoggedIn)

                WikiUser.SessionWrongWiki ->
                    respond (Err Submission.WithdrawSubmissionWrongWikiSession)

                WikiUser.SessionHasAccount accountId ->
                    case Dict.get wikiSlug model.wikis of
                        Nothing ->
                            respond (Err Submission.WithdrawSubmissionWikiNotFound)

                        Just wiki ->
                            if not wiki.active then
                                respond (Err Submission.WithdrawSubmissionWikiInactive)

                            else
                                case Dict.get submissionIdStr model.submissions of
                                    Nothing ->
                                        respond (Err Submission.WithdrawSubmissionNotFound)

                                    Just sub ->
                                        if sub.wikiSlug /= wikiSlug then
                                            respond (Err Submission.WithdrawSubmissionNotFound)

                                        else if sub.authorId /= accountId then
                                            respond (Err Submission.WithdrawSubmissionForbidden)

                                        else
                                            case Submission.withdrawSubmissionToDraft sub of
                                                Err e ->
                                                    respond (Err e)

                                                Ok nextSub ->
                                                    ( { model
                                                        | submissions =
                                                            Dict.insert submissionIdStr nextSub model.submissions
                                                      }
                                                    , Effect.Lamdera.sendToFrontend clientId
                                                        (WithdrawSubmissionResponse wikiSlug submissionIdStr (Ok ()))
                                                    )

        DeleteMySubmission wikiSlug submissionIdStr ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respond : Result Submission.DeleteMySubmissionError () -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (DeleteMySubmissionResponse wikiSlug submissionIdStr res)
                    )
            in
            case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                WikiUser.SessionNotLoggedIn ->
                    respond (Err Submission.DeleteMySubmissionNotLoggedIn)

                WikiUser.SessionWrongWiki ->
                    respond (Err Submission.DeleteMySubmissionWrongWikiSession)

                WikiUser.SessionHasAccount accountId ->
                    case Dict.get wikiSlug model.wikis of
                        Nothing ->
                            respond (Err Submission.DeleteMySubmissionWikiNotFound)

                        Just wiki ->
                            if not wiki.active then
                                respond (Err Submission.DeleteMySubmissionWikiInactive)

                            else
                                case Dict.get submissionIdStr model.submissions of
                                    Nothing ->
                                        respond (Err Submission.DeleteMySubmissionNotFound)

                                    Just sub ->
                                        if sub.wikiSlug /= wikiSlug then
                                            respond (Err Submission.DeleteMySubmissionNotFound)

                                        else if sub.authorId /= accountId then
                                            respond (Err Submission.DeleteMySubmissionForbidden)

                                        else
                                            case Submission.mayContributorDeleteSubmission sub of
                                                Err e ->
                                                    respond (Err e)

                                                Ok () ->
                                                    ( { model
                                                        | submissions =
                                                            Dict.remove submissionIdStr model.submissions
                                                      }
                                                    , Effect.Lamdera.sendToFrontend clientId
                                                        (DeleteMySubmissionResponse wikiSlug submissionIdStr (Ok ()))
                                                    )

        ApproveSubmission wikiSlug submissionId ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respondErr : Submission.ApproveSubmissionError -> ( Model, Command BackendOnly ToFrontend Msg )
                respondErr err =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (ApproveSubmissionResponse wikiSlug submissionId (Err err))
                    )
            in
            case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                WikiUser.SessionNotLoggedIn ->
                    respondErr Submission.ApproveNotLoggedIn

                WikiUser.SessionWrongWiki ->
                    respondErr Submission.ApproveWrongWikiSession

                WikiUser.SessionHasAccount accountId ->
                    if not (WikiContributors.isTrustedForWiki wikiSlug accountId model.contributors) then
                        respondErr Submission.ApproveForbidden

                    else
                        case Dict.get wikiSlug model.wikis of
                            Nothing ->
                                respondErr Submission.ApproveWikiNotFound

                            Just wiki ->
                                if not wiki.active then
                                    respondErr Submission.ApproveWikiInactive

                                else
                                    case Dict.get submissionId model.submissions of
                                        Nothing ->
                                            respondErr Submission.ApproveSubmissionNotFound

                                        Just sub ->
                                            if sub.wikiSlug /= wikiSlug then
                                                respondErr Submission.ApproveSubmissionNotFound

                                            else
                                                case Submission.applyApprovedSubmission wiki sub of
                                                    Err e ->
                                                        respondErr e

                                                    Ok approved ->
                                                        let
                                                            pageSlug : String
                                                            pageSlug =
                                                                Submission.pageSlugFromKind sub.kind
                                                                    |> Maybe.withDefault ""

                                                            submissionsAfterApproval : Dict String Submission.Submission
                                                            submissionsAfterApproval =
                                                                case sub.kind of
                                                                    Submission.EditPage editBody ->
                                                                        let
                                                                            maybeCurrentRevision : Maybe Int
                                                                            maybeCurrentRevision =
                                                                                Submission.currentPublishedRevision approved.wiki editBody.pageSlug
                                                                        in
                                                                        case maybeCurrentRevision of
                                                                            Nothing ->
                                                                                Dict.insert submissionId approved.submission model.submissions

                                                                            Just currentRevision ->
                                                                                let
                                                                                    staleNote : String
                                                                                    staleNote =
                                                                                        "Page changed after this edit was submitted. Withdraw the submission, update your draft against the latest page, and submit for review again."
                                                                                in
                                                                                model.submissions
                                                                                    |> Dict.insert submissionId approved.submission
                                                                                    |> Dict.map
                                                                                        (\subId candidate ->
                                                                                            if subId == submissionId || candidate.wikiSlug /= wikiSlug then
                                                                                                candidate

                                                                                            else if Submission.isStalePendingEditSubmission { pageSlug = editBody.pageSlug, currentRevision = currentRevision } candidate then
                                                                                                Submission.markStalePendingEditNeedsRevision staleNote candidate

                                                                                            else
                                                                                                candidate
                                                                                        )

                                                                    Submission.NewPage _ ->
                                                                        Dict.insert submissionId approved.submission model.submissions

                                                                    Submission.DeletePage _ ->
                                                                        Dict.insert submissionId approved.submission model.submissions

                                                            nextModel0 : Model
                                                            nextModel0 =
                                                                { model
                                                                    | wikis = Dict.insert wikiSlug approved.wiki model.wikis
                                                                    , submissions = submissionsAfterApproval
                                                                }

                                                            nextModel : Model
                                                            nextModel =
                                                                recordAudit now
                                                                    wikiSlug
                                                                    accountId
                                                                    (WikiAuditLog.ApprovedSubmission
                                                                        { submissionId = submissionId
                                                                        , pageSlug = pageSlug
                                                                        }
                                                                    )
                                                                    nextModel0
                                                        in
                                                        ( nextModel
                                                        , Effect.Lamdera.sendToFrontend clientId
                                                            (ApproveSubmissionResponse wikiSlug submissionId (Ok ()))
                                                        )

        RejectSubmission wikiSlug rej ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                submissionId : String
                submissionId =
                    rej.submissionId

                respondErr : Submission.RejectSubmissionError -> ( Model, Command BackendOnly ToFrontend Msg )
                respondErr err =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (RejectSubmissionResponse wikiSlug submissionId (Err err))
                    )
            in
            case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                WikiUser.SessionNotLoggedIn ->
                    respondErr Submission.RejectNotLoggedIn

                WikiUser.SessionWrongWiki ->
                    respondErr Submission.RejectWrongWikiSession

                WikiUser.SessionHasAccount accountId ->
                    if not (WikiContributors.isTrustedForWiki wikiSlug accountId model.contributors) then
                        respondErr Submission.RejectForbidden

                    else
                        case Dict.get wikiSlug model.wikis of
                            Nothing ->
                                respondErr Submission.RejectWikiNotFound

                            Just w ->
                                if not w.active then
                                    respondErr Submission.RejectWikiInactive

                                else
                                    case Dict.get submissionId model.submissions of
                                        Nothing ->
                                            respondErr Submission.RejectSubmissionNotFound

                                        Just sub ->
                                            if sub.wikiSlug /= wikiSlug then
                                                respondErr Submission.RejectSubmissionNotFound

                                            else
                                                case Submission.rejectPendingSubmission rej.reasonText sub of
                                                    Err e ->
                                                        respondErr e

                                                    Ok rejected ->
                                                        let
                                                            pageSlug : String
                                                            pageSlug =
                                                                Submission.pageSlugFromKind sub.kind
                                                                    |> Maybe.withDefault ""

                                                            nextModel0 : Model
                                                            nextModel0 =
                                                                { model
                                                                    | submissions =
                                                                        Dict.insert submissionId rejected model.submissions
                                                                }

                                                            nextModel : Model
                                                            nextModel =
                                                                recordAudit now
                                                                    wikiSlug
                                                                    accountId
                                                                    (WikiAuditLog.RejectedSubmission
                                                                        { submissionId = submissionId
                                                                        , pageSlug = pageSlug
                                                                        }
                                                                    )
                                                                    nextModel0
                                                        in
                                                        ( nextModel
                                                        , Effect.Lamdera.sendToFrontend clientId
                                                            (RejectSubmissionResponse wikiSlug submissionId (Ok ()))
                                                        )

        RequestSubmissionChanges wikiSlug req ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                submissionId : String
                submissionId =
                    req.submissionId

                respondErr : Submission.RequestChangesSubmissionError -> ( Model, Command BackendOnly ToFrontend Msg )
                respondErr err =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (RequestSubmissionChangesResponse wikiSlug submissionId (Err err))
                    )
            in
            case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                WikiUser.SessionNotLoggedIn ->
                    respondErr Submission.RequestChangesNotLoggedIn

                WikiUser.SessionWrongWiki ->
                    respondErr Submission.RequestChangesWrongWikiSession

                WikiUser.SessionHasAccount accountId ->
                    if not (WikiContributors.isTrustedForWiki wikiSlug accountId model.contributors) then
                        respondErr Submission.RequestChangesForbidden

                    else
                        case Dict.get wikiSlug model.wikis of
                            Nothing ->
                                respondErr Submission.RequestChangesWikiNotFound

                            Just w ->
                                if not w.active then
                                    respondErr Submission.RequestChangesWikiInactive

                                else
                                    case Dict.get submissionId model.submissions of
                                        Nothing ->
                                            respondErr Submission.RequestChangesSubmissionNotFound

                                        Just sub ->
                                            if sub.wikiSlug /= wikiSlug then
                                                respondErr Submission.RequestChangesSubmissionNotFound

                                            else
                                                case Submission.requestPendingSubmissionChanges req.guidanceText sub of
                                                    Err e ->
                                                        respondErr e

                                                    Ok needsRevision ->
                                                        let
                                                            pageSlug : String
                                                            pageSlug =
                                                                Submission.pageSlugFromKind sub.kind
                                                                    |> Maybe.withDefault ""

                                                            nextModel0 : Model
                                                            nextModel0 =
                                                                { model
                                                                    | submissions =
                                                                        Dict.insert submissionId needsRevision model.submissions
                                                                }

                                                            nextModel : Model
                                                            nextModel =
                                                                recordAudit now
                                                                    wikiSlug
                                                                    accountId
                                                                    (WikiAuditLog.RequestedSubmissionChanges
                                                                        { submissionId = submissionId
                                                                        , pageSlug = pageSlug
                                                                        }
                                                                    )
                                                                    nextModel0
                                                        in
                                                        ( nextModel
                                                        , Effect.Lamdera.sendToFrontend clientId
                                                            (RequestSubmissionChangesResponse wikiSlug submissionId (Ok ()))
                                                        )

        HostAdminLogin password ->
            if password == Env.hostAdminPassword then
                let
                    sessionKey : String
                    sessionKey =
                        Effect.Lamdera.sessionIdToString sessionId
                in
                ( { model | hostSessions = Set.insert sessionKey model.hostSessions }
                , Effect.Lamdera.sendToFrontend clientId (HostAdminLoginResponse (Ok ()))
                )

            else
                ( model
                , Effect.Lamdera.sendToFrontend clientId
                    (HostAdminLoginResponse (Err HostAdmin.WrongPassword))
                )

        RequestHostWikiList ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId
            in
            if Set.member sessionKey model.hostSessions then
                let
                    summaries : List Wiki.CatalogEntry
                    summaries =
                        model.wikis
                            |> Dict.values
                            |> List.map Wiki.catalogEntry
                            |> List.sortBy .slug
                in
                ( model
                , Effect.Lamdera.sendToFrontend clientId (HostAdminWikiListResponse (Ok summaries))
                )

            else
                ( model
                , Effect.Lamdera.sendToFrontend clientId
                    (HostAdminWikiListResponse (Err HostAdmin.NotHostAuthenticated))
                )

        RequestHostAuditLog filter ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respond :
                    Result HostAdmin.ProtectedError (List WikiAuditLog.ScopedAuditEvent)
                    -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId (HostAuditLogResponse filter res)
                    )
            in
            if Set.member sessionKey model.hostSessions then
                model.wikiAuditEvents
                    |> WikiAuditLog.allScopedEventsFromDict
                    |> WikiAuditLog.filterScopedEvents filter
                    |> Ok
                    |> respond

            else
                respond (Err HostAdmin.NotHostAuthenticated)

        CreateHostedWiki create ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respondErr : HostAdmin.CreateHostedWikiError -> ( Model, Command BackendOnly ToFrontend Msg )
                respondErr e =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId (CreateHostedWikiResponse (Err e))
                    )
            in
            if not (Set.member sessionKey model.hostSessions) then
                respondErr HostAdmin.CreateNotHostAuthenticated

            else
                case Submission.validatePageSlug create.rawSlug of
                    Err ve ->
                        respondErr (HostAdmin.CreateSlugInvalid ve)

                    Ok slug ->
                        case HostAdmin.validateHostedWikiName create.rawName of
                            Err ne ->
                                respondErr (HostAdmin.CreateWikiNameInvalid ne)

                            Ok name ->
                                case ContributorAccount.validateRegistrationFields create.initialAdminUsername create.initialAdminPassword of
                                    Err regErr ->
                                        respondErr (HostAdmin.CreateInitialAdminInvalid regErr)

                                    Ok _ ->
                                        if Dict.member slug model.wikis then
                                            respondErr HostAdmin.CreateWikiSlugTaken

                                        else
                                            let
                                                wiki : Wiki
                                                wiki =
                                                    { slug = slug
                                                    , name = name
                                                    , summary = ""
                                                    , active = True
                                                    , pages = Dict.empty
                                                    }

                                                modelWithWiki : Model
                                                modelWithWiki =
                                                    { model | wikis = Dict.insert slug wiki model.wikis }
                                            in
                                            case
                                                WikiContributors.seedAdminContributorAtWiki
                                                    slug
                                                    create.initialAdminUsername
                                                    create.initialAdminPassword
                                                    modelWithWiki.wikis
                                                    modelWithWiki.contributors
                                            of
                                                Err regErr2 ->
                                                    ( model
                                                    , Effect.Lamdera.sendToFrontend clientId
                                                        (CreateHostedWikiResponse (Err (HostAdmin.CreateInitialAdminInvalid regErr2)))
                                                    )

                                                Ok nextContributors ->
                                                    let
                                                        nextWiki : Wiki
                                                        nextWiki =
                                                            Dict.get slug modelWithWiki.wikis
                                                                |> Maybe.withDefault wiki

                                                        nextModel : Model
                                                        nextModel =
                                                            { modelWithWiki | contributors = nextContributors }
                                                    in
                                                    ( nextModel
                                                    , Command.batch
                                                        [ Effect.Lamdera.sendToFrontend clientId
                                                            (CreateHostedWikiResponse (Ok (Wiki.catalogEntry nextWiki)))
                                                        , Effect.Lamdera.broadcast
                                                            (WikiCatalogResponse (Wiki.publicCatalogDict nextModel.wikis))
                                                        ]
                                                    )

        RequestHostWikiDetail wikiSlug ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId
            in
            if not (Set.member sessionKey model.hostSessions) then
                ( model
                , Effect.Lamdera.sendToFrontend clientId
                    (HostWikiDetailResponse wikiSlug (Err HostAdmin.HostWikiDetailNotHostAuthenticated))
                )

            else
                case Dict.get wikiSlug model.wikis of
                    Nothing ->
                        ( model
                        , Effect.Lamdera.sendToFrontend clientId
                            (HostWikiDetailResponse wikiSlug (Err HostAdmin.HostWikiDetailWikiNotFound))
                        )

                    Just wiki ->
                        ( model
                        , Effect.Lamdera.sendToFrontend clientId
                            (HostWikiDetailResponse wikiSlug (Ok (Wiki.catalogEntry wiki)))
                        )

        UpdateHostedWikiMetadata wikiSlug meta ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respondErr : HostAdmin.UpdateHostedWikiMetadataError -> ( Model, Command BackendOnly ToFrontend Msg )
                respondErr e =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (UpdateHostedWikiMetadataResponse wikiSlug (Err e))
                    )
            in
            if not (Set.member sessionKey model.hostSessions) then
                respondErr HostAdmin.UpdateMetadataNotHostAuthenticated

            else
                case Dict.get wikiSlug model.wikis of
                    Nothing ->
                        respondErr HostAdmin.UpdateMetadataWikiNotFound

                    Just wiki ->
                        case HostAdmin.validateHostedWikiName meta.rawName of
                            Err ne ->
                                respondErr (HostAdmin.UpdateMetadataWikiNameInvalid ne)

                            Ok name ->
                                case HostAdmin.validateHostedWikiSummary meta.rawSummary of
                                    Err se ->
                                        respondErr (HostAdmin.UpdateMetadataWikiSummaryInvalid se)

                                    Ok summaryText ->
                                        case HostAdmin.validateHostedWikiMetadataSlug wiki.slug meta.rawSlugDraft of
                                            Err slugErr ->
                                                respondErr slugErr

                                            Ok newSlug ->
                                                let
                                                    nextWikiBase : Wiki
                                                    nextWikiBase =
                                                        { wiki
                                                            | name = name
                                                            , summary = summaryText
                                                        }

                                                    nextWiki : Wiki
                                                    nextWiki =
                                                        { nextWikiBase | slug = newSlug }
                                                in
                                                if newSlug == wikiSlug then
                                                    let
                                                        nextModel : Model
                                                        nextModel =
                                                            { model | wikis = Dict.insert wikiSlug nextWiki model.wikis }
                                                    in
                                                    ( nextModel
                                                    , Effect.Lamdera.sendToFrontend clientId
                                                        (UpdateHostedWikiMetadataResponse wikiSlug (Ok (Wiki.catalogEntry nextWiki)))
                                                    )

                                                else if Dict.member newSlug model.wikis then
                                                    respondErr HostAdmin.UpdateMetadataWikiSlugTaken

                                                else
                                                    let
                                                        nextModel : Model
                                                        nextModel =
                                                            applyHostedWikiSlugRename wikiSlug newSlug nextWiki model
                                                    in
                                                    ( nextModel
                                                    , Effect.Lamdera.sendToFrontend clientId
                                                        (UpdateHostedWikiMetadataResponse wikiSlug (Ok (Wiki.catalogEntry nextWiki)))
                                                    )

        DeactivateHostedWiki wikiSlug ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respondErr : HostAdmin.WikiLifecycleError -> ( Model, Command BackendOnly ToFrontend Msg )
                respondErr e =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (DeactivateHostedWikiResponse wikiSlug (Err e))
                    )
            in
            if not (Set.member sessionKey model.hostSessions) then
                respondErr HostAdmin.WikiLifecycleNotHostAuthenticated

            else
                case Dict.get wikiSlug model.wikis of
                    Nothing ->
                        respondErr HostAdmin.WikiLifecycleWikiNotFound

                    Just wiki ->
                        let
                            nextWiki : Wiki
                            nextWiki =
                                { wiki | active = False }

                            nextModel : Model
                            nextModel =
                                { model | wikis = Dict.insert wikiSlug nextWiki model.wikis }
                        in
                        ( nextModel
                        , Effect.Lamdera.sendToFrontend clientId
                            (DeactivateHostedWikiResponse wikiSlug (Ok (Wiki.catalogEntry nextWiki)))
                        )

        ReactivateHostedWiki wikiSlug ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respondErr : HostAdmin.WikiLifecycleError -> ( Model, Command BackendOnly ToFrontend Msg )
                respondErr e =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (ReactivateHostedWikiResponse wikiSlug (Err e))
                    )
            in
            if not (Set.member sessionKey model.hostSessions) then
                respondErr HostAdmin.WikiLifecycleNotHostAuthenticated

            else
                case Dict.get wikiSlug model.wikis of
                    Nothing ->
                        respondErr HostAdmin.WikiLifecycleWikiNotFound

                    Just wiki ->
                        let
                            nextWiki : Wiki
                            nextWiki =
                                { wiki | active = True }

                            nextModel : Model
                            nextModel =
                                { model | wikis = Dict.insert wikiSlug nextWiki model.wikis }
                        in
                        ( nextModel
                        , Effect.Lamdera.sendToFrontend clientId
                            (ReactivateHostedWikiResponse wikiSlug (Ok (Wiki.catalogEntry nextWiki)))
                        )

        DeleteHostedWiki wikiSlug confirmationPhrase ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respondErr : HostAdmin.DeleteHostedWikiError -> ( Model, Command BackendOnly ToFrontend Msg )
                respondErr e =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (DeleteHostedWikiResponse wikiSlug (Err e))
                    )
            in
            if not (Set.member sessionKey model.hostSessions) then
                respondErr HostAdmin.DeleteHostedWikiNotHostAuthenticated

            else
                case Dict.get wikiSlug model.wikis of
                    Nothing ->
                        respondErr HostAdmin.DeleteHostedWikiWikiNotFound

                    Just _ ->
                        if not (HostAdmin.deleteHostedWikiConfirmationMatches wikiSlug confirmationPhrase) then
                            respondErr HostAdmin.DeleteHostedWikiConfirmationMismatch

                        else
                            let
                                nextSubmissions : Dict String Submission.Submission
                                nextSubmissions =
                                    model.submissions
                                        |> Dict.filter (\_ sub -> sub.wikiSlug /= wikiSlug)

                                nextModel : Model
                                nextModel =
                                    { model
                                        | wikis = Dict.remove wikiSlug model.wikis
                                        , contributors = Dict.remove wikiSlug model.contributors
                                        , contributorSessions = WikiUser.dropBindingsForWiki wikiSlug model.contributorSessions
                                        , submissions = nextSubmissions
                                        , wikiAuditEvents = Dict.remove wikiSlug model.wikiAuditEvents
                                    }
                            in
                            ( nextModel
                            , Effect.Lamdera.sendToFrontend clientId
                                (DeleteHostedWikiResponse wikiSlug (Ok ()))
                            )

        RequestHostAdminDataExport ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId
            in
            if not (Set.member sessionKey model.hostSessions) then
                ( model
                , Effect.Lamdera.sendToFrontend clientId
                    (HostAdminDataExportResponse (Err HostAdmin.DataExportNotHostAuthenticated))
                )

            else
                ( model
                , Effect.Lamdera.sendToFrontend clientId
                    (HostAdminDataExportResponse (Ok (BackendDataExport.encodeModelToJsonString model)))
                )

        ImportHostAdminDataSnapshot rawJson ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId
            in
            if not (Set.member sessionKey model.hostSessions) then
                ( model
                , Effect.Lamdera.sendToFrontend clientId
                    (HostAdminDataImportResponse (Err HostAdmin.DataImportNotHostAuthenticated))
                )

            else
                case BackendDataExport.decodeImportString rawJson of
                    Err importErr ->
                        ( model
                        , Effect.Lamdera.sendToFrontend clientId
                            (HostAdminDataImportResponse
                                (Err
                                    (HostAdmin.DataImportInvalid (BackendDataExport.importErrorToString importErr))
                                )
                            )
                        )

                    Ok snap ->
                        let
                            nextModel : Model
                            nextModel =
                                BackendDataExport.applySnapshotToBackendModel snap model.hostSessions
                        in
                        ( nextModel
                        , Effect.Lamdera.sendToFrontend clientId (HostAdminDataImportResponse (Ok ()))
                        )

        RequestHostAdminWikiDataExport wikiSlug ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId
            in
            if not (Set.member sessionKey model.hostSessions) then
                ( model
                , Effect.Lamdera.sendToFrontend clientId
                    (HostAdminWikiDataExportResponse wikiSlug (Err HostAdmin.WikiDataExportNotHostAuthenticated))
                )

            else
                case BackendDataExport.encodeWikiSnapshotToJsonString wikiSlug model of
                    Nothing ->
                        ( model
                        , Effect.Lamdera.sendToFrontend clientId
                            (HostAdminWikiDataExportResponse wikiSlug (Err HostAdmin.WikiDataExportWikiNotFound))
                        )

                    Just json ->
                        ( model
                        , Effect.Lamdera.sendToFrontend clientId
                            (HostAdminWikiDataExportResponse wikiSlug (Ok json))
                        )

        ImportHostAdminWikiDataSnapshot wikiSlug rawJson ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId
            in
            if not (Set.member sessionKey model.hostSessions) then
                ( model
                , Effect.Lamdera.sendToFrontend clientId
                    (HostAdminWikiDataImportResponse wikiSlug (Err HostAdmin.WikiDataImportNotHostAuthenticated))
                )

            else
                case Dict.get wikiSlug model.wikis of
                    Nothing ->
                        ( model
                        , Effect.Lamdera.sendToFrontend clientId
                            (HostAdminWikiDataImportResponse wikiSlug (Err HostAdmin.WikiDataImportWikiNotFound))
                        )

                    Just _ ->
                        case BackendDataExport.decodeWikiImportForSlug wikiSlug rawJson of
                            Err importErr ->
                                ( model
                                , Effect.Lamdera.sendToFrontend clientId
                                    (HostAdminWikiDataImportResponse wikiSlug
                                        (Err
                                            (HostAdmin.WikiDataImportInvalid
                                                (BackendDataExport.importErrorToString importErr)
                                            )
                                        )
                                    )
                                )

                            Ok snap ->
                                case BackendDataExport.applyWikiSnapshotMerge wikiSlug snap model of
                                    Err detail ->
                                        ( model
                                        , Effect.Lamdera.sendToFrontend clientId
                                            (HostAdminWikiDataImportResponse wikiSlug
                                                (Err (HostAdmin.WikiDataImportInvalid detail))
                                            )
                                        )

                                    Ok nextModel ->
                                        ( nextModel
                                        , Effect.Lamdera.sendToFrontend clientId
                                            (HostAdminWikiDataImportResponse wikiSlug (Ok ()))
                                        )

        ImportHostAdminWikiDataSnapshotAuto rawJson ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId
            in
            if not (Set.member sessionKey model.hostSessions) then
                ( model
                , Effect.Lamdera.sendToFrontend clientId
                    (HostAdminWikiDataImportAutoResponse (Err HostAdmin.WikiDataImportNotHostAuthenticated))
                )

            else
                case BackendDataExport.decodeWikiImportString rawJson of
                    Err importErr ->
                        ( model
                        , Effect.Lamdera.sendToFrontend clientId
                            (HostAdminWikiDataImportAutoResponse
                                (Err
                                    (HostAdmin.WikiDataImportInvalid
                                        (BackendDataExport.importErrorToString importErr)
                                    )
                                )
                            )
                        )

                    Ok ( wikiSlug, snap ) ->
                        case BackendDataExport.applyWikiSnapshotMerge wikiSlug snap model of
                            Err detail ->
                                ( model
                                , Effect.Lamdera.sendToFrontend clientId
                                    (HostAdminWikiDataImportAutoResponse
                                        (Err (HostAdmin.WikiDataImportInvalid detail))
                                    )
                                )

                            Ok nextModel ->
                                ( nextModel
                                , Effect.Lamdera.sendToFrontend clientId
                                    (HostAdminWikiDataImportAutoResponse (Ok wikiSlug))
                                )


subscriptions : Model -> Subscription BackendOnly Msg
subscriptions _ =
    Subscription.none


app_ :
    { init : ( Model, Command BackendOnly ToFrontend Msg )
    , update : Msg -> Model -> ( Model, Command BackendOnly ToFrontend Msg )
    , updateFromFrontend :
        SessionId
        -> ClientId
        -> ToBackend
        -> Model
        -> ( Model, Command BackendOnly ToFrontend Msg )
    , subscriptions : Model -> Subscription BackendOnly Msg
    }
app_ =
    { init = init
    , update = update
    , updateFromFrontend = updateFromFrontend
    , subscriptions = subscriptions
    }


app :
    { init : ( Model, Cmd Msg )
    , update : Msg -> Model -> ( Model, Cmd Msg )
    , updateFromFrontend : String -> String -> ToBackend -> Model -> ( Model, Cmd Msg )
    , subscriptions : Model -> Sub Msg
    }
app =
    Effect.Lamdera.backend Lamdera.broadcast Lamdera.sendToFrontend app_

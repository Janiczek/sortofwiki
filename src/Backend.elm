module Backend exposing (Model, Msg, app, app_)

import ContributorAccount
import Dict exposing (Dict)
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Lamdera exposing (ClientId, SessionId)
import Effect.Subscription as Subscription exposing (Subscription)
import Env
import HostAdmin
import Lamdera
import Page
import Set
import Submission
import SubmissionReviewDetail
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


{-| Append one audit row and advance the monotonic server clock (stories 25, 34).
Uses the acting account id (moderator / admin), not submission authors.
-}
recordAudit : Wiki.Slug -> ContributorAccount.Id -> WikiAuditLog.AuditEventKind -> Model -> Model
recordAudit wikiSlug actorId kind model =
    let
        actor : String
        actor =
            WikiContributors.displayUsernameForAccount wikiSlug actorId model.contributors
                |> Maybe.withDefault "unknown"
    in
    { model
        | wikiAuditEvents =
            WikiAuditLog.append wikiSlug model.auditClockMillis actor kind model.wikiAuditEvents
        , auditClockMillis = model.auditClockMillis + 1
    }


seedWikis : Dict Wiki.Slug Wiki
seedWikis =
    [ { slug = "demo"
      , name = "Demo Wiki"
      , summary = "This is a demo testing hardcoded wiki, just for testing!"
      , active = True
      , pages =
            [ Page.withPublishedAndPending "Home"
                """Welcome to the Demo Wiki. See [Guides](/w/demo/p/Guides) and [MarkdownPlayground](/w/demo/p/MarkdownPlayground)."""
                """### STORY06_PENDING_LEAK

Unpublished draft only. [[OnlyPending]]"""
            , Page.withPublished "Guides"
                """## How to use this wiki

Read the **manual**.

The home page links here, so it shows under *Backlinks* below. That list is inbound links only—this page does not link back to home.
"""
            , Page.withPublished "About"
                """This page links only to [[Home]]. The home page does not link here; *Backlinks* on home still lists this page because other pages pointing **to** the current page are what backlinks mean.
"""
            , Page.withPublished "MarkdownPlayground"
                """# Markdown Playground

This page demonstrates seeded Markdown support.

## Inline formatting

This paragraph includes **bold**, *italic*, `inline code`, and ~~strikethrough~~.

## Links

- External link: [Lamdera](https://lamdera.com)
- In-wiki link by slug: [[Guides]]
- In-wiki link with label: [[About|About this wiki]]
- Raw URL autolink: <https://example.com>

## Lists

- Unordered item one
- Unordered item two
  - Nested unordered item

1. Ordered item one
2. Ordered item two

## Blockquote

> This is a blockquote.
>
> It spans multiple lines.

## Code block

```elm
viewGreeting : String -> String
viewGreeting name =
    "Hello, " ++ name
```

## Horizontal rule

---

## Escaping and entities

Use \\*asterisks\\* literally and show an ampersand entity: &amp;.
"""
            , Page.pendingOnly "OnlyPending"
                """STORY06_PENDING_ONLY visible if leaked."""
            ]
                |> slugDict
      }
    , { slug = "elm-tips"
      , name = "Elm Tips"
      , summary = ""
      , active = True
      , pages =
            [ Page.withPublished "Home" """Tips and notes about Elm.""" ]
                |> slugDict
      }
    ]
        |> slugDict


slugDict : List { a | slug : String } -> Dict String { a | slug : String }
slugDict list =
    list
        |> List.map (\item -> ( item.slug, item ))
        |> Dict.fromList


{-| Demo submissions for story 12 (log in as `statusdemo` / `password12` on `demo`).
Story 15: `demoReviewQueuePendingSubmission` seeds pending `sub_queue_demo` for the trusted review queue.
Story 19: `demoRequestChangesPendingSubmission` seeds pending `sub_changes_demo` (separate id so approve/reject e2e tests on `sub_queue_demo` stay isolated).
-}
demoReviewQueuePendingSubmission : ContributorAccount.Id -> Submission.Submission
demoReviewQueuePendingSubmission authorId =
    { id = Submission.idFromKey "sub_queue_demo"
    , wikiSlug = "demo"
    , authorId = authorId
    , kind =
        Submission.NewPage
            { pageSlug = "queue-demo-page"
            , markdown = "Seeded pending submission for the trusted review queue (story 15)."
            }
    , status = Submission.Pending
    , reviewerNote = Nothing
    }


demoRequestChangesPendingSubmission : ContributorAccount.Id -> Submission.Submission
demoRequestChangesPendingSubmission authorId =
    { id = Submission.idFromKey "sub_changes_demo"
    , wikiSlug = "demo"
    , authorId = authorId
    , kind =
        Submission.NewPage
            { pageSlug = "request-changes-demo-page"
            , markdown = "Seeded pending submission for request-changes (story 19)."
            }
    , status = Submission.Pending
    , reviewerNote = Nothing
    }


demoStatusSeededSubmissions : ContributorAccount.Id -> Dict String Submission.Submission
demoStatusSeededSubmissions authorId =
    Dict.fromList
        [ ( "sub_rejected_demo"
          , { id = Submission.idFromKey "sub_rejected_demo"
            , wikiSlug = "demo"
            , authorId = authorId
            , kind =
                Submission.NewPage
                    { pageSlug = "seed-rejected"
                    , markdown = "Seeded submission (rejected)."
                    }
            , status = Submission.Rejected
            , reviewerNote =
                Just "Seeded reviewer note (story 13): expand the outline and add sources before resubmitting."
            }
          )
        , ( "sub_approved_demo"
          , { id = Submission.idFromKey "sub_approved_demo"
            , wikiSlug = "demo"
            , authorId = authorId
            , kind =
                Submission.EditPage
                    { pageSlug = "Home"
                    , baseMarkdown = "Welcome to the demo wiki."
                    , baseRevision = 1
                    , proposedMarkdown = "Seeded submission (approved)."
                    }
            , status = Submission.Approved
            , reviewerNote = Nothing
            }
          )
        , ( "sub_needs_revision_demo"
          , { id = Submission.idFromKey "sub_needs_revision_demo"
            , wikiSlug = "demo"
            , authorId = authorId
            , kind =
                Submission.DeletePage
                    { pageSlug = "Guides"
                    , reason = Nothing
                    }
            , status = Submission.NeedsRevision
            , reviewerNote = Just "Please justify why this page should be removed; deletion is disruptive."
            }
          )
        ]


init : ( Model, Command BackendOnly ToFrontend Msg )
init =
    let
        wikis : Dict Wiki.Slug Wiki
        wikis =
            seedWikis

        contributors : WikiContributors.Registry
        contributors =
            case WikiContributors.seedContributorAtWiki "demo" "statusdemo" "password12" wikis WikiContributors.emptyRegistry of
                Err _ ->
                    WikiContributors.emptyRegistry

                Ok afterStatus ->
                    case WikiContributors.seedTrustedContributorAtWiki "demo" "trustedpub" "password12" wikis afterStatus of
                        Err _ ->
                            afterStatus

                        Ok afterTrusted ->
                            case WikiContributors.seedAdminContributorAtWiki "demo" "wikidemo" "password12" wikis afterTrusted of
                                Err _ ->
                                    afterTrusted

                                Ok afterAdmin ->
                                    case WikiContributors.seedTrustedContributorAtWiki "demo" "grantadmin_trusted" "password12" wikis afterAdmin of
                                        Err _ ->
                                            afterAdmin

                                        Ok afterGrantSeed ->
                                            afterGrantSeed

        statusDemoAuthorId : ContributorAccount.Id
        statusDemoAuthorId =
            ContributorAccount.newAccountId "demo" "statusdemo"

        submissions : Dict String Submission.Submission
        submissions =
            demoStatusSeededSubmissions statusDemoAuthorId
                |> Dict.insert "sub_queue_demo" (demoReviewQueuePendingSubmission statusDemoAuthorId)
                |> Dict.insert "sub_changes_demo" (demoRequestChangesPendingSubmission statusDemoAuthorId)
    in
    ( { wikis = wikis
      , contributors = contributors
      , contributorSessions = WikiUser.emptySessions
      , hostSessions = Set.empty
      , submissions = submissions
      , nextSubmissionCounter = 1
      , wikiAuditEvents = Dict.empty
      , auditClockMillis = 1704067200000
      }
    , Command.none
    )


update : Msg -> Model -> ( Model, Command BackendOnly ToFrontend Msg )
update msg model =
    case msg of
        BackendNoOp ->
            ( model, Command.none )


{-| Client messages from Lamdera.

**Authorization (story 33):** privileged handlers consult `contributorSessions` and `hostSessions`
(and wiki binding) before changing state. Regression coverage: `tests/BackendAuthorizationTest.elm`
(per-message `Err` and no mutation where applicable) and `ProgramTest.Story33_BackendAuthorization`.

**Public:** `RequestWikiCatalog`, `RequestWikiFrontendDetails`, `RequestPageFrontendDetails`.
**Credential setup:** `RegisterContributor`, `LoginContributor`, `HostAdminLogin`.

-}
updateFromFrontend :
    SessionId
    -> ClientId
    -> ToBackend
    -> Model
    -> ( Model, Command BackendOnly ToFrontend Msg )
updateFromFrontend sessionId clientId msg model =
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
                case Dict.get sessionKey model.contributorSessions of
                    Nothing ->
                        respond (Err Submission.ReviewQueueNotLoggedIn)

                    Just (WikiUser.Binding boundWiki accountId) ->
                        if boundWiki /= wikiSlug then
                            respond (Err Submission.ReviewQueueWrongWikiSession)

                        else if not (WikiContributors.isTrustedForWiki wikiSlug accountId model.contributors) then
                            respond (Err Submission.ReviewQueueForbidden)

                        else
                            model.submissions
                                |> Submission.pendingSubmissionsForWiki wikiSlug
                                |> List.map (Submission.reviewQueueItemFromSubmission lookupAuthor)
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
                        case Dict.get sessionKey model.contributorSessions of
                            Nothing ->
                                respond (Err WikiAdminUsers.NotLoggedIn)

                            Just (WikiUser.Binding boundWiki accountId) ->
                                if boundWiki /= wikiSlug then
                                    respond (Err WikiAdminUsers.WrongWikiSession)

                                else if not (WikiContributors.isAdminForWiki wikiSlug accountId model.contributors) then
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
                        case Dict.get sessionKey model.contributorSessions of
                            Nothing ->
                                respond (Err WikiAuditLog.NotLoggedIn)

                            Just (WikiUser.Binding boundWiki accountId) ->
                                if boundWiki /= wikiSlug then
                                    respond (Err WikiAuditLog.WrongWikiSession)

                                else if not (WikiContributors.isAdminForWiki wikiSlug accountId model.contributors) then
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
                        case Dict.get sessionKey model.contributorSessions of
                            Nothing ->
                                respond (Err WikiAdminUsers.PromoteNotLoggedIn)

                            Just (WikiUser.Binding boundWiki accountId) ->
                                if boundWiki /= wikiSlug then
                                    respond (Err WikiAdminUsers.PromoteWrongWikiSession)

                                else if not (WikiContributors.isAdminForWiki wikiSlug accountId model.contributors) then
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
                                                ( recordAudit wikiSlug
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
                        case Dict.get sessionKey model.contributorSessions of
                            Nothing ->
                                respond (Err WikiAdminUsers.DemoteNotLoggedIn)

                            Just (WikiUser.Binding boundWiki accountId) ->
                                if boundWiki /= wikiSlug then
                                    respond (Err WikiAdminUsers.DemoteWrongWikiSession)

                                else if not (WikiContributors.isAdminForWiki wikiSlug accountId model.contributors) then
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
                                                ( recordAudit wikiSlug
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
                        case Dict.get sessionKey model.contributorSessions of
                            Nothing ->
                                respond (Err WikiAdminUsers.GrantTrustedNotLoggedIn)

                            Just (WikiUser.Binding boundWiki accountId) ->
                                if boundWiki /= wikiSlug then
                                    respond (Err WikiAdminUsers.GrantTrustedWrongWikiSession)

                                else if not (WikiContributors.isAdminForWiki wikiSlug accountId model.contributors) then
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
                                                ( recordAudit wikiSlug
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
                        case Dict.get sessionKey model.contributorSessions of
                            Nothing ->
                                respond (Err WikiAdminUsers.RevokeAdminNotLoggedIn)

                            Just (WikiUser.Binding boundWiki accountId) ->
                                if boundWiki /= wikiSlug then
                                    respond (Err WikiAdminUsers.RevokeAdminWrongWikiSession)

                                else if not (WikiContributors.isAdminForWiki wikiSlug accountId model.contributors) then
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
                                                ( recordAudit wikiSlug
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
            case Dict.get sessionKey model.contributorSessions of
                Nothing ->
                    respond (Err SubmissionReviewDetail.ReviewSubmissionDetailNotLoggedIn)

                Just (WikiUser.Binding boundWiki accountId) ->
                    if boundWiki /= wikiSlug then
                        respond (Err SubmissionReviewDetail.ReviewSubmissionDetailWrongWikiSession)

                    else if not (WikiContributors.isTrustedForWiki wikiSlug accountId model.contributors) then
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
            case Dict.get sessionKey model.contributorSessions of
                Nothing ->
                    respond (Err Submission.DetailsNotLoggedIn)

                Just (WikiUser.Binding boundWiki accountId) ->
                    if boundWiki /= wikiSlug then
                        respond (Err Submission.DetailsWrongWikiSession)

                    else
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

        RegisterContributor wikiSlug username password ->
            case WikiContributors.attemptRegister wikiSlug username password model.wikis model.contributors of
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
                        (RegisterContributorResponse wikiSlug (Ok WikiRole.UntrustedContributor))
                    )

        LoginContributor wikiSlug username password ->
            case WikiContributors.attemptLogin wikiSlug username password model.wikis model.contributors of
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
                                |> Maybe.withDefault WikiRole.UntrustedContributor
                    in
                    ( { model | contributorSessions = nextSessions }
                    , Effect.Lamdera.sendToFrontend clientId
                        (LoginContributorResponse wikiSlug (Ok role))
                    )

        SubmitNewPage wikiSlug rawSlug rawMarkdown ->
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
            case Dict.get sessionKey model.contributorSessions of
                Nothing ->
                    respondErr Submission.NotLoggedIn

                Just (WikiUser.Binding boundWiki accountId) ->
                    if boundWiki /= wikiSlug then
                        respondErr Submission.WrongWikiSession

                    else
                        case Dict.get wikiSlug model.wikis of
                            Nothing ->
                                respondErr Submission.WikiNotFound

                            Just wiki ->
                                if not wiki.active then
                                    respondErr Submission.WikiInactive

                                else
                                    case Submission.validateNewPageFields rawSlug rawMarkdown of
                                        Err ve ->
                                            respondErr (Submission.Validation ve)

                                        Ok payload ->
                                            if Dict.member payload.pageSlug wiki.pages then
                                                respondErr Submission.SlugAlreadyInUse

                                            else if Submission.pendingNewPageSlugInUse wikiSlug payload.pageSlug model.submissions then
                                                respondErr Submission.SlugAlreadyInUse

                                            else if WikiContributors.isTrustedForWiki wikiSlug accountId model.contributors then
                                                let
                                                    nextWiki : Wiki
                                                    nextWiki =
                                                        Wiki.publishNewPageOnWiki payload wiki

                                                    nextModel0 : Model
                                                    nextModel0 =
                                                        { model
                                                            | wikis = Dict.insert wikiSlug nextWiki model.wikis
                                                        }

                                                    nextModel : Model
                                                    nextModel =
                                                        recordAudit wikiSlug
                                                            accountId
                                                            (WikiAuditLog.TrustedPublishedNewPage { pageSlug = payload.pageSlug })
                                                            nextModel0
                                                in
                                                ( nextModel
                                                , Effect.Lamdera.sendToFrontend clientId
                                                    (SubmitNewPageResponse wikiSlug (Ok Submission.NewPagePublishedImmediately))
                                                )

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

        SubmitPageEdit wikiSlug pageSlug rawMarkdown ->
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
            case Dict.get sessionKey model.contributorSessions of
                Nothing ->
                    respondErr Submission.EditNotLoggedIn

                Just (WikiUser.Binding boundWiki accountId) ->
                    if boundWiki /= wikiSlug then
                        respondErr Submission.EditWrongWikiSession

                    else
                        case Dict.get wikiSlug model.wikis of
                            Nothing ->
                                respondErr Submission.EditWikiNotFound

                            Just wiki ->
                                if not wiki.active then
                                    respondErr Submission.EditWikiInactive

                                else
                                    case Submission.validateEditMarkdown rawMarkdown of
                                        Err ve ->
                                            respondErr (Submission.EditValidation ve)

                                        Ok markdown ->
                                            if not (Submission.wikiHasPublishedPage pageSlug wiki) then
                                                respondErr Submission.EditTargetPageNotPublished

                                            else if Submission.pendingEditForAuthorOnPageInUse wikiSlug accountId pageSlug model.submissions then
                                                respondErr Submission.EditAlreadyPendingForAuthor

                                            else if WikiContributors.isTrustedForWiki wikiSlug accountId model.contributors then
                                                let
                                                    nextWiki : Wiki
                                                    nextWiki =
                                                        Wiki.applyPublishedMarkdownEdit pageSlug markdown wiki

                                                    nextModel0 : Model
                                                    nextModel0 =
                                                        { model
                                                            | wikis = Dict.insert wikiSlug nextWiki model.wikis
                                                        }

                                                    nextModel : Model
                                                    nextModel =
                                                        recordAudit wikiSlug
                                                            accountId
                                                            (WikiAuditLog.TrustedPublishedPageEdit { pageSlug = pageSlug })
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
                                                                , proposedMarkdown = markdown
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

        SubmitPageDelete wikiSlug pageSlug rawReason ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respondErr : Submission.SubmitPageDeleteError -> ( Model, Command BackendOnly ToFrontend Msg )
                respondErr err =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (SubmitPageDeleteResponse wikiSlug (Err err))
                    )
            in
            case Dict.get sessionKey model.contributorSessions of
                Nothing ->
                    respondErr Submission.DeleteNotLoggedIn

                Just (WikiUser.Binding boundWiki accountId) ->
                    if boundWiki /= wikiSlug then
                        respondErr Submission.DeleteWrongWikiSession

                    else
                        case Dict.get wikiSlug model.wikis of
                            Nothing ->
                                respondErr Submission.DeleteWikiNotFound

                            Just wiki ->
                                if not wiki.active then
                                    respondErr Submission.DeleteWikiInactive

                                else
                                    case Submission.validateDeleteReason rawReason of
                                        Err ve ->
                                            respondErr (Submission.DeleteValidation ve)

                                        Ok maybeReason ->
                                            if not (Submission.wikiHasPublishedPage pageSlug wiki) then
                                                respondErr Submission.DeleteTargetPageNotPublished

                                            else if WikiContributors.isTrustedForWiki wikiSlug accountId model.contributors then
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
                                                        recordAudit wikiSlug
                                                            accountId
                                                            (WikiAuditLog.TrustedPublishedPageDelete { pageSlug = pageSlug })
                                                            nextModel0
                                                in
                                                ( nextModel
                                                , Effect.Lamdera.sendToFrontend clientId
                                                    (SubmitPageDeleteResponse wikiSlug (Ok Submission.DeletePublishedImmediately))
                                                )

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
                                                                , reason = maybeReason
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
                                                    (SubmitPageDeleteResponse wikiSlug (Ok (Submission.DeleteSubmittedForReview submissionId)))
                                                )

        ResubmitPageEdit wikiSlug submissionId rawMarkdown ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respondErr : Submission.ResubmitPageEditError -> ( Model, Command BackendOnly ToFrontend Msg )
                respondErr err =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (ResubmitPageEditResponse wikiSlug submissionId (Err err))
                    )
            in
            case Dict.get sessionKey model.contributorSessions of
                Nothing ->
                    respondErr Submission.ResubmitEditNotLoggedIn

                Just (WikiUser.Binding boundWiki accountId) ->
                    if boundWiki /= wikiSlug then
                        respondErr Submission.ResubmitEditWrongWikiSession

                    else
                        case Dict.get wikiSlug model.wikis of
                            Nothing ->
                                respondErr Submission.ResubmitEditWikiNotFound

                            Just wiki ->
                                if not wiki.active then
                                    respondErr Submission.ResubmitEditWikiInactive

                                else
                                    case Dict.get submissionId model.submissions of
                                        Nothing ->
                                            respondErr Submission.ResubmitEditSubmissionNotFound

                                        Just sub ->
                                            if sub.wikiSlug /= wikiSlug then
                                                respondErr Submission.ResubmitEditSubmissionNotFound

                                            else if sub.authorId /= accountId then
                                                respondErr Submission.ResubmitEditForbidden

                                            else
                                                case sub.kind of
                                                    Submission.EditPage body ->
                                                        if not (Submission.wikiHasPublishedPage body.pageSlug wiki) then
                                                            respondErr Submission.ResubmitEditTargetPageNotPublished

                                                        else
                                                            let
                                                                currentMarkdown : String
                                                                currentMarkdown =
                                                                    SubmissionReviewDetail.publishedMarkdownForSlug wiki body.pageSlug

                                                                currentRevision : Int
                                                                currentRevision =
                                                                    Submission.currentPublishedRevision wiki body.pageSlug
                                                                        |> Maybe.withDefault 0
                                                            in
                                                            case
                                                                Submission.resubmitNeedsRevisionEdit
                                                                    { markdown = rawMarkdown
                                                                    , currentMarkdown = currentMarkdown
                                                                    , currentRevision = currentRevision
                                                                    }
                                                                    sub
                                                            of
                                                                Err err ->
                                                                    respondErr err

                                                                Ok nextSub ->
                                                                    ( { model
                                                                        | submissions =
                                                                            Dict.insert submissionId nextSub model.submissions
                                                                      }
                                                                    , Effect.Lamdera.sendToFrontend clientId
                                                                        (ResubmitPageEditResponse wikiSlug submissionId (Ok ()))
                                                                    )

                                                    Submission.NewPage _ ->
                                                        respondErr Submission.ResubmitEditNotEditKind

                                                    Submission.DeletePage _ ->
                                                        respondErr Submission.ResubmitEditNotEditKind

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
            case Dict.get sessionKey model.contributorSessions of
                Nothing ->
                    respondErr Submission.ApproveNotLoggedIn

                Just (WikiUser.Binding boundWiki accountId) ->
                    if boundWiki /= wikiSlug then
                        respondErr Submission.ApproveWrongWikiSession

                    else if not (WikiContributors.isTrustedForWiki wikiSlug accountId model.contributors) then
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
                                                                                        "Page changed after this edit was submitted. Resolve conflicts against the latest page and resubmit."
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
                                                                recordAudit wikiSlug
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

        RejectSubmission wikiSlug submissionId rawReason ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respondErr : Submission.RejectSubmissionError -> ( Model, Command BackendOnly ToFrontend Msg )
                respondErr err =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (RejectSubmissionResponse wikiSlug submissionId (Err err))
                    )
            in
            case Dict.get sessionKey model.contributorSessions of
                Nothing ->
                    respondErr Submission.RejectNotLoggedIn

                Just (WikiUser.Binding boundWiki accountId) ->
                    if boundWiki /= wikiSlug then
                        respondErr Submission.RejectWrongWikiSession

                    else if not (WikiContributors.isTrustedForWiki wikiSlug accountId model.contributors) then
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
                                                case Submission.rejectPendingSubmission rawReason sub of
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
                                                                recordAudit wikiSlug
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

        RequestSubmissionChanges wikiSlug submissionId rawGuidance ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respondErr : Submission.RequestChangesSubmissionError -> ( Model, Command BackendOnly ToFrontend Msg )
                respondErr err =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (RequestSubmissionChangesResponse wikiSlug submissionId (Err err))
                    )
            in
            case Dict.get sessionKey model.contributorSessions of
                Nothing ->
                    respondErr Submission.RequestChangesNotLoggedIn

                Just (WikiUser.Binding boundWiki accountId) ->
                    if boundWiki /= wikiSlug then
                        respondErr Submission.RequestChangesWrongWikiSession

                    else if not (WikiContributors.isTrustedForWiki wikiSlug accountId model.contributors) then
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
                                                case Submission.requestPendingSubmissionChanges rawGuidance sub of
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
                                                                recordAudit wikiSlug
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

        CreateHostedWiki rawSlug rawName ->
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
                case Submission.validatePageSlug rawSlug of
                    Err ve ->
                        respondErr (HostAdmin.CreateSlugInvalid ve)

                    Ok slug ->
                        case HostAdmin.validateHostedWikiName rawName of
                            Err ne ->
                                respondErr (HostAdmin.CreateWikiNameInvalid ne)

                            Ok name ->
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

                                        nextModel : Model
                                        nextModel =
                                            { model | wikis = Dict.insert slug wiki model.wikis }
                                    in
                                    ( nextModel
                                    , Effect.Lamdera.sendToFrontend clientId
                                        (CreateHostedWikiResponse (Ok (Wiki.catalogEntry wiki)))
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

        UpdateHostedWikiMetadata wikiSlug rawName rawSummary rawSlugDraft ->
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
                        case HostAdmin.validateHostedWikiName rawName of
                            Err ne ->
                                respondErr (HostAdmin.UpdateMetadataWikiNameInvalid ne)

                            Ok name ->
                                case HostAdmin.validateHostedWikiSummary rawSummary of
                                    Err se ->
                                        respondErr (HostAdmin.UpdateMetadataWikiSummaryInvalid se)

                                    Ok summaryText ->
                                        case HostAdmin.validateHostedWikiMetadataSlug wiki.slug rawSlugDraft of
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

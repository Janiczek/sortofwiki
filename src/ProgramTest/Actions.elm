module ProgramTest.Actions exposing
    ( createPage
    , loginToWiki
    , navigateToPath
    , navigateToWikiSubmitEdit
    , submitHostAdminLoginFormViaFormSubmit
    , submitWikiEditForm
    , submitWikiLoginForm
    , triggerFormSubmit
    )

{-| Reusable browser steps for program tests.

`loginToWiki` assumes the client opens on the wiki catalog (`/`).

`submitWikiLoginForm` assumes the login page is already showing (dispatches `submit` on `wiki-login-form`, same as Enter in the fields).

`submitHostAdminLoginFormViaFormSubmit` fills the password and submits `host-admin-login-form`.

`triggerFormSubmit` is for program-test only: primary actions use `type="submit"` without `onClick`, so tests must dispatch `submit` on the form element.

`createPage` navigates to new-page submit for the slug, fills markdown, submits, and asserts the rendered `h1`.

Trusted direct edit: `navigateToWikiSubmitEdit` then `submitWikiEditForm wikiSlug pageSlug markdown`. When you need assertions between navigation and the form (loaded draft), use those two separately.

-}

import Backend
import Effect.Browser.Dom
import Effect.Test
import Frontend
import Json.Encode
import ProgramTest.Model
import ProgramTest.Query
import Route
import Types exposing (FrontendMsg(..), ToBackend, ToFrontend)
import Url exposing (Protocol(..), Url)
import Wiki


programTestUrl : String -> Maybe String -> Url
programTestUrl path query =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = path
    , query = query
    , fragment = Nothing
    }


{-| Synthetic `submit` on a form by id (matches browser implicit submit / Enter in fields).
-}
triggerFormSubmit :
    String
    -> Effect.Test.FrontendActions ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model
    -> List (Effect.Test.Action ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
triggerFormSubmit formId client =
    [ client.custom 100 (Effect.Browser.Dom.id formId) "submit" (Json.Encode.object []) ]


{-| Simulate `UrlChanged` to a path (no query string), e.g. typing a URL or following a bookmark when no sidebar link exists.
-}
navigateToPath :
    String
    -> Effect.Test.FrontendActions ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model
    -> List (Effect.Test.Action ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
navigateToPath path client =
    [ client.update 100
        (UrlChanged (programTestUrl path Nothing))
    ]


{-| First ATX heading text (`# ...`) if present; otherwise `pageSlug`.
-}
markdownH1OrPageSlug : String -> String -> String
markdownH1OrPageSlug pageSlug markdownBody =
    case String.lines markdownBody |> List.head of
        Nothing ->
            pageSlug

        Just line ->
            let
                trimmed : String
                trimmed =
                    String.trim line
            in
            if String.startsWith "# " trimmed then
                String.dropLeft 2 trimmed |> String.trim

            else if String.startsWith "#" trimmed && String.length trimmed > 1 then
                String.dropLeft 1 trimmed |> String.trim

            else
                pageSlug


{-| Username, password, and submit on `wiki-login-page` (no navigation).
-}
submitWikiLoginForm :
    { username : String
    , password : String
    }
    -> Effect.Test.FrontendActions ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model
    -> List (Effect.Test.Action ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
submitWikiLoginForm creds client =
    List.concat
        [ [ client.input 100 (Effect.Browser.Dom.id "wiki-login-username") creds.username
          , client.input 100 (Effect.Browser.Dom.id "wiki-login-password") creds.password
          ]
        , triggerFormSubmit "wiki-login-form" client
        ]


{-| Password field filled; `HostAdminLoginSubmitted` via `host-admin-login-form` submit (Enter in password).
-}
submitHostAdminLoginFormViaFormSubmit :
    String
    -> Effect.Test.FrontendActions ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model
    -> List (Effect.Test.Action ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
submitHostAdminLoginFormViaFormSubmit password client =
    List.concat
        [ [ client.input 100 (Effect.Browser.Dom.id "host-admin-login-password") password
          ]
        , triggerFormSubmit "host-admin-login-form" client
        ]


loginToWikiFromCatalog :
    { wikiSlug : Wiki.Slug
    , username : String
    , password : String
    , wikiHomeToLoginHref : String
    }
    -> Effect.Test.FrontendActions ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model
    -> List (Effect.Test.Action ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
loginToWikiFromCatalog creds client =
    List.concat
        [ [ client.checkView 400
                (ProgramTest.Query.withinWikiCatalogRow creds.wikiSlug
                    (ProgramTest.Query.expectHasText (Wiki.wikiHomeUrlPath creds.wikiSlug))
                )
          , client.clickLink 100 (Wiki.wikiHomeUrlPath creds.wikiSlug)
          , client.checkView 400
                (ProgramTest.Query.expectWikiHomePageShowsSlug creds.wikiSlug)
          , client.clickLink 100 creds.wikiHomeToLoginHref
          , client.checkView 200
                (ProgramTest.Query.expectWikiLoginPageShowsSlug creds.wikiSlug)
          ]
        , submitWikiLoginForm { username = creds.username, password = creds.password } client
        ]


{-| From `/`, open the wiki home, follow "Log in", and submit credentials.
Does not assert post-login navigation; add a `checkView` after this list as needed.
-}
loginToWiki :
    { wikiSlug : Wiki.Slug
    , username : String
    , password : String
    }
    -> Effect.Test.FrontendActions ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model
    -> List (Effect.Test.Action ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
loginToWiki creds client =
    loginToWikiFromCatalog
        { wikiSlug = creds.wikiSlug
        , username = creds.username
        , password = creds.password
        , wikiHomeToLoginHref = Wiki.loginUrlPath creds.wikiSlug
        }
        client


{-| `UrlChanged` to the program-test wiki new-page form with suggested slug (`?page=`).
-}
navigateToWikiSubmitNew :
    Wiki.Slug
    -> String
    -> Effect.Test.FrontendActions ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model
    -> List (Effect.Test.Action ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
navigateToWikiSubmitNew wikiSlug pageSlug client =
    [ client.update 100
        (UrlChanged
            (programTestUrl (Wiki.submitNewPageUrlPath wikiSlug) (Just ("page=" ++ pageSlug)))
        )
    ]


{-| Fill markdown, submit, assert published heading in `page-markdown`.
-}
createPage :
    Wiki.Slug
    -> String
    -> String
    -> Effect.Test.FrontendActions ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model
    -> List (Effect.Test.Action ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
createPage wikiSlug pageSlug markdownBody client =
    List.concat
        [ navigateToWikiSubmitNew wikiSlug pageSlug client
        , [ client.input 100 (Effect.Browser.Dom.id "content-markdown-textarea") markdownBody
          ]
        , triggerFormSubmit "wiki-submit-new-form" client
        , [ client.checkView 300
                (ProgramTest.Query.withinPageMarkdownHeading "h1"
                    (ProgramTest.Query.expectHasText (markdownH1OrPageSlug pageSlug markdownBody))
                )
          ]
        ]


{-| `UrlChanged` to the wiki submit-edit route for a published page slug.
-}
navigateToWikiSubmitEdit :
    Wiki.Slug
    -> String
    -> Effect.Test.FrontendActions ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model
    -> List (Effect.Test.Action ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
navigateToWikiSubmitEdit wikiSlug pageSlug client =
    [ client.update 100
        (UrlChanged (programTestUrl (Wiki.submitEditUrlPath wikiSlug pageSlug) Nothing))
    ]


{-| Replace markdown in the submit-edit form, submit, assert trusted direct publish lands on the published page.
Assumes the submit-edit screen is already showing and the actor publishes immediately (trusted moderator).
-}
submitWikiEditForm :
    Wiki.Slug
    -> String
    -> String
    -> Effect.Test.FrontendActions ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model
    -> List (Effect.Test.Action ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
submitWikiEditForm wikiSlug pageSlug newMarkdown client =
    List.concat
        [ [ client.input 100 (Effect.Browser.Dom.id "wiki-submit-edit-markdown") newMarkdown
          ]
        , triggerFormSubmit "wiki-submit-edit-form" client
        , [ client.checkModel 300
                (ProgramTest.Model.expectRoute (Route.WikiPage wikiSlug pageSlug)
                    "expected redirect to published page after trusted direct edit"
                )
          , client.checkView 300
                (ProgramTest.Query.withinPageMarkdownHeading "h1"
                    (ProgramTest.Query.expectHasText (markdownH1OrPageSlug pageSlug newMarkdown))
                )
          ]
        ]

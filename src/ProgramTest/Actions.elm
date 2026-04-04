module ProgramTest.Actions exposing
    ( createPage
    , loginToWiki
    , navigateToPath
    , navigateToWikiSubmitEdit
    , submitWikiEditForm
    , submitWikiLoginForm
    )

{-| Reusable browser steps for program tests.

`loginToWiki` assumes the client opens on the wiki catalog (`/`).

`submitWikiLoginForm` assumes the login page is already showing.

`createPage` navigates to new-page submit for the slug, fills markdown, submits, and asserts the rendered `h1`.

`editPage` is `navigateToWikiSubmitEdit` followed by `submitWikiEditForm`. When you need assertions between navigation and the form (loaded draft), use those two separately.

-}

import Backend
import Effect.Browser.Dom
import Effect.Test
import Frontend
import ProgramTest.Query
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
    [ client.input 100 (Effect.Browser.Dom.id "wiki-login-username") creds.username
    , client.input 100 (Effect.Browser.Dom.id "wiki-login-password") creds.password
    , client.click 100 (Effect.Browser.Dom.id "wiki-login-submit")
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
          , client.click 100 (Effect.Browser.Dom.id "wiki-submit-new-submit")
          , client.checkView 300
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


{-| Replace markdown in the submit-edit form, publish, assert success banner.
Assumes the submit-edit screen is already showing.
-}
submitWikiEditForm :
    String
    -> Effect.Test.FrontendActions ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model
    -> List (Effect.Test.Action ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
submitWikiEditForm newMarkdown client =
    [ client.input 100 (Effect.Browser.Dom.id "wiki-submit-edit-markdown") newMarkdown
    , client.click 100 (Effect.Browser.Dom.id "wiki-submit-edit-submit")
    , client.checkView 300
        (ProgramTest.Query.withinId "wiki-submit-edit-success"
            (ProgramTest.Query.expectHasText "Published. Your edit is live.")
        )
    ]

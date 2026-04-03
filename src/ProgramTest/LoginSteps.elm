module ProgramTest.LoginSteps exposing (loginToWiki, submitWikiLoginForm)

{-| Reusable browser steps for program tests.

`loginToWiki` assumes the client opens on the wiki catalog (`/`).

`submitWikiLoginForm` assumes the login page is already showing.

-}

import Backend
import Effect.Browser.Dom
import Effect.Test
import Frontend
import ProgramTest.Query
import Types exposing (ToBackend, ToFrontend)
import Wiki


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

module BackendWikiTodosTest exposing (suite)

import Backend
import Dict
import Effect.Lamdera
import Expect
import ProgramTest.Config
import Test exposing (Test)
import Time
import Types exposing (ToBackend(..), ToFrontend(..))
import Wiki
import WikiTodos


sessionKey : String
sessionKey =
    "backend-wiki-todos-session"


clientKey : String
clientKey =
    "backend-wiki-todos-client"


clientId : Effect.Lamdera.ClientId
clientId =
    Effect.Lamdera.clientIdFromString clientKey


pagesFixture : Backend.Model
pagesFixture =
    ProgramTest.Config.replayInitStepsOntoModel ProgramTest.Config.demoWikiPagesSteps


expectedDemoRows : List WikiTodos.TableRow
expectedDemoRows =
    Dict.get "Demo" pagesFixture.wikis
        |> Maybe.map
            (\w ->
                WikiTodos.tableRows
                    "Demo"
                    (Wiki.frontendDetails w).publishedPageMarkdownSources
            )
        |> Maybe.withDefault []


suite : Test
suite =
    Test.describe "Backend wiki TODOs cache"
        [ Test.test "RequestWikiTodos populates cache and returns rows" <|
            \() ->
                let
                    ( after, cmd ) =
                        Backend.updateFromFrontendWithTime
                            (Effect.Lamdera.sessionIdFromString sessionKey)
                            clientId
                            (RequestWikiTodos "Demo")
                            (Time.millisToPosix 0)
                            pagesFixture
                in
                Expect.all
                    [ \_ ->
                        cmd
                            |> Expect.equal
                                (Effect.Lamdera.sendToFrontend
                                    clientId
                                    (WikiTodosResponse "Demo" (Ok expectedDemoRows))
                                )
                    , \_ ->
                        Dict.get "Demo" after.wikiTodosCaches
                            |> Expect.equal (Just expectedDemoRows)
                    ]
                    ()
        , Test.test "RequestWikiTodos returns Err for unknown wiki" <|
            \() ->
                let
                    ( _, cmd ) =
                        Backend.updateFromFrontendWithTime
                            (Effect.Lamdera.sessionIdFromString sessionKey)
                            clientId
                            (RequestWikiTodos "NoSuchWiki")
                            (Time.millisToPosix 0)
                            pagesFixture
                in
                cmd
                    |> Expect.equal
                        (Effect.Lamdera.sendToFrontend
                            clientId
                            (WikiTodosResponse "NoSuchWiki" (Err ()))
                        )
        ]

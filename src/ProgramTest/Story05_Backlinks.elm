module ProgramTest.Story05_Backlinks exposing (endToEndTests)

import Page
import ProgramTest.Actions
import ProgramTest.Config
import ProgramTest.Model
import ProgramTest.Query
import ProgramTest.Start
import Route
import Types exposing (FrontendMsg(..))
import Url exposing (Protocol(..), Url)
import Wiki


wikiSlug : Wiki.Slug
wikiSlug =
    "Demo"


targetPageSlug : Page.Slug
targetPageSlug =
    "Target"


linkerPageSlug : Page.Slug
linkerPageSlug =
    "Linker"


publishedTargetUrl : Url
publishedTargetUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = Wiki.publishedPageUrlPath wikiSlug targetPageSlug
    , query = Nothing
    , fragment = Nothing
    }


publishedLinkerUrl : Url
publishedLinkerUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = Wiki.publishedPageUrlPath wikiSlug linkerPageSlug
    , query = Nothing
    , fragment = Nothing
    }


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    ProgramTest.Start.bothViewports
        { baseName = "Backlinks: create, check existence, remove, check absence"
        , config = ProgramTest.Config.demoWikiCatalogOnly
        , sessionId = "session-story05-backlinks"
        , path = "/"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                List.concat
                    [ ProgramTest.Actions.loginToWiki
                        { wikiSlug = wikiSlug
                        , username = "demo_wiki_admin"
                        , password = "password12"
                        }
                        client
                    , [ client.checkView 400 (ProgramTest.Query.expectWikiHomePageShowsSlug wikiSlug)
                      ]
                    , ProgramTest.Actions.createPage wikiSlug targetPageSlug "# Target\n\nStandalone page." client
                    , ProgramTest.Actions.createPage wikiSlug linkerPageSlug "# Linker\n\nSee [[Target]] for more." client
                    , [ client.update 100 (UrlChanged publishedTargetUrl)
                      , client.checkView 300 (ProgramTest.Query.expectBacklinks wikiSlug [ linkerPageSlug ])
                      , client.update 100 (UrlChanged publishedLinkerUrl)
                      , client.checkView 800 (ProgramTest.Query.expectNoBacklinkFrom targetPageSlug)
                      ]
                    , ProgramTest.Actions.navigateToWikiSubmitEdit wikiSlug linkerPageSlug client
                    , [ client.checkModel 200
                            (ProgramTest.Model.expectRoute (Route.WikiSubmitEdit wikiSlug linkerPageSlug)
                                "expected submit-edit route for linker page after navigation"
                            )
                      , client.checkModel 3000
                            (\model ->
                                if String.contains "[[Target]]" model.pageEditSubmitDraft.markdownBody then
                                    Ok ()

                                else
                                    Err
                                        ("expected Linker edit draft to contain [[Target]], got length "
                                            ++ String.fromInt (String.length model.pageEditSubmitDraft.markdownBody)
                                        )
                            )
                      ]
                    , ProgramTest.Actions.submitWikiEditForm wikiSlug linkerPageSlug "# Linker\n\nNo wiki link here." client
                    , [ client.update 100 (UrlChanged publishedTargetUrl)
                      , client.checkView 800 (ProgramTest.Query.expectBacklinks wikiSlug [ linkerPageSlug ])
                      ]
                    ]
        }

module SideNavMenuTest exposing (suite)

import Expect
import Fuzz
import Fuzzers
import Route
import SideNavMenu
import Test exposing (Test)


suite : Test
suite =
    Test.describe "SideNavMenu"
        [ Test.describe "globalChromeSections"
            [ Test.test "anonymous user never sees host-admin management routes" <|
                \() ->
                    let
                        forbidden : List Route.Route
                        forbidden =
                            [ Route.HostAdminWikis
                            , Route.HostAdminWikiNew
                            , Route.HostAdminBackup
                            , Route.HostAdminAudit
                            ]

                        linkRoutes : List Route.Route
                        linkRoutes =
                            SideNavMenu.globalChromeSections
                                { hostAdminAuthenticated = False
                                , showHostAdminTools = True
                                }
                                |> SideNavMenu.allLinks
                                |> List.map .linkRoute

                        touchesForbidden : Route.Route -> Bool
                        touchesForbidden route =
                            List.member route forbidden
                    in
                    linkRoutes
                        |> List.any touchesForbidden
                        |> Expect.equal False
            , Test.fuzz (Fuzz.map2 Tuple.pair Fuzz.bool Fuzz.bool) "SortOfWiki nav always includes All wikis" <|
                \( hostAdminAuthenticated, showHostAdminTools ) ->
                    SideNavMenu.globalChromeSections
                        { hostAdminAuthenticated = hostAdminAuthenticated
                        , showHostAdminTools = showHostAdminTools
                        }
                        |> SideNavMenu.allLinks
                        |> List.map .linkRoute
                        |> List.member Route.WikiList
                        |> Expect.equal True
            ]
        , Test.describe "wikiNavLinks"
            [ Test.test "anonymous wiki nav includes public graph page" <|
                \() ->
                    SideNavMenu.wikiNavLinks "Demo" Nothing
                        |> List.map .linkRoute
                        |> List.member (Route.WikiGraph "Demo")
                        |> Expect.equal True
            , Test.test "anonymous wiki nav includes public TODOs page" <|
                \() ->
                    SideNavMenu.wikiNavLinks "Demo" Nothing
                        |> List.map .linkRoute
                        |> List.member (Route.WikiTodos "Demo")
                        |> Expect.equal True
            ]
        , Test.describe "sidebar link access"
            [ Test.fuzz
                (Fuzz.map2 Tuple.pair Fuzzers.navAccessContext Fuzz.bool)
                "global and wiki nav links pass Route.canAccess for the same context"
              <|
                \( ctx, showHostAdminTools ) ->
                    let
                        globalLinks : List SideNavMenu.Link
                        globalLinks =
                            SideNavMenu.globalChromeSections
                                { hostAdminAuthenticated = ctx.hostAdminAuthenticated
                                , showHostAdminTools = showHostAdminTools
                                }
                                |> SideNavMenu.allLinks

                        wikiLinks : List SideNavMenu.Link
                        wikiLinks =
                            SideNavMenu.wikiNavLinks ctx.activeWikiSlug ctx.contributorOnActiveWiki

                        allSidebarLinks : List SideNavMenu.Link
                        allSidebarLinks =
                            List.append globalLinks wikiLinks

                        linkIsAllowed : SideNavMenu.Link -> Bool
                        linkIsAllowed link =
                            Route.canAccess ctx link.linkRoute
                    in
                    allSidebarLinks
                        |> List.all linkIsAllowed
                        |> Expect.equal True
            ]
        ]

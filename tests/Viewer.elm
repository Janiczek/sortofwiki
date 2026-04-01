module Viewer exposing (main)

import Effect.Test
import Story.Story01_WikiList as Story01
import Story.Story35_NotFound as Story35
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)


main :
    Program
        ()
        (Effect.Test.Model ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
        (Effect.Test.Msg ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
main =
    [ Story01.endToEndTests
    , Story35.endToEndTests
    ]
        |> List.concat
        |> Effect.Test.viewer

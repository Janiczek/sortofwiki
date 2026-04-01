module ProgramTest.Viewer exposing (main)

import Backend
import Effect.Test
import Frontend
import ProgramTest.Story01_WikiList as Story01
import ProgramTest.Story02_WikiHome as Story02
import ProgramTest.Story35_NotFound as Story35
import Types exposing (ToBackend, ToFrontend)


main :
    Program
        ()
        (Effect.Test.Model ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
        (Effect.Test.Msg ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
main =
    [ Story01.endToEndTests
    , Story02.endToEndTests
    , Story35.endToEndTests
    ]
        |> List.concat
        |> Effect.Test.viewer

module ProgramTest.Model exposing (expectRoute)

import Frontend
import Route


{-| Assert the frontend resolved route; `errorMessage` is returned when it differs.
-}
expectRoute : Route.Route -> String -> Frontend.Model -> Result String ()
expectRoute expectedRoute errorMessage model =
    if model.route == expectedRoute then
        Ok ()

    else
        Err errorMessage

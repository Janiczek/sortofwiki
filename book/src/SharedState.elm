module SharedState exposing (SharedState, initialState)


type alias SharedState =
    { chip1 : Bool
    , chip2 : Bool
    , chip3 : Bool
    }


initialState : SharedState
initialState =
    { chip1 = False
    , chip2 = True
    , chip3 = False
    }

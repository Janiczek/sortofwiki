module Evergreen.V25.WikiFrontendSubscription exposing (..)

import Dict
import Evergreen.V25.Wiki
import Set


type alias WikiFrontendListeners =
    { sessions : Dict.Dict String (Set.Set String)
    }


type alias WikiFrontendClientSets =
    Dict.Dict Evergreen.V25.Wiki.Slug WikiFrontendListeners

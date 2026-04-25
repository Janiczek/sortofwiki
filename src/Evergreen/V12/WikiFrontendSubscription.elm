module Evergreen.V12.WikiFrontendSubscription exposing (..)

import Dict
import Evergreen.V12.Wiki
import Set


type alias WikiFrontendListeners =
    { sessions : Dict.Dict String (Set.Set String)
    }


type alias WikiFrontendClientSets =
    Dict.Dict Evergreen.V12.Wiki.Slug WikiFrontendListeners

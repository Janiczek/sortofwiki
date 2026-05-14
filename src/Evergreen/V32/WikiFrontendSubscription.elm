module Evergreen.V32.WikiFrontendSubscription exposing (..)

import Dict
import Evergreen.V32.Wiki
import Set


type alias WikiFrontendListeners =
    { sessions : Dict.Dict String (Set.Set String)
    }


type alias WikiFrontendClientSets =
    Dict.Dict Evergreen.V32.Wiki.Slug WikiFrontendListeners

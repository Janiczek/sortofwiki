module Evergreen.V17.WikiFrontendSubscription exposing (..)

import Dict
import Evergreen.V17.Wiki
import Set


type alias WikiFrontendListeners =
    { sessions : Dict.Dict String (Set.Set String)
    }


type alias WikiFrontendClientSets =
    Dict.Dict Evergreen.V17.Wiki.Slug WikiFrontendListeners

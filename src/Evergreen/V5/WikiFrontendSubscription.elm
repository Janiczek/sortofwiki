module Evergreen.V5.WikiFrontendSubscription exposing (..)

import Dict
import Evergreen.V5.Wiki
import Set


type alias WikiFrontendListeners =
    { sessions : Dict.Dict String (Set.Set String)
    }


type alias WikiFrontendClientSets =
    Dict.Dict Evergreen.V5.Wiki.Slug WikiFrontendListeners

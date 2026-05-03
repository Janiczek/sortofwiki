module Evergreen.V28.WikiFrontendSubscription exposing (..)

import Dict
import Evergreen.V28.Wiki
import Set


type alias WikiFrontendListeners =
    { sessions : Dict.Dict String (Set.Set String)
    }


type alias WikiFrontendClientSets =
    Dict.Dict Evergreen.V28.Wiki.Slug WikiFrontendListeners

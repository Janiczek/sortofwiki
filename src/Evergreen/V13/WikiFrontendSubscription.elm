module Evergreen.V13.WikiFrontendSubscription exposing (..)

import Dict
import Evergreen.V13.Wiki
import Set


type alias WikiFrontendListeners =
    { sessions : Dict.Dict String (Set.Set String)
    }


type alias WikiFrontendClientSets =
    Dict.Dict Evergreen.V13.Wiki.Slug WikiFrontendListeners

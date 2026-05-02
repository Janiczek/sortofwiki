module Evergreen.V20.WikiFrontendSubscription exposing (..)

import Dict
import Evergreen.V20.Wiki
import Set


type alias WikiFrontendListeners =
    { sessions : Dict.Dict String (Set.Set String)
    }


type alias WikiFrontendClientSets =
    Dict.Dict Evergreen.V20.Wiki.Slug WikiFrontendListeners

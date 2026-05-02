module Evergreen.V26.WikiFrontendSubscription exposing (..)

import Dict
import Evergreen.V26.Wiki
import Set


type alias WikiFrontendListeners =
    { sessions : Dict.Dict String (Set.Set String)
    }


type alias WikiFrontendClientSets =
    Dict.Dict Evergreen.V26.Wiki.Slug WikiFrontendListeners

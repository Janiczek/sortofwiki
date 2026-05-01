module Evergreen.V16.WikiFrontendSubscription exposing (..)

import Dict
import Evergreen.V16.Wiki
import Set


type alias WikiFrontendListeners =
    { sessions : Dict.Dict String (Set.Set String)
    }


type alias WikiFrontendClientSets =
    Dict.Dict Evergreen.V16.Wiki.Slug WikiFrontendListeners

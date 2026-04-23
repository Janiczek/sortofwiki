module Evergreen.V11.WikiFrontendSubscription exposing (..)

import Dict
import Evergreen.V11.Wiki
import Set


type alias WikiFrontendListeners =
    { sessions : Dict.Dict String (Set.Set String)
    }


type alias WikiFrontendClientSets =
    Dict.Dict Evergreen.V11.Wiki.Slug WikiFrontendListeners

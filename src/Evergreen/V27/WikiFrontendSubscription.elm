module Evergreen.V27.WikiFrontendSubscription exposing (..)

import Dict
import Evergreen.V27.Wiki
import Set


type alias WikiFrontendListeners =
    { sessions : Dict.Dict String (Set.Set String)
    }


type alias WikiFrontendClientSets =
    Dict.Dict Evergreen.V27.Wiki.Slug WikiFrontendListeners

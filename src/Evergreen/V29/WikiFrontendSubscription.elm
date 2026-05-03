module Evergreen.V29.WikiFrontendSubscription exposing (..)

import Dict
import Evergreen.V29.Wiki
import Set


type alias WikiFrontendListeners =
    { sessions : Dict.Dict String (Set.Set String)
    }


type alias WikiFrontendClientSets =
    Dict.Dict Evergreen.V29.Wiki.Slug WikiFrontendListeners

module Evergreen.V14.WikiFrontendSubscription exposing (..)

import Dict
import Evergreen.V14.Wiki
import Set


type alias WikiFrontendListeners =
    { sessions : Dict.Dict String (Set.Set String)
    }


type alias WikiFrontendClientSets =
    Dict.Dict Evergreen.V14.Wiki.Slug WikiFrontendListeners

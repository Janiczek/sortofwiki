module Evergreen.V32.PendingReviewCount exposing (..)

import Dict
import Evergreen.V32.Wiki
import Set


type alias WikiPendingListeners =
    { trustedSessions : Dict.Dict String (Set.Set String)
    }


type alias PendingReviewClientSets =
    Dict.Dict Evergreen.V32.Wiki.Slug WikiPendingListeners

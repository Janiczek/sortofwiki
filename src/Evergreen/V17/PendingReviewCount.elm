module Evergreen.V17.PendingReviewCount exposing (..)

import Dict
import Evergreen.V17.Wiki
import Set


type alias WikiPendingListeners =
    { trustedSessions : Dict.Dict String (Set.Set String)
    }


type alias PendingReviewClientSets =
    Dict.Dict Evergreen.V17.Wiki.Slug WikiPendingListeners

module Evergreen.V25.PendingReviewCount exposing (..)

import Dict
import Evergreen.V25.Wiki
import Set


type alias WikiPendingListeners =
    { trustedSessions : Dict.Dict String (Set.Set String)
    }


type alias PendingReviewClientSets =
    Dict.Dict Evergreen.V25.Wiki.Slug WikiPendingListeners

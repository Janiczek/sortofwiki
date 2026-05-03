module Evergreen.V28.PendingReviewCount exposing (..)

import Dict
import Evergreen.V28.Wiki
import Set


type alias WikiPendingListeners =
    { trustedSessions : Dict.Dict String (Set.Set String)
    }


type alias PendingReviewClientSets =
    Dict.Dict Evergreen.V28.Wiki.Slug WikiPendingListeners

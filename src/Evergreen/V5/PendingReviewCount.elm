module Evergreen.V5.PendingReviewCount exposing (..)

import Dict
import Evergreen.V5.Wiki
import Set


type alias WikiPendingListeners =
    { trustedSessions : Dict.Dict String (Set.Set String)
    }


type alias PendingReviewClientSets =
    Dict.Dict Evergreen.V5.Wiki.Slug WikiPendingListeners

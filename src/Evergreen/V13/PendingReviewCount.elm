module Evergreen.V13.PendingReviewCount exposing (..)

import Dict
import Evergreen.V13.Wiki
import Set


type alias WikiPendingListeners =
    { trustedSessions : Dict.Dict String (Set.Set String)
    }


type alias PendingReviewClientSets =
    Dict.Dict Evergreen.V13.Wiki.Slug WikiPendingListeners

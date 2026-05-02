module Evergreen.V20.PendingReviewCount exposing (..)

import Dict
import Evergreen.V20.Wiki
import Set


type alias WikiPendingListeners =
    { trustedSessions : Dict.Dict String (Set.Set String)
    }


type alias PendingReviewClientSets =
    Dict.Dict Evergreen.V20.Wiki.Slug WikiPendingListeners

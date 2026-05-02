module Evergreen.V26.PendingReviewCount exposing (..)

import Dict
import Evergreen.V26.Wiki
import Set


type alias WikiPendingListeners =
    { trustedSessions : Dict.Dict String (Set.Set String)
    }


type alias PendingReviewClientSets =
    Dict.Dict Evergreen.V26.Wiki.Slug WikiPendingListeners

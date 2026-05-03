module Evergreen.V29.PendingReviewCount exposing (..)

import Dict
import Evergreen.V29.Wiki
import Set


type alias WikiPendingListeners =
    { trustedSessions : Dict.Dict String (Set.Set String)
    }


type alias PendingReviewClientSets =
    Dict.Dict Evergreen.V29.Wiki.Slug WikiPendingListeners

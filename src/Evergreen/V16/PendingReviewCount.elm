module Evergreen.V16.PendingReviewCount exposing (..)

import Dict
import Evergreen.V16.Wiki
import Set


type alias WikiPendingListeners =
    { trustedSessions : Dict.Dict String (Set.Set String)
    }


type alias PendingReviewClientSets =
    Dict.Dict Evergreen.V16.Wiki.Slug WikiPendingListeners

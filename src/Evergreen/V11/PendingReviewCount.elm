module Evergreen.V11.PendingReviewCount exposing (..)

import Dict
import Evergreen.V11.Wiki
import Set


type alias WikiPendingListeners =
    { trustedSessions : Dict.Dict String (Set.Set String)
    }


type alias PendingReviewClientSets =
    Dict.Dict Evergreen.V11.Wiki.Slug WikiPendingListeners

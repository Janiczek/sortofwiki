module Evergreen.V12.PendingReviewCount exposing (..)

import Dict
import Evergreen.V12.Wiki
import Set


type alias WikiPendingListeners =
    { trustedSessions : Dict.Dict String (Set.Set String)
    }


type alias PendingReviewClientSets =
    Dict.Dict Evergreen.V12.Wiki.Slug WikiPendingListeners

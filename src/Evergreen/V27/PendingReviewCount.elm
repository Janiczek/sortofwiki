module Evergreen.V27.PendingReviewCount exposing (..)

import Dict
import Evergreen.V27.Wiki
import Set


type alias WikiPendingListeners =
    { trustedSessions : Dict.Dict String (Set.Set String)
    }


type alias PendingReviewClientSets =
    Dict.Dict Evergreen.V27.Wiki.Slug WikiPendingListeners

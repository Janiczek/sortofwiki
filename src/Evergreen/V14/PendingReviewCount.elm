module Evergreen.V14.PendingReviewCount exposing (..)

import Dict
import Evergreen.V14.Wiki
import Set


type alias WikiPendingListeners =
    { trustedSessions : Dict.Dict String (Set.Set String)
    }


type alias PendingReviewClientSets =
    Dict.Dict Evergreen.V14.Wiki.Slug WikiPendingListeners

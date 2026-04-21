module Evergreen.V3.WikiUser exposing (..)

import Dict
import Evergreen.V3.ContributorAccount
import Evergreen.V3.Wiki


type alias WikiBindings =
    Dict.Dict Evergreen.V3.Wiki.Slug Evergreen.V3.ContributorAccount.Id


type alias SessionTable =
    Dict.Dict String WikiBindings

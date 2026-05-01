module Evergreen.V17.WikiUser exposing (..)

import Dict
import Evergreen.V17.ContributorAccount
import Evergreen.V17.Wiki


type alias WikiBindings =
    Dict.Dict Evergreen.V17.Wiki.Slug Evergreen.V17.ContributorAccount.Id


type alias SessionTable =
    Dict.Dict String WikiBindings

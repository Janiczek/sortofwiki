module Evergreen.V32.WikiUser exposing (..)

import Dict
import Evergreen.V32.ContributorAccount
import Evergreen.V32.Wiki


type alias WikiBindings =
    Dict.Dict Evergreen.V32.Wiki.Slug Evergreen.V32.ContributorAccount.Id


type alias SessionTable =
    Dict.Dict String WikiBindings

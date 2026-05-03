module Evergreen.V28.WikiUser exposing (..)

import Dict
import Evergreen.V28.ContributorAccount
import Evergreen.V28.Wiki


type alias WikiBindings =
    Dict.Dict Evergreen.V28.Wiki.Slug Evergreen.V28.ContributorAccount.Id


type alias SessionTable =
    Dict.Dict String WikiBindings

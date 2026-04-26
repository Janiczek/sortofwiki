module Evergreen.V13.WikiUser exposing (..)

import Dict
import Evergreen.V13.ContributorAccount
import Evergreen.V13.Wiki


type alias WikiBindings =
    Dict.Dict Evergreen.V13.Wiki.Slug Evergreen.V13.ContributorAccount.Id


type alias SessionTable =
    Dict.Dict String WikiBindings

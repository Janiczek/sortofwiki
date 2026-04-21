module Evergreen.V1.WikiUser exposing (..)

import Dict
import Evergreen.V1.ContributorAccount
import Evergreen.V1.Wiki


type alias WikiBindings =
    Dict.Dict Evergreen.V1.Wiki.Slug Evergreen.V1.ContributorAccount.Id


type alias SessionTable =
    Dict.Dict String WikiBindings

module Evergreen.V5.WikiUser exposing (..)

import Dict
import Evergreen.V5.ContributorAccount
import Evergreen.V5.Wiki


type alias WikiBindings =
    Dict.Dict Evergreen.V5.Wiki.Slug Evergreen.V5.ContributorAccount.Id


type alias SessionTable =
    Dict.Dict String WikiBindings

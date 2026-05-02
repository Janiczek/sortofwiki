module Evergreen.V25.WikiUser exposing (..)

import Dict
import Evergreen.V25.ContributorAccount
import Evergreen.V25.Wiki


type alias WikiBindings =
    Dict.Dict Evergreen.V25.Wiki.Slug Evergreen.V25.ContributorAccount.Id


type alias SessionTable =
    Dict.Dict String WikiBindings

module Evergreen.V2.WikiUser exposing (..)

import Dict
import Evergreen.V2.ContributorAccount
import Evergreen.V2.Wiki


type alias WikiBindings =
    Dict.Dict Evergreen.V2.Wiki.Slug Evergreen.V2.ContributorAccount.Id


type alias SessionTable =
    Dict.Dict String WikiBindings

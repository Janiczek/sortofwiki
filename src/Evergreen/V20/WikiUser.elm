module Evergreen.V20.WikiUser exposing (..)

import Dict
import Evergreen.V20.ContributorAccount
import Evergreen.V20.Wiki


type alias WikiBindings =
    Dict.Dict Evergreen.V20.Wiki.Slug Evergreen.V20.ContributorAccount.Id


type alias SessionTable =
    Dict.Dict String WikiBindings

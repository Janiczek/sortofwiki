module Evergreen.V11.WikiUser exposing (..)

import Dict
import Evergreen.V11.ContributorAccount
import Evergreen.V11.Wiki


type alias WikiBindings =
    Dict.Dict Evergreen.V11.Wiki.Slug Evergreen.V11.ContributorAccount.Id


type alias SessionTable =
    Dict.Dict String WikiBindings

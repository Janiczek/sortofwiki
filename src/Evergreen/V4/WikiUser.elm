module Evergreen.V4.WikiUser exposing (..)

import Dict
import Evergreen.V4.ContributorAccount
import Evergreen.V4.Wiki


type alias WikiBindings =
    Dict.Dict Evergreen.V4.Wiki.Slug Evergreen.V4.ContributorAccount.Id


type alias SessionTable =
    Dict.Dict String WikiBindings

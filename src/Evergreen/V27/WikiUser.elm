module Evergreen.V27.WikiUser exposing (..)

import Dict
import Evergreen.V27.ContributorAccount
import Evergreen.V27.Wiki


type alias WikiBindings =
    Dict.Dict Evergreen.V27.Wiki.Slug Evergreen.V27.ContributorAccount.Id


type alias SessionTable =
    Dict.Dict String WikiBindings

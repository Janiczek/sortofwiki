module Evergreen.V29.WikiUser exposing (..)

import Dict
import Evergreen.V29.ContributorAccount
import Evergreen.V29.Wiki


type alias WikiBindings =
    Dict.Dict Evergreen.V29.Wiki.Slug Evergreen.V29.ContributorAccount.Id


type alias SessionTable =
    Dict.Dict String WikiBindings

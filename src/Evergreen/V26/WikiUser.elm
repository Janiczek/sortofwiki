module Evergreen.V26.WikiUser exposing (..)

import Dict
import Evergreen.V26.ContributorAccount
import Evergreen.V26.Wiki


type alias WikiBindings =
    Dict.Dict Evergreen.V26.Wiki.Slug Evergreen.V26.ContributorAccount.Id


type alias SessionTable =
    Dict.Dict String WikiBindings

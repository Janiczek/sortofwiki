module Evergreen.V12.WikiUser exposing (..)

import Dict
import Evergreen.V12.ContributorAccount
import Evergreen.V12.Wiki


type alias WikiBindings =
    Dict.Dict Evergreen.V12.Wiki.Slug Evergreen.V12.ContributorAccount.Id


type alias SessionTable =
    Dict.Dict String WikiBindings

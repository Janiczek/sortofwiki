module Evergreen.V16.WikiUser exposing (..)

import Dict
import Evergreen.V16.ContributorAccount
import Evergreen.V16.Wiki


type alias WikiBindings =
    Dict.Dict Evergreen.V16.Wiki.Slug Evergreen.V16.ContributorAccount.Id


type alias SessionTable =
    Dict.Dict String WikiBindings

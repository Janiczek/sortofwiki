module Evergreen.V14.WikiUser exposing (..)

import Dict
import Evergreen.V14.ContributorAccount
import Evergreen.V14.Wiki


type alias WikiBindings =
    Dict.Dict Evergreen.V14.Wiki.Slug Evergreen.V14.ContributorAccount.Id


type alias SessionTable =
    Dict.Dict String WikiBindings

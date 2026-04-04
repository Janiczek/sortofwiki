module ContributorWikiSession exposing (ContributorWikiSession)

import WikiRole


{-| Frontend mirror of one wiki login (role + display name). Wiki slug is the `Dict` key in the model.
-}
type alias ContributorWikiSession =
    { role : WikiRole.WikiRole
    , displayUsername : String
    }

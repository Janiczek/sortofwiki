module Evergreen.V27.WikiRole exposing (..)


type SubmissionsScope
    = SubmissionsScope


type alias UntrustedContributorCaps =
    { submissions : SubmissionsScope
    }


type WikiRole
    = UntrustedContributor UntrustedContributorCaps
    | TrustedContributor
    | Admin

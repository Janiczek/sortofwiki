module Env exposing (dummyConfigItem, hostAdminPassword)

-- The Env.elm file is for per-environment configuration.
-- See https://dashboard.lamdera.app/docs/environment for more info.


dummyConfigItem : String
dummyConfigItem =
    ""


{-| Password for platform host admin (`/admin`).

**Production:** set the corresponding value in the Lamdera project environment so this is not the dev default.

**Development and automated tests:** this string is the fallback; program tests import `Env.hostAdminPassword` so they stay aligned with the backend.

-}
hostAdminPassword : String
hostAdminPassword =
    "sortofwiki-dev-host-admin-password"

module ContributorAccount exposing
    ( Id
    , LoginContributorError(..)
    , RegisterContributorError(..)
    , Verifier
    , idToString
    , loginErrorToUserText
    , newAccountId
    , normalizeUsername
    , registerErrorToUserText
    , validateLoginFields
    , validateRegistrationFields
    , verifierFromPassword
    , verifierMatchesPassword
    )

import SHA256
import Wiki


{-| Stable account id for a wiki + normalized username (MVP).
-}
type Id
    = Id String


idToString : Id -> String
idToString (Id s) =
    s


newAccountId : Wiki.Slug -> String -> Id
newAccountId wikiSlug normalizedUsername =
    Id ("acc:" ++ wikiSlug ++ ":" ++ normalizedUsername)


type Verifier
    = Verifier String


verifierFromPassword : String -> Verifier
verifierFromPassword password =
    password
        |> SHA256.fromString
        |> SHA256.toHex
        |> Verifier


verifierMatchesPassword : String -> Verifier -> Bool
verifierMatchesPassword password (Verifier storedHex) =
    case verifierFromPassword password of
        Verifier hex ->
            hex == storedHex


type LoginContributorError
    = LoginWikiNotFound
    | LoginInvalidCredentials
    | LoginUsernameEmpty
    | LoginPasswordEmpty


loginErrorToUserText : LoginContributorError -> String
loginErrorToUserText err =
    case err of
        LoginWikiNotFound ->
            "This wiki does not exist."

        LoginInvalidCredentials ->
            "Invalid username or password."

        LoginUsernameEmpty ->
            "Enter a username."

        LoginPasswordEmpty ->
            "Enter a password."


type RegisterContributorError
    = RegisterWikiNotFound
    | RegisterUsernameTaken
    | RegisterUsernameEmpty
    | RegisterUsernameTooShort
    | RegisterUsernameTooLong
    | RegisterUsernameInvalidChars
    | RegisterPasswordTooShort


registerErrorToUserText : RegisterContributorError -> String
registerErrorToUserText err =
    case err of
        RegisterWikiNotFound ->
            "This wiki does not exist."

        RegisterUsernameTaken ->
            "That username is already taken."

        RegisterUsernameEmpty ->
            "Enter a username."

        RegisterUsernameTooShort ->
            "Username must be at least 3 characters."

        RegisterUsernameTooLong ->
            "Username must be at most 32 characters."

        RegisterUsernameInvalidChars ->
            "Username may only use letters, digits, underscores, and hyphens."

        RegisterPasswordTooShort ->
            "Password must be at least 8 characters."


usernameRestCharOk : Char -> Bool
usernameRestCharOk c =
    Char.isAlphaNum c || c == '_' || c == '-'


{-| First character letter or digit; rest letters, digits, `_`, or `-`.
-}
usernameCharsOk : String -> Bool
usernameCharsOk s =
    case String.uncons s of
        Nothing ->
            False

        Just ( first, rest ) ->
            Char.isAlphaNum first && String.all usernameRestCharOk rest


{-| Lowercase trim for lookups.
-}
normalizeUsername : String -> String
normalizeUsername raw =
    raw
        |> String.trim
        |> String.toLower


{-| First validation error wins (MVP).
-}
validateRegistrationFields : String -> String -> Result RegisterContributorError { normalizedUsername : String, password : String }
validateRegistrationFields rawUsername password =
    let
        normalized : String
        normalized =
            normalizeUsername rawUsername
    in
    if String.isEmpty normalized then
        Err RegisterUsernameEmpty

    else if String.length normalized < 3 then
        Err RegisterUsernameTooShort

    else if String.length normalized > 32 then
        Err RegisterUsernameTooLong

    else if not (usernameCharsOk normalized) then
        Err RegisterUsernameInvalidChars

    else if String.length password < 8 then
        Err RegisterPasswordTooShort

    else
        Ok { normalizedUsername = normalized, password = password }


{-| Minimal checks before a login request (MVP).
-}
validateLoginFields : String -> String -> Result LoginContributorError { normalizedUsername : String, password : String }
validateLoginFields rawUsername password =
    let
        normalized : String
        normalized =
            normalizeUsername rawUsername
    in
    if String.isEmpty normalized then
        Err LoginUsernameEmpty

    else if String.isEmpty password then
        Err LoginPasswordEmpty

    else
        Ok { normalizedUsername = normalized, password = password }

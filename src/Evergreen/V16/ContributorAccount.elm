module Evergreen.V16.ContributorAccount exposing (..)


type RegisterContributorError
    = RegisterWikiNotFound
    | RegisterWikiInactive
    | RegisterUsernameTaken
    | RegisterUsernameEmpty
    | RegisterUsernameTooShort
    | RegisterUsernameTooLong
    | RegisterUsernameInvalidChars
    | RegisterPasswordEmpty


type LoginContributorError
    = LoginWikiNotFound
    | LoginWikiInactive
    | LoginInvalidCredentials
    | LoginUsernameEmpty
    | LoginPasswordEmpty


type Id
    = Id String


type Verifier
    = Verifier String

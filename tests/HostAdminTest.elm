module HostAdminTest exposing (suite)

import Expect
import Fuzz
import HostAdmin
import Submission
import Test exposing (Test)


suite : Test
suite =
    Test.describe "HostAdmin"
        [ Test.describe "loginErrorToUserText"
            [ Test.test "WrongPassword" <|
                \() ->
                    HostAdmin.WrongPassword
                        |> HostAdmin.loginErrorToUserText
                        |> Expect.equal "Invalid password."
            ]
        , Test.describe "protectedErrorToUserText"
            [ Test.test "NotHostAuthenticated" <|
                \() ->
                    HostAdmin.NotHostAuthenticated
                        |> HostAdmin.protectedErrorToUserText
                        |> Expect.equal "Host admin sign-in required."
            ]
        , Test.describe "validateHostedWikiName"
            [ Test.test "trims and accepts" <|
                \() ->
                    HostAdmin.validateHostedWikiName "  My Wiki  "
                        |> Expect.equal (Ok "My Wiki")
            , Test.test "rejects empty" <|
                \() ->
                    HostAdmin.validateHostedWikiName "   "
                        |> Expect.equal (Err HostAdmin.WikiNameEmpty)
            , Test.test "rejects too long" <|
                \() ->
                    HostAdmin.validateHostedWikiName (String.repeat (HostAdmin.wikiNameMaxLength + 1) "a")
                        |> Expect.equal (Err HostAdmin.WikiNameTooLong)
            , Test.fuzz Fuzz.string "trim-empty iff WikiNameEmpty" <|
                \s ->
                    if String.isEmpty (String.trim s) then
                        HostAdmin.validateHostedWikiName s
                            |> Expect.equal (Err HostAdmin.WikiNameEmpty)

                    else if String.length (String.trim s) > HostAdmin.wikiNameMaxLength then
                        HostAdmin.validateHostedWikiName s
                            |> Expect.equal (Err HostAdmin.WikiNameTooLong)

                    else
                        HostAdmin.validateHostedWikiName s
                            |> Expect.equal (Ok (String.trim s))
            ]
        , Test.describe "createHostedWikiErrorToUserText"
            [ Test.test "CreateWikiSlugTaken" <|
                \() ->
                    HostAdmin.CreateWikiSlugTaken
                        |> HostAdmin.createHostedWikiErrorToUserText
                        |> Expect.equal "A wiki with this slug already exists."
            , Test.test "CreateSlugInvalid uses wiki wording" <|
                \() ->
                    HostAdmin.CreateSlugInvalid Submission.SlugEmpty
                        |> HostAdmin.createHostedWikiErrorToUserText
                        |> Expect.equal "Enter a wiki slug."
            ]
        , Test.describe "validateHostedWikiSummary"
            [ Test.test "trims" <|
                \() ->
                    HostAdmin.validateHostedWikiSummary "  hi  "
                        |> Expect.equal (Ok "hi")
            , Test.test "empty ok" <|
                \() ->
                    HostAdmin.validateHostedWikiSummary "   "
                        |> Expect.equal (Ok "")
            , Test.test "too long" <|
                \() ->
                    HostAdmin.validateHostedWikiSummary (String.repeat (HostAdmin.wikiSummaryMaxLength + 1) "x")
                        |> Expect.equal (Err HostAdmin.WikiSummaryTooLong)
            ]
        , Test.describe "updateHostedWikiMetadataErrorToUserText"
            [ Test.test "UpdateMetadataWikiSummaryInvalid" <|
                \() ->
                    HostAdmin.updateHostedWikiMetadataErrorToUserText
                        (HostAdmin.UpdateMetadataWikiSummaryInvalid HostAdmin.WikiSummaryTooLong)
                        |> String.contains (String.fromInt HostAdmin.wikiSummaryMaxLength)
                        |> Expect.equal True
            ]
        , Test.describe "wikiLifecycleErrorToUserText"
            [ Test.test "WikiLifecycleWikiNotFound" <|
                \() ->
                    HostAdmin.WikiLifecycleWikiNotFound
                        |> HostAdmin.wikiLifecycleErrorToUserText
                        |> Expect.equal "That wiki was not found."
            , Test.test "WikiLifecycleNotHostAuthenticated matches protected" <|
                \() ->
                    HostAdmin.WikiLifecycleNotHostAuthenticated
                        |> HostAdmin.wikiLifecycleErrorToUserText
                        |> Expect.equal (HostAdmin.protectedErrorToUserText HostAdmin.NotHostAuthenticated)
            ]
        , Test.describe "deleteHostedWikiConfirmationMatches"
            [ Test.test "accepts exact slug" <|
                \() ->
                    HostAdmin.deleteHostedWikiConfirmationMatches "acme" "acme"
                        |> Expect.equal True
            , Test.test "accepts slug with surrounding whitespace" <|
                \() ->
                    HostAdmin.deleteHostedWikiConfirmationMatches "acme" "  acme  "
                        |> Expect.equal True
            , Test.test "accepts DELETE" <|
                \() ->
                    HostAdmin.deleteHostedWikiConfirmationMatches "acme" "DELETE"
                        |> Expect.equal True
            , Test.test "rejects wrong phrase" <|
                \() ->
                    HostAdmin.deleteHostedWikiConfirmationMatches "acme" "acm"
                        |> Expect.equal False
            ]
        , Test.describe "deleteHostedWikiErrorToUserText"
            [ Test.test "ConfirmationMismatch" <|
                \() ->
                    HostAdmin.DeleteHostedWikiConfirmationMismatch
                        |> HostAdmin.deleteHostedWikiErrorToUserText
                        |> Expect.equal "Confirmation must match the wiki slug or the word DELETE."
            , Test.test "DeleteHostedWikiNotHostAuthenticated matches protected" <|
                \() ->
                    HostAdmin.DeleteHostedWikiNotHostAuthenticated
                        |> HostAdmin.deleteHostedWikiErrorToUserText
                        |> Expect.equal (HostAdmin.protectedErrorToUserText HostAdmin.NotHostAuthenticated)
            ]
        ]

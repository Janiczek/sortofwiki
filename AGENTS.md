For compiling and using the package manager, use `lamdera` instead of `elm`.

For testing the Elm codebase, use `elm-test --compiler=lamdera`.
Do not nest another module’s `suite` inside one module's `suite`; keep domain/unit suites in their own modules.

You can test things yourself by running a local Lamdera development server via `lamdera live` and opening http://localhost:8000/ in the browser.
Even better, if an end-to-end test fails (tests/Story/*), you can open the dev server and open http://localhost:8000/src/ProgramTest/Viewer.elm, select the test and then you can click on the timeline to see how it looked at various steps, show the model, rightclick to diff the models, etc.

Use `github.com/lamdera/program-test` for end-to-end unit tests. See `src/ProgramTest/Viewer.elm`, `src/ProgramTest/Story*.elm` and `tests/Story/*.elm` for such. This forces use of these modules instead of their non-`Effect.*` variants:
- Effect.Browser.Dom
- Effect.Browser.Events
- Effect.Browser.Navigation
- Effect.File
- Effect.File.Download
- Effect.File.Select
- Effect.Http
- Effect.Lamdera
- Effect.Process
- Effect.Task
- Effect.Time

All implemented user stories must have a program test (end-to-end unit test) present (numbered like in `spec/user-stories.md`.) When an user story is implemented, its checkbox must be checked in `spec/user-stories.md`.

Domain types must live in their own modules together with their helper functions, not in `Types.elm`. Foo.barIsBaz, Foo.barFromString, Foo.barDecoder are an antipattern, and Bar (or Foo.Bar) should have its own module.

All domain types need to be both unit-tested (showing examples of usage) and PBT-tested (checking general properties and invariants) if there's something to test (a function with some behaviour, not just the type definition). Edge cases need to be tested via both unit tests and PBT tests.
The `describe` tree should be: module name > function, so eg.
```elm
suite : Test
suite =
  Test.describe "Foo"
    [ Test.describe "bar"
        [ Test.test "does X" <| \() -> ... Foo.bar someFoo ...
        , Test.fuzz Fuzzers.foo "does Y" <| \foo -> ... Foo.bar foo ...
        ]
    ]
```

Unqualified imports: only allowed for types of the same name as the module. Values, constructors and functions must be qualified when used.
* yes: `import Foo exposing (Foo)`
* no: `import Foo exposing (Foo(..))`
* no: `import Foo exposing (Foo, fromString)`
* no: `import Foo exposing (fromString)`

When unit/PBT-testing helpers that would normally not be exposed, you can expose aliases of them that start with `test_`. `elm-review` will make sure they are not used outside tests.

You're allowed to have a `tests/Fuzzers.elm` module holding all fuzzers across domains/types.

Use pipeline style: instead of
```elm
Fuzz.map (String.filter Char.isAlphaNum) Fuzz.string
```
write:
```elm
Fuzz.string
    |> Fuzz.map (String.filter Char.isAlphaNum)
```
Similarly instead of 
```elm
Expect.equal True (Foo.isBar "bar")
```
write:
```elm
Foo.isBar "bar"
    |> Expect.equal True
```

When matching on custom types that we define, always list all cases instead of using `_ ->`. When multiple cases share behaviour, you can do
```elm
let
  common : () -> foo
  common () =
    ...the common behaviour...
in
case bar of
  Baz -> common ()
  Quux -> common ()
  Quuz -> ...something else...
```

`lamdera live` _REQUIRES_ that there exist `Types.FrontendModel`, `Types.BackendModel`, `Types.FrontendMsg` and `Types.BackendMsg`, and that `Types.ToFrontend` and `Types.ToBackend` aren't aliases.
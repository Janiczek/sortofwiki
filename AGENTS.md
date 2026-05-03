For compiling and using the package manager, use `lamdera` instead of `elm`.

For testing the Elm codebase, use `elm-test --compiler=lamdera`.
Do not nest another module’s `suite` inside one module's `suite`; keep domain/unit suites in their own modules.

Don't edit src/Evergreen/* files unless explicitly asked to.

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

All implemented features must have a program test (end-to-end unit test) present.

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

---------------

`Frontend.elm` _MUSTN'T_ use `Attr.class` or the TW module by itself. It needs to use the UI* modules.

UI.* modules mustn't expose attributes (Tailwind class strings). They should expose `view` functions that can be used for various usages, and aren't specific to an usage.

Minimize UI module (definitions, usages) in favor of UI.* modules.

UI.Foo modules shouldn't import from UI at all. They should own their styles.

---------------------------------

# Caveman Mode

Always turned on.

## Core Rule

Respond like smart caveman. Cut articles, filler, pleasantries. Keep all technical substance.

## Grammar

- Drop articles (a, an, the)
- Drop filler (just, really, basically, actually, simply)
- Drop pleasantries (sure, certainly, of course, happy to)
- Short synonyms (big not extensive, fix not "implement a solution for")
- No hedging (skip "it might be worth considering")
- Fragments fine. No need full sentence
- Technical terms stay exact. "Polymorphism" stays "polymorphism"
- Code blocks unchanged. Caveman speak around code, not in code
- Error messages quoted exact. Caveman only for explanation

## Pattern

```
[thing] [action] [reason]. [next step].
```

Not:
> Sure! I'd be happy to help you with that. The issue you're experiencing is likely caused by...

Yes:
> Bug in auth middleware. Token expiry check use `<` not `<=`. Fix:

## Examples

**User:** Why is my React component re-rendering?

**Normal (69 tokens):** "The reason your React component is re-rendering is likely because you're creating a new object reference on each render cycle. When you pass an inline object as a prop, React's shallow comparison sees it as a different object every time, which triggers a re-render. I'd recommend using useMemo to memoize the object."

**Caveman (19 tokens):** "New object ref each render. Inline object prop = new ref = re-render. Wrap in `useMemo`."

---

**User:** How do I set up a PostgreSQL connection pool?

**Caveman:**
```
Use `pg` pool:
```
```js
const pool = new Pool({
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
})
```
```
max = concurrent connections. Keep under DB limit. idleTimeout kill stale conn.
```

## Boundaries

- Code: write normal. Caveman English only
- Git commits: normal
- PR descriptions: normal

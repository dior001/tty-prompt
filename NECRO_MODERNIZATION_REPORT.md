# tty-prompt Modernization Report

This PR modernizes `tty-prompt` for current Ruby (target: 4.0.6) and brings
the gem's tooling, tests, docs, and dependencies up to date. The gem's code
already ran unmodified on Ruby 4.0.6 — no removed-stdlib or deprecated-API
fixes were needed — so this pass focused on dependencies, declaring the
support floor explicitly, closing test-coverage gaps (fixing two real bugs
along the way), documentation, lint, and security.

## 1. Dependencies

### Runtime

| Gem | Before | After | Notes |
|---|---|---|---|
| `pastel` | `~> 0.8` | `~> 0.8` | Already at latest (0.8.0); constraint unchanged |
| `tty-reader` | `~> 0.8` | `~> 0.9` | Bumped to latest (0.9.0) |

Both are actively maintained by the same author's `tty-toolkit` and remain
the right choice — no dead dependency to replace here.

### Development

| Gem | Before | After |
|---|---|---|
| `rake` | unconstrained (gemspec) | `~> 13.0` |
| `rspec` | `>= 3.0` (gemspec) | `~> 3.13` |
| `benchmark-ips` | `~> 2.13.0` | `~> 2.15` |
| `simplecov` | `~> 0.22.0` | `~> 1.0` (major bump) |
| `coveralls_reborn` | `~> 0.28.0` | `~> 1.0` (major bump) |
| `rubocop` | *(not present)* | `~> 1.88` *(new)* |
| `bundler-audit` | *(not present)* | `~> 0.9` *(new)* |

The `Gemfile` also drops two pieces of dead conditional logic that only
existed to support Ruby versions this gem no longer targets:
`gem "json", "2.4.1" if RUBY_VERSION == "2.0.0"` and the
`if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.7.0")` guard
around the coverage gems (always true now that the floor is 3.2).

`bundle install` resolves cleanly against Ruby 4.0.6 with 50 gems.

## 2. Compatibility (Ruby 4.0.6)

The existing code already ran cleanly and warning-free on Ruby 4.0.6 with
the full 494-example suite passing before any changes — this gem never
relied on stdlib that's since been removed or on APIs that emit
deprecation warnings on modern Ruby. What this PR adds is an **explicit**
declaration of the support floor, rather than continuing to imply support
back to Ruby 2.0:

- Added `.ruby-version` pinned to `4.0.6` (previously gitignored —
  un-ignored it so it's actually tracked, since the task requires
  declaring the target explicitly).
- Raised `required_ruby_version` from `>= 2.0.0` to `>= 3.2.0` in the
  gemspec. 3.2 was chosen (rather than, say, 3.0) because it's the actual
  floor `simplecov` 1.x — a dev dependency — needs; keeping the gem's own
  floor aligned with its tooling avoids a `bundle install` mismatch for
  anyone developing against this gemspec.
- Rewrote the GitHub Actions matrix: dropped Ruby 2.0–3.1 and JRuby
  9.2/9.3 (long past this floor), kept `ruby-head`/`jruby-9.4`/
  `jruby-head`/`truffleruby-head` as `continue-on-error` canaries, and
  added `3.2`, `3.3`, `3.4`, and `4.0.6` (coverage now runs on 4.0.6
  instead of the old 2.7 job). Added dedicated `lint` (RuboCop) and
  `audit` (bundler-audit) jobs.
- Updated `appveyor.yml` similarly (Windows Ruby 3.2–3.4 instead of
  2.0–2.6), and removed a `gem install bundler -v '< 2.0'` pin that no
  longer makes sense.
- **Review fix:** the first version of this bump broke
  `continuous-integration/appveyor/pr`. AppVeyor only pre-installs a
  given Ruby version on specific build-worker images, and Ruby 3.2/3.3/3.4
  aren't present on the account's default (older) image — so
  `C:\Ruby32-x64\bin` etc. didn't exist and `bundle`/`ruby` were never on
  `PATH`. Fixed by pinning `image: Visual Studio 2022` in `appveyor.yml`,
  the current AppVeyor image with those Ruby versions preinstalled. This
  is Windows/AppVeyor-specific — the GitHub Actions matrix was unaffected
  since `ruby/setup-ruby` installs the requested Ruby itself rather than
  relying on a preinstalled image.

No source in `lib/` needed a behavioral compatibility fix for Ruby 4.0.6
itself, but several latent bugs turned up while writing tests for full
coverage (see §3) and one bug was very nearly *introduced* by RuboCop's
autocorrect (also §3) — worth knowing about even though it's not a
Ruby-version issue per se.

## 3. Tests & coverage

**Coverage: 97.51% → 100.00%** (2009/2009 lines; two lines in
`Timer#time_now`'s `Time.now` fallback — which only runs on platforms
without `Process::CLOCK_MONOTONIC` — are excluded via
`# simplecov:disable` / `# simplecov:enable` since Ruby 4.0.6 always has
a monotonic clock and there's no way to exercise that branch honestly in
this environment).

49 new example groups were added across 13 new spec files and edits to
~20 existing ones, exercising: `Prompt#debug`/`#tty?`/`#stdin`/`#stdout`/
`#stderr`, `AnswersCollector#respond_to_missing?`, `Const::Undefined`,
`ConverterRegistry#inspect`, block-based pagination edge cases, `EnumList`
left/right page cycling and DSL setters, `Keypress` with a restricted
`:keys` list, `List`/`Select` numeric-jump (`:enum`) and up-cycling,
`MultiList` DSL `min`/`max`, mask-question backspace handling, several
`Question` internals (`#raw`, `#to_s`, `#inspect`, `#convert_result`,
`Checks::CheckModifier`, `Checks::CheckRange.cast`, `Validation#call`'s
unsupported-type branch), and `Utils.extract_options`.

### Bugs found and fixed while writing tests

1. **`ConverterRegistry#inspect` was broken** (`lib/tty/prompt/converter_registry.rb`).
   It read `@_registry` (single underscore) but the ivar is `@__registry`
   (double underscore) — `inspect` always returned `"nil"`. Fixed the typo
   and added a spec (`converter_registry_spec.rb`) that would have caught
   it.

2. **A test had `if event.value = "l"`** (assignment, not comparison) in
   `spec/unit/slider_spec.rb`. It happened to still pass because
   assignment returns a truthy value, so the block ran unconditionally —
   RuboCop's `Lint/AssignmentInCondition` cop is disabled project-wide
   (intentionally, for legitimate `if (x = ...)` patterns used elsewhere),
   which is exactly why this typo went unnoticed. Fixed to `==`.

3. **Two `Lint/Void` dead-code spots**: `Question#render_question` and
   `Multiline#render_question` each had a branch (`if !echo? ... header`)
   that referenced the `header` array for no effect. Restructured both
   into `if echo? ... end` wrappers with identical behavior and no dead
   reference.

4. **Caught, not committed**: `rubocop -A`'s autocorrect rewrote
   `converter_registry.keys.each do |type|` (in `converters.rb`) to
   `converter_registry.each_key do |type|`. That loop *registers new
   converters inside its own body*, so iterating the live hash instead of
   a `.keys` snapshot raises `RuntimeError: can't add a new key into hash
   during iteration` — caught immediately because the full suite was run
   after every autocorrect pass. Reverted to `.keys.each` with an inline
   `# rubocop:disable Style/HashEachMethods` and a comment explaining why.
   This is the main reason every autocorrect batch in this PR was
   followed by a full test run rather than trusted blindly.

### Latent dead-code branches (documented, left alone)

Several branches turned out to be structurally unreachable through any
public call path — not new problems, just characteristics of the existing
design that surfaced while chasing 100% coverage. Fixing them would mean
changing behavior/API surface, which is out of scope for a compatibility
pass, so each is covered with a direct unit test (calling the method or
class directly, bypassing the normal guard) rather than papered over with
a coverage exclusion:

- `ConfirmQuestion#negative?` — never reached through
  `setup_defaults`'s own branching, since the enclosing conditions already
  guarantee `negative?` is only evaluated when it's redundant.
- `Question::Checks::CheckModifier`'s "no modifier" branch — `@modifier`
  always defaults to `[]`, never `nil`, so the branch that handles a nil
  modifier can't trigger via the constructor.
- `Question::Checks::CheckRange.cast`'s integer branch — `float?`'s regex
  (`(\d*[.])?\d+`) matches plain integers too (the decimal part is
  optional), so it always wins before `int?` gets a chance.
- `Question::Validation#call`'s `else false` — `coerce` (run in
  `initialize`) already raises `ValidationCoercion` for any pattern type
  other than `String`/`Symbol`/`Regexp`/`Proc`, so `@pattern` can never
  hold anything `call` doesn't already handle.
- `Question::UndefinedSetting#to_s`/`#inspect` — the sentinel is always
  used as the *class object itself* (`UndefinedSetting`) for identity
  checks, never instantiated, so its instance methods are unreachable in
  practice.
- `EnumList#validate_defaults`'s nil-default branch — `setup_defaults`
  always fills in a default before calling `validate_defaults`, so the
  "no default at all" message can't be produced through normal use.

## 4. Documentation

- Added class/module-level YARD docs to the 13 classes/modules RuboCop's
  `Style/Documentation` flagged as missing them:
  `AnswersCollector`, `BlockPaginator`, `ConfirmQuestion`, `ConverterDSL`,
  `Converters`, `Keypress`, `MaskQuestion`, `Paginator`,
  `Question::Checks::CheckConversion`, `Test::StringIOExtensions`, `Test`,
  `Timer`, `Utils`.
- Added method-level docs to 61 previously-undocumented methods across 16
  files — internal `keyXXX` event-dispatch callbacks (tagged
  `@api private`, since they're invoked by `TTY::Reader`'s subscribe
  mechanism rather than called directly), plus real public-facing methods
  like `Prompt.messages`, `ConfirmQuestion#positive?`/`#negative?`/
  `#suffix?`, `Result#success?`/`#failure?`, and the `Question::Checks`
  validator classes.
- Fixed a couple of stray doc typos found along the way (`@api pbulic` →
  `@api public` in `enum_list.rb`, `represeting` → `representing` in
  `timer.rb`).
- README was reviewed for staleness (installation instructions, Ruby
  version claims, dependency links) — nothing needed updating; it doesn't
  reference specific old Ruby versions.

## 5. Lint (RuboCop)

`bundle exec rubocop` now passes with **zero offenses** across 117 files
(was 500, 422 auto-correctable, on the first run with a bare
`rubocop 1.88` against this codebase's existing style).

Notable non-mechanical decisions baked into `.rubocop.yml`:

- Excluded `benchmarks/**/*` and `examples/**/*` globally — matches the
  CI workflow's own `paths-ignore`, since neither ships in the gem
  (`spec.files = Dir["lib/**/*"]`) nor is covered by the test suite.
- `Metrics/PerceivedComplexity` disabled, mirroring the pre-existing
  `Metrics/CyclomaticComplexity: Enabled: false` — same rationale
  (rendering/pagination logic is inherently branchy), same author intent.
- `Metrics/AbcSize`/`Metrics/MethodLength` excluded for five files whose
  core algorithms (pagination math, Damerau-Levenshtein distance,
  multi-select rendering) are legitimately complex; refactoring
  battle-tested logic purely to satisfy a line-count metric was judged
  higher-risk than the lint benefit, consistent with the original
  author's own choice to already raise these two cops' thresholds above
  RuboCop's defaults (`Max: 35` / `Max: 20`).
  `lib/tty/prompt.rb#initialize`'s `Metrics/ParameterLists` offense was
  handled the same way — the many independent keyword options are the
  gem's actual public configuration surface, and collapsing them into an
  options hash would be a breaking API change, not a cleanup.
- `Naming/FileName` excluded for `lib/tty-prompt.rb` (the hyphenated
  entry-point file every `require "tty-prompt"` needs; standard for
  gems named with a hyphen).
- Real fixes, not exclusions: `Lint/MixedRegexpCaptureTypes` in
  `converters.rb` (converted unnamed inner groups to non-capturing —
  `(\.\d+)?` → `(?:\.\d+)?` — since only the named captures were ever
  read), `Lint/UnreachableLoop` in `Expander#validate_choices` (an
  `errors.each { raise ... }` that could only ever run once — rewritten
  as `raise ... if errors.any?`), `Style/MissingRespondToMissing` in
  `AnswersCollector` (added `respond_to_missing?` delegating to the
  wrapped prompt), `Naming/PredicateMethod` in `Test::StringIOExtensions`
  (kept `wait_readable` — not `wait_readable?` — with a disable comment,
  since it must duck-type `IO#wait_readable`, which `tty-reader` calls by
  that exact name).
- Fixed the deprecated `Metrics/BlockLength: IgnoredMethods` config key
  (renamed to `AllowedMethods` by RuboCop upstream) and added
  `AllCops: SuggestExtensions: false` to quiet the `rubocop-rake`/
  `rubocop-rspec` upsell notices.
- **Review fix:** `examples/ask.rb:10` was flagged for
  `Layout/LineLength` (87/80). `examples/**/*` is excluded from the
  project's own `bundle exec rubocop` run (see above), so this didn't
  show up in CI lint — but a reviewer's editor/tooling checks the file
  directly regardless of that exclude, which is standard RuboCop
  behavior for an explicitly-targeted path. Reformatted the
  `prompt.ask(...)` call's keyword arguments one per line so every line
  is within 80 columns; re-verified with
  `bundle exec rubocop examples/ask.rb` (no offenses) and the full suite
  (538 examples, 0 failures, 100% coverage).
- **Review fix:** `spec/unit/multi_select_spec.rb:347` was flagged for
  `Layout/LineLength` (87/80) — same situation as the `examples/ask.rb`
  fix above: `spec/**/*` is deliberately excluded from this cop in
  `.rubocop.yml` (a pre-existing choice predating this PR, not something
  this modernization pass introduced), so it never showed up in
  `bundle exec rubocop`, but a reviewer flagged the line directly.
  Wrapped the `hint:` string literal's concatenation across an extra
  line so every fragment is within 80 columns; the concatenated string
  value is unchanged. Re-verified with `bundle exec rubocop` (117 files,
  no offenses) and the full suite (538 examples, 0 failures, 100%
  coverage).
- **Review fix:** `spec/unit/question/validation/call_spec.rb:36` was
  flagged for `Style/LambdaCall` (prefer `lambda.call(...)` over
  `lambda.(...)`). The `.()` shorthand is ordinary syntax supported since
  long before this gem's `>= 3.2.0` floor, so this was a pure style fix
  with no compatibility angle: replaced all four `.()` call sites in that
  file with explicit `.call(...)`. Re-verified with `bundle exec rubocop`
  (117 files, no offenses) and the full suite (538 examples, 0 failures,
  100% coverage).

## 6. Security

`bundle-audit check --update` (against the live `ruby-advisory-db`,
1229 advisories as of this run): **no vulnerabilities found**, both
before and after the dependency bumps in §1. No CVEs applied to this
gem's dependency set at either the old or new pinned versions.

## Not changed / out of scope

- `lib/tty/prompt/question/checks.rb`'s `CheckRange.cast` and
  `Question::Validation#call`'s design quirks (see §3) are pre-existing
  behavior, not modernization bugs — fixing them would change what
  `Question#in`/`#validate` accept, which is a behavioral change outside
  this PR's scope. They're now at least documented and covered.
- Gem version (`0.23.1`) was left untouched — bumping it is a maintainer
  release decision, not something to presume in a compatibility PR.

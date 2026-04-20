# tutorials

In-app guided tour engine for LMS and school-os.

Ships:
- YAML-authored tours with i18n translation keys
- DB-tracked per-user progress
- Route-based availability (a tour is visible when the user can reach the route it teaches)
- `data-tour="..."` selector convention with runtime fallback and CI audit
- Stimulus controller wrapping driver.js
- `bin/rails g tutorials:tour NAME` scaffolder
- `bin/rails tutorials:audit_selectors` rake task for host-app CI

## Installation (host app)

Add to `Gemfile`:

    gem "tutorials", path: "../tutorials"

Then:

    bundle install
    bin/rails generate tutorials:install
    bin/rails db:migrate

Adds an `onboarded_at` column to `users`, creates `tutorials_user_tour_progresses`, writes a stub `config/initializers/tutorials.rb`, and creates `config/tours/.keep`.

## Authoring a tour

    bin/rails generate tutorials:tour teacher/grade_assignment

Creates a YAML stub under `config/tours/teacher/grade_assignment.yml` and a matching translation key block in `config/locales/tutorials.en.yml`.

## Running the selector audit

    bin/rails tutorials:audit_selectors

Prints any `data-tour` selectors in registered tour YAML that do not resolve against the live DOM for the matching route, then exits non-zero if any are orphaned. Wire into CI with your usual system-test runner.

## Public API

The host app interacts with the gem through a small set of entry points:

- `Tutorials.configure { |c| c.authorize_with { |user, tour| ... } }` — configure the per-tour authorization policy (default: all tours visible). Called from `config/initializers/tutorials.rb`.
- `Tutorials::Registry.find(id)` — look up a registered tour by id.
- `Tutorials::Registry.all` — iterate every registered tour (used by the gallery page).
- `Tutorials::Tour.load_file(path)` — parse a tour from a YAML file.
- `Tutorials::Tour.load_hash(hash)` — build a tour from an already-parsed hash (used by `SourceResolver` hooks; accepts string- or symbol-keyed hashes).
- `Tutorials::SourceResolver.register_hook(callable)` — register a loader hook that produces tour hashes programmatically (see below).
- `bin/rails tutorials:audit_selectors` — host-app CI task. Fails when any `data-tour` selector in registered YAML doesn't resolve in the rendered DOM for its matching route.

## Examples

- [`docs/EXAMPLES.md`](docs/EXAMPLES.md) — cookbook with 8 recipes: minimal and full tour YAML, the `data-tour` convention, i18n, Pundit- and role-based `authorize_with`, mounting launcher + loader, opening a tour programmatically, and writing a `SourceResolver` hook.
- [`examples/tours/`](examples/tours/) — 2 copy-pasteable archetype YAMLs: a three-step student dashboard tour and a five-step teacher-grading tour.

## Integration with workflows gem

`Tutorials::SourceResolver` unifies tour loading across multiple sources. By default it reads legacy `config/tours/*.yml` files; other gems can register a hook that contributes tour hashes programmatically. When the host mounts both `tutorials` and [`workflows`](https://github.com/ye-lin-aung/workflows), the workflows engine registers a hook at boot:

```ruby
# lib/workflows/engine.rb (excerpt)
Tutorials::SourceResolver.register_hook(lambda do |workflows_dir|
  Workflows::YamlLoader.load_directory(workflows_dir).map do |wf|
    Workflows::Compilers::Tour.call(wf)
  end
end)
```

At that point, every workflow YAML under `config/workflows/` automatically becomes a driver.js tour in the `Tutorials::Registry`. Tours from both sources coexist: on id collision, the hook-produced tour wins (last write wins via `SourceResolver#merge_by_id`), which lets the workflows gem supersede a legacy tour with the same dotted id.

The practical result for host-app developers:

- New tours authored today should go through the workflows gem (one YAML, three outputs).
- Legacy `config/tours/*.yml` files continue to work and appear in the registry alongside workflow-derived tours.
- The tour id convention matches: `config/workflows/teacher/grade_assignment.yml` becomes tour id `teacher.grade_assignment`, identical to the id you'd have given a hand-written tour file at the same path.

See `docs/superpowers/specs/2026-04-20-workflows-design.md` in the school-management repo for the full workflows design, or `vendor/gems/workflows/README.md` in either host app for the authoring guide.

## Design docs

- `docs/superpowers/specs/2026-04-13-tutorials-design.md` in the school-management repo — full design for this gem.
- `docs/superpowers/specs/2026-04-20-workflows-design.md` — downstream integration via `SourceResolver`.

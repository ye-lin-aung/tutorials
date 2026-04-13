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

See `docs/superpowers/specs/2026-04-13-tutorials-design.md` in the school-management repo for the full design.

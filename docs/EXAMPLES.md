# Tutorials cookbook

Eight recipes covering the patterns you hit while authoring tours, wiring the
host app, and integrating with other gems. Every code block is meant to be
copy-pasteable — no `...` placeholders.

If you are new to the gem: read `../README.md` first for the install + public
API overview, then come back here.

## Table of contents

1. [Minimal tour YAML + full tour YAML](#1-minimal-tour-yaml--full-tour-yaml)
2. [Adding `data-tour` selectors to views](#2-adding-data-tour-selectors-to-views)
3. [i18n for tour titles and step bodies](#3-i18n-for-tour-titles-and-step-bodies)
4. [`authorize_with` for Pundit](#4-authorize_with-for-pundit)
5. [`authorize_with` for role-based auth](#5-authorize_with-for-role-based-auth)
6. [Mounting launcher + loader in the layout](#6-mounting-launcher--loader-in-the-layout)
7. [Opening a tour programmatically via CustomEvent](#7-opening-a-tour-programmatically-via-customevent)
8. [Writing a SourceResolver hook](#8-writing-a-sourceresolver-hook)

---

## 1. Minimal tour YAML + full tour YAML

When to use: as your starting templates for any new tour. The generator
(`bin/rails generate tutorials:tour teacher/grade_assignment`) produces
something close to the minimal shape — use the full shape once you need
`description_key`, `first_login`, or `preview_path`.

**Minimal tour** — exactly the required keys:

```yaml
id: student.dashboard
route: /
title_key: tours.student.dashboard.title
steps:
  - element: "[data-tour='dashboard-hero']"
    title_key: tours.student.dashboard.steps.1.title
    body_key:  tours.student.dashboard.steps.1.body
```

`Tutorials::Tour::REQUIRED_KEYS` is `id, route, title_key, steps`; each step
requires `element, title_key, body_key`. Anything else at the top level
raises `InvalidTour: unknown top-level key ...` at load time — the schema is
strict by design.

**Full tour** — every field exercised:

```yaml
id: teacher.grade_assignment
route: /gradebook/:slug
preview_path: /gradebook/algebra-i-fundamentals
title_key: tours.teacher.grade_assignment.title
description_key: tours.teacher.grade_assignment.description
first_login: false
steps:
  - element: "[data-tour='gradebook-table']"
    title_key: tours.teacher.grade_assignment.steps.1.title
    body_key:  tours.teacher.grade_assignment.steps.1.body

  - element: "[data-tour='gradebook-row-jordan']"
    title_key: tours.teacher.grade_assignment.steps.2.title
    body_key:  tours.teacher.grade_assignment.steps.2.body

  - element: "[data-tour='gradebook-save']"
    title_key: tours.teacher.grade_assignment.steps.3.title
    body_key:  tours.teacher.grade_assignment.steps.3.body
```

Field notes:

- `route`: matched against the request path. Placeholders like `:slug`
  compile to regex fragments via `Tutorials::PathMatcher` — so the tour
  fires on *any* `/gradebook/<anything>` URL, not just the literal route.
- `preview_path`: the Tour Gallery's "Preview" button deep-links to this
  URL with `?tutorial=<id>`. Use it when `route` contains placeholders that
  the default `:slug → "1"` substitution wouldn't satisfy. Skip it for
  placeholder-free routes.
- `first_login: true`: pairs with `Registry.first_login_tour_for(request_path)`
  so a controller can auto-open the tour the first time a new user hits the
  matching route. Only one tour should set this per route; the match is
  first-wins across the registry.
- `description_key`: shown on the tour-gallery card below the title. Skip
  if you only want a title.

The archetype YAMLs under `../examples/tours/` (`student_dashboard.yml`,
`teacher_grade_first_assignment.yml`) are ready to drop into a host's
`config/tours/` directory and try out.

---

## 2. Adding `data-tour` selectors to views

When to use: every tour step. The `element` key in tour YAML is a CSS
selector; keeping selectors stable across CSS/i18n churn is the whole point
of the `[data-tour='...']` convention.

Example ERB for a gradebook page:

```erb
<%= tag.div data: { tour: "gradebook-page-hero" }, class: "page-hero" do %>
  <h1><%= @course.name %> — Gradebook</h1>
<% end %>

<table data-tour="gradebook-table" class="min-w-full divide-y">
  <thead>
    <tr>
      <th>Student</th>
      <% @assignments.each do |assignment| %>
        <th data-tour="gradebook-column-<%= assignment.slug %>">
          <%= assignment.title %>
        </th>
      <% end %>
    </tr>
  </thead>
  <tbody>
    <% @students.each do |student| %>
      <tr data-tour="gradebook-row-<%= student.slug %>">
        <td><%= student.name %></td>
        <% @assignments.each do |a| %>
          <td data-tour="gradebook-cell-<%= student.slug %>-<%= a.slug %>">
            <%= grade_for(student, a) %>
          </td>
        <% end %>
      </tr>
    <% end %>
  </tbody>
</table>

<%= link_to "Save", save_gradebook_path, class: "btn-primary",
            data: { tour: "gradebook-save" } %>
```

Naming convention:

- Object-namespaced: `gradebook-table`, `gradebook-row-<slug>`,
  `gradebook-cell-<student>-<assignment>`. The first segment is the object
  the page is about, the rest is what you're pointing at. Not
  `save-button` — that's too generic, and the moment you have two save
  buttons on one page the tour has no way to target the right one.
- Stable under CSS refactors: a `[data-tour]` attribute survives a
  Tailwind rewrite, a move to ViewComponent, a layout overhaul. CSS
  class selectors don't.
- Stable under i18n: don't use text-based selectors (`button:contains("Save")`);
  they break the moment a translator relabels the button.
- Lowercase, hyphen-separated. Matches the attribute style the whole
  codebase uses.

CI enforcement:

```bash
bin/rails tutorials:audit_selectors
```

Prints every `data-tour` selector in registered tour YAML that fails to
resolve against the rendered DOM for its matching route, then exits
non-zero if any are orphaned. Wire it into CI alongside your system test
runner — orphan selectors ship silently otherwise, and the user sees a
driver.js highlight box around nothing.

---

## 3. i18n for tour titles and step bodies

When to use: every production tour — titles and body text are always
translation keys, never inline strings. `Tutorials::Tour` stores
`title_key` and passes it to `I18n.t` at render time, so the tour YAML
itself stays locale-agnostic.

The tour:

```yaml
id: student.dashboard
route: /
title_key: tours.student.dashboard.title
description_key: tours.student.dashboard.description
first_login: true
steps:
  - element: "[data-tour='dashboard-hero']"
    title_key: tours.student.dashboard.steps.1.title
    body_key:  tours.student.dashboard.steps.1.body

  - element: "[data-tour='dashboard-stats']"
    title_key: tours.student.dashboard.steps.2.title
    body_key:  tours.student.dashboard.steps.2.body
```

The matching `config/locales/tutorials.en.yml`:

```yaml
en:
  tours:
    student:
      dashboard:
        title: "Welcome to your dashboard"
        description: "A quick tour of the main page."
        steps:
          "1":
            title: "Your homepage"
            body:  "This is where you land each time you sign in."
          "2":
            title: "Today's stats"
            body:  "Your attendance, upcoming assignments, and messages."
```

And `config/locales/tutorials.es.yml`:

```yaml
es:
  tours:
    student:
      dashboard:
        title: "Bienvenido a tu panel"
        description: "Un recorrido rápido por la página principal."
        steps:
          "1":
            title: "Tu página principal"
            body:  "Aquí aterrizas cada vez que inicias sesión."
          "2":
            title: "Estadísticas de hoy"
            body:  "Tu asistencia, próximas tareas y mensajes."
```

Key naming conventions:

- `tours.<role>.<tour_id>.title`
- `tours.<role>.<tour_id>.description` (optional)
- `tours.<role>.<tour_id>.steps.<N>.title`
- `tours.<role>.<tour_id>.steps.<N>.body`

Step numbers as strings (`"1"`, `"2"`) rather than integers — YAML
integer keys get awkward under some loaders.

A missing key falls back to Rails' `translation missing: ...` default, so
QA sees the gap visibly in the popover. The tour still renders, just with
the fallback string in place of the translation.

---

## 4. `authorize_with` for Pundit

When to use: your app already uses Pundit for request-level authorization
and you want tour visibility to follow the same rules. The `authorize_with`
block decides whether a given `(user, tour)` pair shows the tour in the
launcher — route-matching already filters by URL, so this block is where
role/permission checks go.

```ruby
# config/initializers/tutorials.rb
Tutorials.configure do |config|
  config.authorize_with do |user, tour|
    next false unless user

    # Tour IDs follow the convention <feature>.<tour_name>, e.g.
    # gradebook.quick_start or billing.first_invoice. We expect a matching
    # Pundit policy for each feature — GradebookPolicy, BillingPolicy.
    feature       = tour.id.to_s.split(".").first
    policy_class  = "#{feature.camelize}Policy".safe_constantize
    next false unless policy_class

    # Every policy exposes a :tour_feature? predicate that answers "is this
    # user allowed to see the feature this tour teaches?". Using a standard
    # name keeps the dispatch simple — no per-tour logic in this block.
    Pundit.policy(user, feature.to_sym).public_send(:tour_feature?)
  rescue Pundit::NotDefinedError
    # A tour whose feature has no policy is treated as public — better than
    # silently hiding a tour because someone forgot to write the policy.
    true
  end
end
```

The matching policy:

```ruby
# app/policies/gradebook_policy.rb
class GradebookPolicy < ApplicationPolicy
  def tour_feature?
    # Whatever your gradebook's actual show? rule is.
    user.teacher? || user.admin?
  end
end
```

`Tutorials::Configuration#authorize_with` just stores the block; the
authorization check is driven by whatever calls
`Configuration.instance.authorized?(user:, tour:)`. The before-action
shipped with the gem (see Recipe 6) and `Tutorials::Availability.for` both
consult it.

`Pundit::NotDefinedError` is a deliberate allow-all fallback here — the
alternative is silently hiding every tour whose policy is missing, which
is invisible at runtime. If you prefer fail-closed, change the rescue arm
to `false`.

---

## 5. `authorize_with` for role-based auth

When to use: your app uses a simple role model (a `Role` AR record per
user, or a string column on `User`) rather than a full policy library. The
real school-management initializer uses this pattern — tour IDs are
role-prefixed and the authorize block looks up a matching `Role` record.

```ruby
# config/initializers/tutorials.rb
Tutorials.configure do |config|
  role_prefix_to_name = {
    "student"      => "Student",
    "admin"        => "Admin",
    "teacher"      => "Instructor",
    "parent"       => "Parent",
    "finance"      => "Finance",
    "system_admin" => "System Admin"
  }.freeze

  config.authorize_with do |user, tour|
    next false unless user
    # System admins always see every tour.
    next true  if user.try(:system_admin?)

    prefix    = tour.id.to_s.split(".").first
    role_name = role_prefix_to_name[prefix]

    if role_name == "Parent"
      # Parents may not hold a formal Role record in some deployments;
      # fall back to the parent_student_links association.
      user.roles.exists?(name: "Parent") ||
        (user.respond_to?(:parent_student_links) && user.parent_student_links.exists?)
    elsif role_name
      user.roles.exists?(name: role_name)
    else
      # Unknown prefix — treat as "any signed-in user with an active
      # membership". Keeps legacy tours working during a rename.
      user.school_memberships.active.exists?
    end
  end
end
```

The convention that makes this work: every tour ID starts with one of the
known role prefixes. `student.view_grades`, `teacher.gradebook`,
`parent.child_progress`, `finance.invoices`. If you add a new role,
extend `role_prefix_to_name` in one place and every tour with that prefix
is now visible to that role.

The `Parent` branch is worth calling out. In multi-tenant school apps,
parents are often modeled as "users who have at least one
parent-student link" rather than holding a formal role record — they get
the parent experience by virtue of being linked to a student, not by
sitting in a `roles` table. The branch handles both shapes.

---

## 6. Mounting launcher + loader in the layout

When to use: once, per host app. Drops two partials into the application
layout — the *loader* sets up the Stimulus controller and driver.js assets,
the *launcher* renders the floating "Start a tour" button that lists the
tours available for the current page.

In your layout (typically `app/views/layouts/application.html.erb`):

```erb
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="csrf-token" content="<%= form_authenticity_token %>">
  <%= yield :head %>
  <%= stylesheet_link_tag "application" %>
  <%= javascript_importmap_tags %>
</head>
<body>
  <%= render "shared/navbar" %>

  <main>
    <%= yield %>
  </main>

  <%= render "tutorials/launcher" %>
  <%= render "tutorials/loader" %>
</body>
</html>
```

`tutorials/loader` renders a hidden `<div data-controller="tutorials">`
with the list of available tour IDs as a data value and (optionally) the
`auto-open` tour ID. It also ships the driver.js CSS. Put it at the *end*
of `<body>` so the Stimulus controller finds it after your other elements
parse.

`tutorials/launcher` renders the floating button (bottom-right by default)
and the dropdown that lists available tours. Order doesn't matter for
the launcher — put it anywhere visible inside the layout.

Both partials rely on instance variables set by a before-action in your
`ApplicationController`:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :set_available_tours

  private

  def set_available_tours
    return unless current_user
    @tutorials_available  = Tutorials::Availability.for(user: current_user, path: request.path)
    @tutorials_auto_open  = Tutorials::Availability.auto_open_tour(user: current_user, path: request.path)
  end
end
```

`Availability.for` returns only tours that (a) match the current path and
(b) pass the `authorize_with` block (Recipe 4, Recipe 5).
`Availability.auto_open_tour` returns the first-login tour, if any, and
only when `current_user.onboarded_at.nil?` — the progress table stores that
to make sure first-login fires exactly once per user.

If you skip the before-action, the instance variables are nil and the
partials render a no-op. No exceptions, no noise. Wiring up the
before-action is how you opt the app in.

---

## 7. Opening a tour programmatically via CustomEvent

When to use: a custom element — a command palette entry, a "Show me how"
button inside a component, a keyboard shortcut — should open a specific
tour. The Stimulus controller listens for a `tutorials:open` CustomEvent
with a `tourId` in `detail`.

The minimal Stimulus controller:

```javascript
// app/javascript/controllers/open_tour_button_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { tourId: String }

  open() {
    this.element.dispatchEvent(
      new CustomEvent("tutorials:open", {
        detail: { tourId: this.tourIdValue },
        bubbles: true
      })
    )
  }
}
```

Wired up in the view:

```erb
<button type="button"
        data-controller="open-tour-button"
        data-open-tour-button-tour-id-value="student.dashboard"
        data-action="click->open-tour-button#open"
        class="btn-ghost">
  Show me how this dashboard works
</button>
```

The key detail is `bubbles: true` on the CustomEvent. The Stimulus
controller that handles the tour lives on a root-level `<div
data-controller="tutorials">` (from Recipe 6), and bubbling is how the
event reaches it from wherever the button happens to be in the DOM.

Three other places this pattern shows up:

1. **Command palette** — whatever library you use, have each palette item
   dispatch `tutorials:open` with the appropriate `tourId` in its command
   handler.
2. **First-run modal** — after a user clicks "Get started" on a welcome
   modal, dispatch `tutorials:open` for the introductory tour.
3. **Deep links** — `?tutorial=<id>` in the URL opens the named tour
   automatically on page load (built-in to the Stimulus controller, no
   CustomEvent needed).

The controller also dispatches three events you can listen to:

- `tutorials:started { detail: { tourId } }` — after the tour opens
- `tutorials:step    { detail: { tourId, stepIndex } }` — on every step
- `tutorials:done    { detail: { tourId, completed } }` — when the tour
  closes (`completed: true` on last step finished, `false` on dismiss)

Use these to wire analytics, trigger confetti on completion, or nudge
users who dismissed the tour on step 1.

---

## 8. Writing a SourceResolver hook

When to use: your gem has its own DSL for describing tour-like things and
you want those registered alongside legacy `config/tours/*.yml` files
automatically. The `workflows` gem (see
`https://github.com/ye-lin-aung/workflows`) is the reference
implementation — one tour projection function, one hook registration in
its engine, done.

The hook is a callable that takes a `workflows_dir` path and returns an
array of tour-shape hashes:

```ruby
# In your gem's engine (lib/<your_gem>/engine.rb)
module MyGem
  class Engine < ::Rails::Engine
    initializer "my_gem.register_tutorials_hook", before: "tutorials.load_tours" do
      begin
        require "tutorials/source_resolver"
      rescue LoadError
        # tutorials gem not mounted — that's fine, we're just a no-op.
        next
      end
      next unless defined?(::Tutorials::SourceResolver)

      ::Tutorials::SourceResolver.register_hook(lambda do |workflows_dir|
        # The hook is invoked from tutorials.load_tours, which runs before
        # Rails' main autoloader is set up. Eagerly require classes the
        # lambda touches so references resolve without relying on autoload.
        require "my_gem/my_dsl_loader"
        require "my_gem/compilers/tour"

        next [] unless workflows_dir && File.directory?(workflows_dir)

        MyGem::MyDslLoader.load_directory(workflows_dir).map do |authored|
          MyGem::Compilers::Tour.call(authored)
        end
      end)
    end
  end
end
```

Each hash your hook returns must be shaped like a tour:

```ruby
{
  id:              "teacher.grade_assignment",
  route:           "/gradebook/:slug",
  title_key:       "tours.teacher.grade_assignment.title",
  description_key: "tours.teacher.grade_assignment.description",
  first_login:     false,
  preview_path:    nil,
  steps: [
    {
      element:   "[data-tour='gradebook-table']",
      title_key: "tours.teacher.grade_assignment.steps.1.title",
      body_key:  "tours.teacher.grade_assignment.steps.1.body"
    },
    # ...
  ]
}
```

Symbol or string keys — `Tutorials::Tour.load_hash` normalizes both. The
`steps` array must contain at least one entry; every entry must have
`element`, `title_key`, `body_key`.

**Merge semantics.** `SourceResolver#merge_by_id` does last-write-wins on
id collision. Legacy tours load first, hook-produced tours load second, so
a hook-produced tour with the same id as a legacy one *supersedes* it.
This is the intended behavior for the workflows gem: a team mid-migration
can drop a workflow YAML with the same id as a legacy tour and see the
workflow-generated tour take over with no code changes.

If the host app doesn't mount the hook-providing gem, or the gem's
`workflows_dir` (or equivalent) doesn't exist, the hook returns `[]` —
legacy tours still load, nothing else happens. This is what makes the
integration opt-in.

For the full workflows-side wiring, see
`/Users/yelinaung/w/school/workflows/lib/workflows/engine.rb` in the
workflows gem repo. The key lines (condensed):

```ruby
initializer "workflows.register_tutorials_hook", before: "tutorials.load_tours" do
  next unless defined?(::Tutorials::SourceResolver)

  ::Tutorials::SourceResolver.register_hook(lambda do |workflows_dir|
    next [] unless workflows_dir && File.directory?(workflows_dir)
    require "workflows/step"
    require "workflows/workflow"
    require "workflows/yaml_loader"
    require "workflows/compilers/tour"
    Workflows::YamlLoader.load_directory(workflows_dir).map do |wf|
      Workflows::Compilers::Tour.call(wf)
    end
  end)
end
```

That's the entire integration surface between the two gems.

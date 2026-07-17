# Rails Generator Tooling

Rails application files should be created with Rails generators instead of
being handwritten into place. This keeps generated framework structure aligned
with Rails itself while preserving the project's Docker-first development
boundary.

Generator tooling lives outside the application runtime:

- `generator/` defines the Ruby and Rails image used only for file generation
- `compose.generator.yml` mounts the repository into the generator container
- `bin/rails-new` creates the initial Rails application under `monolith/`
- `bin/rails-generate` runs future Rails generators inside the generated app
- `docs/rails-generator-history.md` records successful generator commands

The generator history is intentionally factual. Architectural context and
human/AI decision-making belong in ADRs, decision notes, commit messages, and
pull request descriptions.

The reasoning behind this tooling is captured in
[`docs/decision-notes/2026-07-09-rails-generator-tooling.md`](../decision-notes/2026-07-09-rails-generator-tooling.md).

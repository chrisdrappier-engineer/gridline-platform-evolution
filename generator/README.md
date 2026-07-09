# Rails Generator Tooling

This directory defines the container used to run Rails generators for this
repository.

The generator container is separate from the application runtime. It exists so
Rails-created files are produced by Rails itself, while avoiding a dependency
on the host machine's Ruby, Rails, Bundler, or native gem environment.

Use the repository scripts rather than invoking this image directly:

- `bin/rails-new` creates the initial Rails application under `app/` with the
  pinned generator Rails version
- `bin/rails-generate` runs future Rails generators inside the generated app
  with the app's own bundle

Successful generator commands are recorded in
`docs/rails-generator-history.md`. That file should stay factual and concise;
architecture context belongs in ADRs, decision notes, commit messages, and pull
request descriptions.

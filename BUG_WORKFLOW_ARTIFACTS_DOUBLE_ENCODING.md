# Bug: `WorkflowArtifactsPerStep#artifacts` Double-Encoding

## Summary

The `artifacts` attribute on `WorkflowArtifactsPerStep` records can be read back as either a
Ruby `Hash` or a `String` depending on how the record was written. This is caused by callers
pre-encoding the value to JSON before assigning it to an attribute that is itself declared with
`serialize :artifacts, coder: JSON`.

## Background

The model declares:

```ruby
# src/api/app/models/workflow_artifacts_per_step.rb
serialize :artifacts, coder: JSON
```

`serialize` with a JSON coder tells ActiveRecord to call `JSON.dump` on the value before writing
to the database and `JSON.parse` after reading. The attribute therefore expects a plain Ruby
`Hash` or `Array` to be assigned — it handles encoding and decoding itself.

## Root Cause

Both `Workflows::ArtifactsCollector` and the FactoryBot factory call `.to_json` on the Hash
before assigning it to `artifacts`:

```ruby
# src/api/app/services/workflows/artifacts_collector.rb
WorkflowArtifactsPerStep.find_or_create_by(
  workflow_run_id: @workflow_run_id,
  step:            @step.class.name,
  artifacts:       artifacts.to_json   # already a String
)
```

```ruby
# src/api/spec/factories/workflow_artifacts_per_step.rb
workflow_artifacts_per_step.artifacts = { source_project: ..., ... }.to_json
```

Because the value is already a `String` when assigned, ActiveRecord's `serialize` layer encodes
it a second time on write. The database therefore stores a double-encoded JSON string — a JSON
string whose value is itself a JSON string.

On read, ActiveRecord decodes one level and returns a `String` instead of a `Hash`.

## Symptom

The `_workflow_artifacts_per_step` partial contains this guard to handle both possible types:

```haml
-# src/api/app/views/webui/workflow_artifacts_per_step/_workflow_artifacts_per_step.html.haml
:ruby
  raw_artifacts = workflow_artifacts_per_step.artifacts
  artifacts = (raw_artifacts.is_a?(String) ? JSON.parse(raw_artifacts) : raw_artifacts).deep_symbolize_keys
```

This `is_a?(String)` check exists solely as a workaround for the double-encoding issue: when a
record was written via `ArtifactsCollector` or the factory, `raw_artifacts` is a `String` and
must be parsed manually; when written correctly (plain Hash assigned), it is already a `Hash`.

## Affected Files

| File | Note |
|------|------|
| `src/api/app/models/workflow_artifacts_per_step.rb` | Declares `serialize :artifacts, coder: JSON` |
| `src/api/app/services/workflows/artifacts_collector.rb` | Calls `.to_json` before assignment |
| `src/api/spec/factories/workflow_artifacts_per_step.rb` | Calls `.to_json` before assignment |
| `src/api/app/views/webui/workflow_artifacts_per_step/_workflow_artifacts_per_step.html.haml` | `is_a?(String)` workaround in the view |
| `src/api/db/migrate/20220126155601_create_workflow_artifacts_per_steps.rb` | Column defined as plain `text`, not JSON |

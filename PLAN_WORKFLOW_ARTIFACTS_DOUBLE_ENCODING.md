# Fix WorkflowArtifactsPerStep Double-Encoding Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Stop new records from being double-encoded, keep the app working for legacy records during the migration window, and provide a rake task to back-fill existing rows.

**Architecture:** Fix callers first, make the component tolerate both types, then provide an operator-run rake task for the data fix.

**Tech Stack:** Ruby on Rails, ActiveRecord `serialize`, RSpec, FactoryBot, Rake

---

### Before you start — Create the branch

Tasks 1–4 all ship in a single PR. Create a feature branch from `main` before touching any file:

```bash
git checkout main
git pull
git checkout -b fix-workflow-artifact-double-encoding
```

---

### Task 1 — Fix the component to handle both `Hash` and `String`

**Files:**
- Modify: `src/api/app/components/workflow_artifacts_per_step_component.rb:15`
- Create: `src/api/spec/components/workflow_artifacts_per_step_component_spec.rb`

**Step 1: Write the failing spec**

Create `src/api/spec/components/workflow_artifacts_per_step_component_spec.rb` with two contexts,
both using `allow(record).to receive(:artifacts)` to simulate what AR returns after deserialization:

```ruby
RSpec.describe WorkflowArtifactsPerStepComponent, type: :component do
  let(:workflow_run) { create(:workflow_run) }

  context 'when artifacts is a Hash (correctly serialized record)' do
    let(:record) do
      build(:workflow_artifacts_per_step_rebuild_package,
            workflow_run: workflow_run,
            source_project_name: 'home:foo',
            source_package_name: 'bar')
    end

    before do
      allow(record).to receive(:artifacts).and_return(
        { 'project' => 'home:foo', 'package' => 'bar' }
      )
      render_inline(described_class.new(artifacts_per_step: record))
    end

    it { expect(rendered_content).to have_text('home:foo') }
    it { expect(rendered_content).to have_text('bar') }
  end

  context 'when artifacts is a String (legacy double-encoded record)' do
    let(:record) do
      build(:workflow_artifacts_per_step_rebuild_package,
            workflow_run: workflow_run,
            source_project_name: 'home:foo',
            source_package_name: 'bar')
    end

    before do
      allow(record).to receive(:artifacts).and_return(
        { project: 'home:foo', package: 'bar' }.to_json
      )
      render_inline(described_class.new(artifacts_per_step: record))
    end

    it { expect(rendered_content).to have_text('home:foo') }
    it { expect(rendered_content).to have_text('bar') }
  end
end
```

**Step 2: Run spec to confirm failure**

```bash
bundle exec rspec spec/components/workflow_artifacts_per_step_component_spec.rb
```

Expected: failures — `JSON.parse` raises `TypeError` when given a `Hash`.

**Step 3: Fix line 15 of the component**

```ruby
# Before
parsed_artifacts = JSON.parse(artifacts).deep_symbolize_keys

# After
parsed_artifacts = (artifacts.is_a?(Hash) ? artifacts : JSON.parse(artifacts)).deep_symbolize_keys
```

**Step 4: Run spec to confirm it passes**

```bash
bundle exec rspec spec/components/workflow_artifacts_per_step_component_spec.rb
```

Expected: 4 examples, 0 failures.

**Step 5: Commit**

```bash
git add src/api/app/components/workflow_artifacts_per_step_component.rb \
        src/api/spec/components/workflow_artifacts_per_step_component_spec.rb
git commit -m "Handle both Hash and String artifacts in WorkflowArtifactsPerStepComponent

WorkflowArtifactsPerStep#artifacts can currently be deserialized as either
a Hash (correctly written records) or a String (double-encoded legacy records).
This is a temporary solution while we fix the records on production.

Assisted-by: OpenCode:claude-sonnet-4-6@default"
```

---

### Task 2 — Fix `ArtifactsCollector`

**File:** `src/api/app/services/workflows/artifacts_collector.rb:34`

**Step 1: Remove `.to_json`**

```ruby
# Before
WorkflowArtifactsPerStep.find_or_create_by(workflow_run_id: @workflow_run_id, step: @step.class.name, artifacts: artifacts.to_json) if artifacts

# After
WorkflowArtifactsPerStep.find_or_create_by(workflow_run_id: @workflow_run_id, step: @step.class.name, artifacts: artifacts) if artifacts
```

**Step 2: Run specs**

```bash
bundle exec rspec spec/services/workflows/artifacts_collector_spec.rb
```

Expected: all pass.

**Step 3: Commit**

```bash
git add src/api/app/services/workflows/artifacts_collector.rb
git commit -m "Stop double-encoding artifacts to JSON in ArtifactsCollector

WorkflowArtifactsPerStep declares 'serialize :artifacts, coder: JSON', which
means ActiveRecord handles encoding. Calling .to_json before assignment caused
the value to be encoded twice, producing a double-encoded JSON string in the
database.

Assisted-by: OpenCode:claude-sonnet-4-6@default"
```

---

### Task 3 — Fix the factory

**File:** `src/api/spec/factories/workflow_artifacts_per_step.rb`

**Step 1: Remove `.to_json` from all 6 `before(:create)` blocks**

Lines 20–23, 30–33, 40–41, 48–49, 55–69, 75–84. Each Hash literal currently ends with `.to_json` — remove it so a plain Hash is assigned.

**Step 2: Run specs**

```bash
bundle exec rspec spec/models/workflow_artifacts_per_step_spec.rb \
               spec/components/workflow_artifacts_per_step_component_spec.rb
```

Expected: all pass.

**Step 3: Commit**

```bash
git add src/api/spec/factories/workflow_artifacts_per_step.rb
git commit -m "Stop pre-encoding factory artifacts to JSON

Same root cause as ArtifactsCollector: assigning a .to_json String to a
serialized attribute causes double-encoding. Assign plain Hashes so test
records are written the same way production records now are.

Assisted-by: OpenCode:claude-sonnet-4-6@default"
```

---

### Task 4 — Rake task for data back-fill

**File:** `src/api/lib/tasks/data_backfill.rake` — add inside the existing `namespace :data` / `namespace :backfill` block

**Step 1: Add the task**

```ruby
desc 'Fix double-encoded artifacts JSON on WorkflowArtifactsPerStep records'
task fix_workflow_artifacts_double_encoding: :environment do
  fixed_count = 0

  WorkflowArtifactsPerStep.find_each do |record|
    # AR automatically encodes hashes to JSON. When reading record.artifacts,
    # it de-serializes the JSON into a hash, so we skip properly encoded records.
    next unless record.artifacts.is_a?(String)

    # record.artifacts is the inner JSON string (one level already decoded by AR).
    # Parse it into a Hash, re-encode as JSON, and write directly via raw SQL.
    # update_columns still goes through the AR type layer for text columns, which
    # would double-encode again, so we use raw SQL to write the value verbatim.
    conn = WorkflowArtifactsPerStep.connection
    single_encoded = JSON.parse(record.artifacts).to_json
    conn.execute("UPDATE workflow_artifacts_per_steps SET artifacts = #{conn.quote(single_encoded)} WHERE id = #{record.id}")
    fixed_count += 1
  end

  puts "Done. Fixed #{fixed_count} record(s)."
end
```

**Step 2: Verify the task is listed**

```bash
bundle exec rake --tasks | grep fix_workflow_artifacts
```

Expected: `rake data:backfill:fix_workflow_artifacts_double_encoding`

**Step 3: Commit**

```bash
git add src/api/lib/tasks/data_backfill.rake
git commit -m "Add rake task to fix double-encoded WorkflowArtifactsPerStep artifacts

Existing rows written by ArtifactsCollector or the factory have their artifacts
column stored as a double-encoded JSON string. This rake task detects affected
rows (where AR's serialize layer returns a String instead of a Hash) and rewrites
them as single-encoded JSON. Run manually in each environment once the code fix
is deployed: rake data:backfill:fix_workflow_artifacts_double_encoding

Assisted-by: OpenCode:claude-sonnet-4-6@default"
```

---

### After Task 4 — Open the pull request

Push the branch and open a PR against `main`:

```bash
git push -u origin fix-workflow-artifact-double-encoding
gh pr create \
  --base main \
  --title "Fix WorkflowArtifactsPerStep double-encoded artifacts" \
  --body "$(cat <<'EOF'
## Problem

`WorkflowArtifactsPerStep` declares `serialize :artifacts, coder: JSON`, so
ActiveRecord handles JSON encoding on write and decoding on read. Both
`Workflows::ArtifactsCollector` and the FactoryBot factory were calling
`.to_json` on the Hash before assigning it, causing the value to be encoded
twice. The database stored a JSON string whose content was itself a JSON string.
On read, ActiveRecord decoded one level and returned a `String` instead of a
`Hash`, leading to inconsistent behaviour across the codebase.

This PR adds:
- A rake task to fix the wrongfully double-encoded records.
- A change in the model to understand both the wrong and the fixed records while the data migration finishes.

## Follow-up

A separate PR will remove the code to understand both record shapes, the rake task, and the specs to prove the fix.

Assisted-by: OpenCode:claude-sonnet-4-6@default
EOF
)"
```

---

### Task 5 (future, separate PR) — Remove transition code

Once ops confirms the rake task has been run in all environments, open a new branch
off `main` for this cleanup:

```bash
git checkout main
git pull
git checkout -b cleanup-workflow-artifact-transition-guard
```

**Step 1: Revert the component**

```ruby
# src/api/app/components/workflow_artifacts_per_step_component.rb:15
# Before (transition guard)
parsed_artifacts = (artifacts.is_a?(Hash) ? artifacts : JSON.parse(artifacts)).deep_symbolize_keys

# After (serialize guarantees a Hash)
parsed_artifacts = artifacts.deep_symbolize_keys
```

**Step 2: Delete the component spec**

```bash
rm src/api/spec/components/workflow_artifacts_per_step_component_spec.rb
```

Both contexts in that spec are temporary — they document and test the transition behavior only.

**Step 3: Delete the rake task**

Remove the `fix_workflow_artifacts_double_encoding` task from
`src/api/lib/tasks/data_backfill.rake`. Delete the entire `desc` line and the
`task` block that follows it.

**Step 4: Commit**

```bash
git add src/api/app/components/workflow_artifacts_per_step_component.rb \
        src/api/lib/tasks/data_backfill.rake
git rm src/api/spec/components/workflow_artifacts_per_step_component_spec.rb
git commit -m "Remove double-encoding transition code now that all records are migrated

All WorkflowArtifactsPerStep rows have been back-filled by the rake task
data:backfill:fix_workflow_artifacts_double_encoding. The serialize layer now
always returns a Hash, so the is_a?(String) guard, its accompanying spec,
and the rake task are no longer needed.

Assisted-by: OpenCode:claude-sonnet-4-6@default"
```

**Step 5: Open the pull request**

```bash
git push -u origin cleanup-workflow-artifact-transition-guard
gh pr create \
  --base main \
  --title "Remove WorkflowArtifactsPerStep double-encoding transition code" \
  --body "$(cat <<'EOF'
## Context

PR #<number> fixed the double-encoding bug in `WorkflowArtifactsPerStep#artifacts`
and introduced a temporary `is_a?(String)` guard in `WorkflowArtifactsPerStepComponent`
to keep the app working during the migration window. It also added a rake task
(`data:backfill:fix_workflow_artifacts_double_encoding`) to rewrite existing
double-encoded rows.

## This PR

Ops has confirmed the rake task has been run in all environments. All rows now
store a single-encoded JSON object, so `serialize :artifacts, coder: JSON`
always deserializes to a `Hash`. This PR removes all transition code that was
explicitly marked as temporary.

## Changes

- **`WorkflowArtifactsPerStepComponent`** — simplifies `parsed_artifacts`
  assignment back to `artifacts.deep_symbolize_keys`.
- **`workflow_artifacts_per_step_component_spec.rb`** — deleted; both contexts
  existed solely to test the transition behaviour.
- **`data_backfill.rake`** — removes the `fix_workflow_artifacts_double_encoding`
  task; it has served its purpose and is no longer needed.

Assisted-by: OpenCode:claude-sonnet-4-6@default
EOF
)"
```

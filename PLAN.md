# Plan: Dynamic Distro Releases Timeline & OBS Styling

## Objectives
1. Remove Chartkick from `@src/api/app/views/webui/distros/show.html.haml`.
2. Render distro releases and their lifecycle/date ranges dynamically from `@distro.distro_releases` in the timeline table starting around line 37.
3. Adapt timeline styling to match OBS's design system, including proper light and dark mode support using Bootstrap 5 variables.
4. Write this plan into `PLAN.md`.

## Detailed Steps

### Step 1: Write `PLAN.md`
- Save this exact plan into `/home/ddonisa/src/work/open-build-service/PLAN.md`.

### Step 2: Analyze Data Structure for Distro Releases & Lifecycles
- Check what attributes `DistroRelease` and `DistroReleaseLifecycle` have for dates/lifecycles.
- If lifecycles have dates or if distro releases have dates, write helper logic in the view or model to calculate min/max years and bar positions.

### Step 3: Update `src/api/app/views/webui/distros/show.html.haml`
- Remove line 2: `content_for(:content_for_head, javascript_include_tag("//www.google.com/jsapi", "chartkick"))`
- Remove static `timeline` chart on lines 34-36.
- Replace static rows in the timeline table (lines 37-190) with dynamic iteration over `@distro.distro_releases`.

### Step 4: Update Styling in `src/api/app/assets/stylesheets/webui/distro-release.scss`
- Refactor hardcoded colors (`#fff`, `#f8f9fa`, `#e1e4e8`, `#212529`, etc.) to use CSS custom properties / Bootstrap 5 variables (`var(--bs-card-bg)`, `var(--bs-tertiary-bg)`, `var(--bs-border-color)`, `var(--bs-body-color)`, `var(--bs-secondary-color)`, etc.) to support both light and dark modes natively.

### Step 5: Verify and Test
- Run tests (`bundle exec rspec`) and linter (`rake dev:lint:all`).

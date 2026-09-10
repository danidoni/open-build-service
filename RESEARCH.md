# Research: Distro, Release, and Lifecycle Models in Open Build Service (OBS)

## Overview

Open Build Service (OBS) supports enhanced distribution management through three hierarchical models:
1. **Distro (`Distro`)**: Represents a Linux distribution family or product associated with a `Vendor`.
2. **Distro Release (`DistroRelease`)**: Represents a specific release version of a distro.
3. **Distro Release Lifecycle (`DistroReleaseLifecycle`)**: Represents milestones or phases in a release's lifecycle.

---

## 1. Data Models & Database Schema

### `Distro`
- **Table Name:** `distros`
- **Associations:**
  - `belongs_to :vendor`
  - `has_many :distro_releases, dependent: :destroy`
  - `has_one :project, through: :vendor`
- **Attributes:**
  - `name` (string, max 255, unique within vendor)
  - `description` (text)
  - `url` (string)
  - `vendor_id` (bigint)

### `DistroRelease`
- **Table Name:** `distro_releases`
- **Associations:**
  - `belongs_to :distro`
  - `has_many :distro_release_lifecycles, dependent: :destroy`
  - `has_many :distro_release_repository_architectures, dependent: :destroy`
  - `has_many :repository_architectures, through: :distro_release_repository_architectures`
- **Attributes:**
  - `name` (string)
  - `description` (text)
  - `url` (string)
  - `distro_id` (bigint)

### `DistroReleaseLifecycle`
- **Table Name:** `distro_release_lifecycles`
- **Associations:**
  - `belongs_to :distro_release`
- **Attributes:**
  - `name` (string)
  - `date` (date)
  - `status` (integer enum: `planned` [0], `active` [1], `ended` [2])
  - `distro_release_id` (bigint)

---

## 2. Believable openSUSE Examples

To illustrate how openSUSE distributions, releases, and lifecycles are modeled in OBS:

### Example 1: openSUSE Leap
- **Vendor:** openSUSE
- **Distro (`Distro`):**
  - `name`: "openSUSE Leap"
  - `description`: "Regular enterprise-based Linux distribution for desktop and server."
  - `url`: "https://www.opensuse.org/#leap"
- **Distro Releases (`DistroRelease`):**
  1. `name`: "openSUSE Leap 15.5"
     - `description`: "Leap 15.5 minor release based on SLE 15 SP5."
     - `url`: "https://get.opensuse.org/leap/15.5/"
     - **Lifecycles (`DistroReleaseLifecycle`):**
       - General Availability: `Date.new(2023, 5, 31)` (Status: `ended`)
       - End of Life (EOL): `Date.new(2024, 12, 31)` (Status: `ended`)
  2. `name`: "openSUSE Leap 15.6"
     - `description`: "Leap 15.6 minor release based on SLE 15 SP6."
     - `url`: "https://get.opensuse.org/leap/15.6/"
     - **Lifecycles (`DistroReleaseLifecycle`):**
       - General Availability: `Date.new(2024, 6, 12)` (Status: `active`)
       - End of Life (EOL): `Date.new(2025, 12, 31)` (Status: `planned`)

### Example 2: openSUSE Tumbleweed
- **Vendor:** openSUSE
- **Distro (`Distro`):**
  - `name`: "openSUSE Tumbleweed"
  - `description`: "Rolling release distribution containing the latest up-to-date packages."
  - `url`: "https://www.opensuse.org/#tumbleweed"
- **Distro Releases (`DistroRelease`):**
  1. `name`: "Tumbleweed Snapshot"
     - `description`: "Continuous rolling snapshots."
     - `url`: "https://get.opensuse.org/tumbleweed/"
     - **Lifecycles (`DistroReleaseLifecycle`):**
       - Inception / Launch: `Date.new(2014, 11, 4)` (Status: `active`)


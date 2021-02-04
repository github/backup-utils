# Making a Backup Utilities release

Starting with Backup Utilities v2.13.0, all major releases will follow GitHub Enterprise releases and the version support is inline with that of the [GitHub Enterprise upgrade requirements](https://help.github.com/enterprise/admin/guides/installation/about-upgrade-requirements/) and as such, support is limited to three versions of GitHub Enterprise: the version that corresponds with the version of Backup Utilities, and the two releases prior to it.

For example, Backup Utilities 2.13.0 can be used to backup and restore all patch releases from 2.11.0 to the latest patch release of GitHub Enterprise 2.13. Backup utilities 2.14.0 will be released when GitHub Enterprise 2.14.0 is released and will then be used to backup all releases of GitHub Enterprise from 2.12.0 to the latest patch release of GitHub Enterprise 2.14.

There is no need to align Backup Utilities patch releases with GitHub Enterprise patch releases.

When making a `.0` release, you will need to specify the minimum supported version of GitHub Enterprise that that release supports.

## Automatic Process from chatops (internal to GitHub only) - Coming :soon:

### Feature release:

`.ghe backup-utils-release 2.13.0 2.11.0`

### Patch release:

`.ghe backup-utils-release 2.13.1`

## Automatic Process from CLI

1. Install the Debian `devscripts` package:
  `sudo apt-get install devscripts`
2. Run...
  - Feature release:  
  `GH_AUTHOR="Bob Smith <bob@example.com>" GH_RELEASE_TOKEN=your-amazing-secure-token script/release 2.13.0 2.11.0`
  - Patch release:  
  `GH_AUTHOR="Bob Smith <bob@example.com>" GH_RELEASE_TOKEN=your-amazing-secure-token script/release 2.13.1`

## Manual Process

In the event you can't perform the automatic process, or a problem is encountered with the automatic process, these are the manual steps you need to perform for a release.

1. Install the Debian `devscripts` package:
  `sudo apt-get install devscripts`
2. Add a new version and release notes to the `debian/changelog` file:
  `dch --newversion 2.13.0 --release-heuristic log`
  You can use `make pending-prs` to craft the release notes.
3. Rev the `share/github-backup-utils/version` file. If this is a feature release, update `supported_minimum_version=` in `bin/ghe-host-check` too.
4. Commit your changes.
5. Tag the release: `git tag v2.13.0`
6. Build that tarball package: `make dist`
7. Build the deb package: `make deb`. All the tests should pass.
8. Draft a new release at https://github.com/github/backup-utils/releases, including the release notes and attaching the tarball and deb packages.
  The dist tarball you should upload has the revision in the file name, i.e. something like `github-backup-utils-v2.13.0.tar.gz`
9. Push the head of the release to the 'stable' branch.

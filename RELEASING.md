# Making a backup-utils release

## Automatic Process from chatops (internal to GitHub only)

1. `.ghe backup-utils-release 2.12.0`

## Automatic Process from CLI

1. Install the Debian `devscripts` package:
  `sudo apt-get install devscripts`
2. Run `GH_AUTHOR="Bob Smith <bob@example.com>" GH_RELEASE_TOKEN=your-amazing-secure-token script/release 2.12.0`

## Manual Process

In the event you can't perform the automatic process, or a problem is encountered with the automatic process, these are the manual steps you need to perform for a release.

1. Install the Debian `devscripts` package:
  `sudo apt-get install devscripts`
2. Add a new version and release notes to the `debian/changelog` file:
  `dch --newversion 2.12.0 --release-heuristic log`
  You can use `make pending-prs` to craft the release notes.
3. Rev the `share/github-backup-utils/version` file.
4. Tag the release: `git tag v2.12.0`
5. Build that tarball package: `make dist`
6. Build the deb package: `make deb`. All the tests should pass.
7. Draft a new release at https://github.com/github/backup-utils/releases, including the release notes and attaching the tarball and deb packages.
  The dist tarball you should upload has the revision in the file name, i.e. something like `github-backup-utils-v2.12.0.tar.gz`
8. Push the head of the release to the 'stable' branch.

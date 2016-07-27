# Making a backup-utils release

 1. Install the debian devscripts package:
    `sudo apt-get install devscripts`
 2. Add a new version and release notes to the `debian/changelog` file:
    `dch --newversion 2.6.0 --release-heuristic log`
    You can use `make pending-prs` to craft the release notes.
 3. Rev the `share/github-backup-utils/version` file.
 4. Tag the release: `git tag v2.0.2`
 5. Build that tarball package: `make dist`
 6. Build the deb package: `make deb`. All the tests should pass.
 7. Draft a new release at https://github.com/github/backup-utils/releases, including the release notes and attaching the tarball and deb packages.
    The dist tarball you should upload has the git revision in the file name, i.e. something like `github-backup-utils-v2.5.0-1-g23c41cc.tar.gz`
 8. Push the head of the release to the 'stable' branch.

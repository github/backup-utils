# Making a backup-utils release

 1. Add a new version and release notes to the `debian/changelog` file:
    `dch --newversion 2.6.0 --release-heuristic log`
 2. Rev the `share/github-backup-utils/version` file.
 3. Tag the release: `git tag v2.0.2`
 4. Build that tarball package: `make dist`
 5. Build the deb package: `make deb`. All the tests should pass.
 6. Draft a new release at https://github.com/github/backup-utils/releases, including the release notes and attaching the tarball and deb packages.
    The dist tarball you should upload has the git revision in the file name, i.e. something like `github-backup-utils-v2.5.0-1-g23c41cc.tar.gz`
 7. Push the head of the release to the 'stable' branch.

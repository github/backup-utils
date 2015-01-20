# Making a backup-utils release

 1. Add a new version and release notes to the `debian/changelog` file.
 2. Rev the `share/github-backup-utils/version` file.
 3. Tag the release: `git tag v2.0.2`
 4. Build that tarball package: `make dist`
 5. Install the debian devscripts package if necessary:
    `sudo apt-get install devscripts`
 6. Build the deb package: `debuild -uc -us`
 7. Draft a new release at https://github.com/github/backup-utils/releases,
    including the release notes and attaching the tarball and deb packages.
 8. Push the head of the release to the 'stable' branch.

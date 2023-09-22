<!-- Welcome to backup-utils-private repo and Thanks for contributing!

Note: Merging to the master branch will include your change in a future (unreleased) version of backup-utils. If the change needs to be shipped to the current release versions it will need to be backported. For more information, see the backport guide https://github.com/github/enterprise-releases/blob/master/docs/backport-an-existing-pr.md

If you have any questions we can be found in the #ghes-backup-utils Slack channel.
-->

<!--
Additional notes regarding CI:
- All required CIs needs to be pass before merging PR
- Integration test will run against enterprise2 repo with environment variable, do not re-run directly from janky or Github CI, please use Actions to re-run the failed tests
- If you are making changes impacts cluster, please add `cluster` label or `[cluster]` in your PR title so it will trigger optional cluster integration test. Those tests will take about 3 hours so relax and come back later to check the results. ;)
-->

# PR Details

### Description
<!--
[Please fill out a brief description of the change being made]
-->
### Testing
<!--
[Please add testing done as part of this change.] 
-->
<!-- Keep in mind that for backup-utils the following applies:
- Backup-util [current version] will support
   - GHES [current version]
   - GHES [current version -1]
   - GHES [current version -2]
- Any changes that are made to backup-utils will also need to be supported on those GHES versions above (n-2)
- Please make sure those versions are tested against for this change 
-->

### Ownership
<!-- [Add any relevants owners for this change]
-->

### Related Links
<!-- [Please add any related links/issues to this PR]
-->

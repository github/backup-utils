SHELL = /bin/sh

test: info
	@script/cibuild --no-package

info:
	@echo This is github/backup-utils
	@echo shell is $(shell ls -l $(SHELL) | sed 's@.*/bin/sh@/bin/sh@')
	@rsync --version | head -1
	@echo

dist:
	@script/package-tarball

deb:
	@script/package-deb

clean:
	rm -rf dist

# List pull requests that need to be merged into stable
# (helpful for the release notes)
pending-prs:
	@git log stable...master | grep "Merge pull request"

.PHONY: test info dist clean pending-prs

SHELL = /bin/sh

test: info
	@echo "Running tests ..."
	@ls -1 test/test-*.sh | xargs -P 4 -n 1 $(SHELL)

info:
	@echo This is github/backup-utils
	@echo shell is $(shell ls -l $(SHELL) | sed 's@.*/bin/sh@/bin/sh@')
	@rsync --version | head -1
	@echo

.PHONY: test info

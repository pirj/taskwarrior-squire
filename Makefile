PREFIX ?= $(HOME)/.local
SHARE = $(PREFIX)/share/taskwarrior-squire
# Where the installed files are found at run time; Homebrew passes its opt path.
RUNTIME ?= $(SHARE)

install:
	mkdir -p $(PREFIX)/bin $(SHARE)/hooks $(SHARE)/tui $(PREFIX)/share/man/man7
	sed 's|@SHARE@|$(RUNTIME)|g' taskrc.in > $(SHARE)/taskrc
	sed 's|@SHARE@|$(RUNTIME)|g' tui/taskrc.in > $(SHARE)/tui/taskrc
	cp tui/hand $(SHARE)/tui/approve
	for move in reject postpone back; do ln -sf approve $(SHARE)/tui/$$move; done
	sed 's|@SHARE@|$(RUNTIME)|g' squire.in > $(PREFIX)/bin/squire
	chmod +x $(PREFIX)/bin/squire
	cp mine SKILL.md $(SHARE)/
	cp hooks/on-modify.squire $(SHARE)/hooks/on-modify.squire
	ln -sf on-modify.squire $(SHARE)/hooks/on-add.squire
	cp man/taskwarrior-squire.7 $(PREFIX)/share/man/man7/

uninstall:
	rm -rf $(SHARE) $(PREFIX)/bin/squire $(PREFIX)/share/man/man7/taskwarrior-squire.7

test:
	test/run.sh

.PHONY: install uninstall test

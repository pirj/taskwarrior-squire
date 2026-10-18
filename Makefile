PREFIX ?= $(HOME)/.local
SHARE = $(PREFIX)/share/taskwarrior-squire

install:
	mkdir -p $(SHARE)/hooks $(PREFIX)/share/man/man7
	sed 's|@SHARE@|$(SHARE)|g' taskrc.in > $(SHARE)/taskrc
	cp mine $(SHARE)/mine
	cp hooks/on-modify.squire $(SHARE)/hooks/on-modify.squire
	ln -sf on-modify.squire $(SHARE)/hooks/on-add.squire
	cp man/taskwarrior-squire.7 $(PREFIX)/share/man/man7/

uninstall:
	rm -rf $(SHARE) $(PREFIX)/share/man/man7/taskwarrior-squire.7

test:
	test/run.sh

.PHONY: install uninstall test

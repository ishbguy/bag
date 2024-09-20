.PHONY: all
all: test
	for dir in $^; do make -C $$dir; done

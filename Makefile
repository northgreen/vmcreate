.PHONY: check examples clean

check:
	mkdir -p build/test-results
	cd build/test-results && DEJAGNU="$(CURDIR)/testsuite/site.exp" runtest --tool vmcreate --srcdir ../..

examples:
	bash ./generate-boot.sh examples/ubuntu.m4 build/ubuntu/boot.sh
	bash ./generate-boot.sh examples/windows.m4 build/windows/boot.sh
	bash ./generate-boot.sh examples/freedos.m4 build/freedos/boot.sh
	bash ./generate-boot.sh examples/server.m4 build/server/boot.sh

clean:
	rm -rf build

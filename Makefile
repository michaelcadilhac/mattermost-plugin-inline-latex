.PHONY: build test run clean stop check-style gofmt dist localdeploy

GOOS=$(shell uname -s | tr '[:upper:]' '[:lower:]')
GOARCH=amd64

check-style: gofmt
	@echo Checking for style guide compliance

	cd webapp && npm run check

gofmt:
	@echo Running GOFMT

	@for package in $$(go list ./server/...); do \
		echo "Checking "$$package; \
		files=$$(go list -f '{{range .GoFiles}}{{$$.Dir}}/{{.}} {{end}}' $$package); \
		if [ "$$files" ]; then \
			gofmt_output=$$(gofmt -d -s $$files 2>&1); \
			if [ "$$gofmt_output" ]; then \
				echo "$$gofmt_output"; \
				echo "gofmt failure"; \
				exit 1; \
			fi; \
		fi; \
	done
	@echo "gofmt success"; \

webapp/.npminstall:
	@echo Getting dependencies using npm

	cd webapp && npm install
	touch $@

dist: plugin.json
	@echo Building plugin

	# Clean old dist
	rm -rf dist
	rm -f server/plugin.exe

	# Build files from server
	cd server && go get github.com/mitchellh/gox
	$(shell go env GOPATH)/bin/gox -osarch='darwin/amd64 linux/amd64 windows/amd64' -output 'dist/intermediate/plugin_{{.OS}}_{{.Arch}}' ./server

	mkdir -p dist/inline-latex/

	# Copy plugin files
	cp plugin.json dist/inline-latex/

	# Copy server executables & compress plugin
	mkdir -p dist/inline-latex/server
	mv dist/intermediate/plugin_linux_amd64 dist/inline-latex/server/plugin.exe
	cd dist && tar -zcvf mattermost-inline-latex-plugin-linux-amd64.tar.gz inline-latex/*
	mv dist/intermediate/plugin_windows_amd64.exe dist/inline-latex/server/plugin.exe
	cd dist && tar -zcvf mattermost-inline-latex-plugin-windows-amd64.tar.gz inline-latex/*
	mv dist/intermediate/plugin_darwin_amd64 dist/inline-latex/server/plugin.exe
	cd dist && tar -zcvf mattermost-inline-latex-plugin-darwin-amd64.tar.gz inline-latex/*

	# Clean up temp files
	rm -rf dist/inline-latex
	rm -rf dist/intermediate

	@echo Linux plugin built at: dist/mattermost-inline-latex-plugin-linux-amd64.tar.gz
	@echo MacOS X plugin built at: dist/mattermost-inline-latex-plugin-darwin-amd64.tar.gz
	@echo Windows plugin built at: dist/mattermost-inline-latex-plugin-windows-amd64.tar.gz

localdeploy: dist
	cp dist/mattermost-inline-latex-plugin-$(GOOS)-$(GOARCH).tar.gz ../mattermost-server/plugins/
	rm -rf ../mattermost-server/plugins/inline-latex
	tar -C ../mattermost-server/plugins/ -zxvf ../mattermost-server/plugins/mattermost-inline-latex-plugin-$(GOOS)-$(GOARCH).tar.gz

stop:
	@echo Not yet implemented

clean:
	@echo Cleaning plugin

	rm -rf dist
	rm -rf webapp/dist
	rm -rf webapp/node_modules
	rm -rf webapp/.npminstall
	rm -f server/plugin.exe

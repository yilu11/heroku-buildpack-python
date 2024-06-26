# These targets are not files
.PHONY: lint lint-scripts lint-ruby compile publish

STACK ?= heroku-24
FIXTURE ?= spec/fixtures/python_version_unspecified

# Converts a stack name of `heroku-NN` to its build Docker image tag of `heroku/heroku:NN-build`.
STACK_IMAGE_TAG := heroku/$(subst -,:,$(STACK))-build

lint: lint-scripts lint-ruby

# TODO: Enable scanning for files that are currently missed and/or restructure repo
# layout to make it more viable to use wildcards here, given:
# https://github.com/koalaman/shellcheck/issues/962
lint-scripts:
	@shellcheck -x bin/compile bin/detect bin/release bin/test-compile bin/utils bin/warnings bin/default_pythons
	@shellcheck -x bin/steps/collectstatic bin/steps/nltk bin/steps/pip-install bin/steps/pipenv bin/steps/pipenv-python-version bin/steps/python
	@shellcheck -x bin/steps/hooks/*
	@shellcheck -x vendor/WEB_CONCURRENCY.sh
	@shellcheck -x builds/*.sh

lint-ruby:
	@bundle exec rubocop

compile:
	@echo "Running compile using: STACK=$(STACK) FIXTURE=$(FIXTURE)"
	@echo
	@docker run --rm -it --user root -v $(PWD):/src:ro -e "STACK=$(STACK)" -w /buildpack "$(STACK_IMAGE_TAG)" \
		bash -c 'cp -r /src/{bin,requirements,vendor} /buildpack && cp -r /src/$(FIXTURE) /build && mkdir /cache /env && bin/compile /build /cache /env'
	@echo

publish:
	@etc/publish.sh

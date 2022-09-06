PACTICIPANT ?= "realworld-openapi-spec"

## ====================
## Pactflow Provider Publishing
## ====================
PACT_CLI="docker run --rm -v ${PWD}:/app -w "/app" -e PACT_BROKER_BASE_URL -e PACT_BROKER_TOKEN pactfoundation/pact-cli"
OAS_FILE_PATH?=api/openapi.yml
OAS_FILE_CONTENT_TYPE?=application/yaml
REPORT_FILE_PATH?=api/README.md
REPORT_FILE_CONTENT_TYPE?=text/markdown
VERIFIER_TOOL?=newman

# Export all variable to sub-make if .env exists
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

default:
	cat ./Makefile

ci: ci-test publish_pacts can_i_deploy

# Run the ci target from a developer machine with the environment variables
# set as if it was on CI.
# Use this for quick feedback when playing around with your workflows.
fake_ci:
	@CI=true \
	GIT_COMMIT=`git rev-parse --short HEAD` \
	GIT_BRANCH=`git rev-parse --abbrev-ref HEAD` \
	make ci

## =====================
## Build/test tasks
## =====================

ci-test:
	@echo "\n========== STAGE: CI Tests ==========\n"

## =====================
## Pact tasks
## =====================

publish_pacts:
	@echo "\n========== STAGE: publish provider contract (spec + results) - success ==========\n"
	PACTICIPANT=${PACTICIPANT} \
	"${PACT_CLI}" pactflow publish-provider-contract \
	/app/${OAS_FILE_PATH} \
	--provider ${PACTICIPANT} \
	--provider-app-version ${GIT_COMMIT} \
	--branch ${GIT_BRANCH} \
	--content-type ${OAS_FILE_CONTENT_TYPE} \
	--verification-exit-code=0 \
	--verification-results /app/${REPORT_FILE_PATH} \
	--verification-results-content-type ${REPORT_FILE_CONTENT_TYPE} \
	--verifier ${VERIFIER_TOOL}

deploy: deploy_app record_deployment

can_i_deploy:
	@echo "\n========== STAGE: can-i-deploy? 🌉 ==========\n"
	"${PACT_CLI}" broker can-i-deploy --pacticipant ${PACTICIPANT} --version ${GIT_COMMIT} --to-environment test

deploy_app:
	@echo "\n========== STAGE: deploy ==========\n"
	@echo "Deploying to test"

record_deployment:
	"${PACT_CLI}" broker record-deployment --pacticipant ${PACTICIPANT} --version ${GIT_COMMIT} --environment test

## =====================
## Misc
## =====================

.env:
	cp -n .env.example .env || true

#-*- mode: makefile; -*-
# Project-specific targets for Amazon::Lambda::Runtime
# Included automatically by .includes/perl.mk via: -include project.mk

DEBIAN_RELEASE    ?= trixie
PERL_VERSION_FILE  = .debian-$(DEBIAN_RELEASE)-perl-version
PERL_VERSION       = $(shell cat $(PERL_VERSION_FILE) 2>/dev/null)
ALR_BASE_IMAGE     = perl-lambda-base
ALR_BASE_TAG       = $(PERL_VERSION)-debian-$(DEBIAN_RELEASE)

ECR_REGION        ?= us-east-1

########################################################################
$(PERL_VERSION_FILE): docker/Dockerfile
########################################################################
	$(NO_ECHO)echo "Detecting Perl version in debian:$(DEBIAN_RELEASE)..."; \
	version=$$(docker run --rm debian:$(DEBIAN_RELEASE) /bin/bash -c \
	    "apt-get update -qq && apt-get install -y -qq perl && perl -e 'printf \"%vd\", \$$^V'" \
	    | tail -1 | cut -d. -f1,2); \
	test -z "$$version" && { \
	    echo "ERROR: could not detect Perl version" >&2; exit 1; \
	}; \
	echo "$$version" > $@; \
	echo "Perl version: $$version"

.PHONY: alr-base
alr-base: cpanfile $(PERL_VERSION_FILE) ## build and push the alr-base Lambda runtime image (maintainer only)
	$(NO_ECHO)test -n "$$(command -v alr-helper)" || { \
	    echo "ERROR: alr-helper not found - install Amazon::Lambda::Runtime::Builder" >&2; exit 1; \
	}; \
	test -e docker/Dockerfile || { \
	    echo "ERROR: docker/Dockerfile not found" >&2; exit 1; \
	}; \
	test -z "$(PERL_VERSION)" && { \
	    echo "ERROR: $(PERL_VERSION_FILE) not found - run make $(PERL_VERSION_FILE)" >&2; exit 1; \
	}; \
	ecr_uri=$$(alr-helper describe-repositories $(ALR_BASE_IMAGE) filter=repositories[0].repositoryUri 2>/dev/null); \
	if [[ -z "$$ecr_uri" ]]; then \
	    ecr_uri=$$(alr-helper create-repository $(ALR_BASE_IMAGE) filter=repository.repositoryUri); \
	fi; \
	test -z "$$ecr_uri" && { \
	    echo "ERROR: could not determine ECR URI for $(ALR_BASE_IMAGE)" >&2; exit 1; \
	}; \
	cp cpanfile docker/cpanfile; \
	docker build \
	    -t $(ALR_BASE_IMAGE):$(ALR_BASE_TAG) \
	    -t $(ALR_BASE_IMAGE):latest \
	    -f docker/Dockerfile docker/ || { rm -f docker/cpanfile; exit 1; }; \
	rm -f docker/cpanfile; \
	docker tag $(ALR_BASE_IMAGE):latest          $$ecr_uri:latest; \
	docker tag $(ALR_BASE_IMAGE):$(ALR_BASE_TAG) $$ecr_uri:$(ALR_BASE_TAG); \
	docker push $$ecr_uri:latest; \
	docker push $$ecr_uri:$(ALR_BASE_TAG); \
	echo "Pushed $(ALR_BASE_IMAGE):$(ALR_BASE_TAG)"

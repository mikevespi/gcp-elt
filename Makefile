# Taken from cas-cif and modified. [Source code](https://github.com/bcgov/cas-cif)
# cff321ce09b65098ebd9541c0a37eb6970ef4263

SHELL := /usr/bin/env bash
__FILENAME := $(lastword $(MAKEFILE_LIST))
__DIRNAME := $(abspath $(realpath $(lastword $(MAKEFILE_LIST)))/../)
PERL=perl
PERL_VERSION=${shell ${PERL} -e 'print substr($$^V, 1)'}
PERL_MIN_VERSION=5.10
PSQL=psql -h localhost
CPAN=cpan
# CPANM home has to be in the current directory, so that it can find the
# pg_config executable, installed via asdf
CPANM=PERL_CPANM_HOME=$(__DIRNAME)/.cpanm cpanm --notest
SQITCH=sqitch
SQITCH_VERSION=${word 3,${shell ${SQITCH} --version}}
SQITCH_MIN_VERSION=1.1.0
DB_NAME=dem
PG_PROVE=pg_prove -h localhost
PGTAP_VERSION=1.2.0

help: ## Show this help.
	@sed -ne '/@sed/!s/## //p' $(MAKEFILE_LIST)

.PHONY: install_asdf_tools
install_asdf_tools: ## install languages runtimes and tools specified in .tool-versions
install_asdf_tools:
	@cat .tool-versions | cut -f 1 -d ' ' | xargs -n 1 asdf plugin-add || true
	@asdf plugin-update --all
	@#MAKELEVEL=0 is required because of https://www.postgresql.org/message-id/1118.1538056039%40sss.pgh.pa.us
	@MAKELEVEL=0 POSTGRES_EXTRA_CONFIGURE_OPTIONS='--with-libxml' asdf install
	@asdf reshim
	@pip install -r requirements.txt
	@asdf reshim

.PHONY: install_pgtap
install_pgtap: ## install pgTAP extension into postgres
install_pgtap: start_pg
install_pgtap:
	@$(PSQL) -d postgres -tc "select count(*) from pg_available_extensions where name='pgtap' and default_version='$(PGTAP_VERSION)';" | \
		grep -q 1 || \
		(git clone https://github.com/theory/pgtap.git --depth 1 --branch v$(PGTAP_VERSION) && \
		$(MAKE) -C pgtap && \
		$(MAKE) -C pgtap install && \
		$(MAKE) -C pgtap installcheck && \
		rm -rf pgtap)

.PHONY: install_cpanm
install_cpanm: ## install the cpanm tool
install_cpanm:
ifeq ($(shell which $(word 2,$(CPANM))),)
	# install cpanm
	@$(CPAN) App::cpanminus
endif

.PHONY: install_cpandeps
install_cpandeps: ## install Perl dependencies from cpanfile
install_cpandeps:
	@$(CPANM) --installdeps .
	@rm -rf $(__DIRNAME)/.cpanm

.PHONY: postinstall_check
postinstall_check: ## check that the installation was successful and that the correct sqitch version is available in the PATH
postinstall_check:
	@printf '%s\n%s\n' "${SQITCH_MIN_VERSION}" "${SQITCH_VERSION}" | sort -CV ||\
 	(echo "FATAL: sqitch version should be at least ${SQITCH_MIN_VERSION}. Make sure the sqitch executable installed by cpanminus is available has the highest priority in the PATH" && exit 1);

.PHONY: install_perl_tools
install_perl_tools: ## install cpanm and sqitch
install_perl_tools: install_cpanm install_cpandeps postinstall_check

.PHONY: install_dev_tools
install_dev_tools: ## install development tools
install_dev_tools: stop_pg install_asdf_tools install_perl_tools install_pgtap

.PHONY: start_pg
start_pg: ## start the database server if it is not running
start_pg:
	@pg_ctl status || pg_ctl start

.PHONY: stop_pg
stop_pg: ## stop the database server. Always exits with 0
stop_pg:
	@pg_ctl stop; true

.PHONY: create_db
create_db: ## Ensure that the $(DB_NAME) database exists
create_db:
	@$(PSQL) -d postgres -tc "SELECT count(*) FROM pg_database WHERE datname = '$(DB_NAME)'" | \
		grep -q 1 || \
		$(PSQL) -d postgres -c "CREATE DATABASE $(DB_NAME)" && \
		$(PSQL) -d $(DB_NAME) -c "create extension if not exists pgtap";

.PHONY: drop_db
drop_db: ## Drop the $(DB_NAME) database if it exists
drop_db:
	@$(PSQL) -d postgres -tc "SELECT count(*) FROM pg_database WHERE datname = '$(DB_NAME)'" | \
		grep -q 0 || \
		$(PSQL) -d postgres -c "DROP DATABASE $(DB_NAME)";

.PHONY: create_test_db
create_test_db: ## Ensure that the $(DB_NAME)_test database exists
create_test_db:
	@$(PSQL) -d postgres -tc "SELECT count(*) FROM pg_database WHERE datname = '$(DB_NAME)_test'" | \
		grep -q 1 || \
		$(PSQL) -d postgres -c "CREATE DATABASE $(DB_NAME)_test" &&\
		$(PSQL) -d $(DB_NAME)_test -c "create extension if not exists pgtap";

.PHONY: drop_test_db
drop_test_db: ## Drop the $(DB_NAME)_test database if it exists
drop_test_db:
	@$(PSQL) -d postgres -tc "SELECT count(*) FROM pg_database WHERE datname = '$(DB_NAME)_test'" | \
		grep -q 0 || \
		$(PSQL) -d postgres -c "DROP DATABASE $(DB_NAME)_test";

.PHONY: deploy_db_migrations
deploy_db_migrations: ## deploy the database migrations with sqitch
deploy_db_migrations: start_pg create_db
deploy_db_migrations:
	@$(SQITCH) --chdir db deploy

deploy_dev_data: ## deploy the database migrations with sqitch and load the data for local development
deploy_dev_data: deploy_db_migrations
deploy_dev_data:
	@for file in $(__DIRNAME)/db/data/dev/*; do \
		$(PSQL) -d $(DB_NAME) -f "$${file}"; \
	done;

.PHONY: revert_db_migrations
revert_db_migrations: ## revert the database migrations with sqitch
revert_db_migrations: start_pg
revert_db_migrations:
	@$(SQITCH) --chdir db revert

.PHONY: deploy_test_db_migrations
deploy_test_db_migrations: ## deploy the test database migrations with sqitch
deploy_test_db_migrations: start_pg create_test_db
deploy_test_db_migrations:
	@SQITCH_TARGET="db:pg:" PGHOST=localhost PGDATABASE=$(DB_NAME)_test $(SQITCH) --chdir db deploy

.PHONY: revert_test_db_migrations
revert_test_db_migrations: ## revert the test database migrations with sqitch
revert_test_db_migrations: start_pg
revert_test_db_migrations:
	@SQITCH_TARGET="db:pg:" PGHOST=localhost PGDATABASE=$(DB_NAME)_test $(SQITCH) --chdir db revert

.PHONY: db_unit_tests
db_unit_tests: ## run the database unit tests
db_unit_tests: | start_pg drop_test_db create_test_db deploy_test_db_migrations
db_unit_tests:
	@$(PG_PROVE) --failures -d $(DB_NAME)_test db/test/unit/**/*_test.sql

.PHONY: db_style_tests
db_style_tests: ## run the database style tests
db_style_tests: | start_pg deploy_test_db_migrations
db_style_tests:
	@$(PG_PROVE) --failures -d $(DB_NAME)_test db/test/style/*_test.sql --set schemas_to_test=dem,dem_private

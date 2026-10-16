.PHONY: help validate index bundle dashboard verify serve mcp rag test clean

help:
	@echo "A Book Of Life To Rebuild The World"
	@echo ""
	@echo "  make validate    Validate all sidecars + field tests"
	@echo "  make index       Build the hybrid search index"
	@echo "  make bundle      Build the offline HTML + ZIM bundle"
	@echo "  make dashboard   Build the verification dashboard"
	@echo "  make verify      Advance a verification state (see scripts/verify.py)"
	@echo "  make serve       Run the local API server"
	@echo "  make mcp         Run the MCP server (stdio)"
	@echo "  make rag         Query the RAG layer"
	@echo "  make test        Run the full test suite"
	@echo "  make clean       Remove build artifacts"

validate:
	python scripts/validate.py
	python scripts/validate_field_tests.py

index:
	python scripts/build_index.py

bundle:
	python scripts/build_zim.py

dashboard:
	python scripts/dashboard.py

verify:
	@echo "Usage: python scripts/verify.py show <entry_id>"
	@echo "       python scripts/verify.py advance <entry_id> --to <status> --actor <you>"

serve:
	python scripts/serve.py

mcp:
	python scripts/mcp_server.py

rag:
	@echo "Usage: python scripts/rag.py \"your question\""

test:
	pytest -v

clean:
	rm -rf build/ __pycache__/ .pytest_cache/ scripts/__pycache__/ tests/__pycache__/

.PHONY: models media i18n variants simulators enrich

models:
	python scripts/build_models.py

media:
	python scripts/build_media.py

i18n:
	python scripts/validate_i18n.py
	python scripts/build_i18n.py

variants:
	python scripts/build_variants.py

simulators:
	@ls simulators/*.html 2>/dev/null | wc -l | xargs echo "Simulators found:"

enrich: models media i18n variants simulators
	@echo "Phase 4 enrichment complete."

.PHONY: sdk-python-test sdk-ts-test sdk-rust-test federation-identity federation-manifest federation-sync state-of-the-book

sdk-python-test:
	cd sdk/python && pip install -e ".[dev]" && pytest -v

sdk-ts-test:
	cd sdk/typescript && npm install && npm run build && npm test

sdk-rust-test:
	cd sdk/rust && cargo build && cargo test

federation-identity:
	python scripts/federation.py identity

federation-manifest:
	python scripts/federation.py manifest

federation-sync:
	python scripts/federation.py sync

state-of-the-book:
	python scripts/state_of_the_book.py --year $(shell date +%Y)

.PHONY: audit archive backup-verify survey-render bump-version

audit:
	python scripts/audit_deps.py

archive:
	python scripts/archive.py --target all

backup-verify:
	python scripts/backup_verify.py

survey-render:
	python scripts/survey.py render survey-2026

bump-version:
	@echo "Usage: make bump-version VERSION=1.1.0"
	@test -n "$(VERSION)" || (echo "VERSION required" && exit 1)
	python scripts/bump_version.py $(VERSION)

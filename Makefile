# Makefile for NYC Education Analytics Project
# 
# Workflow: Edit .org files -> Export to .qmd -> Render with Quarto
# ============================================================

.PHONY: all qmd render preview clean setup help renv-init renv-restore renv-snapshot renv-status renv-update

# Default target
all: qmd render

## --- Setup ---

setup: renv-restore ## Restore renv packages, install project packages, and verify Quarto
	@echo ""
	@echo "Installing project R packages..."
	Rscript -e "source('src/R/setup.R')"
	@echo ""
	@echo "Checking Quarto installation..."
	@which quarto || echo "Warning: Quarto not found. Install from https://quarto.org"
	@echo ""
	@echo "Setup complete!"

## --- renv Package Management ---

renv-init: ## Initialize renv (first time only)
	@echo "Initializing renv..."
	Rscript -e "if (!requireNamespace('renv', quietly = TRUE)) install.packages('renv'); renv::init()"
	@echo "renv initialized. Run 'make renv-snapshot' to save package state."

renv-restore: ## Restore packages from renv.lock
	@echo "Restoring R packages from renv.lock..."
	Rscript -e "renv::restore()"
	@echo "Package restore complete."

renv-snapshot: ## Save current package state to renv.lock
	@echo "Saving package state to renv.lock..."
	Rscript -e "renv::snapshot()"
	@echo "Snapshot complete."

renv-status: ## Check package status vs renv.lock
	@echo "Checking renv status..."
	Rscript -e "renv::status()"

renv-update: ## Update packages and snapshot
	@echo "Updating packages..."
	Rscript -e "renv::update(); renv::snapshot()"
	@echo "Update complete."

renv-install: ## Install a package (usage: make renv-install PKG=packagename)
	@if [ -z "$(PKG)" ]; then \
		echo "Usage: make renv-install PKG=packagename"; \
		exit 1; \
	fi
	@echo "Installing $(PKG)..."
	Rscript -e "renv::install('$(PKG)')"
	@echo "Run 'make renv-snapshot' to save changes."

## --- Export & Build ---

qmd: ## Convert org files to qmd (Emacs required)
	@echo "Converting .org to .qmd..."
	@if command -v emacs >/dev/null 2>&1; then \
		emacs --batch -l scripts/org-to-qmd.el 2>/dev/null; \
	else \
		echo "Emacs not found. Using pandoc fallback..."; \
		$(MAKE) qmd-pandoc; \
	fi

qmd-pandoc: ## Convert org files using pandoc (alternative)
	@echo "Converting .org to .qmd via pandoc..."
	@for f in org/*.org; do \
		base=$$(basename "$$f" .org); \
		echo "  $$f -> $$base.qmd"; \
		pandoc "$$f" -f org -t markdown -o "$$base.qmd" 2>/dev/null || echo "  (skipped)"; \
	done

render: ## Render Quarto website
	@echo "Rendering Quarto project..."
	quarto render

preview: ## Start Quarto preview server
	@echo "Starting preview server..."
	quarto preview

## --- Data ---

fetch-data: ## Fetch all datasets from NYC Open Data
	@echo "Fetching datasets..."
	Rscript -e "source('src/R/setup.R'); source('src/R/nyc_data.R'); \
		for(name in names(NYC_DATA)) { \
			tryCatch({ \
				fetch_dataset(NYC_DATA[[name]], cache_name=name); \
			}, error=function(e) message('Skipped: ', name)) \
		}"

clear-cache: ## Clear all cached data
	@echo "Clearing data cache..."
	rm -f data/*.parquet
	@echo "Cache cleared."

## --- R Analysis ---

run-analysis: ## Execute R code blocks from org files
	@echo "Running R analysis..."
	Rscript -e "source('src/R/setup.R'); \
		source('src/R/nyc_data.R'); \
		source('src/R/utils.R'); \
		# Add analysis scripts here"

## --- Cleaning ---

clean: ## Remove generated files
	@echo "Cleaning generated files..."
	rm -f *.qmd
	rm -rf docs/*
	rm -rf _freeze
	rm -f output/*.png
	@echo "Clean complete."

clean-all: clean clear-cache ## Remove all generated files and cache
	@echo "Full clean complete."

## --- Help ---

help: ## Show this help message
	@echo "NYC Education Analytics - Makefile Commands"
	@echo "============================================"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Typical workflow:"
	@echo "  1. Edit org/*.org files"
	@echo "  2. make qmd        # Export to .qmd"
	@echo "  3. make preview    # Preview locally"
	@echo "  4. make render     # Build final site"

# ==============================================================================
#  🍷 MLflow Wine Quality Predictor — Makefile
#  Repository : https://github.com/abdallahatefhatem-boop/mlflow-test
#  Tracking   : https://dagshub.com/abdallahatefhatem/mlflow-test.mlflow
# ==============================================================================

SHELL       := /bin/bash
PYTHON      := python3
VENV        := .venv
PIP         := $(VENV)/bin/pip
PYTHON_VENV := $(VENV)/bin/python
MLFLOW_PORT := 5000

# Default params (can be overridden: make run ALPHA=0.3 L1=0.7)
ALPHA    := 0.5
L1_RATIO := 0.5

# ── Colours ──────────────────────────────────────────────────────────────────
RESET  := \033[0m
BOLD   := \033[1m
GREEN  := \033[0;32m
CYAN   := \033[0;36m
YELLOW := \033[0;33m
RED    := \033[0;31m

define log
	@printf "$(CYAN)$(BOLD)[MLflow]$(RESET) $(1)\n"
endef

define success
	@printf "$(GREEN)$(BOLD)✔ $(1)$(RESET)\n"
endef

define warn
	@printf "$(YELLOW)$(BOLD)⚠ $(1)$(RESET)\n"
endef

# ==============================================================================
#  🎯 DEFAULT TARGET
# ==============================================================================
.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help message
	@printf "\n$(BOLD)🍷 MLflow Wine Quality Predictor$(RESET)\n"
	@printf "$(CYAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(RESET) %s\n", $$1, $$2}'
	@printf "\n$(YELLOW)Usage examples:$(RESET)\n"
	@printf "  make setup           — Install all dependencies\n"
	@printf "  make run             — Run the full pipeline\n"
	@printf "  make run ALPHA=0.3 L1_RATIO=0.7\n"
	@printf "  make experiments     — Grid search over hyperparams\n"
	@printf "  make ui              — Launch local MLflow UI\n"
	@printf "\n"

# ==============================================================================
#  📦 ENVIRONMENT SETUP
# ==============================================================================
.PHONY: venv
venv: ## Create Python virtual environment
	$(call log,Creating virtual environment...)
	@$(PYTHON) -m venv $(VENV)
	$(call success,Virtual environment created at $(VENV)/)

.PHONY: install
install: venv ## Install project dependencies
	$(call log,Installing dependencies...)
	@$(PIP) install --upgrade pip -q
	@$(PIP) install -r requirements.txt -q
	$(call success,Dependencies installed!)

.PHONY: setup
setup: install ## Full environment setup (venv + dependencies)
	$(call success,Environment ready! Activate with: source $(VENV)/bin/activate)

# ==============================================================================
#  🚀 PIPELINE EXECUTION
# ==============================================================================
.PHONY: run
run: ## Run training pipeline (usage: make run ALPHA=0.5 L1_RATIO=0.5)
	$(call log,Running ElasticNet pipeline with alpha=$(ALPHA) l1_ratio=$(L1_RATIO)...)
	@source $(VENV)/bin/activate && $(PYTHON_VENV) demo.py $(ALPHA) $(L1_RATIO)
	$(call success,Pipeline complete! Check results on DagsHub.)

.PHONY: dvc-run
dvc-run: ## Run full DVC reproducible pipeline
	$(call log,Running DVC pipeline...)
	@source $(VENV)/bin/activate && dvc repro
	$(call success,DVC pipeline complete!)

.PHONY: dvc-run-force
dvc-run-force: ## Force re-run entire DVC pipeline (ignore cache)
	$(call log,Force re-running DVC pipeline (no cache)...)
	@source $(VENV)/bin/activate && dvc repro --force
	$(call success,Force pipeline complete!)

# ==============================================================================
#  🧪 EXPERIMENTS & HYPERPARAMETER TUNING
# ==============================================================================
.PHONY: experiments
experiments: ## Run a grid of experiments with different hyperparameters
	$(call log,Running hyperparameter grid search...)
	@source $(VENV)/bin/activate && \
	for alpha in 0.1 0.3 0.5 0.7 0.9; do \
		for l1 in 0.1 0.3 0.5 0.7 0.9; do \
			printf "$(CYAN)  ▶ alpha=$$alpha  l1_ratio=$$l1$(RESET)\n"; \
			$(PYTHON_VENV) demo.py $$alpha $$l1; \
		done \
	done
	$(call success,Grid search complete! Check all runs on DagsHub.)

.PHONY: exp-run
exp-run: ## Run a DVC experiment (usage: make exp-run ALPHA=0.3 L1_RATIO=0.7)
	$(call log,Running DVC experiment: alpha=$(ALPHA) l1_ratio=$(L1_RATIO)...)
	@source $(VENV)/bin/activate && \
	dvc exp run --set-param demo.alpha=$(ALPHA) --set-param demo.l1_ratio=$(L1_RATIO)

.PHONY: exp-show
exp-show: ## Show all DVC experiments in a table
	$(call log,Showing experiment history...)
	@source $(VENV)/bin/activate && dvc exp show

.PHONY: exp-diff
exp-diff: ## Show diff between last two DVC experiments
	@source $(VENV)/bin/activate && dvc exp diff

# ==============================================================================
#  📊 MLFLOW UI
# ==============================================================================
.PHONY: ui
ui: ## Launch MLflow tracking UI on localhost:5000
	$(call log,Starting MLflow UI on http://localhost:$(MLFLOW_PORT) ...)
	@source $(VENV)/bin/activate && mlflow ui --port $(MLFLOW_PORT)

.PHONY: dagshub
dagshub: ## Open DagsHub MLflow dashboard in browser
	$(call log,Opening DagsHub MLflow dashboard...)
	@xdg-open https://dagshub.com/abdallahatefhatem/mlflow-test.mlflow 2>/dev/null || \
	 open https://dagshub.com/abdallahatefhatem/mlflow-test.mlflow 2>/dev/null || \
	 echo "Visit: https://dagshub.com/abdallahatefhatem/mlflow-test.mlflow"

# ==============================================================================
#  🔍 DVC UTILITIES
# ==============================================================================
.PHONY: dvc-dag
dvc-dag: ## Show the DVC pipeline DAG
	@source $(VENV)/bin/activate && dvc dag

.PHONY: dvc-status
dvc-status: ## Show DVC pipeline status (what needs to re-run)
	@source $(VENV)/bin/activate && dvc status

.PHONY: dvc-params
dvc-params: ## Show current DVC params
	@source $(VENV)/bin/activate && dvc params diff

.PHONY: dvc-metrics
dvc-metrics: ## Show current DVC metrics
	@source $(VENV)/bin/activate && dvc metrics show 2>/dev/null || \
	 printf "$(YELLOW)No DVC metrics file defined yet.$(RESET)\n"

# ==============================================================================
#  🔬 TESTING & CODE QUALITY
# ==============================================================================
.PHONY: test
test: ## Run all tests
	$(call log,Running tests...)
	@source $(VENV)/bin/activate && \
	$(PYTHON_VENV) -m pytest tests/ -v --tb=short 2>/dev/null || \
	printf "$(YELLOW)No tests directory found. Create tests/ to get started.$(RESET)\n"

.PHONY: lint
lint: ## Run code linting (flake8)
	$(call log,Running linter...)
	@source $(VENV)/bin/activate && \
	$(PYTHON_VENV) -m flake8 demo.py --max-line-length=120 2>/dev/null || \
	$(PIP) install flake8 -q && $(PYTHON_VENV) -m flake8 demo.py --max-line-length=120

.PHONY: format
format: ## Auto-format code with black
	$(call log,Formatting code with black...)
	@source $(VENV)/bin/activate && \
	$(PYTHON_VENV) -m black demo.py 2>/dev/null || \
	($(PIP) install black -q && $(PYTHON_VENV) -m black demo.py)
	$(call success,Code formatted!)

# ==============================================================================
#  🔁 GIT & CI/CD
# ==============================================================================
.PHONY: commit
commit: ## Stage all changes and commit (usage: make commit MSG="your message")
ifndef MSG
	$(call warn,Usage: make commit MSG="your commit message")
	@exit 1
endif
	$(call log,Committing: $(MSG))
	@git add -A
	@git commit -m "$(MSG)"
	$(call success,Committed!)

.PHONY: push
push: ## Push to remote (GitHub + DagsHub)
	$(call log,Pushing to GitHub...)
	@git push origin main
	$(call success,Pushed!)

.PHONY: status
status: ## Show git status and DVC status
	@printf "\n$(BOLD)── Git Status ──$(RESET)\n"
	@git status --short
	@printf "\n$(BOLD)── DVC Status ──$(RESET)\n"
	@source $(VENV)/bin/activate && dvc status 2>/dev/null || echo "DVC not configured"

# ==============================================================================
#  🧹 CLEANUP
# ==============================================================================
.PHONY: clean
clean: ## Remove Python caches and build artifacts
	$(call log,Cleaning up caches...)
	@find . -type d -name "__pycache__" -not -path "./.venv/*" -exec rm -rf {} + 2>/dev/null; true
	@find . -type f -name "*.pyc" -not -path "./.venv/*" -delete 2>/dev/null; true
	@find . -type d -name ".pytest_cache" -not -path "./.venv/*" -exec rm -rf {} + 2>/dev/null; true
	@find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null; true
	$(call success,Cache cleaned!)

.PHONY: clean-mlflow
clean-mlflow: ## Remove local mlruns directory
	$(call warn,This will delete local MLflow runs!)
	@rm -rf mlruns/
	$(call success,Local MLflow runs deleted.)

.PHONY: clean-dvc
clean-dvc: ## Remove DVC cache
	$(call warn,Clearing DVC cache...)
	@dvc gc --workspace 2>/dev/null || true
	$(call success,DVC cache cleared.)

.PHONY: clean-all
clean-all: clean clean-mlflow ## Remove all generated files (keeps .venv)
	$(call success,Full clean done!)

.PHONY: nuke
nuke: clean-all ## DANGER: Remove everything including .venv
	$(call warn,Removing virtual environment...)
	@rm -rf $(VENV)
	$(call success,Nuked! Run 'make setup' to start fresh.)

# ==============================================================================
#  ℹ️  PROJECT INFO
# ==============================================================================
.PHONY: info
info: ## Print project configuration summary
	@printf "\n$(BOLD)🍷 MLflow Wine Quality Predictor$(RESET)\n"
	@printf "$(CYAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"
	@printf "  %-20s %s\n" "Python:"       "$$($(PYTHON) --version 2>&1)"
	@printf "  %-20s %s\n" "MLflow:"       "$$(source $(VENV)/bin/activate && mlflow --version 2>/dev/null || echo 'not installed')"
	@printf "  %-20s %s\n" "DVC:"          "$$(source $(VENV)/bin/activate && dvc --version 2>/dev/null || echo 'not installed')"
	@printf "  %-20s %s\n" "Default alpha:" "$(ALPHA)"
	@printf "  %-20s %s\n" "Default l1_ratio:" "$(L1_RATIO)"
	@printf "  %-20s %s\n" "MLflow Port:"  "$(MLFLOW_PORT)"
	@printf "  %-20s %s\n" "DagsHub:"      "https://dagshub.com/abdallahatefhatem/mlflow-test"
	@printf "  %-20s %s\n" "GitHub:"       "https://github.com/abdallahatefhatem-boop/mlflow-test"
	@printf "$(CYAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n\n"

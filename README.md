<div align="center">

---

## 📌 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Quick Start](#-quick-start)
- [DVC Pipeline](#-dvc-pipeline)
- [MLflow Tracking](#-mlflow-tracking)
- [Experiment Parameters](#-experiment-parameters)
- [Metrics](#-metrics)
- [CI/CD](#-cicd)
- [Contributing](#-contributing)

---

## 🧠 Overview

This project demonstrates a **production-grade MLOps workflow** that trains an ElasticNet regression model on the classic [Red Wine Quality dataset](https://raw.githubusercontent.com/mlflow/mlflow/master/tests/datasets/winequality-red.csv), with full experiment tracking, pipeline versioning, and remote model registry — all wired together using industry-standard tools.

> **Goal:** Predict wine quality (score 3–9) from physicochemical features, while maintaining full reproducibility and experiment auditability.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        ML Pipeline                          │
│                                                             │
│   📥 Data Fetch (URL)                                       │
│        │                                                    │
│        ▼                                                    │
│   🔀 Train / Test Split (75/25)                             │
│        │                                                    │
│        ▼                                                    │
│   🧪 ElasticNet Training (alpha, l1_ratio)                  │
│        │                                                    │
│        ▼                                                    │
│   📊 Evaluate (RMSE, MAE, R²)                               │
│        │                                                    │
│        ▼                                                    │
│   📦 Log & Register Model ──► DagsHub / MLflow              │
└─────────────────────────────────────────────────────────────┘
         ▲
         │  Versioned by
    DVC Pipeline (dvc.yaml)
         │  Params from
    params.yaml
```

---

## ⚙️ Tech Stack

| Tool                     | Role                                     |
| ------------------------ | ---------------------------------------- |
| **MLflow 2.2.2**   | Experiment tracking, model registry      |
| **DVC**            | Pipeline orchestration & data versioning |
| **DagsHub**        | Remote MLflow server & Git hosting       |
| **scikit-learn**   | ElasticNet model training & metrics      |
| **pandas / numpy** | Data processing                          |
| **GitHub Actions** | CI/CD automation                         |

---

## 📂 Project Structure

```
mlflow-test/
├── 📄 demo.py              # Main training & tracking script
├── 📄 dvc.yaml             # DVC pipeline definition
├── 📄 dvc.lock             # Pipeline state snapshot (auto-generated)
├── 📄 params.yaml          # Hyperparameters (alpha, l1_ratio)
├── 📄 requirements.txt     # Python dependencies
├── 📄 .gitignore           # Git ignore rules
├── 📁 .dvc/               # DVC internals & config
└── 📁 .github/workflows/  # CI/CD pipeline definitions
```

---

## 🚀 Quick Start

### Prerequisites

- Python 3.8+
- Git
- DVC (`pip install dvc`)
- A [DagsHub](https://dagshub.com) account

### 1. Clone the Repository

```bash
git clone https://github.com/abdallahatefhatem-boop/mlflow-test.git
cd mlflow-test
```

### 2. Set Up Environment

```bash
make setup
```

Or manually:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 3. Set DagsHub Credentials

```bash
export DAGSHUB_USER_TOKEN=<your_dagshub_token>
```

Or configure via `dagshub login` in your Python session.

### 4. Run the Pipeline

```bash
make run
```

This executes the full DVC pipeline and pushes metrics/models to DagsHub.

---

## 🔁 DVC Pipeline

The pipeline is defined in [`dvc.yaml`](dvc.yaml) and tracked by [`dvc.lock`](dvc.lock).

```yaml
stages:
  demo:
    cmd: python -m demo
    deps:
      - demo.py
    params:
      - demo.alpha
      - demo.l1_ratio
```

### Run Pipeline Commands

```bash
# Reproduce the full pipeline
dvc repro

# Check pipeline DAG
dvc dag

# Show pipeline status
dvc status
```

---

## 📈 MLflow Tracking

All experiments are tracked remotely on **DagsHub MLflow Server**:

🔗 [https://dagshub.com/abdallahatefhatem/mlflow-test.mlflow](https://dagshub.com/abdallahatefhatem/mlflow-test.mlflow)

Each run logs:

| Logged Item          | Details                              |
| -------------------- | ------------------------------------ |
| **Parameters** | `alpha`, `l1_ratio`              |
| **Metrics**    | `rmse`, `mae`, `r2`            |
| **Model**      | Registered as`ElasticnetWineModel` |
| **Signature**  | Auto-inferred via`infer_signature` |

### View Experiments Locally (Optional)

```bash
mlflow ui
# Open http://localhost:5000
```

---

## 🎛️ Experiment Parameters

Hyperparameters are controlled via [`params.yaml`](params.yaml):

```yaml
demo:
  alpha: 0.5      # Regularization strength (0 = no regularization)
  l1_ratio: 0.5   # Mix between L1 (Lasso) and L2 (Ridge). 0=Ridge, 1=Lasso
```

### Run Custom Experiment

```bash
# Via DVC params override
dvc exp run --set-param demo.alpha=0.3 --set-param demo.l1_ratio=0.7

# Or directly
python demo.py 0.3 0.7
```

### Experiment Grid Search

```bash
make experiments
```

---

## 📊 Metrics

The model is evaluated on the 25% held-out test split:

| Metric         | Description                                                     |
| -------------- | --------------------------------------------------------------- |
| **RMSE** | Root Mean Squared Error — penalizes large errors               |
| **MAE**  | Mean Absolute Error — average prediction error                 |
| **R²**  | Coefficient of Determination — goodness of fit (1.0 = perfect) |

Example output:

```
Elasticnet model (alpha=0.500000, l1_ratio=0.500000):
  RMSE: 0.7936
  MAE:  0.6271
  R2:   0.1085
```

---

## 🔄 CI/CD

This project uses **GitHub Actions** for automated pipeline execution on every push.

```
Push to main
    │
    ▼
GitHub Actions (.github/workflows/main.yml)
    │
    ├── Install dependencies
    ├── Authenticate with DagsHub
    ├── Run DVC pipeline (dvc repro)
    └── Push metrics & model to MLflow/DagsHub
```

---

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/my-experiment`
3. Commit your changes: `git commit -m 'Add new experiment'`
4. Push to the branch: `git push origin feature/my-experiment`
5. Open a Pull Request

---

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

---

<div align="center">
  <sub>Built with ❤️ by <a href="https://github.com/abdallahatefhatem-boop">Abdallah Atef</a> · Tracked on <a href="https://dagshub.com/abdallahatefhatem/mlflow-test">DagsHub</a></sub>
</div>

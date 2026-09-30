# NeoResilience

## Overview
NeoResilience is a robust platform designed to monitor and predict supply chain risks across healthcare facilities. The system is currently powered by a set of synthetic datasets modeled around the Banswara district, producing realistic baseline consumption, seasonal trends, simulated disease outbreaks, and cold-chain excursions.

## Data and ML Implementation

```mermaid
graph TD
    A[Data Generators SOH, Sensors] -->|Seed Data| B[NetworkState Cache]
    B --> C[Forecast & Risk Engines]
    C --> D[Twin Simulator]
    C --> E[AI Optimizer PuLP (CBC solver)]
    E --> F[Tamper-Evident Audit Firewall]
    F --> G[Federated Hub]
    
    H[Frontend Control Tower] -->|REST| F
    H -->|REST| D
    H -->|REST| C
```

- **Data Generation**: All data (facilities, inventory, sensor readings, and 180 days of daily metrics) is completely synthetic and generated on-the-fly using reproducible seeds.
- **Forecasting Model**: The primary demand forecasting engine uses a global `HistGradientBoostingRegressor` (Scikit-Learn). 
  - Uses lagged consumption features, rolling means, and outbreak indicators.
  - Predicts daily expected demand alongside robust multi-horizon Monte Carlo sampling for 7, 14, and 30-day quantile bounds and stock-out probabilities.

### Forecast Evaluation
| Aggregation | Baseline (Seasonal-Naive) WAPE | Model (Mean Prediction) WAPE |
|-------------|---------------------------------|---------------------------------------------|
| **Daily - All** | 53.69% | 49.38% |
| **Weekly - All** | 30.10% | 36.19% |
| **Outbreak (Excl first 3 days)** | 60.02% | 58.18% |

**Diagnostic Note**: Initially, the weekly WAPE for the model was significantly worse than the baseline because the model (using `loss='quantile', quantile=0.5`) predicted the median. Given that consumption distributions are right-skewed and zero-inflated, the median is negatively biased (Mean Signed Error = 0.554). Weekly aggregation compounded this bias. Switching the point prediction to a mean regressor (`loss='squared_error'`) resolved the negative bias, though the baseline still slightly outperforms on weekly sums due to simple smoothing.

**Quantile Calibration (Validation Set)**: p10 Coverage = 15%, p50 Coverage = 59%, p90 Coverage = 96%.

**Alert Operating Curve**: Evaluated if the system flagged a stock-out within 7 days.
- **Validation**: Swept probability thresholds. Selected Threshold = 0.8.
- **Test Set Model**: Precision = 48.9%, Recall = 75.2%, Median Lead Time = 4.5 days
- **Test Set Baseline (Days of Cover)**: Precision = 36.5%, Recall = 100.0%, Median Lead Time = 2.0 days

## Tamper-Evident Audit Log
- All automated transfer recommendations and manual modifications are strictly tracked in a **Tamper-Evident Hash-Chained Audit Log**.
- The recommendation engine utilizes **PuLP (CBC solver)** for optimal redistributions minimizing transfer cost and cold-chain risk.

## Twin Simulation Engine
The Resilience Twin simulates the network forward 30 days (60 days for Supplier Shock). Stock-outs are defined as total stock-out days (facility × medicine × day).
*Note: A strict conservation-of-stock invariant runs on every trajectory (initial + received == final + transit + consumed + wasted) and passes perfectly.*

**Baseline Plausibility**: Baseline stock-out days account for **25.26%** of all available facility-medicine-days (1,895 out of 7,500). This indicates that the seeded network is **intentionally misallocated and under-stocked** at initiation. 

| Preset Scenario | Baseline Stock-outs | Baseline (Reactive) | Stressed (No Response) | Stressed (Reactive) | Stressed (Proactive) | Resilience Gap |
|-----------------|---------------------|---------------------|-------------------------|---------------------|----------------------|----------------|
| **Monsoon + Fridge Fail** | 1,847 | 118 | 1,890 | 1,042 | 736 | **Reactive:** 924<br>**Proactive:** 618 |
| **Supplier Shock** | 1,847 | 118 | 4,195 | 198 | 3,061 | **Reactive:** 80<br>**Proactive:** 2,943 |
| **Outbreak Spike** | 1,847 | 118 | 2,155 | 262 | 1,043 | **Reactive:** 144<br>**Proactive:** 925 |

*(Note on Monsoon: The baseline response is so effective that it drops stockouts to 118. When the Monsoon stress is applied, the road closures cripple the optimizer's ability to move stock. Because "Resilience Gap" isolates the extra stockouts caused strictly by the stress despite intervention, a large positive gap (924) indicates the system struggled to mitigate the physical road closures).*

## Federated Learning Demonstration (BRICS Hub)
- The system includes an in-process simulation of federated learning across cross-border nodes.
- **Protocol Honesty**: The exact same model weights (aggregated globally) are evaluated on the local test set for all "Federated" methods. **Absolutely zero local fine-tuning, per-node adaptation, or personalization is applied to the federated model.**
- **Strategy Pattern**: Uses a FedAvg pattern to aggregate weights from local `SGDClassifier` models trained entirely on locally held data.
- **Privacy Mechanism**: Implements DP-style clipping (clip_norm=1.0) and Gaussian noise (scale=0.01) locally prior to aggregation. *(Note: This is illustrative and does not constitute a formal privacy guarantee. The accuracy cost of this noise is visible below).*
- **Explicit Cold-Start Scenario**: Data across nodes is highly non-IID. India (379/410 pos) and Brazil (198/212 pos) are data-rich. South Africa (Cold Start) has **0 positives in training** and exactly 9 in the test set.

### Federated Evaluation (Mean AUC over 10 seeds)
| Node | Local-Only AUC | Federated (DP Noise) | Federated (No Noise) | Centralized (Pooled) |
|------|----------------|----------------------|----------------------|----------------------|
| **India-Rajasthan** *(324 train pos, 76 test pos)*| 0.924 ± 0.021 | 0.929 ± 0.011 | 0.932 ± 0.008 | 0.804 ± 0.089 |
| **Brazil** *(155 train pos, 45 test pos)* | 0.941 ± 0.013 | 0.931 ± 0.018 | 0.928 ± 0.014 | 0.786 ± 0.082 |
| **South Africa (Data-Rich)** *(125 train pos, 25 test pos)*| 0.881 ± 0.028 | 0.879 ± 0.028 | 0.890 ± 0.037 | 0.775 ± 0.061 |
| **South Africa (Cold Start)** *(0 train pos, 9 test pos)* | 0.500 ± 0.000 | 0.965 ± 0.017 | 0.969 ± 0.021 | 0.852 ± 0.104 |
| **South Africa (Anti-Transfer)** *(Reversed Signature)*| 0.906 ± 0.030 | 0.098 ± 0.033 | 0.092 ± 0.034 | 0.204 ± 0.119 |

*Observation 1*: The South Africa Cold-Start node benefits massively from federation (0.500 -> 0.965 AUC). 
*Observation 2 (Failure Scenario)*: When the underlying signature differs significantly (Anti-Transfer), Federated Learning catastrophically fails (0.098 AUC) because transferring weights from mismatched distributions hurts performance compared to local training (0.906 AUC).
*Audit of Centralized Degradation*: The centralized (pooled) model heavily degrades (~0.80) because merging shifted distributions destroys linear separability. Federated Learning naturally respects node boundaries through local updates.

## Known Limitations
- **Synthetic Data**: The platform is entirely powered by synthetic data generators for demonstration purposes.
- **Alert Evaluation**: The alert evaluation uses a constructed "pseudo-QOH" inventory timeline on synthetic data.
- **Network Initialization**: The baseline stock-out rate is extremely high (~25%) because the seeded network is intentionally under-stocked and misallocated to stress-test the optimizer.
- **Federated Alignment Risk**: As shown in the Anti-Transfer result, plain FedAvg can be severely harmed by a misaligned node. A production deployment would require per-node validation and robust/secure aggregation techniques to detect and reject misaligned updates.
- **No Secure Aggregation**: The federated simulation does **not** employ a formal secure aggregation layer.
- **No Calibrated DP**: The DP-style noise is purely illustrative and does not provide calibrated formal Differential Privacy.
- **No Auth/RBAC**: There is no authentication or role-based access control beyond a simulated role switch.
- **No Real Integrations**: The system is not yet integrated with live e-Aushadhi, HMIS, or HRMS pipelines.

## Getting Started
To boot up both the frontend and backend concurrently:
```bash
make dev
```

## Cloud Run Deployment Instructions

You can deploy NeoResilience as separate backend and frontend services on Google Cloud Run.

### 1. Build and Push the Backend
```bash
cd backend
gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/neoresilience-backend
gcloud run deploy neoresilience-backend \
  --image gcr.io/YOUR_PROJECT_ID/neoresilience-backend \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars="GEMINI_API_KEY=your_key,ENVIRONMENT=production"
```

### 2. Build and Push the Frontend
Before building, update the `API_BASE` in `frontend/src/App.tsx` and `Twin.tsx` to point to the URL of the deployed backend service (e.g., `https://neoresilience-backend-xxx.a.run.app/api`).

```bash
cd frontend
gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/neoresilience-frontend
gcloud run deploy neoresilience-frontend \
  --image gcr.io/YOUR_PROJECT_ID/neoresilience-frontend \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

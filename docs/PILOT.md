# NeoResilience District Pilot Plan

## 1. Objectives
The objective of this pilot is to field-test the NeoResilience Control Tower within a single designated district for a 3-month operational window.
Success is defined by:
- A measurable reduction in stock-out days for essential medicines.
- Accurate prediction of short-term demand surges (Forecast WAPE).
- Seamless workflow integration for district medical officers (DMOs) utilizing the AI recommendations.

## 2. Integration Points
To move from synthetic to production data, NeoResilience requires the following pipeline integrations:

- **e-Aushadhi / LMIS**: Daily sync of inventory levels (SOH), batch expiries, and dispatch logs.
- **HMIS / e-Sanjeevani**: Daily extraction of syndromic surveillance indicators (e.g., fever clusters) to seed the outbreak multiplier and adjust the risk model.
- **HRMS**: Daily attendance logs to estimate staffing gaps impacting operational resilience.
- **Cold Chain Sensors (eVIN/eVCCM)**: Real-time telemetry (MQTT/webhook) for refrigerator temperatures.

## 3. Data-Sharing & Safety Assumptions
- **Anonymization**: No PII/PHI is transmitted. Only aggregate daily consumption and syndromic counts at the facility level are processed.
- **Federated Governance**: For cross-district or state-level insights, raw data remains local. Only model weight updates are transmitted to the global aggregator via the FedAvg-based Federated pattern (with DP clipping/noise).
- **Human-in-the-Loop Constraint**: The Autonomy Level will be locked at **Level 2 (Human-in-the-Loop)** for the duration of the pilot. All inventory transfers must be manually approved by the DMO; the system acts solely as a recommendation engine.

## 4. Key Performance Indicators (KPIs)
1. **Stock-outs Avoided**: Number of simulated critical stock-outs preempted by executed transfer recommendations.
2. **Forecast Accuracy (WAPE)**: Reduction of 30-day demand forecast error below 40% WAPE.
3. **Response Time**: Reduction in the average time taken from anomaly detection to inventory transfer execution (from an assumed 7 days to < 48 hours).
4. **Adoption**: DMO approval rate of generated AI transfers.

## 5. Timeline
- **Month 1**: Sandbox integration (shadow mode running on live data but disconnected from approval workflows).
- **Month 2**: Active mode with soft notifications; DMOs manually review the top 5 daily recommendations.
- **Month 3**: Active mode with the Control Tower fully integrated into daily operational stand-ups.

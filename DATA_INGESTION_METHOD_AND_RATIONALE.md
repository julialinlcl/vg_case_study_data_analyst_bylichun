### Data Ingestion Method and Rationale

#### Chosen Method:
We adopted a **model-driven ingestion and transformation approach using dbt**, supported by **manual data exploration and validation via DBeaver**, and finalized with **semantic modeling and reporting in Power BI**.

#### Ingestion & Modeling Flow:

1. **Source Data Exploration**:
   - Used **DBeaver** to connect to the source database and explore raw tables.
   - Performed initial profiling and validation to understand data structure and quality.

2. **Staging Layer (dbt)**:
   - Created **staging models** in dbt to standardize and clean raw data.
   - Applied naming conventions, type casting, and basic transformations.
   - Ensured consistency across different source systems.

3. **Intermediate Models (dbt)**:
   - Built **intermediate models** to join, filter, and enrich data from staging.
   - These models served as the foundation for business logic and metrics.

4. **Marts Layer (dbt)**:
   - Designed **marts models** to reflect business entities (e.g., customers, orders, revenue).
   - These models were optimized for analytics and reporting.

5. **Reporting (Power BI)**:
   - Exported curated data from marts layer to **Power BI**.
   - Built dashboards and reports for stakeholders using semantic models.

#### Rationale:
- **Modularity**: dbt’s layered approach (staging → intermediate → marts) promotes clean separation of concerns and reusability.
- **Transparency**: SQL-based transformations in dbt are version-controlled and easy to audit.
- **Flexibility**: DBeaver allows quick inspection and validation of data during development.
- **Business Alignment**: Power BI enables interactive reporting and aligns data models with business needs.

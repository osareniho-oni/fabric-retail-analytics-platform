# Semantic model and report-design evidence

[Dashboard design and KPIs](../documentation/dashboard-design.md) | [Model relationships](../documentation/data-model.md) | [Screenshots](../screenshots/README.md)

- [Measures](<Retail Analytics Model.SemanticModel/definition/tables/_Measures.tmdl>) and [relationships](<Retail Analytics Model.SemanticModel/definition/relationships.tmdl>) demonstrate analytical definitions.
- [Time Intelligence](<Retail Analytics Model.SemanticModel/definition/tables/Time Intelligence.tmdl>) defines period comparisons.
- [Report excerpts](report-excerpts/README.md) retain two page configurations and a relative semantic-model reference, clearly labelled as incomplete.

The semantic-model folder retains all 27 table/helper files referenced by model.tmdl, plus expressions, relationships, compatibility metadata, and definition.pbism. Even small helper files are retained to preserve model context and avoid breaking its source references. Live storage bindings are substituted. No compile/import validation is claimed.

Report visuals and themes are not included, and no retained excerpt depends on an absent theme/resource file. The supplied [profitability](../screenshots/dashboards/revenue-profitability.png) and [marginal](../screenshots/dashboards/marginal-cost-revenue.png) captures show rendered design only; [financial correctness](../documentation/financial-reconciliation.md) remains unresolved.

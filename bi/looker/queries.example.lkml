# LookML Query Examples — Product Analytics Dashboard

This file demonstrates how to query the LookML model for common analytics questions.
Run these in Looker via Explore or the SQL Runner.

---

## 1. Daily KPI Overview (`daily_kpis` explore)

### Daily new users, conversions, and revenue — last 30 days
```lookml
explore: daily_kpis

{% for day in _current_page.date_range %}
SELECT
  metric_date,
  new_users,
  paid_conversions,
  conversion_rate,
  net_revenue_usd
FROM marts_daily_kpis
WHERE metric_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
ORDER BY metric_date
{% endfor %}
```

### Monthly KPI summary with conversion and refund rates
```lookml
explore: daily_kpis

SELECT
  DATE_TRUNC(metric_date, MONTH) AS metric_month,
  SUM(new_users)                         AS total_new_users,
  SUM(active_users)                      AS total_active_users,
  SUM(paid_conversions)                  AS total_conversions,
  SAFE_DIVIDE(SUM(paid_conversions), SUM(new_users)) AS conversion_rate,
  SUM(net_revenue_usd)                   AS total_revenue,
  SAFE_DIVIDE(SUM(refunded_usd), SUM(gross_revenue_usd)) AS refund_rate
FROM marts_daily_kpis
GROUP BY 1
ORDER BY 1
```

### Alert flag: flag days where KPI thresholds are breached
```lookml
SELECT
  metric_date,
  new_users,
  paid_conversions,
  conversion_rate,
  net_revenue_usd,
  refund_rate,
  CASE
    WHEN conversion_rate < 0.03 THEN '⚠️ Low Conversion'
    WHEN refund_rate > 0.12      THEN '⚠️ High Refund Rate'
    WHEN net_revenue_usd < 3000  THEN '⚠️ Low Revenue'
    ELSE '✅ Healthy'
  END AS alert_status
FROM marts_daily_kpis
WHERE metric_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
ORDER BY metric_date
```

---

## 2. Channel Performance (`channel_performance` explore)

### Channel-level revenue and ARPU comparison
```lookml
explore: channel_performance

SELECT
  acquisition_channel,
  SUM(signups)                            AS total_signups,
  SUM(paying_users)                       AS total_paying_users,
  SAFE_DIVIDE(SUM(paying_users), SUM(signups)) AS paid_conversion_rate,
  SUM(net_revenue_usd)                    AS total_revenue,
  AVG(arpu)                               AS avg_arpu,
  SUM(net_revenue_usd) / NULLIF(SUM(signups), 0) AS revenue_per_signup
FROM marts_channel_performance
GROUP BY 1
ORDER BY total_revenue DESC
```

### Week-over-week channel trend
```lookml
explore: channel_performance

SELECT
  DATE_TRUNC(COALESCE(reported_date, CURRENT_DATE()), WEEK) AS channel_week,
  acquisition_channel,
  SUM(signups)        AS weekly_signups,
  SUM(paying_users)   AS weekly_paying_users,
  SUM(net_revenue_usd) AS weekly_revenue
FROM marts_channel_performance
GROUP BY 1, 2
ORDER BY 1 DESC, weekly_revenue DESC
```

---

## 3. A/B Experiments (`experiments` explore)

### Active experiments with conversion lift
```lookml
explore: experiments

SELECT
  experiment_name,
  variant,
  status,
  start_date,
  end_date,
  control_users,
  treatment_users,
  control_conversion_rate,
  treatment_conversion_rate,
  relative_lift,
  CASE
    WHEN statistical_significance = 1 AND relative_lift > 0
      THEN '✅ Significant Winner'
    WHEN statistical_significance = 1 AND relative_lift < 0
      THEN '❌ Significant Loser'
    ELSE '⏳ Inconclusive'
  END AS experiment_verdict
FROM marts_ab_experiments
WHERE status = 'active'
ORDER BY start_date DESC
```

### Experiment summary for a date range
```lookml
SELECT
  experiment_name,
  variant,
  SUM(sample_size)                        AS total_sample_size,
  SUM(control_users + treatment_users)   AS total_users,
  MAX(control_conversion_rate)            AS baseline_rate,
  MAX(treatment_conversion_rate)          AS variant_rate,
  MAX(relative_lift)                      AS lift
FROM marts_ab_experiments
WHERE start_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY 1, 2
ORDER BY lift DESC
```

---

## 4. User Funnel (`funnel` explore)

### Full funnel conversion by stage
```lookml
explore: funnel

SELECT
  funnel_stage,
  acquisition_channel,
  SUM(users_entered)    AS users_entered,
  SUM(users_completed)  AS users_completed,
  SUM(users_entered) - SUM(users_completed) AS drop_off,
  SAFE_DIVIDE(SUM(users_completed), SUM(users_entered)) AS stage_conversion_rate
FROM marts_user_funnel
WHERE cohort_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 14 DAY)
GROUP BY 1, 2
ORDER BY acquisition_channel, FIELD(funnel_stage,
  'impression', 'click', 'signup', 'onboarding', 'first_action', 'conversion'
)
```

### Funnel drop-off analysis — which stage loses the most users
```lookml
SELECT
  funnel_stage,
  acquisition_channel,
  SUM(users_entered)    AS entered,
  SUM(users_completed)  AS completed,
  SUM(users_entered) - SUM(users_completed) AS dropped,
  ROUND((SUM(users_entered) - SUM(users_completed)) * 100.0 / NULLIF(SUM(users_entered), 0), 1) AS drop_rate_pct
FROM marts_user_funnel
WHERE cohort_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY 1, 2
HAVING dropped > 0
ORDER BY dropped DESC
LIMIT 20
```

---

## 5. Alert History (`alerts` explore)

### Alert volume and resolution rate — last 7 days
```lookml
explore: alerts

SELECT
  DATE(evaluated_at)    AS alert_date,
  metric_name,
  severity,
  status,
  COUNT(*)               AS alert_count,
  AVG(resolution_time_minutes) AS avg_resolution_minutes
FROM marts_alert_history
WHERE evaluated_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY 1, 2, 3, 4
ORDER BY alert_count DESC
```

### Open alerts requiring attention
```lookml
explore: alerts

SELECT
  alert_name,
  metric_name,
  severity,
  triggered_by,
  evaluated_at,
  resolution_time_minutes
FROM marts_alert_history
WHERE status = 'triggered'
  AND evaluated_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 24 HOUR)
ORDER BY severity DESC, evaluated_at DESC
```

### Alert health summary by metric
```lookml
SELECT
  metric_name,
  COUNT(*)                               AS total_alerts,
  COUNTIF(status = 'triggered')          AS triggered_count,
  COUNTIF(status = 'resolved')           AS resolved_count,
  SAFE_DIVIDE(COUNTIF(status = 'resolved'), COUNT(*)) AS resolution_rate,
  AVG(CASE WHEN status = 'resolved' THEN resolution_time_minutes END) AS avg_resolution_minutes
FROM marts_alert_history
WHERE evaluated_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY 1
ORDER BY triggered_count DESC
```

---

## 6. Cross-explore Joins

### Daily KPIs joined with Channel Performance (Looker native join)
```lookml
view: daily_kpis_with_channel {
  join: channel_performance {
    type: left
    relationship: many_to_one
    sql_on: ${daily_kpis.metric_date} = ${channel_performance.reported_date} ;;
  }
}
```

---

## Notes

- All timestamps in warehouse are UTC; Looker timezone settings apply
- `SAFE_DIVIDE` / `NULLIF` used throughout to prevent division-by-zero errors
- Alert thresholds (`conversion_rate < 0.03`, `refund_rate > 0.12`, `net_revenue_usd < 3000`) align with `alerts` view thresholds
- Queries use standard BigQuery SQL dialect; adjust `DATE_SUB` / `DATE_TRUNC` for Snowflake/Redshift/Postgres
- See also: `bi/powerbi/kpi_visual_mapping.csv` for KPI → visual type mapping
- See also: `bi/tableau/calculated_fields.md` for equivalent Tableau calculated fields

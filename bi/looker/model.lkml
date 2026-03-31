connection: "analytics_warehouse"

include: "/views/*.view.lkml"

explore: daily_kpis {
  label: "Daily KPI Overview"
  description: "Primary explore for KPI cards, conversion tracking, and reliability checks."
  join: channel_performance {
    type: left
    relationship: many_to_one
    sql_on: ${daily_kpis.metric_date} = ${channel_performance.reported_date} ;;
  }
}

explore: channel_performance {
  label: "Channel Performance"
  description: "Explore for channel revenue, ARPU, and acquisition attribution."
}

explore: experiments {
  label: "A/B Experiments"
  description: "Experiment results, variant comparison, and statistical significance."
}

explore: funnel {
  label: "User Funnel"
  description: "Multi-stage conversion funnel by channel and cohort."
}

explore: alerts {
  label: "Alert History"
  description: "Alert volume, resolution rates, and open alert tracking."
}

view: alerts {
  sql_table_name: marts_alert_history ;;

  dimension: alert_id {
    type: string
    primary_key: yes
    sql: ${TABLE}.alert_id ;;
  }

  dimension: alert_name {
    type: string
    sql: ${TABLE}.alert_name ;;
  }

  dimension: metric_name {
    type: string
    sql: ${TABLE}.metric_name ;;
  }

  dimension: status {
    type: string
    sql: ${TABLE}.status ;;
  }

  dimension: severity {
    type: string
    sql: ${TABLE}.severity ;;
  }

  dimension: triggered_by {
    type: string
    sql: ${TABLE}.triggered_by ;;
  }

  dimension_group: evaluated_at {
    type: time
    timeframes: [time, date, hour, week, month]
    sql: ${TABLE}.evaluated_at ;;
  }

  measure: total_alerts {
    type: count
  }

  measure: alerts_triggered {
    type: count
    filters: [status: "triggered"]
  }

  measure: alerts_resolved {
    type: count
    filters: [status: "resolved"]
  }

  measure: open_alerts {
    type: count
    filters: [status: "triggered"]
  }

  measure: avg_resolution_time_minutes {
    type: average
    sql: ${TABLE}.resolution_time_minutes ;;
    value_format_name: decimal_1
  }

  measure: max_severity_score {
    type: max
    sql: ${TABLE}.severity_score ;;
  }
}

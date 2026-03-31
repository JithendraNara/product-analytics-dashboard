view: experiments {
  sql_table_name: marts_ab_experiments ;;

  dimension: experiment_id {
    type: string
    primary_key: yes
    sql: ${TABLE}.experiment_id ;;
  }

  dimension: experiment_name {
    type: string
    sql: ${TABLE}.experiment_name ;;
    link: {
      label: "View in Experiment Dashboard"
      url: "/dashboards/experiments?experiment_id={{ value }}"
    }
  }

  dimension: variant {
    type: string
    sql: ${TABLE}.variant ;;
  }

  dimension: status {
    type: string
    sql: ${TABLE}.status ;;
  }

  dimension_group: start_date {
    type: time
    timeframes: [date, week, month]
    sql: ${TABLE}.start_date ;;
  }

  dimension_group: end_date {
    type: time
    timeframes: [date, week, month]
    sql: ${TABLE}.end_date ;;
  }

  measure: sample_size {
    type: sum
    sql: ${TABLE}.sample_size ;;
  }

  measure: control_users {
    type: sum
    sql: ${TABLE}.control_users ;;
  }

  measure: treatment_users {
    type: sum
    sql: ${TABLE}.treatment_users ;;
  }

  measure: control_conversions {
    type: sum
    sql: ${TABLE}.control_conversions ;;
  }

  measure: treatment_conversions {
    type: sum
    sql: ${TABLE}.treatment_conversions ;;
  }

  measure: control_conversion_rate {
    type: number
    sql: SUM(${TABLE}.control_conversions) / NULLIF(SUM(${TABLE}.control_users), 0) ;;
    value_format_name: percent_3
  }

  measure: treatment_conversion_rate {
    type: number
    sql: SUM(${TABLE}.treatment_conversions) / NULLIF(SUM(${TABLE}.treatment_users), 0) ;;
    value_format_name: percent_3
  }

  measure: relative_lift {
    type: number
    sql: (
      SUM(${TABLE}.treatment_conversions) / NULLIF(SUM(${TABLE}.treatment_users), 0)
      -
      SUM(${TABLE}.control_conversions) / NULLIF(SUM(${TABLE}.control_users), 0)
    ) / NULLIF(SUM(${TABLE}.control_conversions) / NULLIF(SUM(${TABLE}.control_users), 0), 0) ;;
    value_format_name: percent_2
  }

  measure: statistical_significance {
    type: number
    sql: CASE
      WHEN ABS(${relative_lift}) > 0.05
       AND SQRT(
         (SUM(${TABLE}.treatment_conversions) / NULLIF(SUM(${TABLE}.treatment_users), 0))
         * (1 - SUM(${TABLE}.treatment_conversions) / NULLIF(SUM(${TABLE}.treatment_users), 0))
         / NULLIF(SUM(${TABLE}.treatment_users), 0)
         +
         (SUM(${TABLE}.control_conversions) / NULLIF(SUM(${TABLE}.control_users), 0))
         * (1 - SUM(${TABLE}.control_conversions) / NULLIF(SUM(${TABLE}.control_users), 0))
         / NULLIF(SUM(${TABLE}.control_users), 0)
       ) > 1.96
      THEN 1
      ELSE 0
    END ;;
  }
}

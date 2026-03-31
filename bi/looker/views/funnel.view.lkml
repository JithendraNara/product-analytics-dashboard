view: funnel {
  sql_table_name: marts_user_funnel ;;

  dimension: funnel_stage {
    type: string
    primary_key: yes
    sql: ${TABLE}.funnel_stage ;;
  }

  dimension: acquisition_channel {
    type: string
    sql: ${TABLE}.acquisition_channel ;;
  }

  dimension_group: cohort_date {
    type: time
    timeframes: [date, week, month]
    sql: ${TABLE}.cohort_date ;;
  }

  measure: users_entered {
    type: sum
    sql: ${TABLE}.users_entered ;;
  }

  measure: users_completed {
    type: sum
    sql: ${TABLE}.users_completed ;;
  }

  measure: drop_off_users {
    type: number
    sql: ${users_entered} - ${users_completed} ;;
  }

  measure: stage_conversion_rate {
    type: number
    sql: ${users_completed} / NULLIF(${users_entered}, 0) ;;
    value_format_name: percent_2
  }

  measure: cumulative_conversion_rate {
    type: number
    sql: ${users_completed} / NULLIF(SUM(${users_entered}) OVER (PARTITION BY ${acquisition_channel}), 0) ;;
    value_format_name: percent_2
  }
}

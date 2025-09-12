#!/bin/bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
TOKEN_FILE="$SCRIPT_DIR/.api_token"
LAST_RESP_TIME_FILE="${SCRIPT_DIR}/.last_response_time"
LAST_RESP_FILE="${SCRIPT_DIR}/.last_response"
INTERVAL_SECONDS=180

get_last_execution_timestamp() {
    if [[ -f "$LAST_RESP_TIME_FILE" ]]; then
        cat "$LAST_RESP_TIME_FILE" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

sync_data() {
    date +%s > $LAST_RESP_TIME_FILE
    auth_token=$(cat "$TOKEN_FILE")
    startDay=$(date --iso-8601=seconds --date "today 00:00:00")
    endDay=$(date --iso-8601=seconds --date "today 23:59:59")
    current_timer_resp=$(curl -u "$auth_token:api_token" \
         -G \
         -H "Content-Type: application/json" \
         -s \
         -X GET "https://api.track.toggl.com/api/v9/me/time_entries" \
         --data-urlencode "start_date=${startDay}" \
         --data-urlencode "end_date=${endDay}")

    if [ $? -ne 0 ]; then
        echo "Error fetching current timer. Please check your network connection or API token."
        rm $LAST_RESP_TIME_FILE
        exit 1
    else
        echo "${current_timer_resp}" > $LAST_RESP_FILE
    fi

}

if [ -f "$TOKEN_FILE" ]; then
    now=$(date +%s)
    last_resp_time=$(get_last_execution_timestamp)

    time_diff=$((now - last_resp_time))

    # Check if it's time to execute the action
    if [[ "$1" == "--force-sync" ]] || [[ $time_diff -ge $INTERVAL_SECONDS ]]; then
        sync_data
    fi

    current_resp=$(cat $LAST_RESP_FILE)

    current_timer=$(echo "$current_resp" | jq 'first(.[] | select(.stop == null))')
    if [ -z "$current_timer" ]; then
        others_duration=$(echo "$current_resp" | jq '[.[] | select(.stop != null) | .duration] | add // 0')
        others_duration_format=$(date -d@$others_duration -u +%H:%M:%S)
        echo "○ No timer running. [$others_duration_format]"
        exit 0
    fi


    current_timer_desc=$(echo "$current_timer" | jq -r '.description')
    if [ -z "$current_timer_desc" ]; then
        current_timer_desc="n/a"
    fi

    start=$(echo "$current_timer" | jq -r '.start' | xargs -I {} date -d "{}" +%s)
    duration=$((now - start))
    duration_format=$(date -d@$duration -u +%H:%M:%S)

    others_duration=$(echo "$current_resp" | jq '[.[] | select(.stop != null) | .duration] | add // 0')
    all_duration=$(($others_duration + $duration))
    all_duration_format=$(date -d@$all_duration -u +%H:%M:%S)

    echo "◉ Running: $current_timer_desc ($duration_format) [$all_duration_format]"
else
    echo "Authentication token file not found. Get one at https://track.toggl.com/profile"
    exit 1
fi

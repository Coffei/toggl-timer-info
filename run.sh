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
    current_timer_resp=$(curl -u "$auth_token:api_token" \
         -H "Content-Type: application/json" \
         -s \
         -X GET "https://api.track.toggl.com/api/v9/me/time_entries/current")

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


    if [ "$current_resp" = "null" ]; then
        echo "○ No timer running."
        exit 0
    fi

    current_timer_desc=$(echo "$current_resp" | jq -r '.description')
    if [ -z "$current_timer_desc" ]; then
        current_timer_desc="n/a"
    fi


    start=$(echo "$current_resp" | jq -r '.start' | xargs -I {} date -d "{}" +%s)
    duration=$((now - start))
    duration_format=$(date -d@$duration -u +%H:%M:%S)

    echo "◉ Running: $current_timer_desc ($duration_format)"
else
    echo "Authentication token file not found. Get one at https://track.toggl.com/profile"
    exit 1
fi

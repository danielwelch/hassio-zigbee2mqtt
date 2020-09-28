#!/usr/bin/env bashio
DATA_PATH=$(bashio::config 'data_path') 
ZIGBEE_HERDSMAN_DEBUG=$(bashio::config 'zigbee_herdsman_debug')
ZIGBEE_SHEPHERD_DEVICES=$(bashio::config 'zigbee_shepherd_devices')
DEBUG=""

if ! bashio::fs.directory_exists "$DATA_PATH"; then
    bashio::log.info "$DATA_PATH not present, probably first run, creating folder ..."
    mkdir -p "$DATA_PATH"
fi

if bashio::fs.file_exists "$DATA_PATH/configuration.yaml" && ! bashio::fs.file_exists "$DATA_PATH/configuration.yaml.bk"; then
    bashio::log.info "Config 'configuration.yaml' found, but backup is missing. Creating backup '.configuration.yaml.bk' ..."
    cp $DATA_PATH/configuration.yaml $DATA_PATH/.configuration.yaml.bk
fi

if bashio::config.true 'zigbee_herdsman_debug'; then
    bashio::log.info "Zigbee Herdsman debug logging enabled"
    DEBUG="zigbee-herdsman:*"
fi

if bashio::config.true 'zigbee_shepherd_devices'; then
    bashio::log.info "Searching for custom devices file in zigbee2mqtt data path..."
    if bashio::fs.file_exists "$DATA_PATH/devices.js"; then
        ashio::log.info "File devices.js found, copying to ./node_modules/zigbee-herdsman-converters/ ..."
        cp -f "$DATA_PATH"/devices.js ./node_modules/zigbee-herdsman-converters/devices.js
    else
        bashio::log.warn "No devices.js file found in data path, starting with default devices.js ..."
    fi
if

CONFIG_PATH=/data/options.json
# Parse config
cat "$CONFIG_PATH" | jq 'del(.data_path, .zigbee_shepherd_debug, .zigbee_shepherd_devices, .socat)' \
    | jq 'if .advanced.ext_pan_id_string then .advanced.ext_pan_id = (.advanced.ext_pan_id_string | (split(",")|map(tonumber))) | del(.advanced.ext_pan_id_string) else . end' \
    | jq 'if .advanced.network_key_string then .advanced.network_key = (.advanced.network_key_string | (split(",")|map(tonumber))) | del(.advanced.network_key_string) else . end' \
    | jq 'if .device_options_string then .device_options = (.device_options_string|fromjson) | del(.device_options_string) else . end' \
    > $DATA_PATH/configuration.yaml

# FORK SOCAT IN A SEPARATE PROCESS IF ENABLED
SOCAT_EXEC="$(dirname $0)/socat.sh"
$SOCAT_EXEC $CONFIG_PATH

# RUN zigbee2mqtt
ZIGBEE2MQTT_DATA="$DATA_PATH" DEBUG="$DEBUG" pm2-runtime start npm -- start

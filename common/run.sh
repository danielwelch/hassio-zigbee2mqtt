#!/usr/bin/with-contenv bashio
DATA_PATH=$(bashio::config 'data_path') 
DEBUG=""

bashio::log.info "Checking if $DATA_PATH exists"
if ! bashio::fs.directory_exists "$DATA_PATH"; then
    bashio::log.warning "Data path not found"
    bashio::log.info "Creating $DATA_PATH"
    mkdir -p "$DATA_PATH"
else
    bashio::log.info "Check if there was a previous configuration"
    if bashio::fs.file_exists "$DATA_PATH/configuration.yaml"; then
        bashio::log.info "Previous configuration found, checking backup"
        if ! bashio::fs.file_exists "$DATA_PATH/configuration.yaml.bk"; then
            bashio::log.info "Creating backup config in '.configuration.yaml.bk'"
            cp $DATA_PATH/configuration.yaml $DATA_PATH/.configuration.yaml.bk
        else
            bashio::log.info "Backup already exists, skipping"
        fi
    else
        bashio::log.warning "No configuration found yet to backup"
    fi
fi

bashio::log.info "Check if any custom devices.js manipulation required"
if bashio::config.true 'zigbee_shepherd_devices'; then
    bashio::log.info "Searching for custom devices.js file in zigbee2mqtt data path..."
    if bashio::fs.file_exists "$DATA_PATH/devices.js"; then
        bashio::log.info "File devices.js found, copying to ./node_modules/zigbee-herdsman-converters/"
        cp -f "$DATA_PATH"/devices.js ./node_modules/zigbee-herdsman-converters/devices.js
    else
        bashio::log.warning "No devices.js file found in data path, starting with default devices.js"
    fi
else
    bashio::log.info "No devices.js file manipulation required"
fi

if bashio::config.true 'zigbee_herdsman_debug'; then
    bashio::log.info "Zigbee Herdsman debug logging enabled"
    DEBUG="zigbee-herdsman:*"
fi

CONFIG_PATH=/data/options.json
bashio::log.info "Adjusting configuration"
cat "$CONFIG_PATH" | jq 'del(.data_path, .zigbee_shepherd_debug, .zigbee_shepherd_devices, .socat)' \
    | jq 'if .advanced.ext_pan_id_string then .advanced.ext_pan_id = (.advanced.ext_pan_id_string | (split(",")|map(tonumber))) | del(.advanced.ext_pan_id_string) else . end' \
    | jq 'if .advanced.network_key_string then .advanced.network_key = (.advanced.network_key_string | (split(",")|map(tonumber))) | del(.advanced.network_key_string) else . end' \
    | jq 'if .device_options_string then .device_options = (.device_options_string|fromjson) | del(.device_options_string) else . end' \
    > $DATA_PATH/configuration.yaml

bashio::log.info "Check if socat is required"
if bashio::config.true 'socat.enabled'; then
    bashio::log.info "Starting socat in a separate process"
    SOCAT_EXEC="/app/socat.sh"
    $SOCAT_EXEC $CONFIG_PATH
else
    bashio::log.info "Socat not required, skipping"
fi

bashio::log.info "Handing over control to Zigbee2mqtt Core ..."
ZIGBEE2MQTT_DATA="$DATA_PATH" DEBUG="$DEBUG" pm2-runtime start npm -- start

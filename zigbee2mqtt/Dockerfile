ARG BUILD_FROM
FROM $BUILD_FROM

# Add env
ENV LANG C.UTF-8

ENV ZIGBEE2MQTT_VERSION=1.14.4

RUN echo "THis is $BUILD_EDGE "

RUN apk add --update --no-cache \
    curl jq nodejs-npm socat \
    make gcc g++ linux-headers udev git python2 && \
  curl -sL -o "/app.tar.gz" \
  "https://github.com/Koenkk/zigbee2mqtt/archive/$ZIGBEE2MQTT_VERSION.tar.gz" && \
  tar xzvf "/app.tar.gz" && \
  mv -v "zigbee2mqtt-$ZIGBEE2MQTT_VERSION" app \
  jq -n --arg commit $ZIGBEE2MQTT_VERSION '{"hash": $commit }' > /app/.hash.json && \
  echo "Installed zigbee2mqtt @ version $(cat /app/.hash.json)" && \
  cd /app && \
  npm install --unsafe-perm -g pm2 && \
  npm install --unsafe-perm && \
  apk del make gcc g++ python2 linux-headers udev git curl && \
  rm -rf docs test images scripts data docker LICENSE README.md update.sh

COPY run.sh /app/run.sh
COPY socat.sh /app/socat.sh
WORKDIR /app

RUN ["chmod", "a+x", "./socat.sh"]
RUN ["chmod", "a+x", "./run.sh"]
CMD [ "./run.sh" ]

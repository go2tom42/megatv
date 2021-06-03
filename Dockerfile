FROM alpine:latest as build
RUN apk add --no-cache go
RUN apk add --no-cache git
RUN go get github.com/koron/go-ssdp
RUN go get github.com/gorilla/websocket
RUN go get github.com/kardianos/osext
RUN git clone https://github.com/xteve-project/xTeVe.git /tmp/xTeVe
WORKDIR /tmp/xTeVe
RUN sed -i 's/System.DVRLimit = 480/System.DVRLimit = 950/' /tmp/xTeVe/src/config.go
RUN sed -i 's/System.PlexChannelLimit = 480/System.PlexChannelLimit = 950/' /tmp/xTeVe/src/config.go
RUN sed -i 's/System.UnfilteredChannelLimit = 480/System.UnfilteredChannelLimit = 950/' /tmp/xTeVe/src/config.go
RUN apk add --no-cache gcc musl-dev
RUN go build xteve.go


FROM alpine:latest
RUN apk update
RUN apk upgrade
RUN apk add --no-cache ca-certificates



# Extras
RUN apk add --no-cache curl

# Timezone (TZ)
RUN apk update && apk add --no-cache tzdata
ENV TZ=Europe/Berlin
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Add Bash shell & dependancies
RUN apk add --no-cache bash busybox-suid su-exec

# Volumes
VOLUME /config
VOLUME /guide2go
VOLUME /root/.xteve
VOLUME /tmp/xteve

# Add ffmpeg and vlc
RUN apk add ffmpeg
RUN apk add vlc
RUN sed -i 's/geteuid/getppid/' /usr/bin/vlc

# Add xTeve and guide2go
COPY --from=build /tmp/xTeVe/xteve /usr/bin
ADD guide2go /usr/bin/guide2go
ADD cronjob.sh /
ADD entrypoint.sh /
ADD sample_cron.txt /
ADD sample_xteve.txt /

# Set executable permissions
RUN chmod +x /entrypoint.sh /cronjob.sh /usr/bin/xteve /usr/bin/guide2go

# Expose Port
EXPOSE 34400

# Entrypoint
ENTRYPOINT ["./entrypoint.sh"]

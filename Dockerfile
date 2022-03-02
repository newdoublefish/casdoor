FROM golang:1.17.5 AS BACK
WORKDIR /go/src/casdoor
COPY . .
RUN cat /etc/apt/sources.list
RUN cp /etc/apt/sources.list /etc/apt/sources.list.bak && \
    echo "" > /etc/apt/sources.list && \
    echo "deb http://mirrors.aliyun.com/debian/ buster main non-free contrib" >> /etc/apt/sources.list && \
    echo "deb-src http://mirrors.aliyun.com/debian/ buster main non-free contrib" >> /etc/apt/source.list && \
    echo "deb http://mirrors.aliyun.com/debian-security buster/updates main" >> /etc/apt/source.list && \
    echo "deb-src http://mirrors.aliyun.com/debian-security buster/updates main" >> /etc/apt/source.list && \
    echo "deb http://mirrors.aliyun.com/debian/ buster-updates main non-free contrib" >>/etc/apt/source.list && \
    echo "deb-src http://mirrors.aliyun.com/debian/ buster-updates main non-free contrib" >> /etc/apt/source.list && \
    echo "deb http://mirrors.aliyun.com/debian/ buster-backports main non-free contrib" >> /etc/apt/source.list && \
    echo "deb-src http://mirrors.aliyun.com/debian/ buster-backports main non-free contrib" >> /etc/apt/source.list && \
    apt clean && \
    cat /etc/apt/source.list && \
    apt update
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GOPROXY=https://goproxy.cn,direct go build -ldflags="-w -s" -o server . \
    && apt update && apt install wait-for-it && chmod +x /usr/bin/wait-for-it

FROM node:16.13.0 AS FRONT
WORKDIR /web
COPY ./web .
RUN yarn config set registry https://registry.npm.taobao.org
RUN yarn install && yarn run build


#FROM debian:latest AS ALLINONE
#RUN apt update
#RUN apt install -y ca-certificates && update-ca-certificates
#RUN apt install -y mariadb-server mariadb-client && mkdir -p web/build && chmod 777 /tmp
#LABEL MAINTAINER="https://casdoor.org/"
#COPY --from=BACK /go/src/casdoor/ ./
#COPY --from=BACK /usr/bin/wait-for-it ./
#COPY --from=FRONT /web/build /web/build
#CMD chmod 777 /tmp && service mariadb start&&\
#if [ "${MYSQL_ROOT_PASSWORD}" = "" ] ;then MYSQL_ROOT_PASSWORD=123456 ; fi&&\
#mysqladmin -u root password ${MYSQL_ROOT_PASSWORD} &&\
#./wait-for-it localhost:3306 -- ./server --createDatabase=true


FROM alpine:latest
RUN sed -i 's/https/http/' /etc/apk/repositories
RUN apk add curl
RUN apk add ca-certificates && update-ca-certificates
LABEL MAINTAINER="https://casdoor.org/"

COPY --from=BACK /go/src/casdoor/ ./
COPY --from=BACK /usr/bin/wait-for-it ./
RUN mkdir -p web/build && apk add --no-cache bash coreutils
COPY --from=FRONT /web/build /web/build
CMD  ./server

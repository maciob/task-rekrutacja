# FROM ubuntu:22.04 as build
# RUN apt-get -y update && apt-get -y install curl
# # nvm env vars
# RUN mkdir -p /usr/local/nvm
# ENV NVM_DIR /usr/local/nvm
# # IMPORTANT: set the exact version
# ENV NODE_VERSION v18.2.0
# RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
# RUN /bin/bash -c "source $NVM_DIR/nvm.sh && nvm install $NODE_VERSION && nvm use --delete-prefix $NODE_VERSION"
# # add node and npm to the PATH
# ENV NODE_PATH $NVM_DIR/versions/node/$NODE_VERSION/bin
# ENV PATH $NODE_PATH:$PATH
# WORKDIR app/
# COPY . .
# RUN npm install
# RUN npm install react
# RUN npm run build


FROM node:alpine AS build
WORKDIR /app
COPY front .
RUN npm install
RUN npm run build

FROM nginx:stable-alpine
COPY ./conf/nginx.conf /etc/nginx/templates/nginx.conf.template
RUN rm -rf /usr/share/nginx/html/*
COPY --from=build /app/build /usr/share/nginx/html
CMD ["nginx", "-g", "daemon off;"]

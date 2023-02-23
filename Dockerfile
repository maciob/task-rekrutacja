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

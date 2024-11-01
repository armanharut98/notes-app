FROM node:18-alpine

WORKDIR /notes-app

COPY ./ ./

WORKDIR /notes-app/backend

RUN npm install

RUN npm run build:ui

CMD [ "npm", "start" ]

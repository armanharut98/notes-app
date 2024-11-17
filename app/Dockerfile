FROM node:22-alpine

WORKDIR /notes-app

COPY ./ ./

WORKDIR /notes-app/frontend

RUN npm install vite

WORKDIR /notes-app/backend

RUN npm cache clean --force

RUN npm install

RUN npm run build:ui

EXPOSE 3001

CMD [ "npm", "start" ]

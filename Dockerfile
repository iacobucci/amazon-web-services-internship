FROM node:latest
WORKDIR /
COPY . .
RUN npm install
EXPOSE 3000
RUN npm run build
CMD [ "npm", "run", "server" ]
FROM iojs
RUN mkdir /app
COPY . /app/
RUN cd /app && npm install && npm run-script build
EXPOSE 8080
WORKDIR /app
CMD ["node", "server.js"]

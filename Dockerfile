FROM node
RUN mkdir /src/
WORKDIR /src
COPY . /src/
RUN chmod u+x /src/entry.sh
RUN npm install
RUN npm install -g ethereumjs-testrpc
EXPOSE 4333 8545
#CMD "./src/entry.sh"
CMD ["sh", "-c", "bash entry.sh"]

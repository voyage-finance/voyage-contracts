FROM node:16-alpine

WORKDIR /app

COPY . .

# node-gyp fails without these dependencies
RUN apk add --no-cache libc6-compat git g++ make py3-pip

RUN yarn install --non-interactive --frozen-lockfile

EXPOSE 8545

ENTRYPOINT ["yarn", "run"]

CMD ["node:deploy"]

import pino from 'pino';
import pretty from 'pino-pretty';

const logLevel = process.env.DEBUG === 'true' ? 'debug' : 'info';
export const log = pino(
  {
    level: logLevel,
  },
  pretty({
    colorize: true,
    singleLine: true,
  })
);
log.level = logLevel;

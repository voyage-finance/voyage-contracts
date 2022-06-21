import hre from 'hardhat';
// @ts-ignore
import { Select, MultiSelect } from 'enquirer';
import { readdirSync } from 'fs';
import path from 'path';
import pino from 'pino';
import pretty from 'pino-pretty';
import execa from 'execa';
import { Transform, TransformCallback } from 'stream';

const scriptsDir = path.resolve(process.cwd(), 'scripts');
const log = pino(
  pretty({
    colorize: true,
    singleLine: true,
  })
);

async function main() {
  // exclude hardhat; it is the default in-memory network.
  const networks = Object.keys(hre.config.networks).filter(
    (network) => network !== 'hardhat'
  );
  const select = new Select({
    name: 'network',
    message: 'Choose a network.',
    choices: networks,
  });
  const network = await select.run();
  log.info(`Scripts will run against ${network}`);

  log.info(`Reading files in ${scriptsDir}`);
  const scripts = readdirSync(scriptsDir).filter(
    (file) => !file.includes('runner.ts')
  );
  const prompt = new MultiSelect({
    name: 'targets',
    message:
      'Use <space> to select scripts to run. If none are selected, all scripts will be run.\n',
    choices: scripts.map((file) => ({
      name: file,
      value: file,
    })),
  });

  let selection = await prompt.run();
  if (!selection.length) {
    log.info(`No scripts chosen. Defaulting to running all scripts.`);
    selection = scripts;
  }
  log.info(
    `Selection: ${selection}. Running ${selection.length} scripts in total.`
  );

  // run the scripts serially, because of dependencies.
  for (const script of selection) {
    const proc = execa(
      'yarn',
      [
        'hardhat',
        '--network',
        network,
        'run',
        path.join(process.cwd(), 'scripts', script),
      ],
      { cleanup: true, all: true, stripFinalNewline: true }
    );

    proc?.stdout?.pipe(
      new Transform({
        transform(
          chunk: Buffer,
          _: BufferEncoding,
          callback: TransformCallback
        ) {
          log.info(`${script} - ${chunk.toString('utf8')}`);
          callback(null, chunk);
        },
      })
    );

    proc?.stderr?.pipe(
      new Transform({
        transform(
          chunk: Buffer,
          _: BufferEncoding,
          callback: TransformCallback
        ) {
          log.error(`${script} - ${chunk.toString('utf8')}`);
          callback(null, chunk);
        },
      })
    );

    await proc;

    log.info(`${script} ran successfully.`);
  }
}

main()
  .then(() => {
    log.info('All scripts ran successfully. Exiting');
    process.exit(0);
  })
  .catch((error) => {
    log.error(error);
    process.exit(1);
  });

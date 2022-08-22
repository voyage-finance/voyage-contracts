import fs from 'fs';
import { makeSuite } from './helpers/make-suite';
import { executeStory } from './helpers/scenario-engine';

const scenarioFolder = 'test/helpers/scenarios/';

fs.readdirSync(scenarioFolder).forEach((file) => {
  const scenario = require(`./helpers/scenarios/${file}`);
  makeSuite(scenario.title, async (testEnv) => {
    for (const story of scenario.stories) {
      it.only(story.description, async function () {
        await executeStory(story, testEnv);
      });
    }
  });
});

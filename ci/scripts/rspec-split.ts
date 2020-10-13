import { promises as fs } from 'fs';

import {
  FileWithRuntime,
  FileWithRuntimeDictionary,
  RspecExample,
  FileGroup,
} from './models';
import {
  createFilesWithRuntime,
  splitFilesIntoGroups,
  createFileDictionary,
} from './util';

async function createSplitConfig(): Promise<void> {
  // Read cli arguments
  const [filePath, outputPath, manualGroupCount] = process.argv.slice(2);

  if (
    filePath === undefined ||
    outputPath === undefined ||
    manualGroupCount === undefined
  ) {
    console.error('Missing cli arguments');
    process.exit(1);
  }

  // Read in rspec report
  const rspecReport = await fs.readFile(`./${filePath}`, 'utf-8');

  // Convert string to workable object
  const examples: RspecExample[] = JSON.parse(rspecReport).examples;

  // Create a dictionary of
  const filesByRuntime: FileWithRuntimeDictionary = createFileDictionary(
    examples
  );

  const arrayOfSlowFiles: FileWithRuntime[] = createFilesWithRuntime(
    filesByRuntime
  );

  const splitConfig: FileGroup[] = splitFilesIntoGroups(
    arrayOfSlowFiles,
    +manualGroupCount
  );

  await fs.writeFile(
    `./${outputPath}/rspec-split-config.json`,
    JSON.stringify(splitConfig)
  );
}

createSplitConfig();

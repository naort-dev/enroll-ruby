const { promises: fs } = require("fs");

async function getJson() {
  const response = await fs.readFile("./ci/rspec-report.json", "utf-8");

  const { version, examples, summary, summary_line } = JSON.parse(response);

  const filesByRuntime = examples.reduce((totalConfig, example) => {
    const filePath = example.file_path;

    if (totalConfig[filePath] !== undefined) {
      const currentTotal = totalConfig[filePath].runTime;

      return {
        ...totalConfig,
        [filePath]: { runTime: currentTotal + example.run_time },
      };
    } else {
      return {
        ...totalConfig,
        [filePath]: { runTime: example.run_time },
      };
    }
  }, {});

  // 20 slowest files
  const arrayOfSlowFiles = Object.entries(filesByRuntime)
    .map(([key, value]) => ({
      filePath: removeLeadingDotSlash(key),
      ...value,
    }))
    .sort((a, b) => (a.runTime < b.runTime ? 1 : -1));

  const splitConfig = splitFilesIntoGroups(20, arrayOfSlowFiles);

  const jsonList = JSON.stringify(splitConfig);

  await fs.writeFile("./ci/rspec-split-config.json", jsonList);
}

getJson();

function splitFilesIntoGroups(numberOfGroups, arr) {
  console.log("Splitting", arr.length, "files into", numberOfGroups, "groups");
  let split = [];

  const length = arr.length;
  for (let i = 0; i < length; i++) {
    // e.g. 0 % 20 = 0, 1 % 20 = 1, 43 % 20 = 3
    const bucket = i % numberOfGroups;

    split[bucket] =
      split[bucket] === undefined
        ? { files: [arr[i].filePath] }
        : { files: [...split[bucket].files, arr[i].filePath] };
  }

  return split;
}

function removeLeadingDotSlash(filePath) {
  return filePath.replace(/\.\//, "");
}

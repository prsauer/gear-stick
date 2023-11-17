import "dotenv/config";
import fetch from "node-fetch";
import { Root } from "./types";
import { closeSync, openSync, writeFileSync } from "fs";
import { join, resolve } from "path";

const outputFolder = resolve("./");
async function fetchHistoBlob(name: string) {
  const res = await fetch(process.env.STORAGE_URL + name);
  return (await res.json()) as Root;
}

function makeTTLine(
  specId: string,
  item: { id: string; percent: number },
  isRankOne: boolean,
  bisName: string
) {
  return `["${specId}${item.id}"] = {${item.percent.toFixed(
    1
  )}, ${isRankOne}, "${bisName}"},\n`;
}

async function writeDbLuaFile(data: Root, dbName: string, fileName: string) {
  let lines = `${dbName} = {\n`;
  data.forEach((specInfo) => {
    specInfo?.histoMaps.forEach((histoMap) => {
      histoMap.histo.forEach((k, idx) => {
        lines += makeTTLine(
          specInfo.specId,
          k,
          idx === 0,
          idx > 0
            ? `${
                histoMap.histo[0].item.name
              } (${histoMap.histo[0].percent.toFixed(1)}%)`
            : ""
        );
      });
    });
  });
  lines += "};";

  const fout = openSync(join(outputFolder, fileName), "w");
  writeFileSync(fout, lines);
  closeSync(fout);
}

async function main() {
  console.log("Starting build");

  const pveData = "composed_pve_LATEST.json";
  console.log(`Fetch: ${pveData}`);
  const pveJson = await fetchHistoBlob(pveData);
  await writeDbLuaFile(pveJson, "usageDbPvE", "GearingPvE.lua");

  const data2v2 = "composed_2v2_LATEST.json";
  console.log(`Fetch: ${data2v2}`);
  const json2v2 = await fetchHistoBlob(data2v2);
  await writeDbLuaFile(json2v2, "usageDb2v2", "Gearing2v2.lua");

  const data3v3 = "composed_3v3_LATEST.json";
  console.log(`Fetch: ${data3v3}`);
  const json3v3 = await fetchHistoBlob(data3v3);
  await writeDbLuaFile(json3v3, "usageDb3v3", "Gearing3v3.lua");
}

main();

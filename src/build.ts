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

const slotTypeToWOWItemLocationIndex = {
  HEAD: 1,
  NECK: 2,
  SHOULDER: 3,
  CHEST: 5,
  WAIST: 6,
  LEGS: 7,
  FEET: 8,
  WRIST: 9,
  HANDS: 10,
  FINGER_1: 11,
  FINGER_2: 11,
  TRINKET_1: 12,
  TRINKET_2: 12,
  BACK: 16,
  MAIN_HAND: 13,
  OFF_HAND: 14,
};

function makeTTLine(key: string, item: { id: string; percent: number }, isRankOne: boolean, bisName: string) {
  return `["${key}"] = {${item.percent.toFixed(1)}, ${isRankOne}, "${bisName}"},\n`;
}

function sanitizeItemName(name: string) {
  return name.replace(/"/g, '\\"');
}

async function writeDbLuaFile(data: Root, dbName: string, fileName: string) {
  let lines = `${dbName} = {\n`;
  data.forEach((specInfo) => {
    specInfo?.histoMaps.forEach((histoMap) => {
      if (histoMap.histo[0]) {
        lines += makeTTLine(
          `${specInfo.specId}${slotTypeToWOWItemLocationIndex[histoMap.slotType]}`,
          histoMap.histo[0],
          true,
          `${sanitizeItemName(histoMap.histo[0].item.name)} (${histoMap.histo[0].percent.toFixed(1)}%)`
        );
      }

      histoMap.histo.forEach((k, idx) => {
        lines += makeTTLine(
          `${specInfo.specId}${k.id}`,
          k,
          idx === 0,
          idx > 0 ? `${sanitizeItemName(histoMap.histo[0].item.name)} (${histoMap.histo[0].percent.toFixed(1)}%)` : ""
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

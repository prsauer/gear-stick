import "dotenv/config";
import fetch from "node-fetch";
import { Root } from "./types";
import { closeSync, openSync, writeFileSync } from "fs";
import { join, resolve } from "path";
import { SpecializationsApi } from "./specTypes";

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

async function getTalentCode(characterName: string, realm: string, specId: string): Promise<string | null> {
  try {
    const res = await fetch(
      `https://wow.spires.io/api/battlenet/profile/wow/character/${realm}/${characterName.toLowerCase()}/specializations?namespace=profile-us&locale=en_US`
    );
    const data: SpecializationsApi = (await res.json()) as SpecializationsApi;

    // Find the matching spec and its active loadout
    const spec = data.specializations.find((s) => `${s.specialization.id}` === specId);
    if (!spec) return null;

    const activeLoadout = spec.loadouts.find((l) => l.is_active);
    return activeLoadout?.talent_loadout_code || null;
  } catch (error) {
    console.error(`Failed to fetch talent code for ${characterName}-${realm} (spec ${specId}):`, error);
    return null;
  }
}

function getClassIdFromSpecId(specId: string): number {
  const specToClass: Record<string, number> = {
    // Death Knight
    "250": 6, // Blood
    "251": 6, // Frost
    "252": 6, // Unholy

    // Demon Hunter
    "577": 12, // Havoc
    "581": 12, // Vengeance

    // Druid
    "102": 11, // Balance
    "103": 11, // Feral
    "104": 11, // Guardian
    "105": 11, // Restoration

    // Evoker
    "1467": 13, // Devastation
    "1468": 13, // Preservation
    "1473": 13, // Augmentation

    // Hunter
    "253": 3, // Beast Mastery
    "254": 3, // Marksmanship
    "255": 3, // Survival

    // Mage
    "62": 8, // Arcane
    "63": 8, // Fire
    "64": 8, // Frost

    // Monk
    "268": 10, // Brewmaster
    "269": 10, // Windwalker
    "270": 10, // Mistweaver

    // Paladin
    "65": 2, // Holy
    "66": 2, // Protection
    "70": 2, // Retribution

    // Priest
    "256": 5, // Discipline
    "257": 5, // Holy
    "258": 5, // Shadow

    // Rogue
    "259": 4, // Assassination
    "260": 4, // Outlaw
    "261": 4, // Subtlety

    // Shaman
    "262": 7, // Elemental
    "263": 7, // Enhancement
    "264": 7, // Restoration

    // Warlock
    "265": 9, // Affliction
    "266": 9, // Demonology
    "267": 9, // Destruction

    // Warrior
    "71": 1, // Arms
    "72": 1, // Fury
    "73": 1, // Protection
  };

  return specToClass[specId] || 0;
}

async function compileTalents(data: { bracket: string; data: Root }[], fileName: string) {
  let lines = `GSTLoadoutsDb = {\n`;

  for (const { bracket, data: bracketData } of data) {
    for (const specInfo of bracketData) {
      if (specInfo.links && specInfo.links.length > 0) {
        const sortedLinks = [...specInfo.links].sort((a, b) => {
          const aStats = specInfo.stats;
          const bStats = specInfo.stats;
          return (bStats.played || 0) - (aStats.played || 0);
        });

        for (let i = 0; i < Math.min(sortedLinks.length, 5); i++) {
          const link = sortedLinks[i];
          try {
            const talentCode = await getTalentCode(link.name, link.realm, specInfo.specId);

            if (talentCode == null) continue;

            const key = `${specInfo.specId}_${bracket}${i + 1}`;
            lines += `  {\n`;
            lines += `    ["bracket"] = "${bracket}",\n`;
            lines += `    ["rank"] = ${i + 1},\n`;
            lines += `    ["name"] = "${link.name}-${link.realm}",\n`;
            lines += `    ["code"] = "${talentCode || ""}",\n`;
            lines += `    ["classId"] = ${getClassIdFromSpecId(specInfo.specId)},\n`;
            lines += `    ["specId"] = ${parseInt(specInfo.specId)},\n`;
            lines += `  },\n`;
          } catch (error) {
            console.error(error);
          }
        }
      }
    }
  }

  lines += "};\n";

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

  await compileTalents(
    [
      {
        bracket: "pve",
        data: pveJson,
      },
      {
        bracket: "2v2",
        data: json2v2,
      },
      {
        bracket: "3v3",
        data: json3v3,
      },
    ],
    "Loadouts.lua"
  );
}

main();

import "dotenv/config";
import fetch from "node-fetch";
import { Enchantment, Histo, Root } from "./types";
import { closeSync, openSync, writeFileSync } from "fs";
import { join, resolve } from "path";
import { SpecializationsApi } from "./specTypes";

export type ShuffleLeaderBoardName =
  | "shuffle-warrior-fury"
  | "shuffle-demonhunter-vengeance"
  | "shuffle-monk-brewmaster"
  | "shuffle-paladin-protection"
  | "shuffle-shaman-restoration"
  | "shuffle-evoker-devastation"
  | "shuffle-evoker-augmentation"
  | "shuffle-monk-mistweaver"
  | "shuffle-deathknight-frost"
  | "shuffle-warlock-affliction"
  | "shuffle-paladin-holy"
  | "shuffle-warlock-demonology"
  | "shuffle-priest-discipline"
  | "shuffle-druid-guardian"
  | "shuffle-hunter-survival"
  | "shuffle-demonhunter-havoc"
  | "shuffle-warlock-destruction"
  | "shuffle-monk-windwalker"
  | "shuffle-warrior-arms"
  | "shuffle-mage-frost"
  | "shuffle-priest-holy"
  | "shuffle-deathknight-blood"
  | "shuffle-mage-fire"
  | "shuffle-rogue-subtlety"
  | "shuffle-shaman-enhancement"
  | "shuffle-druid-balance"
  | "shuffle-hunter-beastmastery"
  | "shuffle-paladin-retribution"
  | "shuffle-hunter-marksmanship"
  | "shuffle-rogue-outlaw"
  | "shuffle-priest-shadow"
  | "shuffle-evoker-preservation"
  | "shuffle-rogue-assassination"
  | "shuffle-deathknight-unholy"
  | "shuffle-druid-feral"
  | "shuffle-druid-restoration"
  | "shuffle-shaman-elemental"
  | "shuffle-mage-arcane"
  | "shuffle-warrior-protection";

export const shuffleSpecs: string[] = [
  "shuffle-warrior-fury",
  "shuffle-demonhunter-vengeance",
  "shuffle-monk-brewmaster",
  "shuffle-paladin-protection",
  "shuffle-shaman-restoration",
  "shuffle-evoker-devastation",
  "shuffle-evoker-augmentation",
  "shuffle-monk-mistweaver",
  "shuffle-deathknight-frost",
  "shuffle-warlock-affliction",
  "shuffle-paladin-holy",
  "shuffle-warlock-demonology",
  "shuffle-priest-discipline",
  "shuffle-druid-guardian",
  "shuffle-hunter-survival",
  "shuffle-demonhunter-havoc",
  "shuffle-warlock-destruction",
  "shuffle-monk-windwalker",
  "shuffle-warrior-arms",
  "shuffle-mage-frost",
  "shuffle-priest-holy",
  "shuffle-deathknight-blood",
  "shuffle-mage-fire",
  "shuffle-rogue-subtlety",
  "shuffle-shaman-enhancement",
  "shuffle-druid-balance",
  "shuffle-hunter-beastmastery",
  "shuffle-paladin-retribution",
  "shuffle-hunter-marksmanship",
  "shuffle-rogue-outlaw",
  "shuffle-priest-shadow",
  "shuffle-evoker-preservation",
  "shuffle-rogue-assassination",
  "shuffle-deathknight-unholy",
  "shuffle-druid-feral",
  "shuffle-druid-restoration",
  "shuffle-shaman-elemental",
  "shuffle-mage-arcane",
  "shuffle-warrior-protection",
];

type RaidbotsEnchant = {
  id: number;
  displayName: string;
  itemId: number;
  itemName: string;
  craftingQuality: number;
};

const fetchRaidbotsEnchants = async (): Promise<RaidbotsEnchant[]> => {
  const res = await fetch(
    "https://www.raidbots.com/static/data/live/enchantments.json"
  );
  return (await res.json()) as RaidbotsEnchant[];
};

const qualityNames = {
  1: `|A:Professions-ChatIcon-Quality-Tier1:20:20|a`,
  2: `|A:Professions-ChatIcon-Quality-Tier2:20:20|a`,
  3: `|A:Professions-ChatIcon-Quality-Tier3:20:20|a`,
};
const raidbotsEnchantNameMap = new Map<number, string>();

const buildRaidbotsEnchantNameMap = async () => {
  console.log("Building raidbots enchant name map");
  const enchants = await fetchRaidbotsEnchants();
  for (const enchant of enchants) {
    raidbotsEnchantNameMap.set(
      enchant.id,
      `${enchant.itemName} ${qualityNames[enchant.craftingQuality]}`
    );
  }
};

const outputFolder = resolve("./");
async function fetchHistoBlob(name: string) {
  const url = process.env.STORAGE_URL + name;
  console.log("Fetching: " + url);
  const res = await fetch(url);
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
  FINGER_2: 12,
  TRINKET_1: 13,
  TRINKET_2: 14,
  BACK: 15,
  MAIN_HAND: 16,
  OFF_HAND: 17,
};

// Correct slot mapping for summary tooltips
const slotTypeToCorrectWOWSlot = {
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
  FINGER_2: 12,
  TRINKET_1: 13,
  TRINKET_2: 14,
  BACK: 15,
  MAIN_HAND: 16,
  OFF_HAND: 17,
};

function makeTTLine(
  key: string,
  item: { id: string; percent: number },
  rank: number,
  bisName: string
) {
  return `["${key}"] = {${item.percent.toFixed(1)}, ${rank}, "${bisName}"},\n`;
}

function sanitizeItemName(name: string) {
  return name.replace(/"/g, '\\"');
}

function getStatsTag(item: Histo, rename: boolean = true) {
  // get secondaries
  // return (Haste-Mastery) or similar:
  const secondaryStats = [
    "CRIT_RATING",
    "HASTE_RATING",
    "MASTERY_RATING",
    "VERSATILITY",
  ];
  const niceNameMap = {
    VERSATILITY: "Vers",
    HASTE_RATING: "Haste",
    MASTERY_RATING: "Mastery",
    CRIT_RATING: "Crit",
  };
  const stats = item.item.stats
    ? item.item.stats
        .filter((s) => secondaryStats.includes(s.type?.type))
        .sort((a, b) => (b.value || 0) - (a.value || 0))
        .map((s) => (rename ? niceNameMap[s.type!.type] : s.type.type))
        .join("-")
    : "";
  return stats;
}

async function writeDbLuaFile(data: Root, dbName: string, fileName: string) {
  let lines = `${dbName} = {\n`;

  // Add profile count metadata for each spec
  data.forEach((specInfo) => {
    // console.log(`Processing ${specInfo.specId} in ${dbName}`);
    if (specInfo.profilesComparedCount) {
      lines += `["${specInfo.specId}_profileCount"] = ${specInfo.profilesComparedCount},\n`;
    }
    const fingerData: Histo[] = [];
    const trinketData: Histo[] = [];
    specInfo?.histoMaps.forEach((histoMap) => {
      const recompilerSlots = [
        "FINGER_1",
        "FINGER_2",
        "TRINKET_1",
        "TRINKET_2",
      ];
      if (!recompilerSlots.includes(histoMap.slotType)) {
        histoMap.histo.forEach((k, idx) => {
          lines += makeTTLine(
            `${specInfo.specId}${k.id}`,
            k,
            idx + 1,
            idx > 0
              ? `${sanitizeItemName(
                  histoMap.histo[0].item.name
                )} (${getStatsTag(
                  histoMap.histo[0]
                )}) (${histoMap.histo[0].percent.toFixed(1)}% - #${idx})`
              : ""
          );
        });
        // regular process
      } else {
        // console.log(`recomp ${histoMap.slotType} ${histoMap.histo.length}`);
        // recompiler processing
        if (histoMap.slotType === "FINGER_1") {
          fingerData.push(...histoMap.histo);
        } else if (histoMap.slotType === "TRINKET_1") {
          trinketData.push(...histoMap.histo);
        }
        if (histoMap.slotType === "FINGER_2") {
          fingerData.push(...histoMap.histo);
        } else if (histoMap.slotType === "TRINKET_2") {
          trinketData.push(...histoMap.histo);
        }
      }
    });

    // For the recompile data we need to combine items that have the same id
    // items are { id, count, item, percent }
    // item and percent are not useful. we  can just write the last value into the new combined item
    // count should be summed across all that share the key
    const fingerDataCombined = fingerData.reduce((acc, item) => {
      const existing = acc.find((i) => i.id === item.id);
      if (existing) {
        existing.count += item.count;
      } else {
        acc.push(item);
      }
      return acc;
    }, [] as Histo[]);
    const trinketDataCombined = trinketData.reduce((acc, item) => {
      const existing = acc.find((i) => i.id === item.id);
      if (existing) {
        existing.count += item.count;
      } else {
        acc.push(item);
      }
      return acc;
    }, [] as Histo[]);

    // Sort them by count:
    fingerDataCombined.sort((a, b) => b.count - a.count);
    trinketDataCombined.sort((a, b) => b.count - a.count);

    // Write TTline as normal proc:
    fingerDataCombined.forEach((item, idx) => {
      lines += makeTTLine(
        `${specInfo.specId}${item.id}`,
        item,
        idx + 1,
        idx > 0
          ? `${sanitizeItemName(
              fingerDataCombined[0].item.name
            )} (${getStatsTag(
              fingerDataCombined[0]
            )}) (${fingerDataCombined[0].percent.toFixed(1)}% - #${idx})`
          : ""
      );
    });
    trinketDataCombined.forEach((item, idx) => {
      lines += makeTTLine(
        `${specInfo.specId}${item.id}`,
        item,
        idx + 1,
        idx > 0
          ? `${sanitizeItemName(
              trinketDataCombined[0].item.name
            )} (${getStatsTag(
              trinketDataCombined[0]
            )}) (${trinketDataCombined[0].percent.toFixed(1)}% - #${idx})`
          : ""
      );
    });
    // console.log({ fingerDataCombined, trinketDataCombined });
  });

  lines += "};";

  const fout = openSync(join(outputFolder, fileName), "w");
  writeFileSync(fout, lines);
  closeSync(fout);
}

// Cache for getTalentCode results to avoid redundant API calls
const talentCodeCache = new Map<string, string | null>();

function getTalentCacheReport(): void {
  const totalKeys = talentCodeCache.size;
  const nullKeys = Array.from(talentCodeCache.values()).filter(
    (value) => value === null
  ).length;
  const successfulKeys = totalKeys - nullKeys;
  const nullPercentage =
    totalKeys > 0 ? ((nullKeys / totalKeys) * 100).toFixed(1) : "0.0";
  const successPercentage =
    totalKeys > 0 ? ((successfulKeys / totalKeys) * 100).toFixed(1) : "0.0";

  console.log("\n=== Talent Code Cache Report ===");
  console.log(`Total talent code requests: ${totalKeys}`);
  console.log(
    `Successful talent codes: ${successfulKeys} (${successPercentage}%)`
  );
  console.log(`Failed/null talent codes: ${nullKeys} (${nullPercentage}%)`);
  console.log("================================\n");
}

async function getTalentCode(
  characterName: string,
  realm: string,
  specId: string
): Promise<string | null> {
  const url = `https://wow.spires.io/api/battlenet/profile/wow/character/${realm}/${characterName.toLowerCase()}/specializations?namespace=profile-us&locale=en_US`;
  const cacheKey = `${url}#${specId}`;

  // Check if we already have this specific talent code cached
  if (talentCodeCache.has(cacheKey)) {
    console.log(`Using cached talent code for ${cacheKey}`);
    return talentCodeCache.get(cacheKey)!;
  }

  try {
    console.log(`Fetching talent code for ${cacheKey}`);
    const res = await fetch(url);
    const data: SpecializationsApi = (await res.json()) as SpecializationsApi;

    // Find the matching spec and its active loadout
    const spec = data.specializations.find(
      (s) => `${s.specialization.id}` === specId
    );
    if (!spec) {
      console.log(`No spec found for ${cacheKey}`);
      talentCodeCache.set(cacheKey, null);
      return null;
    }

    const activeLoadout = spec.loadouts?.find((l) => l.is_active);
    if (!activeLoadout) {
      console.log(`No active loadout found for ${cacheKey}`);
      talentCodeCache.set(cacheKey, null);
      return null;
    }
    const talentCode = activeLoadout?.talent_loadout_code || null;

    // Cache the result (even if null)
    console.log(`set ${cacheKey} to ${talentCode}`);
    talentCodeCache.set(cacheKey, talentCode);
    return talentCode;
  } catch (error) {
    console.error(`Failed to fetch talent code from ${url}:`, error);
    // Cache the null result to avoid retrying failed requests
    talentCodeCache.set(cacheKey, null);
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

async function compileTalents(
  data: { bracket: string; data: Root }[],
  fileName: string
) {
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
            const talentCode = await getTalentCode(
              link.name,
              link.realm,
              specInfo.specId
            );

            if (talentCode == null) continue;

            const key = `${specInfo.specId}_${bracket}${i + 1}`;
            lines += `  {\n`;
            lines += `    ["bracket"] = "${bracket}",\n`;
            lines += `    ["rank"] = ${i + 1},\n`;
            lines += `    ["name"] = "${link.name}-${link.realm}",\n`;
            lines += `    ["code"] = "${talentCode || ""}",\n`;
            lines += `    ["classId"] = ${getClassIdFromSpecId(
              specInfo.specId
            )},\n`;
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

async function compileEnchants(
  data: { bracket: string; data: Root }[],
  fileName: string
) {
  const ignoredEnchants: number[] = [7933, 7924];
  await buildRaidbotsEnchantNameMap();

  let lines = `GSTEnchantsDb = {\n`;

  for (const { bracket, data: bracketData } of data) {
    const maybeLogBracket = (s: string) =>
      bracket === "xxx2v2" ? console.log(s) : null;
    for (const specInfo of bracketData) {
      maybeLogBracket("SPECINFO: " + specInfo.specId);
      if (specInfo.histoMaps && specInfo.histoMaps.length > 0) {
        for (const histoMap of specInfo.histoMaps) {
          if (histoMap.histo && histoMap.histo.length > 0) {
            const maybeLog = (s: string) =>
              bracket === "xxx2v2" &&
              histoMap.slotType == "FEET" &&
              specInfo.specId === "262"
                ? console.log(s)
                : null;

            // Create a map to track enchants by slot type and enchantment ID
            const enchantMap = new Map<
              string,
              { count: number; percent: number; enchant: Enchantment }
            >();

            for (const histoItem of histoMap.histo) {
              if (
                histoItem.item.enchantments &&
                histoItem.item.enchantments.length > 0
              ) {
                for (const enchant of histoItem.item.enchantments) {
                  if (enchant.enchantment_slot.type !== "PERMANENT") continue;
                  if (ignoredEnchants.includes(enchant.enchantment_id))
                    continue;
                  const enchantKey = `${enchant.enchantment_id}_${histoItem.item.slot.name}_${enchant.enchantment_slot.type}`;
                  // maybeLog(JSON.stringify(enchant));
                  // maybeLog(enchantKey);
                  if (enchantMap.has(enchantKey)) {
                    const existing = enchantMap.get(enchantKey)!;
                    existing.count += histoItem.count;
                    existing.percent += histoItem.percent;
                  } else {
                    maybeLog("Adding: " + enchantKey);
                    enchantMap.set(enchantKey, {
                      count: histoItem.count,
                      percent: histoItem.percent,
                      enchant: enchant,
                    });
                  }
                }
              }
            }

            maybeLog("print?");
            for (var k of enchantMap.keys()) {
              maybeLog(k);
              maybeLog(JSON.stringify(enchantMap.get(k)));
            }

            // Sort enchants by usage percentage and output the top ones
            const sortedEnchants = Array.from(enchantMap.values()).sort(
              (a, b) => b.percent - a.percent
            );

            for (let i = 0; i < sortedEnchants.length; i++) {
              const enchantData = sortedEnchants[i];
              const enchant = enchantData.enchant;

              // 262_3v3
              const key = `${specInfo.specId}_${bracket}_${histoMap.slotType}_${enchant.enchantment_id}`;
              lines += `  {\n`;
              lines += `    ["bracket"] = "${bracket}",\n`;
              lines += `    ["specId"] = ${parseInt(specInfo.specId)},\n`;
              lines += `    ["slotType"] = "${histoMap.slotType}",\n`;
              lines += `    ["enchantId"] = ${enchant.enchantment_id},\n`;
              lines += `    ["enchantName"] = "${sanitizeItemName(
                raidbotsEnchantNameMap.get(enchant.enchantment_id) ||
                  enchant.source_item?.name ||
                  enchant.display_string
              )}",\n`;
              lines += `    ["enchantSlotId"] = ${enchant.enchantment_slot.id},\n`;
              lines += `    ["enchantSlotType"] = "${enchant.enchantment_slot.type}",\n`;
              lines += `    ["percent"] = ${enchantData.percent.toFixed(1)},\n`;
              lines += `    ["rank"] = ${i + 1},\n`;
              lines += `  },\n`;
            }
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

async function compileSlotBasedGear(
  data: { bracket: string; data: Root }[],
  fileName: string
) {
  let lines = `GSTSlotGearDb = {\n`;

  for (const { bracket, data: bracketData } of data) {
    for (const specInfo of bracketData) {
      specInfo?.histoMaps.forEach((histoMap) => {
        const slotID = slotTypeToCorrectWOWSlot[histoMap.slotType];
        if (slotID) {
          // Add top 10 items for each slot
          histoMap.histo.slice(0, 10).forEach((item, idx) => {
            lines += `  {\n`;
            lines += `    ["bracket"] = "${bracket}",\n`;
            lines += `    ["specId"] = ${parseInt(specInfo.specId)},\n`;
            lines += `    ["slotId"] = ${slotID},\n`;
            lines += `    ["slotType"] = "${histoMap.slotType}",\n`;
            lines += `    ["itemId"] = ${item.item.item.id},\n`;
            lines += `    ["variantId"] = ${parseInt(item.id)},\n`;
            lines += `    ["itemName"] = "${sanitizeItemName(
              item.item.name
            )}",\n`;
            // Add detailed stats info to distinguish variants - only secondary stats
            const primaryStats = [
              "Stamina",
              "Strength",
              "Intellect",
              "Agility",
              "Spirit",
            ];
            const statsInfo = item.item.stats
              ? item.item.stats
                  .map((s) => s.type?.name || s.type)
                  .filter((stat) => {
                    const statName =
                      typeof stat === "string"
                        ? stat
                        : (stat as any)?.name || String(stat);
                    return statName && !primaryStats.includes(statName);
                  })
                  .filter(Boolean)
                  .join("/")
              : "";
            const shortStatsInfo = item.item.stats
              ? getStatsTag(item, false)
              : "";
            const statsShortPretty = item.item.stats ? getStatsTag(item) : "";

            lines += `    ["stats"] = "${statsInfo}",\n`;
            lines += `    ["statsShort"] = "${shortStatsInfo}",\n`;
            lines += `    ["statsShortPretty"] = "${statsShortPretty}",\n`;
            lines += `    ["percent"] = ${item.percent.toFixed(1)},\n`;
            lines += `    ["rank"] = ${idx + 1},\n`;

            lines += `  },\n`;
          });
        }
      });
    }
  }

  lines += "};\n\n";

  const fout = openSync(join(outputFolder, fileName), "w");
  writeFileSync(fout, lines);
  closeSync(fout);
}

async function main() {
  console.log("Starting build");

  // TEST
  // const td = await fetchHistoBlob(
  //   "composed_shuffle-deathknight-blood_LATEST.json"
  // );
  // await writeDbLuaFile(td, "td", "td.lua");
  // throw new Error("TEST OVER");
  // EXIT

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

  const shuffleData: Record<string, Root> = {};
  // do for all 40 shuffle specs:
  const slicedSpecs = shuffleSpecs; //.slice(0, 1); for debugging
  const slicedSpecNames = slicedSpecs.map((s) => s.replaceAll("-", "_"));
  for (const spec of slicedSpecs) {
    console.log(`Fetch: ${spec}`);
    const specData = await fetchHistoBlob(`composed_${spec}_LATEST.json`);
    const specName = spec.replaceAll("-", "_");
    shuffleData[specName] = specData;
    await writeDbLuaFile(
      specData,
      `usageDb${specName}`,
      `Gearing${specName}.lua`
    );
  }

  // Write BracketNames.lua:
  const bracketNames = ["pve", "2v2", "3v3", ...slicedSpecNames];
  const fout = openSync(join(outputFolder, "BracketNames.lua"), "w");
  writeFileSync(fout, `GSTBracketNames = {\n`);
  for (const bracket of bracketNames) {
    writeFileSync(fout, `  "${bracket}",\n`);
  }
  writeFileSync(fout, `};\n`);
  closeSync(fout);

  // Talents are FUBAR
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
      ...slicedSpecNames.map((spec) => ({
        bracket: spec,
        data: shuffleData[spec],
      })),
    ],
    "Loadouts.lua"
  );

  // Generate talent cache report
  getTalentCacheReport();

  await compileEnchants(
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
      ...slicedSpecNames.map((spec) => ({
        bracket: spec,
        data: shuffleData[spec],
      })),
    ],
    "Enchants.lua"
  );

  await compileSlotBasedGear(
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
      ...slicedSpecNames.map((spec) => ({
        bracket: spec,
        data: shuffleData[spec],
      })),
    ],
    "SlotGear.lua"
  );
}

main();

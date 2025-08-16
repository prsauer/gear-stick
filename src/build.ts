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
  isRankOne: boolean,
  bisName: string
) {
  return `["${key}"] = {${item.percent.toFixed(
    1
  )}, ${isRankOne}, "${bisName}"},\n`;
}

function sanitizeItemName(name: string) {
  return name.replace(/"/g, '\\"');
}

async function writeDbLuaFile(data: Root, dbName: string, fileName: string) {
  let lines = `${dbName} = {\n`;

  // Add profile count metadata for each spec
  data.forEach((specInfo) => {
    if (specInfo.profilesComparedCount) {
      lines += `["${specInfo.specId}_profileCount"] = ${specInfo.profilesComparedCount},\n`;
    }

    specInfo?.histoMaps.forEach((histoMap) => {
      if (histoMap.histo[0]) {
        lines += makeTTLine(
          `${specInfo.specId}${
            slotTypeToWOWItemLocationIndex[histoMap.slotType]
          }`,
          histoMap.histo[0],
          true,
          `${sanitizeItemName(
            histoMap.histo[0].item.name
          )} (${histoMap.histo[0].percent.toFixed(1)}%)`
        );
      }

      histoMap.histo.forEach((k, idx) => {
        lines += makeTTLine(
          `${specInfo.specId}${k.id}`,
          k,
          idx === 0,
          idx > 0
            ? `${sanitizeItemName(
                histoMap.histo[0].item.name
              )} (${histoMap.histo[0].percent.toFixed(1)}%)`
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

async function getTalentCode(
  characterName: string,
  realm: string,
  specId: string
): Promise<string | null> {
  try {
    const res = await fetch(
      `https://wow.spires.io/api/battlenet/profile/wow/character/${realm}/${characterName.toLowerCase()}/specializations?namespace=profile-us&locale=en_US`
    );
    const data: SpecializationsApi = (await res.json()) as SpecializationsApi;

    // Find the matching spec and its active loadout
    const spec = data.specializations.find(
      (s) => `${s.specialization.id}` === specId
    );
    if (!spec) return null;

    const activeLoadout = spec.loadouts.find((l) => l.is_active);
    return activeLoadout?.talent_loadout_code || null;
  } catch (error) {
    console.error(
      `Failed to fetch talent code for ${characterName}-${realm} (spec ${specId}):`,
      error
    );
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
  let lines = `GSTEnchantsDb = {\n`;

  for (const { bracket, data: bracketData } of data) {
    for (const specInfo of bracketData) {
      if (specInfo.histoMaps && specInfo.histoMaps.length > 0) {
        for (const histoMap of specInfo.histoMaps) {
          if (histoMap.histo && histoMap.histo.length > 0) {
            // Create a map to track enchants by slot type and enchantment ID
            const enchantMap = new Map<
              string,
              { count: number; percent: number; enchant: any }
            >();

            for (const histoItem of histoMap.histo) {
              if (
                histoItem.item.enchantments &&
                histoItem.item.enchantments.length > 0
              ) {
                for (const enchant of histoItem.item.enchantments) {
                  const enchantKey = `${enchant.enchantment_id}_${enchant.enchantment_slot.type}`;

                  if (enchantMap.has(enchantKey)) {
                    const existing = enchantMap.get(enchantKey)!;
                    existing.count += histoItem.count;
                    existing.percent += histoItem.percent;
                  } else {
                    enchantMap.set(enchantKey, {
                      count: histoItem.count,
                      percent: histoItem.percent,
                      enchant: enchant,
                    });
                  }
                }
              }
            }

            // Sort enchants by usage percentage and output the top ones
            const sortedEnchants = Array.from(enchantMap.values())
              .sort((a, b) => b.percent - a.percent)
              .slice(0, 5); // Top 5 enchants per slot

            for (let i = 0; i < sortedEnchants.length; i++) {
              const enchantData = sortedEnchants[i];
              const enchant = enchantData.enchant;

              const key = `${specInfo.specId}_${bracket}_${histoMap.slotType}_${enchant.enchantment_id}`;
              lines += `  {\n`;
              lines += `    ["bracket"] = "${bracket}",\n`;
              lines += `    ["specId"] = ${parseInt(specInfo.specId)},\n`;
              lines += `    ["slotType"] = "${histoMap.slotType}",\n`;
              lines += `    ["enchantId"] = ${enchant.enchantment_id},\n`;
              lines += `    ["enchantName"] = "${sanitizeItemName(
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
              ? item.item.stats
                  .map((s) => {
                    const statType = s.type?.name || s.type;
                    return statType;
                  })
                  .filter((stat) => {
                    const statName =
                      typeof stat === "string"
                        ? stat
                        : (stat as any)?.name || String(stat);
                    return statName && !primaryStats.includes(statName);
                  })
                  .map((statType) => {
                    // Convert to shorter names
                    return typeof statType === "string"
                      ? statType
                          .replace("Critical Strike", "Crit")
                          .replace("Versatility", "Vers")
                          .replace("Mastery", "Mast")
                          .replace("Haste", "Haste")
                      : String(statType);
                  })
                  .filter(Boolean)
                  .join("/")
              : "";

            lines += `    ["stats"] = "${statsInfo}",\n`;
            lines += `    ["statsShort"] = "${shortStatsInfo}",\n`;
            lines += `    ["percent"] = ${item.percent.toFixed(1)},\n`;
            lines += `    ["rank"] = ${idx + 1},\n`;
            lines += `    ["isBis"] = ${idx === 0},\n`;
            lines += `  },\n`;
          });
        }
      });
    }
  }

  lines += "};\n\n";

  // Add helper functions for working with stat variants
  lines += `-- Helper functions for slot gear database\n`;
  lines += `GSTSlotGearHelpers = {}\n\n`;

  lines += `-- Get items for a specific slot/spec/bracket\n`;
  lines += `function GSTSlotGearHelpers.GetSlotItems(slotId, specId, bracket)\n`;
  lines += `    local items = {}\n`;
  lines += `    for _, item in ipairs(GSTSlotGearDb) do\n`;
  lines += `        if item.slotId == slotId and item.specId == specId and item.bracket == bracket then\n`;
  lines += `            table.insert(items, item)\n`;
  lines += `        end\n`;
  lines += `    end\n`;
  lines += `    table.sort(items, function(a, b) return a.rank < b.rank end)\n`;
  lines += `    return items\n`;
  lines += `end\n\n`;

  lines += `-- Find best matching variant for equipped item\n`;
  lines += `function GSTSlotGearHelpers.FindBestMatch(equippedItemId, slotItems)\n`;
  lines += `    -- First try exact itemId match\n`;
  lines += `    for _, item in ipairs(slotItems) do\n`;
  lines += `        if item.itemId == equippedItemId then\n`;
  lines += `            return item\n`;
  lines += `        end\n`;
  lines += `    end\n`;
  lines += `    return nil\n`;
  lines += `end\n\n`;

  lines += `-- Format item display with stats\n`;
  lines += `function GSTSlotGearHelpers.FormatItemDisplay(item)\n`;
  lines += `    local statsText = ""\n`;
  lines += `    if item.statsShort and item.statsShort ~= "" then\n`;
  lines += `        statsText = " (" .. item.statsShort .. ")"\n`;
  lines += `    end\n`;
  lines += `    local bisText = item.isBis and " (BiS)" or ""\n`;
  lines += `    return string.format("%.1f%% - %s%s%s", item.percent, item.itemName, statsText, bisText)\n`;
  lines += `end\n\n`;

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
    ],
    "SlotGear.lua"
  );
}

main();

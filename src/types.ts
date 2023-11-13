export type Root = Root2[];

export interface Root2 {
  specId: string;
  histoMaps: HistoMap[];
  statDist: StatDist;
  links: Link2[];
  stats: Stats;
  profilesComparedCount: number;
}

export interface HistoMap {
  slotType: string;
  histo: Histo[];
}

export interface Histo {
  id: string;
  count: number;
  item: Item;
  percent: number;
}

export interface Item {
  item: Item2;
  sockets?: Socket[];
  slot: Slot;
  quantity: number;
  context?: number;
  bonus_list?: number[];
  quality: Quality;
  name: string;
  modified_appearance_id?: number;
  media: Media2;
  item_class: ItemClass;
  item_subclass: ItemSubclass;
  inventory_type: InventoryType;
  binding: Binding;
  armor?: Armor;
  stats?: Stat[];
  sell_price?: SellPrice;
  requirements?: Requirements;
  set?: Set;
  level: Level2;
  transmog?: Transmog;
  durability?: Durability;
  name_description?: NameDescription;
  is_subclass_hidden?: boolean;
  modified_crafting_stat?: ModifiedCraftingStat[];
  enchantments?: Enchantment[];
  spells?: Spell3[];
  limit_category?: string;
  unique_equipped?: string;
  description?: string;
  weapon?: Weapon;
  shield_block?: ShieldBlock;
  azerite_details?: AzeriteDetails;
  timewalker_level?: number;
  socket_bonus?: string;
}

export interface Item2 {
  key: Key;
  id: number;
}

export interface Key {
  href: string;
}

export interface Socket {
  socket_type: SocketType;
  item?: Item3;
  display_string?: string;
  media?: Media;
  bonus_list?: number[];
  item_level?: number;
  display_color?: DisplayColor;
  context?: number;
}

export interface SocketType {
  type: string;
  name: string;
}

export interface Item3 {
  key: Key2;
  name: string;
  id: number;
}

export interface Key2 {
  href: string;
}

export interface Media {
  key: Key3;
  id: number;
}

export interface Key3 {
  href: string;
}

export interface DisplayColor {
  r: number;
  g: number;
  b: number;
  a: number;
}

export interface Slot {
  type: string;
  name: string;
}

export interface Quality {
  type: string;
  name: string;
}

export interface Media2 {
  key: Key4;
  id: number;
}

export interface Key4 {
  href: string;
}

export interface ItemClass {
  key: Key5;
  name: string;
  id: number;
}

export interface Key5 {
  href: string;
}

export interface ItemSubclass {
  key: Key6;
  name: string;
  id: number;
}

export interface Key6 {
  href: string;
}

export interface InventoryType {
  type: string;
  name: string;
}

export interface Binding {
  type: string;
  name: string;
}

export interface Armor {
  value: number;
  display: Display;
}

export interface Display {
  display_string: string;
  color: Color;
}

export interface Color {
  r: number;
  g: number;
  b: number;
  a: number;
}

export interface Stat {
  type: Type;
  value: number;
  display: Display2;
  is_negated?: boolean;
  is_equip_bonus?: boolean;
}

export interface Type {
  type: string;
  name: string;
}

export interface Display2 {
  display_string: string;
  color: Color2;
}

export interface Color2 {
  r: number;
  g: number;
  b: number;
  a: number;
}

export interface SellPrice {
  value: number;
  display_strings: DisplayStrings;
}

export interface DisplayStrings {
  header: string;
  gold: string;
  silver: string;
  copper: string;
}

export interface Requirements {
  level: Level;
  playable_classes?: PlayableClasses;
  skill?: Skill;
  faction?: Faction;
}

export interface Level {
  value: number;
  display_string: string;
}

export interface PlayableClasses {
  links: Link[];
  display_string: string;
}

export interface Link {
  key: Key7;
  name: string;
  id: number;
}

export interface Key7 {
  href: string;
}

export interface Skill {
  profession: Profession;
  level: number;
  display_string: string;
}

export interface Profession {
  key: Key8;
  name: string;
  id: number;
}

export interface Key8 {
  href: string;
}

export interface Faction {
  value: Value;
  display_string: string;
}

export interface Value {
  type: string;
  name: string;
}

export interface Set {
  item_set: ItemSet;
  items: Item4[];
  effects: Effect[];
  display_string: string;
}

export interface ItemSet {
  key: Key9;
  name: string;
  id: number;
}

export interface Key9 {
  href: string;
}

export interface Item4 {
  item: Item5;
  is_equipped?: boolean;
}

export interface Item5 {
  key: Key10;
  name: string;
  id: number;
}

export interface Key10 {
  href: string;
}

export interface Effect {
  display_string: string;
  required_count: number;
  is_active?: boolean;
}

export interface Level2 {
  value: number;
  display_string: string;
}

export interface Transmog {
  item: Item6;
  display_string: string;
  item_modified_appearance_id: number;
  second_item?: SecondItem;
  second_item_modified_appearance_id?: number;
}

export interface Item6 {
  key: Key11;
  name: string;
  id: number;
}

export interface Key11 {
  href: string;
}

export interface SecondItem {
  key: Key12;
  name: string;
  id: number;
}

export interface Key12 {
  href: string;
}

export interface Durability {
  value: number;
  display_string: string;
}

export interface NameDescription {
  display_string: string;
  color: Color3;
}

export interface Color3 {
  r: number;
  g: number;
  b: number;
  a: number;
}

export interface ModifiedCraftingStat {
  id: number;
  type: string;
  name: string;
}

export interface Enchantment {
  display_string: string;
  enchantment_id: number;
  enchantment_slot: EnchantmentSlot;
  source_item?: SourceItem;
  spell?: Spell;
}

export interface EnchantmentSlot {
  id: number;
  type: string;
}

export interface SourceItem {
  key: Key13;
  name: string;
  id: number;
}

export interface Key13 {
  href: string;
}

export interface Spell {
  spell: Spell2;
  description: string;
}

export interface Spell2 {
  key: Key14;
  name: string;
  id: number;
}

export interface Key14 {
  href: string;
}

export interface Spell3 {
  spell: Spell4;
  description: string;
  display_color?: DisplayColor2;
}

export interface Spell4 {
  key: Key15;
  name: string;
  id: number;
}

export interface Key15 {
  href: string;
}

export interface DisplayColor2 {
  r: number;
  g: number;
  b: number;
  a: number;
}

export interface Weapon {
  damage: Damage;
  attack_speed: AttackSpeed;
  dps: Dps;
}

export interface Damage {
  min_value: number;
  max_value: number;
  display_string: string;
  damage_class: DamageClass;
}

export interface DamageClass {
  type: string;
  name: string;
}

export interface AttackSpeed {
  value: number;
  display_string: string;
}

export interface Dps {
  value: number;
  display_string: string;
}

export interface ShieldBlock {
  value: number;
  display: Display3;
}

export interface Display3 {
  display_string: string;
  color: Color4;
}

export interface Color4 {
  r: number;
  g: number;
  b: number;
  a: number;
}

export interface AzeriteDetails {
  selected_powers?: SelectedPower[];
  selected_powers_string?: string;
  percentage_to_next_level?: number;
  selected_essences?: SelectedEssence[];
  level?: Level3;
}

export interface SelectedPower {
  id: number;
  tier: number;
  spell_tooltip: SpellTooltip;
  is_display_hidden?: boolean;
}

export interface SpellTooltip {
  spell: Spell5;
  description: string;
  cast_time: string;
}

export interface Spell5 {
  key: Key16;
  name: string;
  id: number;
}

export interface Key16 {
  href: string;
}

export interface SelectedEssence {
  slot: number;
  rank: number;
  main_spell_tooltip?: MainSpellTooltip;
  passive_spell_tooltip: PassiveSpellTooltip;
  essence: Essence;
  media: Media3;
}

export interface MainSpellTooltip {
  spell: Spell6;
  description: string;
  cast_time: string;
  cooldown?: string;
}

export interface Spell6 {
  key: Key17;
  name: string;
  id: number;
}

export interface Key17 {
  href: string;
}

export interface PassiveSpellTooltip {
  spell: Spell7;
  description: string;
  cast_time: string;
}

export interface Spell7 {
  key: Key18;
  name: string;
  id: number;
}

export interface Key18 {
  href: string;
}

export interface Essence {
  key: Key19;
  name: string;
  id: number;
}

export interface Key19 {
  href: string;
}

export interface Media3 {
  key: Key20;
  id: number;
}

export interface Key20 {
  href: string;
}

export interface Level3 {
  value: number;
  display_string: string;
}

export interface StatDist {
  VERSATILITY: number;
  MASTERY_RATING: number;
  HASTE_RATING: number;
  CRIT_RATING: number;
}

export interface Link2 {
  name: string;
  realm: string;
  region: string;
}

export interface Stats {
  played: number;
  won: number;
  lost: number;
}

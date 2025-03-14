export interface SpecializationsApi {
  _links: Links;
  specializations: Specialization[];
  active_specialization: ActiveSpecialization;
  character: Character;
  active_hero_talent_tree: ActiveHeroTalentTree;
}

export interface Links {
  self: Self;
}

export interface Self {
  href: string;
}

export interface Specialization {
  specialization: Specialization2;
  pvp_talent_slots: PvpTalentSlot[];
  loadouts: Loadout[];
}

export interface Specialization2 {
  key: Key;
  name: string;
  id: number;
}

export interface Key {
  href: string;
}

export interface PvpTalentSlot {
  selected: Selected;
  slot_number: number;
}

export interface Selected {
  talent: Talent;
  spell_tooltip: SpellTooltip;
}

export interface Talent {
  key: Key2;
  name: string;
  id: number;
}

export interface Key2 {
  href: string;
}

export interface SpellTooltip {
  spell: Spell;
  description: string;
  cast_time: string;
  power_cost?: string;
  cooldown?: string;
}

export interface Spell {
  key: Key3;
  name: string;
  id: number;
}

export interface Key3 {
  href: string;
}

export interface Loadout {
  is_active: boolean;
  talent_loadout_code: string;
  selected_class_talents: SelectedClassTalent[];
  selected_spec_talents: SelectedSpecTalent[];
  selected_hero_talents: SelectedHeroTalent[];
  selected_class_talent_tree: SelectedClassTalentTree;
  selected_spec_talent_tree: SelectedSpecTalentTree;
  selected_hero_talent_tree: SelectedHeroTalentTree;
}

export interface SelectedClassTalent {
  id: number;
  rank: number;
  tooltip?: Tooltip;
  default_points?: number;
}

export interface Tooltip {
  talent: Talent2;
  spell_tooltip: SpellTooltip2;
}

export interface Talent2 {
  key: Key4;
  name: string;
  id: number;
}

export interface Key4 {
  href: string;
}

export interface SpellTooltip2 {
  spell: Spell2;
  description: string;
  cast_time: string;
  cooldown?: string;
  range?: string;
  power_cost?: string;
}

export interface Spell2 {
  key: Key5;
  name: string;
  id: number;
}

export interface Key5 {
  href: string;
}

export interface SelectedSpecTalent {
  id: number;
  rank: number;
  tooltip: Tooltip2;
}

export interface Tooltip2 {
  talent: Talent3;
  spell_tooltip: SpellTooltip3;
}

export interface Talent3 {
  key: Key6;
  name: string;
  id: number;
}

export interface Key6 {
  href: string;
}

export interface SpellTooltip3 {
  spell: Spell3;
  description: string;
  cast_time: string;
  power_cost?: string;
  cooldown?: string;
  range?: string;
}

export interface Spell3 {
  key: Key7;
  name: string;
  id: number;
}

export interface Key7 {
  href: string;
}

export interface SelectedHeroTalent {
  id: number;
  rank: number;
  tooltip: Tooltip3;
  default_points?: number;
}

export interface Tooltip3 {
  talent: Talent4;
  spell_tooltip: SpellTooltip4;
}

export interface Talent4 {
  key: Key8;
  name: string;
  id: number;
}

export interface Key8 {
  href: string;
}

export interface SpellTooltip4 {
  spell: Spell4;
  description: string;
  cast_time: string;
}

export interface Spell4 {
  key: Key9;
  name: string;
  id: number;
}

export interface Key9 {
  href: string;
}

export interface SelectedClassTalentTree {
  key: Key10;
  name: string;
}

export interface Key10 {
  href: string;
}

export interface SelectedSpecTalentTree {
  key: Key11;
  name: string;
}

export interface Key11 {
  href: string;
}

export interface SelectedHeroTalentTree {
  key: Key12;
  name: string;
  id: number;
}

export interface Key12 {
  href: string;
}

export interface ActiveSpecialization {
  key: Key13;
  name: string;
  id: number;
}

export interface Key13 {
  href: string;
}

export interface Character {
  key: Key14;
  name: string;
  id: number;
  realm: Realm;
}

export interface Key14 {
  href: string;
}

export interface Realm {
  key: Key15;
  name: string;
  id: number;
  slug: string;
}

export interface Key15 {
  href: string;
}

export interface ActiveHeroTalentTree {
  key: Key16;
  name: string;
  id: number;
}

export interface Key16 {
  href: string;
}

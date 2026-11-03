/**
 * The domain catalogue: stable display metadata for the sixteen knowledge
 * domains.
 *
 * Titles and descriptions are read from the corpus at export time (the
 * per-domain `README.md` heading and the table in `domains/README.md`); this
 * module only supplies the parts that the corpus does not carry, namely the
 * accent colour and the canonical ordering.
 *
 * @module scripts/lib/domains
 */

/**
 * @typedef {object} DomainSeed
 * @property {string} id Domain slug, e.g. `survival`.
 * @property {number} hue Accent hue in degrees, used by both themes.
 * @property {string} fallbackTitle Used when the corpus has no domain README.
 * @property {string} fallbackDescription Used when the corpus has no domain table.
 */

/**
 * Ordered to match `[domains] list` in `manifest.toml`.
 *
 * @type {DomainSeed[]}
 */
export const DOMAIN_SEEDS = [
  { id: 'survival', hue: 5, fallbackTitle: 'Survival & Immediate Needs', fallbackDescription: 'Immediate needs: water, fire, shelter, first aid' },
  { id: 'water', hue: 195, fallbackTitle: 'Water & Sanitation', fallbackDescription: 'Harvesting, protecting, storing, and reusing water' },
  { id: 'agriculture', hue: 105, fallbackTitle: 'Agriculture & Food Systems', fallbackDescription: 'Food production, soil, livestock, preservation' },
  { id: 'materials', hue: 35, fallbackTitle: 'Materials & Fabrication', fallbackDescription: 'Metals, glass, textiles, chemicals, adhesives' },
  { id: 'energy', hue: 48, fallbackTitle: 'Energy & Power', fallbackDescription: 'Generation, storage, distribution, conversion' },
  { id: 'construction', hue: 20, fallbackTitle: 'Construction & Infrastructure', fallbackDescription: 'Shelter, infrastructure, water systems, sanitation' },
  { id: 'transport', hue: 330, fallbackTitle: 'Transport & Logistics', fallbackDescription: 'Carts, pack animals, ferries, bicycles, logistics' },
  { id: 'health', hue: 345, fallbackTitle: 'Health & Medicine', fallbackDescription: 'Medicine, surgery, pharmacology, mental health' },
  { id: 'knowledge', hue: 175, fallbackTitle: 'Knowledge & Communication', fallbackDescription: 'Communication, printing, education, art, music' },
  { id: 'society', hue: 310, fallbackTitle: 'Society & Governance', fallbackDescription: 'Governance, economics, conflict resolution, culture' },
  { id: 'chemistry', hue: 85, fallbackTitle: 'Chemistry & Laboratory', fallbackDescription: 'Reactions, analysis, separation, laboratory safety' },
  { id: 'biology', hue: 135, fallbackTitle: 'Biology & Life Sciences', fallbackDescription: 'Cells, genetics, ecology, agriculture, field medicine' },
  { id: 'silicon', hue: 230, fallbackTitle: 'Silicon & Semiconductors', fallbackDescription: 'Silicon purification, wafers, fabrication, devices' },
  { id: 'ship', hue: 255, fallbackTitle: 'Ship Design & Building', fallbackDescription: 'Hull design, shipyards, welding, propulsion, safety' },
  { id: 'computers', hue: 275, fallbackTitle: 'Computers & Electronics', fallbackDescription: 'Electronics, embedded software, systems, data' },
  { id: 'quantum', hue: 290, fallbackTitle: 'Quantum Computing', fallbackDescription: 'Qubits, cryogenics, control, error correction' },
];

/**
 * Convert an HSL colour to a hex string.
 *
 * @param {number} hue Hue in degrees.
 * @param {number} saturation Saturation percentage.
 * @param {number} lightness Lightness percentage.
 * @returns {string} Hex colour such as `#3d7ea6`.
 */
export function hslToHex(hue, saturation, lightness) {
  const s = saturation / 100;
  const l = lightness / 100;
  const chroma = (1 - Math.abs(2 * l - 1)) * s;
  const secondary = chroma * (1 - Math.abs(((hue / 60) % 2) - 1));
  const match = l - chroma / 2;
  let r = 0;
  let g = 0;
  let b = 0;
  if (hue < 60) {
    r = chroma; g = secondary;
  } else if (hue < 120) {
    r = secondary; g = chroma;
  } else if (hue < 180) {
    g = chroma; b = secondary;
  } else if (hue < 240) {
    g = secondary; b = chroma;
  } else if (hue < 300) {
    r = secondary; b = chroma;
  } else {
    r = chroma; b = secondary;
  }
  const toHex = (/** @type {number} */ value) => Math.round((value + match) * 255).toString(16).padStart(2, '0');
  return `#${toHex(r)}${toHex(g)}${toHex(b)}`;
}

/**
 * The accent colour used for a domain in the light theme.
 *
 * @param {number} hue
 * @returns {string}
 */
export function domainColor(hue) {
  return hslToHex(hue, 55, 38);
}

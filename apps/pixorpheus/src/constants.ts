export const GABIN_ID = "U0A2SJ7B739";
export const RIDIT_ID = "U0ARC79GEAV";

export const PIXL_CHANNELS = ["C0B5P4N0WHH", "C0B5UEMF4RW"];
export const PIXL_PROMO = `\n\n_Join <#C0B5P4N0WHH> to discover more Pixl commands!_`;

export const TRAINING_CHANNEL = "C0BD7JSTQNM";

/**
 * Channels Pixo must never speak in — not even a mention, chime-in, or
 * easter egg. Checked first thing in the message handler, before anything
 * else runs.
 */
export const SILENCED_CHANNELS = new Set([
  "C0AUZ1LAMH6",
  "C0AUZ1P2DEC",
  "C0AU8AWD5BN",
  "C0AUZ1X5QAU",
]);

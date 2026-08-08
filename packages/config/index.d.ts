export interface PixlConfig {
  name: string;
  tagline: string;
  /** ISO-8601 UTC instant the program goes live. */
  launchDate: string;
  /** ISO-8601 UTC instant from which coding time counts toward shipping. */
  hackatimeCutoff: string;
  urls: {
    site: string;
    play: string;
    docs: string;
    repo: string;
  };
  economy: {
    pixelsPerHour: number;
    pixelValueUsd: number;
  };
  team: string[];
}

export declare const config: PixlConfig;
export declare const launchDate: Date;
export declare const hackatimeCutoff: Date;
export declare const hackatimeCutoffUnix: number;
export declare function hasLaunched(now?: Date): boolean;
export declare function formatDate(
  date: Date,
  opts?: Intl.DateTimeFormatOptions,
  locale?: string,
): string;
export declare const hackatimeCutoffLabel: string;
export declare const launchDateLabel: string;

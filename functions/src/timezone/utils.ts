// functions/src/timezone/utils.ts
import { DateTime } from 'luxon';

/**
 * Validate IANA timezone using luxon
 * Dynamically checks if the timezone is valid by attempting to use it
 * @param zone - The timezone string to validate
 * @returns true if valid IANA timezone, false otherwise
 */
export function isValidIanaZone(zone: string): boolean {
  try {
    if (!zone || typeof zone !== 'string') return false;
    const dt = DateTime.now().setZone(zone);
    return dt.isValid && dt.zoneName === zone;
  } catch (e) {
    return false;
  }
}

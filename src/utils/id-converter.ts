/**
 * Safely converts a string ID to a number
 * Returns null if the conversion fails
 */
export function toNumber(value: string | undefined): number | null {
  if (!value) return null;
  const num = parseInt(value, 10);
  return isNaN(num) ? null : num;
}

/**
 * Converts a string ID to a number
 * Throws an error if the conversion fails
 */
export function toNumberOrThrow(value: string | undefined, paramName: string = 'id'): number {
  const num = toNumber(value);
  if (num === null) {
    throw new Error(`Invalid ${paramName}: ${value}`);
  }
  return num;
} 
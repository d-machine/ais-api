import { _isEmpty, _isNil } from './aisLodash.js';

/**
 * Safely converts a string ID to a number
 * Returns null if the conversion fails
 */
export function toNumber(value: string | null | undefined): number | null {
  if (_isEmpty(value)) return null;
  const num = Number(value);
  return isNaN(num) ? null : num;
}

/**
 * Converts a string ID to a number
 * Throws an error if the conversion fails
 */
export function toNumberOrThrow(value: string | null | undefined, paramName: string): number {
  const num = toNumber(value);
  if (_isNil(num)) {
    throw new Error(`Invalid ${paramName}: ${value}`);
  }
  return num;
} 
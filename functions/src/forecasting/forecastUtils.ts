// functions/src/forecasting/forecastUtils.ts
import { DateTime } from 'luxon';

/** Simple linear regression for y ~ a + b*x */
export function linearRegression(xs: number[], ys: number[]) {
  const n = xs.length;
  if (n === 0) return { a: 0, b: 0 };
  const meanX = xs.reduce((s, v) => s + v, 0) / n;
  const meanY = ys.reduce((s, v) => s + v, 0) / n;
  let num = 0, den = 0;
  for (let i = 0; i < n; i++) {
    num += (xs[i] - meanX) * (ys[i] - meanY);
    den += (xs[i] - meanX) ** 2;
  }
  const b = den === 0 ? 0 : num / den;
  const a = meanY - b * meanX;
  return { a, b };
}

/** Holt's linear exponential smoothing (level + trend) */
export function holtLinear(series: number[], alpha = 0.3, beta = 0.1, horizon = 30): number[] {
  if (series.length === 0) return Array(horizon).fill(0);
  if (series.length === 1) return Array(horizon).fill(series[0]);

  let level = series[0];
  let trend = series[1] - series[0];

  for (let t = 1; t < series.length; t++) {
    const value = series[t];
    const prevLevel = level;
    level = alpha * value + (1 - alpha) * (level + trend);
    trend = beta * (level - prevLevel) + (1 - beta) * trend;
  }

  const forecast: number[] = [];
  for (let i = 1; i <= horizon; i++) {
    forecast.push(level + i * trend);
  }
  return forecast;
}

/** Build ISO date range from start date */
export function buildDateRange(start: Date, days: number): string[] {
  const arr: string[] = [];
  const s = DateTime.fromJSDate(start).startOf('day');
  for (let i = 0; i < days; i++) {
    arr.push(s.plus({ days: i }).toISODate()!);
  }
  return arr;
}

/** Compute residuals and standard deviation */
export function residualsAndStd(series: number[], fitted: number[]) {
  const n = Math.min(series.length, fitted.length);
  if (n === 0) return { residuals: [], std: 0 };
  const residuals = series.slice(0, n).map((v, i) => v - fitted[i]);
  const mean = residuals.reduce((s, v) => s + v, 0) / n;
  const variance = residuals.reduce((s, v) => s + (v - mean) ** 2, 0) / n;
  return { residuals, std: Math.sqrt(variance) };
}

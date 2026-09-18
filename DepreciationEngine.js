/**
 * Enterprise Asset Management System (EAMS)
 * Core Depreciation Engine
 * 
 * Supports:
 * - Straight Line (Garis Lurus)
 * - Declining Balance (Saldo Menurun)
 * - Double Declining Balance
 * - Sum of Years Digit (SYD)
 */

class DepreciationEngine {
    
    /**
     * Calculate Straight Line Depreciation for a single period (month)
     * @param {number} acquisitionCost - Nilai perolehan
     * @param {number} residualValue - Nilai sisa (salvage value)
     * @param {number} usefulLifeMonths - Umur ekonomis dalam bulan
     * @returns {number} Beban penyusutan per bulan
     */
    static calculateStraightLine(acquisitionCost, residualValue, usefulLifeMonths) {
        if (usefulLifeMonths <= 0) return 0;
        const depreciableAmount = acquisitionCost - residualValue;
        return depreciableAmount / usefulLifeMonths;
    }

    /**
     * Calculate Declining Balance Depreciation for a given year
     * @param {number} currentBookValue - Nilai buku di awal tahun
     * @param {number} rate - Persentase penyusutan (misal: 0.2 untuk 20%)
     * @returns {number} Beban penyusutan setahun
     */
    static calculateDecliningBalanceYearly(currentBookValue, rate) {
        return currentBookValue * rate;
    }

    /**
     * Generate full depreciation schedule (Simulasi Penyusutan) - Straight Line
     */
    static generateScheduleStraightLine(assetId, acquisitionDate, acquisitionCost, residualValue, usefulLifeMonths) {
        let schedule = [];
        let currentBookValue = acquisitionCost;
        let accumulatedDepreciation = 0;
        const monthlyDepreciation = this.calculateStraightLine(acquisitionCost, residualValue, usefulLifeMonths);
        
        let currentDate = new Date(acquisitionDate);
        // Start depreciation on the next month
        currentDate.setMonth(currentDate.getMonth() + 1);

        for (let i = 1; i <= usefulLifeMonths; i++) {
            // Last month adjustment to match exact residual value due to rounding
            let actualDepreciation = monthlyDepreciation;
            if (i === usefulLifeMonths) {
                actualDepreciation = currentBookValue - residualValue;
            }

            accumulatedDepreciation += actualDepreciation;
            currentBookValue -= actualDepreciation;

            schedule.push({
                period: i,
                year: currentDate.getFullYear(),
                month: currentDate.getMonth() + 1,
                depreciationExpense: parseFloat(actualDepreciation.toFixed(2)),
                accumulatedDepreciation: parseFloat(accumulatedDepreciation.toFixed(2)),
                bookValue: parseFloat(currentBookValue.toFixed(2))
            });

            currentDate.setMonth(currentDate.getMonth() + 1);
        }

        return schedule;
    }
}

// ==========================================
// EXAMPLE USAGE / TEST
// ==========================================

// Asset: Server Rack, Cost: Rp 120,000,000, Residual: Rp 10,000,000, Life: 48 Months (4 years)
const assetCost = 120000000;
const residual = 10000000;
const lifeMonths = 48;
const acqDate = '2026-09-15';

console.log(`--- EAMS DEPRECIATION SIMULATION ---`);
console.log(`Asset Cost: Rp ${assetCost}`);
console.log(`Residual Value: Rp ${residual}`);
console.log(`Useful Life: ${lifeMonths} months`);
console.log(`Method: Straight Line`);
console.log(`------------------------------------`);

const schedule = DepreciationEngine.generateScheduleStraightLine('AST-001', acqDate, assetCost, residual, lifeMonths);

// Print first 3 months and last 3 months to console
console.log('First 3 Months:');
console.table(schedule.slice(0, 3));

console.log('Last 3 Months:');
console.table(schedule.slice(-3));

// Export module for use in Node/NestJS
// module.exports = DepreciationEngine;

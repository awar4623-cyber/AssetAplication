/**
 * Enterprise Asset Management System (EAMS)
 * Report Generator Logic (Excel/CSV & PDF)
 * 
 * Note: In a real Node.js environment, this would use libraries like:
 * - exceljs (for complex Excel with formatting)
 * - pdfkit or puppeteer (for PDF generation)
 */

class ReportGenerator {

    /**
     * Helper to format currency
     */
    static formatCurrency(amount) {
        return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR' }).format(amount);
    }

    /**
     * 1. Generate Asset Register Report (CSV/Excel format logic)
     * @param {Array} assets - List of asset objects from DB
     * @returns {string} - CSV String (Mock for Excel export)
     */
    static generateAssetRegisterCSV(assets) {
        if (!assets || assets.length === 0) return "No data available";

        console.log("[Report] Generating Asset Register (Excel/CSV)...");

        // Define headers
        const headers = [
            "Asset Code", 
            "Asset Name", 
            "Category", 
            "Acquisition Date", 
            "Acquisition Cost", 
            "Accumulated Depreciation", 
            "Net Book Value",
            "Status"
        ];
        
        let csvContent = headers.join(",") + "\n";

        // Map data rows
        assets.forEach(asset => {
            const row = [
                `"${asset.code}"`,
                `"${asset.name}"`,
                `"${asset.category}"`,
                `"${asset.acquisitionDate}"`,
                `"${asset.acquisitionCost}"`,
                `"${asset.accumulatedDepreciation}"`,
                `"${asset.bookValue}"`,
                `"${asset.status}"`
            ];
            csvContent += row.join(",") + "\n";
        });

        return csvContent;
    }

    /**
     * 2. Generate Depreciation Monthly Report (PDF Layout Logic)
     * @param {string} period - 'YYYY-MM'
     * @param {Array} schedules - Depreciation data
     */
    static generateDepreciationPDFMockup(period, schedules) {
        console.log(`[Report] Generating Monthly Depreciation PDF for ${period}...`);
        
        let totalExpense = 0;
        
        // This simulates drawing PDF text lines (like in pdfkit)
        let pdfOutput = `
=========================================================
            PT. BRONEO ALUMINA INDONESIA
        MONTHLY DEPRECIATION REPORT
=========================================================
Period     : ${period}
Generated  : ${new Date().toLocaleString()}
---------------------------------------------------------
Asset Code | Name                 | Depr. Expense (IDR)
---------------------------------------------------------`;

        schedules.forEach(s => {
            pdfOutput += `\n${s.assetCode.padEnd(10)} | ${s.name.padEnd(20)} | ${this.formatCurrency(s.expense)}`;
            totalExpense += s.expense;
        });

        pdfOutput += `
---------------------------------------------------------
TOTAL DEPRECIATION EXPENSE:     ${this.formatCurrency(totalExpense)}
=========================================================
* This document is computer generated and requires no signature.
`;

        return pdfOutput;
    }
}

// ==========================================
// EXAMPLE USAGE / TEST
// ==========================================

const dummyAssets = [
    { code: 'AST-001', name: 'Server Rack', category: 'IT', acquisitionDate: '2025-01-10', acquisitionCost: 150000000, accumulatedDepreciation: 50000000, bookValue: 100000000, status: 'Active' },
    { code: 'AST-002', name: 'Delivery Truck', category: 'Vehicle', acquisitionDate: '2024-05-20', acquisitionCost: 350000000, accumulatedDepreciation: 150000000, bookValue: 200000000, status: 'Active' }
];

const dummyDepreciation = [
    { assetCode: 'AST-001', name: 'Server Rack', expense: 3125000 },
    { assetCode: 'AST-002', name: 'Delivery Truck', expense: 7291666 }
];

console.log("--- 1. EXPORT TO EXCEL/CSV MOCK ---");
const csvData = ReportGenerator.generateAssetRegisterCSV(dummyAssets);
console.log(csvData);

console.log("\n--- 2. EXPORT TO PDF MOCK ---");
const pdfText = ReportGenerator.generateDepreciationPDFMockup('2026-09', dummyDepreciation);
console.log(pdfText);

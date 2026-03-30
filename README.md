# ConvertItaEInvoiceToPeppolUBLInvoice

## Project Purpose
This project aims to create an XSLT file capable of converting an Italian electronic invoice in XML format (for example, FatturaPA) into an invoice in UBL PEPPOL format.

In other words, the idea is to transform an Italian invoicing XML into a UBL XML compatible with the PEPPOL standard, while preserving the key information required by the target document.

## Technical Scope
- Transformation technology: XSLT 1.0 only.
- Source format: Italian e-invoice XML (FatturaElettronica / FatturaPA style structure).
- Target format: UBL Invoice or UBL CreditNote aligned with PEPPOL BIS Billing 3.0.

## Current Content
- `ConversionItaEInvToPeppol.xslt`: main XSLT transformation file.

## Functional Objective
The XSLT file should map the main data from the Italian invoice to UBL PEPPOL elements, for example:
- Supplier and customer details
- Invoice number and date
- Invoice lines (description, quantity, price, taxable amount)
- Totals, taxes, and currency
- Payment terms

## Implemented VAT Nature Mapping
The transformation currently maps Italian `Natura` values to UBL/PEPPOL tax category codes as follows:

| Italian Natura | PEPPOL Tax Category ID |
|---|---|
| (empty) | S |
| N1 | O |
| N2, N2.* | O |
| N3.1 | G |
| N3.2 | K |
| N3.3 | K |
| N3.4 | G |
| N3.5 | O |
| N3.6 | O |
| N4 | E |
| N5 | O |
| N6, N6.* | AE |
| N7 | O |
| other/unknown | O |

## Withholding Tax (Ritenuta) Handling
Current behavior in the XSLT:
- Calculates withholding taxable base from invoice lines flagged with `Ritenuta = SI`.
- Aggregates withholding amount from `DatiRitenuta/ImportoRitenuta`.
- Writes `cac:WithholdingTaxTotal` in output.
- Uses aggregated withholding amount in payable fallback logic.

## Notes for Validation
- PEPPOL validation can be strict depending on country/community rulesets.
- Some mappings may require refinement based on your receiver and validator profile.
- Always validate produced UBL XML with the same PEPPOL validator used in production.

## Note
This README describes the purpose of the project; detailed mappings depend on business rules and the adopted PEPPOL validation constraints.
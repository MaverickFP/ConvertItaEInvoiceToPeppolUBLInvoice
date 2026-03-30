# ConvertItaEInvoiceToPeppolUBLInvoice

## Project Purpose
This project aims to create an XSLT file capable of converting an Italian electronic invoice in XML format (for example, FatturaPA) into an invoice in UBL PEPPOL format.

In other words, the idea is to transform an Italian invoicing XML into a UBL XML compatible with the PEPPOL standard, while preserving the key information required by the target document.

## Current Content
- `ConversionItaEInvToPeppol.xslt`: main XSLT transformation file.

## Functional Objective
The XSLT file should map the main data from the Italian invoice to UBL PEPPOL elements, for example:
- Supplier and customer details
- Invoice number and date
- Invoice lines (description, quantity, price, taxable amount)
- Totals, taxes, and currency
- Payment terms

## Note
This README describes the purpose of the project; detailed mappings depend on business rules and the adopted PEPPOL validation constraints.
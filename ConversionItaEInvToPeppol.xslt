<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2" exclude-result-prefixes="xsl">
	<xsl:output method="xml" indent="yes" encoding="UTF-8"/>
	<xsl:decimal-format name="it" decimal-separator="." grouping-separator=","/>
	<!-- Utility -->
	<xsl:template name="fmt2">
		<xsl:param name="n"/>
		<xsl:value-of select="format-number(number($n),'0.00','it')"/>
	</xsl:template>
	<xsl:template name="fmt8">
		<xsl:param name="n"/>
		<xsl:value-of select="format-number(number($n),'0.00000000','it')"/>
	</xsl:template>
	<xsl:template name="mapNaturaToTaxCategoryID">
		<xsl:param name="natura"/>
		<xsl:variable name="n" select="normalize-space($natura)"/>
		<xsl:choose>
			<xsl:when test="$n = ''">S</xsl:when>
			<xsl:when test="$n = 'N4'">E</xsl:when>
			<xsl:when test="$n = 'N6' or starts-with($n,'N6.')">AE</xsl:when>
			<xsl:when test="$n = 'N3.2' or $n = 'N3.3'">K</xsl:when>
			<xsl:when test="$n = 'N3.1' or $n = 'N3.4'">G</xsl:when>
			<xsl:when test="$n = 'N1' or $n = 'N2' or starts-with($n,'N2.') or $n = 'N3.5' or $n = 'N3.6' or $n = 'N5' or $n = 'N7'">O</xsl:when>
			<xsl:otherwise>O</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- Template principale -->
	<xsl:template match="/*[local-name()='FatturaElettronica']">
		<xsl:variable name="body" select="/*[local-name()='FatturaElettronica']/*[local-name()='FatturaElettronicaBody']"/>
		<xsl:variable name="hdr" select="/*[local-name()='FatturaElettronica']/*[local-name()='FatturaElettronicaHeader']"/>
		<xsl:variable name="doc" select="$body/*[local-name()='DatiGenerali']/*[local-name()='DatiGeneraliDocumento']"/>
		<xsl:variable name="cur" select="normalize-space($doc/*[local-name()='Divisa'])"/>
		<xsl:variable name="td" select="normalize-space($doc/*[local-name()='TipoDocumento'])"/>
		<xsl:variable name="isCN" select="$td='TD04'"/>
		<!-- Dati bollo -->
		<xsl:variable name="datiBollo" select="$body/*[local-name()='DatiGenerali']
                 /*[local-name()='DatiGeneraliDocumento']
                 /*[local-name()='DatiBollo']"/>
		<!-- Importo bollo come stringa -->
		<xsl:variable name="bolloAmountStr" select="normalize-space($datiBollo/*[local-name()='ImportoBollo'])"/>
		<!-- Flag bollo -->
		<xsl:variable name="hasBollo" select="string-length($bolloAmountStr) &gt; 0"/>
		<!-- Importo bollo numerico -->
		<xsl:variable name="bolloAmountNum" select="number($bolloAmountStr)"/>
		<xsl:variable name="whtBase" select="sum($body/*[local-name()='DatiBeniServizi']/*[local-name()='DettaglioLinee'][normalize-space(*[local-name()='Ritenuta'])='SI']/*[local-name()='PrezzoTotale'])"/>
		<!-- Dati Ritenuta (di solito 0..1) -->
		<xsl:variable name="datiRitenuta" select="/*[local-name()='FatturaElettronica']
            /*[local-name()='FatturaElettronicaBody']
            /*[local-name()='DatiGenerali']
            /*[local-name()='DatiGeneraliDocumento']
            /*[local-name()='DatiRitenuta']"/>
		<xsl:variable name="whtAmount" select="sum($datiRitenuta[normalize-space(*[local-name()='ImportoRitenuta'])!='']/*[local-name()='ImportoRitenuta'])"/>
		<!-- Dati Cassa Previdenziale (0..n) -->
		<xsl:variable name="datiCassa" select="/*[local-name()='FatturaElettronica']
            /*[local-name()='FatturaElettronicaBody']
            /*[local-name()='DatiGenerali']
            /*[local-name()='DatiGeneraliDocumento']
            /*[local-name()='DatiCassaPrevidenziale']"/>
		<xsl:variable name="payableFromFPA" select="number($body/*[local-name()='DatiPagamento']
							 /*[local-name()='DettaglioPagamento']
							 /*[local-name()='ImportoPagamento'])"/>
		<!-- Estrai ModalitaPagamento e IBAN (namespace-safe con local-name()) -->
		<xsl:variable name="mp" select="$body/*[local-name()='DatiPagamento']/*[local-name()='DettaglioPagamento']/*[local-name()='ModalitaPagamento']"/>
		<xsl:variable name="iban" select="normalize-space($body/*[local-name()='DatiPagamento']/*[local-name()='DettaglioPagamento']/*[local-name()='IBAN'])"/>
		<!-- Elementi dinamici per supportare CreditNote -->
		<xsl:variable name="rootLocal">
			<xsl:choose>
				<xsl:when test="$isCN">CreditNote</xsl:when>
				<xsl:otherwise>Invoice</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="rootNS">
			<xsl:choose>
				<xsl:when test="$isCN">urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2</xsl:when>
				<xsl:otherwise>urn:oasis:names:specification:ubl:schema:xsd:Invoice-2</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!--
		<xsl:variable name="rootName">
			<xsl:choose>
				<xsl:when test="$isCN">ubl:CreditNote</xsl:when>
				<xsl:otherwise>ubl:Invoice</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		-->
		<xsl:variable name="lineName">
			<xsl:choose>
				<xsl:when test="$isCN">cac:CreditNoteLine</xsl:when>
				<xsl:otherwise>cac:InvoiceLine</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="qtyName">
			<xsl:choose>
				<xsl:when test="$isCN">cbc:CreditedQuantity</xsl:when>
				<xsl:otherwise>cbc:InvoicedQuantity</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!--<xsl:element name="{$rootName}">-->
		<xsl:element name="{$rootLocal}" namespace="{$rootNS}">
			<ext:UBLExtensions>
				<ext:UBLExtension>
					<ext:ExtensionContent/>
				</ext:UBLExtension>
			</ext:UBLExtensions>
			<cbc:CustomizationID>urn:cen.eu:en16931:2017</cbc:CustomizationID>
			<cbc:ProfileID>urn:fdc:peppol.eu:2017:poacc:billing:3.0</cbc:ProfileID>
			<cbc:ID>
				<xsl:value-of select="$doc/*[local-name()='Numero']"/>
			</cbc:ID>
			<cbc:IssueDate>
				<xsl:value-of select="$doc/*[local-name()='Data']"/>
			</cbc:IssueDate>
			<!-- TypeCode differenziato tra Invoice e CreditNote -->
			<xsl:choose>
				<xsl:when test="$isCN">
					<!-- Nota di credito -->
					<cbc:CreditNoteTypeCode>381</cbc:CreditNoteTypeCode>
				</xsl:when>
				<xsl:otherwise>
					<!-- Fatture -->
					<cbc:InvoiceTypeCode>
						<xsl:choose>
							<xsl:when test="$td='TD01' or $td='TD03' or $td='TD06' or $td='TD20' or $td='TD21' or $td='TD22' or $td='TD23' or $td='TD24' or $td='TD25' or $td='TD26' or $td='TD27'">380</xsl:when>
							<xsl:when test="$td='TD02'">380</xsl:when>
							<xsl:when test="$td='TD05'">383</xsl:when>
							<xsl:when test="$td='TD16' or $td='TD17' or $td='TD18' or $td='TD19'">389</xsl:when>
							<xsl:otherwise>380</xsl:otherwise>
						</xsl:choose>
					</cbc:InvoiceTypeCode>
				</xsl:otherwise>
			</xsl:choose>
			<cbc:DocumentCurrencyCode>
				<xsl:value-of select="$cur"/>
			</cbc:DocumentCurrencyCode>
			<!-- BuyerReference -->
			<xsl:if test="$doc/*[local-name()='Causale']">
				<cbc:BuyerReference>
					<xsl:value-of select="$doc/*[local-name()='Causale'][1]"/>
				</cbc:BuyerReference>
			</xsl:if>
			<!-- OrderReference -->
			<xsl:for-each select="$body/*[local-name()='DatiGenerali']/*[local-name()='DatiOrdineAcquisto']">
				<cac:OrderReference>
					<cbc:ID>
						<xsl:value-of select="normalize-space(*[local-name()='IdDocumento'])"/>
					</cbc:ID>
				</cac:OrderReference>
			</xsl:for-each>
			<!-- Per TD04: riferimento alla fattura rettificata -->
			<xsl:if test="$isCN">
				<xsl:for-each select="$body/*[local-name()='DatiGenerali']/*[local-name()='DatiFattureCollegate']">
					<cac:BillingReference>
						<cac:InvoiceDocumentReference>
							<cbc:ID>
								<xsl:value-of select="normalize-space(*[local-name()='IdDocumento'])"/>
							</cbc:ID>
							<xsl:if test="normalize-space(*[local-name()='Data'])">
								<cbc:IssueDate>
									<xsl:value-of select="normalize-space(*[local-name()='Data'])"/>
								</cbc:IssueDate>
							</xsl:if>
						</cac:InvoiceDocumentReference>
					</cac:BillingReference>
				</xsl:for-each>
			</xsl:if>
			<!-- Supplier -->
			<cac:AccountingSupplierParty>
				<xsl:if test="normalize-space($hdr/*[local-name()='SupplierCode']) != ''">
					<cbc:BuyerAssignedAccountID>
						<xsl:value-of select="normalize-space($hdr/*[local-name()='SupplierCode'])"/>
					</cbc:BuyerAssignedAccountID>
				</xsl:if>
				<cac:Party>
					<xsl:variable name="sp" select="$hdr/*[local-name()='CedentePrestatore']"/>
					<cac:PartyIdentification>
						<cbc:ID schemeID="0211">
							<xsl:value-of select="concat($sp/*[local-name()='DatiAnagrafici']/*[local-name()='IdFiscaleIVA']/*[local-name()='IdPaese'],$sp/*[local-name()='DatiAnagrafici']/*[local-name()='IdFiscaleIVA']/*[local-name()='IdCodice'])"/>
						</cbc:ID>
					</cac:PartyIdentification>
					<xsl:if test="$sp/*[local-name()='DatiAnagrafici']/*[local-name()='CodiceFiscale']">
						<cac:PartyIdentification>
							<cbc:ID schemeID="0210">
								<xsl:value-of select="$sp/*[local-name()='DatiAnagrafici']/*[local-name()='CodiceFiscale']"/>
							</cbc:ID>
						</cac:PartyIdentification>
					</xsl:if>
					<cac:PartyName>
						<cbc:Name>
							<xsl:value-of select="$sp/*[local-name()='DatiAnagrafici']/*[local-name()='Anagrafica']/*[local-name()='Denominazione']"/>
						</cbc:Name>
					</cac:PartyName>
					<cac:PostalAddress>
						<cbc:StreetName>
							<xsl:value-of select="$sp/*[local-name()='Sede']/*[local-name()='Indirizzo']"/>
						</cbc:StreetName>
						<xsl:if test="$sp/*[local-name()='Sede']/*[local-name()='NumeroCivico']">
							<cbc:AdditionalStreetName>
								<xsl:value-of select="$sp/*[local-name()='Sede']/*[local-name()='NumeroCivico']"/>
							</cbc:AdditionalStreetName>
						</xsl:if>
						<cbc:PostalZone>
							<xsl:value-of select="$sp/*[local-name()='Sede']/*[local-name()='CAP']"/>
						</cbc:PostalZone>
						<cbc:CityName>
							<xsl:value-of select="$sp/*[local-name()='Sede']/*[local-name()='Comune']"/>
						</cbc:CityName>
						<cac:Country>
							<cbc:IdentificationCode>
								<xsl:value-of select="$sp/*[local-name()='Sede']/*[local-name()='Nazione']"/>
							</cbc:IdentificationCode>
						</cac:Country>
					</cac:PostalAddress>
				</cac:Party>
			</cac:AccountingSupplierParty>
			<!-- Customer (con fallback CF e regola CompanyID=DED) -->
			<cac:AccountingCustomerParty>
				<cac:Party>
					<xsl:variable name="cp" select="$hdr/*[local-name()='CessionarioCommittente']"/>
					<!-- Componenti IVA normalizzati -->
					<xsl:variable name="vatCountry" select="normalize-space($cp/*[local-name()='DatiAnagrafici']/*[local-name()='IdFiscaleIVA']/*[local-name()='IdPaese'])"/>
					<xsl:variable name="vatCode" select="normalize-space($cp/*[local-name()='DatiAnagrafici']/*[local-name()='IdFiscaleIVA']/*[local-name()='IdCodice'])"/>
					<!-- IVA completa solo se entrambi presenti -->
					<xsl:variable name="customerID_vat">
						<xsl:choose>
							<xsl:when test="string-length($vatCountry) &gt; 0 and string-length($vatCode) &gt; 0">
								<xsl:value-of select="concat($vatCountry,$vatCode)"/>
							</xsl:when>
							<xsl:otherwise/>
						</xsl:choose>
					</xsl:variable>
					<!-- Fallback: Codice Fiscale -->
					<xsl:variable name="customerID_cf" select="normalize-space($cp/*[local-name()='DatiAnagrafici']/*[local-name()='CodiceFiscale'])"/>
					<!-- Nazione (per prefisso), uppercased -->
					<xsl:variable name="countryRaw" select="normalize-space($cp/*[local-name()='Sede']/*[local-name()='Nazione'])"/>
					<xsl:variable name="countryUpper" select="translate($countryRaw,'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
					<!-- ID effettivo -->
					<xsl:variable name="customerID">
						<xsl:choose>
							<xsl:when test="string-length($customerID_vat) &gt; 0">
								<xsl:value-of select="$customerID_vat"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:choose>
									<xsl:when test="string-length($countryUpper) &gt; 0 and string-length($customerID_cf) &gt; 0">
										<xsl:value-of select="concat($countryUpper,$customerID_cf)"/>
									</xsl:when>
									<xsl:when test="string-length($customerID_cf) &gt; 0">
										<xsl:value-of select="concat('IT',$customerID_cf)"/>
									</xsl:when>
									<xsl:otherwise/>
								</xsl:choose>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<cac:PartyIdentification>
						<cbc:ID>
							<xsl:value-of select="$customerID"/>
						</cbc:ID>
					</cac:PartyIdentification>
					<cac:PartyName>
						<cbc:Name>
							<xsl:value-of select="$cp/*[local-name()='DatiAnagrafici']/*[local-name()='Anagrafica']/*[local-name()='Denominazione']"/>
						</cbc:Name>
					</cac:PartyName>
					<!-- Regola CompanyID=DED -->
					<xsl:if test="normalize-space($customerID) = 'IT05994810488' or normalize-space($customerID_cf) = '05994810488'">
						<cac:PartyLegalEntity>
							<cbc:CompanyID>DED</cbc:CompanyID>
						</cac:PartyLegalEntity>
					</xsl:if>
					<cac:PostalAddress>
						<cbc:StreetName>
							<xsl:value-of select="$cp/*[local-name()='Sede']/*[local-name()='Indirizzo']"/>
						</cbc:StreetName>
						<cbc:PostalZone>
							<xsl:value-of select="$cp/*[local-name()='Sede']/*[local-name()='CAP']"/>
						</cbc:PostalZone>
						<cbc:CityName>
							<xsl:value-of select="$cp/*[local-name()='Sede']/*[local-name()='Comune']"/>
						</cbc:CityName>
						<cac:Country>
							<cbc:IdentificationCode>
								<xsl:value-of select="$countryUpper"/>
							</cbc:IdentificationCode>
						</cac:Country>
					</cac:PostalAddress>
				</cac:Party>
			</cac:AccountingCustomerParty>
			<!-- Linee (InvoiceLine vs CreditNoteLine; InvoicedQuantity vs CreditedQuantity) -->
			<!--
			<xsl:for-each select="$body/*[local-name()='DatiBeniServizi']/*[local-name()='DettaglioLinee']">
				<xsl:element name="{$lineName}">
					<cbc:ID>
						<xsl:value-of select="normalize-space(*[local-name()='NumeroLinea'])"/>
					</cbc:ID>
					<xsl:element name="{$qtyName}">
						<xsl:attribute name="unitCode">C62</xsl:attribute>
						<xsl:value-of select="normalize-space(*[local-name()='Quantita'])"/>
					</xsl:element>
					<cbc:LineExtensionAmount>
						<xsl:attribute name="currencyID">
							<xsl:value-of select="$cur"/>
						</xsl:attribute>
						<xsl:call-template name="fmt2">
							<xsl:with-param name="n" select="*[local-name()='PrezzoTotale']"/>
						</xsl:call-template>
					</cbc:LineExtensionAmount>
					<cac:Item>
						<cbc:Description>
							<xsl:value-of select="normalize-space(*[local-name()='Descrizione'])"/>
						</cbc:Description>
						<xsl:for-each select="*[local-name()='CodiceArticolo']/*[local-name()='CodiceValore']">
							<cac:StandardItemIdentification>
								<cbc:ID>
									<xsl:value-of select="."/>
								</cbc:ID>
							</cac:StandardItemIdentification>
						</xsl:for-each>
					</cac:Item>
					<cac:Price>
						<cbc:PriceAmount>
							<xsl:attribute name="currencyID">
								<xsl:value-of select="$cur"/>
							</xsl:attribute>
							<xsl:call-template name="fmt8">
								<xsl:with-param name="n" select="*[local-name()='PrezzoUnitario']"/>
							</xsl:call-template>
						</cbc:PriceAmount>
					</cac:Price>
				</xsl:element>
			</xsl:for-each>
			-->
			<!-- Linee (InvoiceLine vs CreditNoteLine; InvoicedQuantity vs CreditedQuantity) -->
			<xsl:for-each select="$body/*[local-name()='DatiBeniServizi']/*[local-name()='DettaglioLinee']
			  [
				not(
				  $hasBollo
				  and normalize-space(*[local-name()='Natura']) = 'N1'
				  and number(normalize-space(*[local-name()='AliquotaIVA'])) = 0
				  and round(number(normalize-space(*[local-name()='PrezzoTotale'])) * 100)
					  = round(number($bolloAmountNum) * 100)
				)
			  ]">
				<xsl:element name="{$lineName}">
					<cbc:ID>
						<!-- Opzione 1: mantieni NumeroLinea originale -->
						<xsl:value-of select="normalize-space(*[local-name()='NumeroLinea'])"/>
						<!-- Opzione 2 (alternativa): rinumera in modo consecutivo -->
						<!-- <xsl:value-of select="position()"/> -->
					</cbc:ID>
					<xsl:element name="{$qtyName}">
						<xsl:attribute name="unitCode">C62</xsl:attribute>
						<xsl:choose>
							<xsl:when test="normalize-space(*[local-name()='Quantita']) != ''">
								<xsl:value-of select="normalize-space(*[local-name()='Quantita'])"/>
							</xsl:when>
							<xsl:otherwise>1</xsl:otherwise>
						</xsl:choose>
					</xsl:element>
					<cbc:LineExtensionAmount>
						<xsl:attribute name="currencyID">
							<xsl:value-of select="$cur"/>
						</xsl:attribute>
						<xsl:call-template name="fmt2">
							<xsl:with-param name="n" select="*[local-name()='PrezzoTotale']"/>
						</xsl:call-template>
					</cbc:LineExtensionAmount>
					<xsl:if test="normalize-space(*[local-name()='DataInizioPeriodo']) != '' or normalize-space(*[local-name()='DataFinePeriodo']) != ''">
						<cac:InvoicePeriod>
							<xsl:if test="normalize-space(*[local-name()='DataInizioPeriodo']) != ''">
								<cbc:StartDate>
									<xsl:value-of select="normalize-space(*[local-name()='DataInizioPeriodo'])"/>
								</cbc:StartDate>
							</xsl:if>
							<xsl:if test="normalize-space(*[local-name()='DataFinePeriodo']) != ''">
								<cbc:EndDate>
									<xsl:value-of select="normalize-space(*[local-name()='DataFinePeriodo'])"/>
								</cbc:EndDate>
							</xsl:if>
						</cac:InvoicePeriod>
					</xsl:if>
					<cac:Item>
						<cbc:Description>
							<xsl:value-of select="normalize-space(*[local-name()='Descrizione'])"/>
						</cbc:Description>
						<xsl:for-each select="*[local-name()='CodiceArticolo']/*[local-name()='CodiceValore']">
							<cac:StandardItemIdentification>
								<cbc:ID>
									<xsl:value-of select="."/>
								</cbc:ID>
							</cac:StandardItemIdentification>
						</xsl:for-each>
						<cac:ClassifiedTaxCategory>
							<cbc:ID>
								<xsl:call-template name="mapNaturaToTaxCategoryID">
									<xsl:with-param name="natura" select="normalize-space(*[local-name()='Natura'])"/>
								</xsl:call-template>
							</cbc:ID>
							<cbc:Percent>
								<xsl:value-of select="normalize-space(*[local-name()='AliquotaIVA'])"/>
							</cbc:Percent>
							<cac:TaxScheme>
								<cbc:ID>VAT</cbc:ID>
							</cac:TaxScheme>
						</cac:ClassifiedTaxCategory>
					</cac:Item>
					<cac:Price>
						<cbc:PriceAmount>
							<xsl:attribute name="currencyID">
								<xsl:value-of select="$cur"/>
							</xsl:attribute>
							<xsl:call-template name="fmt8">
								<xsl:with-param name="n" select="*[local-name()='PrezzoUnitario']"/>
							</xsl:call-template>
						</cbc:PriceAmount>
					</cac:Price>
				</xsl:element>
			</xsl:for-each>
			<!-- TaxTotal -->
			<cac:TaxTotal>
				<!-- Totale imposta documento (somma TaxSubtotal/TaxAmount) -->
				<cbc:TaxAmount>
					<xsl:attribute name="currencyID">
						<xsl:value-of select="$cur"/>
					</xsl:attribute>
					<xsl:call-template name="fmt2">
						<xsl:with-param name="n" select="sum(
          $body/*[local-name()='DatiBeniServizi']/*[local-name()='DatiRiepilogo']
          [
            not(
              (
                $hasBollo
                and normalize-space(*[local-name()='Natura']) = 'N1'
                and number(normalize-space(*[local-name()='AliquotaIVA'])) = 0
                and round(number(normalize-space(*[local-name()='ImponibileImporto'])) * 100)
                    = round(number($bolloAmountNum) * 100)
              )
              or
              (
                not($hasBollo)
                and contains(
                  translate(normalize-space(*[local-name()='RiferimentoNormativo']),
                            'ABCDEFGHIJKLMNOPQRSTUVWXYZÀÈÉÌÒÙ',
                            'abcdefghijklmnopqrstuvwxyzàèéìòù'),
                  'bollo'
                )
              )
            )
          ]
          /*[local-name()='Imposta']
        )"/>
					</xsl:call-template>
				</cbc:TaxAmount>
				<!-- Subtotali IVA -->
				<xsl:for-each select="$body/*[local-name()='DatiBeniServizi']/*[local-name()='DatiRiepilogo']
    [
      not(
        (
          $hasBollo
          and normalize-space(*[local-name()='Natura']) = 'N1'
          and number(normalize-space(*[local-name()='AliquotaIVA'])) = 0
          and round(number(normalize-space(*[local-name()='ImponibileImporto'])) * 100)
              = round(number($bolloAmountNum) * 100)
        )
        or
        (
          not($hasBollo)
          and contains(
            translate(normalize-space(*[local-name()='RiferimentoNormativo']),
                      'ABCDEFGHIJKLMNOPQRSTUVWXYZÀÈÉÌÒÙ',
                      'abcdefghijklmnopqrstuvwxyzàèéìòù'),
            'bollo'
          )
        )
      )
    ]">
					<!-- variabili di comodo -->
					<xsl:variable name="natura" select="normalize-space(*[local-name()='Natura'])"/>
					<xsl:variable name="rifNorm" select="normalize-space(*[local-name()='RiferimentoNormativo'])"/>
					<cac:TaxSubtotal>
						<cbc:TaxableAmount>
							<xsl:attribute name="currencyID">
								<xsl:value-of select="$cur"/>
							</xsl:attribute>
							<xsl:call-template name="fmt2">
								<xsl:with-param name="n" select="*[local-name()='ImponibileImporto']"/>
							</xsl:call-template>
						</cbc:TaxableAmount>
						<cbc:TaxAmount>
							<xsl:attribute name="currencyID">
								<xsl:value-of select="$cur"/>
							</xsl:attribute>
							<xsl:call-template name="fmt2">
								<xsl:with-param name="n" select="*[local-name()='Imposta']"/>
							</xsl:call-template>
						</cbc:TaxAmount>
						<cac:TaxCategory>
							<!-- ID categoria IVA: fondamentale anche quando Natura è vuota -->
							<cbc:ID>
								<xsl:call-template name="mapNaturaToTaxCategoryID">
									<xsl:with-param name="natura" select="$natura"/>
								</xsl:call-template>
							</cbc:ID>
							<cbc:Percent>
								<xsl:value-of select="normalize-space(*[local-name()='AliquotaIVA'])"/>
							</cbc:Percent>
							<!-- Motivo normativo SOLO se presente (tipico dei casi con Natura) -->
							<xsl:if test="$rifNorm != ''">
								<cbc:TaxExemptionReason>
									<xsl:value-of select="$rifNorm"/>
								</cbc:TaxExemptionReason>
							</xsl:if>
							<cac:TaxScheme>
								<cbc:ID>VAT</cbc:ID>
								<cbc:Name>IVA</cbc:Name>
							</cac:TaxScheme>
						</cac:TaxCategory>
					</cac:TaxSubtotal>
				</xsl:for-each>
			</cac:TaxTotal>
			<!-- Allegati -->
			<xsl:for-each select="$body/*[local-name()='Allegati']">
				<cac:AdditionalDocumentReference>
					<cbc:ID>
						<xsl:choose>
							<xsl:when test="normalize-space(*[local-name()='NomeAttachment'])">
								<xsl:value-of select="normalize-space(*[local-name()='NomeAttachment'])"/>
							</xsl:when>
							<xsl:otherwise>Attachment</xsl:otherwise>
						</xsl:choose>
					</cbc:ID>
					<xsl:if test="normalize-space(*[local-name()='FormatoAttachment'])">
						<cbc:DocumentType>
							<xsl:value-of select="normalize-space(*[local-name()='FormatoAttachment'])"/>
						</cbc:DocumentType>
					</xsl:if>
					<xsl:if test="normalize-space(*[local-name()='DescrizioneAttachment'])">
						<cbc:DocumentDescription>
							<xsl:value-of select="normalize-space(*[local-name()='DescrizioneAttachment'])"/>
						</cbc:DocumentDescription>
					</xsl:if>
					<xsl:if test="normalize-space(*[local-name()='Attachment'])">
						<cac:Attachment>
							<cbc:EmbeddedDocumentBinaryObject>
								<!-- MIME -->
								<xsl:attribute name="mimeCode">
									<xsl:variable name="fmt" select="translate(normalize-space(*[local-name()='FormatoAttachment']),
                          'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
									<xsl:choose>
										<xsl:when test="$fmt='PDF'">application/pdf</xsl:when>
										<xsl:when test="$fmt='XML'">application/xml</xsl:when>
										<xsl:when test="$fmt='TXT'">text/plain</xsl:when>
										<xsl:when test="$fmt='CSV'">text/csv</xsl:when>
										<xsl:when test="$fmt='ZIP'">application/zip</xsl:when>
										<xsl:when test="$fmt='PNG'">image/png</xsl:when>
										<xsl:when test="$fmt='JPG' or $fmt='JPEG'">image/jpeg</xsl:when>
										<xsl:otherwise>application/octet-stream</xsl:otherwise>
									</xsl:choose>
								</xsl:attribute>
								<!-- FILENAME normalizzato + estensione -->
								<xsl:if test="normalize-space(*[local-name()='NomeAttachment'])">
									<xsl:attribute name="filename">
										<xsl:variable name="rawName" select="normalize-space(*[local-name()='NomeAttachment'])"/>
										<xsl:variable name="fmt" select="translate(normalize-space(*[local-name()='FormatoAttachment']),
                            'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
										<!-- spazi -> "_" -->
										<xsl:variable name="nameNoSpaces" select="translate($rawName,' ','_')"/>
										<!-- estensione -->
										<xsl:choose>
											<xsl:when test="contains($nameNoSpaces,'.')">
												<xsl:value-of select="$nameNoSpaces"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="concat(
              $nameNoSpaces,
              '.',
              translate($fmt,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')
            )"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:attribute>
								</xsl:if>
								<!-- BASE64 -->
								<xsl:value-of select="normalize-space(*[local-name()='Attachment'])"/>
							</cbc:EmbeddedDocumentBinaryObject>
						</cac:Attachment>
					</xsl:if>
					<xsl:if test="not(normalize-space(*[local-name()='Attachment']))">
						<cac:Attachment/>
					</xsl:if>
				</cac:AdditionalDocumentReference>
			</xsl:for-each>
			<!-- Payment -->
			<xsl:for-each select="$body/*[local-name()='DatiPagamento']">
				<cac:PaymentMeans>
					<cbc:PaymentMeansCode>
						<xsl:choose>
							<!-- Contanti -->
							<xsl:when test="$mp = 'MP01'">10</xsl:when>
							<!-- Assegno -->
							<xsl:when test="$mp = 'MP02'">20</xsl:when>
							<!-- Bonifico -->
							<xsl:when test="$mp = 'MP05'">
								<xsl:choose>
									<xsl:when test="$iban != ''">58</xsl:when>
									<xsl:otherwise>30</xsl:otherwise>
								</xsl:choose>
							</xsl:when>
							<!-- RID/SDD/Addebito: se lo usi davvero, puoi decidere un codice specifico;
         altrimenti fallback -->
							<xsl:when test="$mp = 'MP04'">
								<xsl:choose>
									<xsl:when test="$iban != ''">58</xsl:when>
									<xsl:otherwise>1</xsl:otherwise>
								</xsl:choose>
							</xsl:when>
							<!-- Carte: dipende dal profilo/validatore (se non sei sicuro, non forzare) -->
							<xsl:when test="$mp = 'MP08'">1</xsl:when>
							<!-- Fallback generale -->
							<xsl:otherwise>
								<xsl:choose>
									<xsl:when test="$iban != ''">58</xsl:when>
									<xsl:otherwise>1</xsl:otherwise>
								</xsl:choose>
							</xsl:otherwise>
						</xsl:choose>
					</cbc:PaymentMeansCode>
					<xsl:if test="*[local-name()='DettaglioPagamento']/*[local-name()='DataScadenzaPagamento']">
						<cbc:PaymentDueDate>
							<xsl:value-of select="normalize-space(*[local-name()='DettaglioPagamento']/*[local-name()='DataScadenzaPagamento'])"/>
						</cbc:PaymentDueDate>
					</xsl:if>
					<xsl:if test="*[local-name()='DettaglioPagamento']/*[local-name()='IBAN']">
						<cac:PayeeFinancialAccount>
							<cbc:ID>
								<xsl:value-of select="normalize-space(*[local-name()='DettaglioPagamento']/*[local-name()='IBAN'])"/>
							</cbc:ID>
						</cac:PayeeFinancialAccount>
					</xsl:if>
				</cac:PaymentMeans>
				<cac:PaymentTerms>
					<cbc:Note>Condizioni: <xsl:value-of select="normalize-space(*[local-name()='CondizioniPagamento'])"/> - Giorni: <xsl:value-of select="normalize-space(*[local-name()='DettaglioPagamento']/*[local-name()='GiorniTerminiPagamento'])"/>
					</cbc:Note>
				</cac:PaymentTerms>
			</xsl:for-each>
			<!-- base ritenuta = somma PrezzoTotale delle righe con Ritenuta='SI' -->
			<xsl:if test="count($datiRitenuta[normalize-space(*[local-name()='ImportoRitenuta'])!='']) &gt; 0">
				<cac:WithholdingTaxTotal>
					<cbc:TaxAmount currencyID="{$cur}">
						<xsl:call-template name="fmt2">
							<xsl:with-param name="n" select="$whtAmount"/>
						</xsl:call-template>
					</cbc:TaxAmount>
					<cac:TaxSubtotal>
						<cbc:TaxableAmount currencyID="{$cur}">
							<xsl:value-of select="format-number(number($whtBase),'0.00')"/>
						</cbc:TaxableAmount>
						<cbc:TaxAmount currencyID="{$cur}">
							<xsl:call-template name="fmt2">
								<xsl:with-param name="n" select="$whtAmount"/>
							</xsl:call-template>
						</cbc:TaxAmount>
						<cbc:Percent>
							<xsl:value-of select="format-number(number($datiRitenuta/*[local-name()='AliquotaRitenuta']),'0.00')"/>
						</cbc:Percent>
						<!-- tassonomia "tecnica" per ritenuta -->
						<cac:TaxCategory>
							<cbc:ID>WHT</cbc:ID>
							<cac:TaxScheme>
								<cbc:ID>WHT</cbc:ID>
							</cac:TaxScheme>
						</cac:TaxCategory>
					</cac:TaxSubtotal>
				</cac:WithholdingTaxTotal>
			</xsl:if>
			<!-- Bollo -> AllowanceCharge -->
			<xsl:if test="$datiBollo and normalize-space($datiBollo/*[local-name()='ImportoBollo']) != ''">
				<cac:AllowanceCharge>
					<cbc:ChargeIndicator>true</cbc:ChargeIndicator>
					<cbc:AllowanceChargeReason>Imposta di bollo virtuale</cbc:AllowanceChargeReason>
					<cbc:Amount>
						<xsl:attribute name="currencyID">
							<xsl:value-of select="$cur"/>
						</xsl:attribute>
						<xsl:call-template name="fmt2">
							<xsl:with-param name="n" select="$datiBollo/*[local-name()='ImportoBollo']"/>
						</xsl:call-template>
					</cbc:Amount>
					<!-- fuori campo IVA -->
					<cac:TaxCategory>
						<cbc:ID>O</cbc:ID>
						<cac:TaxScheme>
							<cbc:ID>VAT</cbc:ID>
						</cac:TaxScheme>
					</cac:TaxCategory>
				</cac:AllowanceCharge>
			</xsl:if>
			<!-- Cassa Previdenziale -> AllowanceCharge (imponibile IVA) -->
			<xsl:if test="$datiCassa and normalize-space($datiCassa/*[local-name()='ImportoContributoCassa']) != ''">
				<cac:AllowanceCharge>
					<cbc:ChargeIndicator>true</cbc:ChargeIndicator>
					<cbc:AllowanceChargeReason>
						<xsl:text>Contributo previdenziale </xsl:text>
						<xsl:value-of select="$datiCassa/*[local-name()='TipoCassa']"/>
						<xsl:text> </xsl:text>
						<xsl:value-of select="format-number(number($datiCassa/*[local-name()='AlCassa']),'0.00')"/>
						<xsl:text>%</xsl:text>
					</cbc:AllowanceChargeReason>
					<cbc:Amount currencyID="{$cur}">
						<xsl:call-template name="fmt2">
							<xsl:with-param name="n" select="$datiCassa/*[local-name()='ImportoContributoCassa']"/>
						</xsl:call-template>
					</cbc:Amount>
					<!-- IVA sulla cassa -->
					<cac:TaxCategory>
						<cbc:ID>S</cbc:ID>
						<cbc:Percent>
							<xsl:call-template name="fmt2">
								<xsl:with-param name="n" select="$datiCassa/*[local-name()='AliquotaIVA']"/>
							</xsl:call-template>
						</cbc:Percent>
						<cac:TaxScheme>
							<cbc:ID>VAT</cbc:ID>
						</cac:TaxScheme>
					</cac:TaxCategory>
				</cac:AllowanceCharge>
			</xsl:if>
			<!-- Totali -->
			<cac:LegalMonetaryTotal>
				<xsl:variable name="righeValide" select="$body/*[local-name()='DatiBeniServizi']
                /*[local-name()='DettaglioLinee']"/>
				<cbc:LineExtensionAmount>
					<xsl:attribute name="currencyID">
						<xsl:value-of select="$cur"/>
					</xsl:attribute>
					<xsl:call-template name="fmt2">
						<xsl:with-param name="n" select="
        sum(
          $righeValide
          [
            not(
              $hasBollo
              and normalize-space(*[local-name()='Natura']) = 'N1'
              and number(normalize-space(*[local-name()='AliquotaIVA'])) = 0
              and round(number(*[local-name()='PrezzoTotale']) * 100)
                  = round(number($bolloAmountNum) * 100)
            )
          ]
          /*[local-name()='PrezzoTotale']
        )
      "/>
					</xsl:call-template>
				</cbc:LineExtensionAmount>
				<xsl:if test="$datiBollo and normalize-space($datiBollo/*[local-name()='ImportoBollo']) != ''">
					<cbc:ChargeTotalAmount>
						<xsl:attribute name="currencyID">
							<xsl:value-of select="$cur"/>
						</xsl:attribute>
						<xsl:call-template name="fmt2">
							<xsl:with-param name="n" select="$datiBollo/*[local-name()='ImportoBollo']"/>
						</xsl:call-template>
					</cbc:ChargeTotalAmount>
				</xsl:if>
				<cbc:TaxInclusiveAmount>
					<xsl:attribute name="currencyID">
						<xsl:value-of select="$cur"/>
					</xsl:attribute>
					<xsl:call-template name="fmt2">
						<xsl:with-param name="n" select="$doc/*[local-name()='ImportoTotaleDocumento']"/>
					</xsl:call-template>
				</cbc:TaxInclusiveAmount>
				<cbc:PayableAmount>
					<xsl:attribute name="currencyID">
						<xsl:value-of select="$cur"/>
					</xsl:attribute>
					<!-- Se TD04 → imposto importo NEGATIVO -->
					<xsl:choose>
						<xsl:when test="$isCN">
							<xsl:choose>
								<xsl:when test="number($doc/*[local-name()='ImportoTotaleDocumento']) &lt; '0'">
									<xsl:call-template name="fmt2">
										<xsl:with-param name="n" select="number($doc/*[local-name()='ImportoTotaleDocumento'])"/>
									</xsl:call-template>
								</xsl:when>
								<xsl:otherwise>
									<xsl:variable name="rawImpTotDoc" select="number($doc/*[local-name()='ImportoTotaleDocumento'])"/>
									<xsl:variable name="rawPosImpTotDoc" select="0 - $rawImpTotDoc"/>
									<xsl:call-template name="fmt2">
										<xsl:with-param name="n" select="number($rawPosImpTotDoc)"/>
									</xsl:call-template>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<!--
						<xsl:otherwise>							
							<xsl:call-template name="fmt2">
								<xsl:with-param name="n" select="number($doc/*[local-name()='ImportoTotaleDocumento'])"/>
							</xsl:call-template>
						</xsl:otherwise>
						-->
						<xsl:otherwise>
							<!-- fatture normali -->
							<xsl:choose>
								<xsl:when test="string($body/*[local-name()='DatiPagamento']
													  /*[local-name()='DettaglioPagamento']
													  /*[local-name()='ImportoPagamento']) != ''
											and not($payableFromFPA != $payableFromFPA)">
									<!-- ImportoPagamento presente e numerico -->
									<xsl:call-template name="fmt2">
										<xsl:with-param name="n" select="$payableFromFPA"/>
									</xsl:call-template>
								</xsl:when>
								<xsl:otherwise>
									<!-- fallback: ImportoTotaleDocumento - ritenuta (se presente) -->
									<xsl:variable name="totDoc" select="number($doc/*[local-name()='ImportoTotaleDocumento'])"/>
									<xsl:variable name="wht" select="$whtAmount"/>
									<xsl:call-template name="fmt2">
										<xsl:with-param name="n" select="$totDoc - ( ($wht = $wht) * $wht )"/>
									</xsl:call-template>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:otherwise>
					</xsl:choose>
					<!--
					<xsl:call-template name="fmt2">
						<xsl:with-param name="n" select="$doc/*[local-name()='ImportoTotaleDocumento']"/>
					</xsl:call-template>
					-->
				</cbc:PayableAmount>
			</cac:LegalMonetaryTotal>
		</xsl:element>
	</xsl:template>
</xsl:stylesheet>
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:s="http://purl.oclc.org/dsdl/schematron"
  xmlns:tr="http://transpect.io" 
  xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
  xmlns="http://purl.oclc.org/dsdl/svrl"
  exclude-result-prefixes="xs"
  version="2.0">

  <xsl:output indent="yes"/>

  <!-- Space-separated list of PI names -->
  <xsl:param name="pi-names" as="xs:string"/>
  
  <!-- message | warning | error | fatal-error -->
  <xsl:param name="severity" as="xs:string"/>

  <!-- e.g., "RNG_tei-cssa: message text" -->
  <xsl:variable name="msg-regex" select="'^((\w+)[-_]([-_\w]+)):?\s+(.+)$'" as="xs:string"/>

	<xsl:variable name="source-dir-uri" as="xs:string"
		select="(/*/@source-dir-uri, /*/*:info/*:keywordset[@role = 'hub']/*:keyword[@role = 'source-dir-uri'], '')[1]"/>

  <xsl:template match="/">
    <xsl:for-each-group select="//processing-instruction()[name() = tokenize($pi-names, '\s+')]" group-by="replace(., $msg-regex, '$2')">
      <xsl:result-document href="{resolve-uri(concat(current-grouping-key(), '.svrl.xml'))}">
        <svrl:schematron-output tr:rule-family="{current-grouping-key()}">
          <xsl:for-each-group select="current-group()" group-by="replace(., $msg-regex, '$1')">
            <svrl:active-pattern document="{base-uri()}" id="{current-grouping-key()}" name="{current-grouping-key()}"/>
            <xsl:apply-templates select="current-group()">
              <xsl:with-param name="id" select="current-grouping-key()"/>
            </xsl:apply-templates>
          </xsl:for-each-group>          
        </svrl:schematron-output>
      </xsl:result-document>
    </xsl:for-each-group>
  </xsl:template>
  
  <!-- if it ends in 'ok', no message should be generated -->
  <xsl:template match="processing-instruction()[not(matches(., '^\S+\sok$'))]">
    <xsl:param name="id" as="xs:string"/>
    <xsl:variable name="actual-severity" as="xs:string">
      <xsl:choose>
        <xsl:when test="matches(., 'NFO')"><xsl:sequence select="'info'"/></xsl:when>
        <xsl:when test="matches(., 'ERR')"><xsl:sequence select="'error'"/></xsl:when>
        <xsl:when test="matches(., 'WRN')"><xsl:sequence select="'warning'"/></xsl:when>
        <xsl:when test="matches(., 'NRE')"><xsl:sequence select="'fatal-error'"/></xsl:when>
        <xsl:otherwise><xsl:sequence select="$severity"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <svrl:successful-report test="(: unknown :)" id="{$id}" role="{$actual-severity}" location="/">
      <svrl:text>
        <span xmlns="http://purl.oclc.org/dsdl/schematron" class="srcpath">
          <xsl:variable name="srcpath" select="(
                                                 ancestor::*[@srcpath][1]/@srcpath,
                                                 following-sibling::*[1][@srcpath]/@srcpath,
                                                 (..//@srcpath)[1],
                                                 preceding::*[@srcpath][1]/@srcpath,
                                                 following::*[@srcpath][1]/@srcpath
                                               )[1]" as="xs:string?"/>
          <xsl:if test="not($srcpath)">
            <xsl:message>errorPI2svrl: could not find srcpath for PI <xsl:value-of select="string-join((name(), .), ': ')"/></xsl:message>
          </xsl:if>
          <xsl:value-of select="string-join(($source-dir-uri, if (not($srcpath)) then 'BC_orphans' else $srcpath), '')"/>
        </span>
        <xsl:value-of select="replace(., '^.+?( (NFO|ERR|WRN|NRE))?\s+', '')"/></svrl:text>
    </svrl:successful-report>
  </xsl:template>
  
</xsl:stylesheet>
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:tr="http://transpect.io"
  xmlns:c="http://www.w3.org/ns/xproc-step" 
  xpath-default-namespace="http://transpect.io"
  exclude-result-prefixes="xs"
  version="2.0">
  
  <xsl:variable name="strings" as="element(string)+" xmlns="http://transpect.io">
    <string xml:id="f1">
      <loc xml:lang="de">Abbruchfehler</loc>
      <loc xml:lang="en">Fatal errors</loc>
    </string>
    <string xml:id="e1">
      <loc xml:lang="de">Fehler/-arten</loc>
      <loc xml:lang="en">Errors/distinct</loc>
    </string>
    <string xml:id="w1">
      <loc xml:lang="de">Warnungen/Warnungsarten</loc>
      <loc xml:lang="en">Warnings/distinct</loc>
    </string>
    <string xml:id="s1">
      <loc xml:lang="de">Meldungen in das HTML-Rendering einmontiert. </loc>
      <loc xml:lang="en">Patched messages into HTML rendering. </loc>
    </string>
  </xsl:variable>
  
  <xsl:template match="/*">
    <xsl:variable name="warnings" as="xs:integer" select="count(/document/messages/message[@severity = 'warning'])"/>
    <xsl:variable name="errors" as="xs:integer" select="count(/document/messages/message[@severity = 'error'])"/>
    <xsl:variable name="fatal-errors" as="xs:integer" select="count(/document/messages/message[@severity = 'fatal-error'])"/>
    <xsl:variable name="distinct-warnings" as="xs:integer" select="count(/document/messages[message[@severity = 'warning']])"/>
    <xsl:variable name="distinct-errors" as="xs:integer" select="count(/document/messages[message[@severity = 'error']])"/>
    <c:messages>
      <xsl:for-each select="('en', 'de')">
        <c:message xml:lang="{.}">
          <xsl:variable name="lang" select="." as="xs:string"/>
          <xsl:value-of select="$strings[@xml:id = 's1']/loc[@xml:lang = $lang]"/>
          <xsl:if test="$fatal-errors gt 0">
            <xsl:value-of select="$strings[@xml:id = 'f1']/loc[@xml:lang = $lang]"/>
            <xsl:text>: </xsl:text>
            <xsl:value-of select="$fatal-errors"/>
            <xsl:text>. </xsl:text>
          </xsl:if>
          <xsl:if test="$distinct-errors gt 0">
            <xsl:value-of select="$strings[@xml:id = 'e1']/loc[@xml:lang = $lang]"/>
            <xsl:text>: </xsl:text>
            <xsl:value-of select="$errors"/>
            <xsl:text>/</xsl:text>
            <xsl:value-of select="$distinct-errors"/>
            <xsl:text>. </xsl:text>
          </xsl:if>
          <xsl:if test="$distinct-warnings gt 0">
            <xsl:value-of select="$strings[@xml:id = 'w1']/loc[@xml:lang = $lang]"/>
            <xsl:text>: </xsl:text>
            <xsl:value-of select="$warnings"/>
            <xsl:text>/</xsl:text>
            <xsl:value-of select="$distinct-warnings"/>
            <xsl:text>.</xsl:text>
          </xsl:if>
          <xsl:text></xsl:text>
        </c:message>
      </xsl:for-each>
    </c:messages>
  </xsl:template>
  
</xsl:stylesheet>
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:l10n="http://transpect.io/l10n"
  xmlns="http://www.w3.org/1999/xhtml"
  version="2.0">

  <xsl:import href="svrl2xsl.xsl"/>
  
  <xsl:decimal-format decimal-separator="," grouping-separator="&#x2009;"/>

  <xsl:template name="l10n:rules-heading">
    <xsl:param name="display-note" as="xs:boolean"/>
    <xsl:param name="max-errors" as="xs:string"/>
    <h3>Prüfregeln 
      <xsl:if test="$display-note">
        <br/>
        <span style="font-size:small; font-weight:normal">Es werden höchstens <xsl:value-of
            select="$max-errors-per-rule"/> Meldungen für jede Prüfregel angezeigt.</span>
      </xsl:if>
    </h3>
  </xsl:template>
  
  <xsl:template name="l10n:message-heading">
    <h3>Meldung</h3>
  </xsl:template>
  
  <xsl:template name="l10n:fallback-for-removed-content">
    <span>Der Inhalt, auf den sich die Meldung bezieht, steht im aktuellen HTML-Rendering nicht zur Verfügung.
    	Es ist auch möglich, dass der Inhalt zwar vorhanden ist, aber zu wenig Informationen über seinen Ursprung miführt. 
    	Es kann sich hierbei um ein Defizit des Konvertierungsprozesses handeln. 
    	Das tut uns leid. Hier ist der sogenannte <em>srcpath</em> für
      diagnostische Zwecke: </span>
  </xsl:template>

  <xsl:template name="l10n:severity-heading">
    <h3>Schweregrad</h3>
  </xsl:template>

  <xsl:template name="l10n:message-empty" xmlns="http://www.w3.org/1999/xhtml">
    <li class="no-messages">OK</li>
  </xsl:template>
  
  <xsl:template name="l10n:report-toggle-label">
    <span id="BC_reportswitch-btn">Bericht anzeigen&#x2009;/&#x2009;verbergen</span>
  </xsl:template>

  <xsl:function name="l10n:severity-role-label" as="xs:string">
    <xsl:param name="role" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$role eq 'error'">
        <xsl:value-of select="'Fehler'"/>
      </xsl:when>
      <xsl:when test="$role eq 'warning'">
        <xsl:value-of select="'Warnung'"/>
      </xsl:when>
      <xsl:when test="$role = ('Info', 'info')">
        <xsl:value-of select="'Informationen'"/>
      </xsl:when>
      <xsl:when test="$role eq 'fatal-error'">
        <xsl:value-of select="'Fatale Fehler'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$role"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

</xsl:stylesheet>
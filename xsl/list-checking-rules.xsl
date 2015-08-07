<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
  xmlns:tr="http://transpect.io" 
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:s="http://purl.oclc.org/dsdl/schematron"
  xmlns="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="#all"
  version="2.0">

  <xsl:param name="interface-language" select="'en'" as="xs:string"/>
  <xsl:param name="s9y1"/>
  <xsl:param name="title" select="'Checking Rules'" as="xs:string"/>

	<xsl:template name="main">
	  <html>
      <head>
        <title>
          <xsl:value-of select="$s9y1"/>
        </title>
      </head>
      <body>
        <h1>
          <xsl:value-of select="$s9y1"/>
        </h1>
        <h4>
          <xsl:value-of select="format-dateTime(current-dateTime(), '[Y]-[M01]-[D01] [H01]:[m01]')"/>
        </h4>
        <xsl:apply-templates select="collection()/s:schema" mode="tr:list-checking-rules"/>
        <xsl:apply-templates select="collection()/tr:document" mode="tr:brief-report"/>
      </body>
    </html>
	</xsl:template>
  
  <!-- Schematron input -->
  
  <xsl:template match="s:schema" mode="tr:list-checking-rules">
    <xsl:apply-templates select="@*, node()" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="s:schema/@*" mode="tr:list-checking-rules"/>
  
  <xsl:template match="@tr:rule-family" mode="tr:list-checking-rules" priority="2">
    <h2>
      <xsl:value-of select="upper-case(.)"/>
    </h2>
  </xsl:template>
  
  <xsl:template match="s:rule[@context]" mode="tr:list-checking-rules">
    <h3>
      <xsl:choose>
        <xsl:when test="matches($interface-language, '^de(-\p{Lu}+)?$')">
          <xsl:text>Kontext: </xsl:text>    
        </xsl:when>
        <xsl:when test="matches($interface-language, '^fr(-\p{Lu}+)?$')">
          <xsl:text>Contexte: </xsl:text>    
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>Context: </xsl:text>
        </xsl:otherwise>
      </xsl:choose>
      <code>
        <xsl:value-of select="@context"/>
      </code>
    </h3>
    <dl>
      <xsl:apply-templates mode="#current"/>
    </dl>
  </xsl:template>
  
  <xsl:template match="s:assert | s:report" mode="tr:list-checking-rules">
    <dt>
      <span class="{@role}" title="{@role} {@id} {@test}">
        <xsl:value-of select="local-name()"/>
        <xsl:apply-templates select="@role" mode="#current"/>
      </span>
    </dt>
<!--    <xsl:apply-templates select="@test" mode="#current"/>-->
    <dd>
      <xsl:variable name="translation" as="element(s:diagnostic)*" 
        select="key('translation', tokenize(@diagnostics, '\s+'))[@xml:lang = $interface-language]"></xsl:variable>
      <xsl:apply-templates select="($translation, .)[1]/node()" mode="#current"/>
    </dd>
  </xsl:template>
  
  <xsl:template match="@role" mode="tr:list-checking-rules">
    <xsl:text> (</xsl:text>
    <xsl:choose>
      <xsl:when test="matches($interface-language, '^de(-\p{Lu}+)?$')">
        <xsl:text>Schweregrad: </xsl:text>
      </xsl:when>
      <xsl:when test="matches($interface-language, '^fr(-\p{Lu}+)?$')">
        <xsl:text>Sévérité: </xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>Severity: </xsl:text>
      </xsl:otherwise>
      </xsl:choose>
    <xsl:value-of select="."/>
    <xsl:apply-templates select="../@id" mode="tr:list-checking-rules_id-after-role"/>
    <xsl:text>)</xsl:text>
  </xsl:template>
  
  <xsl:template match="@id" mode="tr:list-checking-rules_id-after-role">
    <xsl:text>, ID: </xsl:text>
    <xsl:value-of select="."/>
  </xsl:template>
  
  <xsl:key name="translation" match="s:diagnostic" use="@id"/>
  
  <xsl:template match="@test" mode="tr:list-checking-rules">
    <dd>
      <code>
        <xsl:value-of select="."/>
      </code>
    </dd>
  </xsl:template>

  <xsl:template match="*:value-of" mode="tr:list-checking-rules">
    <span title="{@select}">[…]</span>
  </xsl:template>
  
  <xsl:template match="s:span[@class = 'srcpath']" mode="tr:brief-report tr:list-checking-rules"/>

  <!-- messages-grouped-by-type.xml input -->

  <xsl:template match="tr:document" mode="tr:brief-report">
    <xsl:if test="count(tr:messages/tr:message[@severity = 'fatal-error']) gt 1">
      <p>
        <xsl:choose>
          <xsl:when test="matches($interface-language, '^de(-\p{Lu}+)?$')">
            <xsl:text>Abbruchfehler: </xsl:text>
          </xsl:when>
          <xsl:when test="matches($interface-language, '^fr(-\p{Lu}+)?$')">
            <xsl:text>Erreurs fatales: </xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>Fatal Errors: </xsl:text>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:value-of select="count(tr:messages/tr:message[@severity = 'error'])"/>
      </p>
    </xsl:if>
    <p>
      <xsl:choose>
        <xsl:when test="matches($interface-language, '^de(-\p{Lu}+)?$')">
          <xsl:text>Fehler: </xsl:text>
        </xsl:when>
        <xsl:when test="matches($interface-language, '^fr(-\p{Lu}+)?$')">
          <xsl:text>Erreurs: </xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>Errors: </xsl:text>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:value-of select="count(tr:messages/tr:message[@severity = 'error'])"></xsl:value-of>
    </p>
    <p>
      <xsl:choose>
        <xsl:when test="matches($interface-language, '^de(-\p{Lu}+)?$')">
          <xsl:text>Warnungen: </xsl:text>
        </xsl:when>
        <xsl:when test="matches($interface-language, '^fr(-\p{Lu}+)?$')">
          <xsl:text>Alertes: </xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>Warnings: </xsl:text>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:value-of select="count(tr:messages/tr:message[@severity = 'warning'])"></xsl:value-of>
    </p>
    
    <xsl:if test="count(tr:messages/tr:message[@severity = ('fatal-error', 'error')]) = 0">
      <xsl:if test="count(tr:messages/tr:message[@severity = 'warning']) = 0">
        <p>
          <xsl:choose>
            <xsl:when test="matches($interface-language, '^de(-\p{Lu}+)?$')">
              <xsl:text>Alles ist ok.</xsl:text>
            </xsl:when>
            <xsl:when test="matches($interface-language, '^fr(-\p{Lu}+)?$')">
              <xsl:text>Tout est bien.</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>Everything is ok.</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </p>
      </xsl:if>
      <p>
        <xsl:choose>
          <xsl:when test="matches($interface-language, '^de(-\p{Lu}+)?$')">
            <xsl:text>Sie können das Dokument abgeben.</xsl:text>
          </xsl:when>
          <xsl:when test="matches($interface-language, '^fr(-\p{Lu}+)?$')">
            <xsl:text>Vous pouvez acheminer ce document.</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>You may pass on this document.</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </p>
    </xsl:if>
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="tr:messages" mode="tr:brief-report">
    <xsl:apply-templates select="tr:message[1]" mode="#current"/>
    <xsl:if test="count(tr:message) gt 1">
      <p style="margin-top:0"><i>[+ <xsl:value-of select="count(tr:message) - 1"/>]</i></p>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="@severity[. = 'warning'][$interface-language = 'de']" mode="#all">
    <xsl:value-of select="'Warnung'"/>
  </xsl:template>
  <xsl:template match="@severity[. = 'error'][$interface-language = 'de']" mode="#all">
    <xsl:value-of select="'Fehler'"/>
  </xsl:template>
  <xsl:template match="@severity[. = 'fatal-error'][$interface-language = 'de']" mode="#all">
    <xsl:value-of select="'Abbruchfehler'"/>
  </xsl:template>
  <xsl:template match="@severity" mode="#all">
    <xsl:value-of select="."/>
  </xsl:template>
  
  <xsl:template match="tr:message" mode="tr:brief-report">
    <p style="margin-bottom:0">
      <b>
        <xsl:apply-templates select="@severity" mode="#current"/>
      </b>
      <xsl:text>&#x2002;</xsl:text>
      <xsl:apply-templates select="(svrl:diagnostic-message[@xml:lang = $interface-language], svrl:text)[1]" mode="#current"/>
    </p>
    
  </xsl:template>
  

</xsl:stylesheet>

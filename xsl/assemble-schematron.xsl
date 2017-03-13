<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:tr="http://transpect.io" 
  xmlns:s="http://purl.oclc.org/dsdl/schematron"
  xmlns:xso="xsloutputnamespace"
  xmlns="http://purl.oclc.org/dsdl/schematron"
  exclude-result-prefixes="xs"
  version="2.0">

  <xsl:output indent="yes"/>
	
	<xsl:namespace-alias stylesheet-prefix="xso" result-prefix="xsl"/>

  <xsl:param name="family" />
  <xsl:param name="series" />
  <xsl:param name="publisher" />
  <xsl:param name="s9y1" />
  <xsl:param name="s9y1-path" as="xs:string?"/>
  <xsl:param name="s9y2-path" as="xs:string?"/>
  <xsl:param name="s9y3-path" as="xs:string?"/>
  <xsl:param name="s9y4-path" as="xs:string?"/>
  <xsl:param name="s9y5-path" as="xs:string?"/>
  <xsl:param name="s9y6-path" as="xs:string?"/>
  <xsl:param name="s9y7-path" as="xs:string?"/>
  <xsl:param name="s9y8-path" as="xs:string?"/>
  <xsl:param name="s9y9-path" as="xs:string?"/>
  <xsl:param name="basename" />
  <xsl:param name="fallback-uri" />

  <xsl:variable name="paths" as="xs:string*" 
    select="($s9y1-path, $s9y2-path, $s9y3-path, $s9y4-path, $s9y5-path, $s9y6-path, $s9y7-path, $s9y8-path, $s9y9-path)"/>
  
	<!-- prints a status message with the Id of the schematron report or assert when debug is set to yes -->
	<xsl:param name="schematron-rule-msg" select="'no'"/>
  <xsl:param name="debug" select="'no'"/>

  <xsl:function name="tr:family" as="xs:boolean">
    <xsl:param name="doc" as="document-node(element(s:schema))"/>
    <xsl:param name="fam" as="xs:string?"/>
    <xsl:sequence select="
      if ($fam)
      then (tokenize(document-uri($doc), '/')[last() - 1] = $fam)
      else true()
      "/>
  </xsl:function>

  <xsl:function name="tr:file-exists" as="xs:boolean">
    <xsl:param name="uri" as="xs:string"/>
    <xsl:sequence select="unparsed-text-available($uri)"/>
  </xsl:function>

  <xsl:function name="tr:schematron-collection" as="document-node(element(s:schema))*">
    <xsl:param name="paths" as="xs:string*"/>
    <xsl:param name="fam" as="xs:string"/>
    <xsl:for-each select="$paths">
      <xsl:variable name="url" select="concat(., 'schematron/', $fam)" as="xs:string"/>
      <xsl:sequence select="if (tr:file-exists($url))
                            then collection(concat($url, '?select=*.sch.xml')) 
                            else ()"/>
    </xsl:for-each>
  </xsl:function>

  <xsl:variable name="schematrons" as="document-node(element(s:schema))*" >
    <xsl:apply-templates select="tr:schematron-collection($paths, $family)" mode="tr:expand-includes"/>
  </xsl:variable>
  <xsl:variable name="fallback-schematrons" as="document-node(element(s:schema))*" >
    <xsl:if test="not($schematrons)
                  and
                  exists($fallback-uri)
                  and
                  not($fallback-uri = '') 
                  and
                  doc-available(resolve-uri($fallback-uri))">
      <xsl:apply-templates select="doc(resolve-uri($fallback-uri))" mode="tr:expand-includes"/>  
    </xsl:if>
  </xsl:variable>

  <xsl:template match="s:include" mode="tr:expand-includes">
    <xsl:apply-templates select="doc(@href)/s:schema/*" mode="#current">
      <xsl:with-param name="is-included" select="true()" tunnel="yes"/>
      <xsl:with-param name="is-included-non-a9s" 
        select="if(matches(@href, 'http://this.transpect.io/a9s/')) then false() else true()" tunnel="yes"/>
      <xsl:with-param name="include-href" select="@href" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="/">
    <xsl:message>Schematron family: <xsl:value-of select="$family"/>
    <xsl:if test="not($schematrons/s:schema/self::s:schema) and not($fallback-schematrons/s:schema/self::s:schema)">
      <xsl:value-of select="' - WARNING: No schematron file and no fallback found!'"/>
    </xsl:if>
    </xsl:message>
    <xsl:message>        from <xsl:value-of 
      select="if($fallback-schematrons) then 'fallback-uri' else 'URIs'"/>: <xsl:value-of 
      select="$schematrons/s:schema/base-uri()"/></xsl:message>
    <schema tr:rule-family="{$family}">
      <xsl:for-each-group select="$schematrons/s:schema/s:ns" group-by="@uri">
        <!-- Assumption: no two different prefixes for one uri. --> 
        <ns prefix="{@prefix}" uri="{current-grouping-key()}"/>
      </xsl:for-each-group>
      <xsl:for-each-group select="$schematrons/s:schema/xsl:include[not(matches(@href, 'shared-variables.xsl'))]|$schematrons/s:schema/xsl:import" group-by="@href">
        <xso:include href="{current-grouping-key()}"/>
      </xsl:for-each-group>
      <xsl:for-each-group select="$schematrons/s:schema/xsl:param" group-by="@name">
        <xsl:apply-templates select="tr:most-important-element(current-group())" mode="tr:assemble-schematron"/>
      </xsl:for-each-group>
      <xsl:apply-templates select="($schematrons/s:schema/xsl:include[matches(@href, 'shared-variables.xsl')])[1]"  mode="tr:assemble-schematron"/>
      <xsl:for-each-group select="$schematrons/s:schema/s:phase" group-by="@id">
        <phase id="{current-grouping-key()}">
          <xsl:for-each-group select="current-group()/s:active" group-by="@pattern">
            <active pattern="{current-grouping-key()}"/>
          </xsl:for-each-group>
        </phase>
      </xsl:for-each-group>
      <xsl:for-each-group select="$schematrons/s:schema/s:let" group-by="@name">
        <xsl:apply-templates select="tr:most-important-element(current-group())" mode="tr:assemble-schematron"/>
      </xsl:for-each-group>
      <xsl:for-each-group select="$schematrons/s:schema/s:pattern" group-by="@id">
        <xsl:apply-templates select="tr:most-important-element(current-group())" mode="tr:assemble-schematron"/>
      </xsl:for-each-group>
      <xsl:variable name="diagnostics">
        <xsl:for-each-group select="$schematrons/s:schema/s:diagnostics/s:diagnostic" group-by="@id">
          <xsl:apply-templates select="tr:most-important-element(current-group())" mode="tr:assemble-schematron"/>
        </xsl:for-each-group>
      </xsl:variable>
      <xsl:if test="$diagnostics[descendant-or-self::*]">
        <diagnostics>
          <xsl:sequence select="$diagnostics"/>
        </diagnostics>
      </xsl:if>
      <xsl:for-each-group select="$schematrons/s:schema/xsl:function" group-by="@name">
        <xsl:apply-templates select="tr:most-important-element(current-group())" mode="tr:assemble-schematron"/>
      </xsl:for-each-group>
      <xsl:for-each-group select="$schematrons/s:schema/xsl:variable" group-by="@name">
        <xsl:apply-templates select="tr:most-important-element(current-group())" mode="tr:assemble-schematron"/>
      </xsl:for-each-group>
      <xsl:for-each-group select="$schematrons/s:schema/xsl:key" group-by="@name">
        <xsl:apply-templates select="tr:most-important-element(current-group())" mode="tr:assemble-schematron"/>
      </xsl:for-each-group>
      <xsl:for-each-group select="$schematrons/s:schema/xsl:template[@name]" group-by="@name">
        <xsl:apply-templates select="tr:most-important-element(current-group())" mode="tr:assemble-schematron"/>
      </xsl:for-each-group>
      <xsl:apply-templates select="$schematrons/s:schema/xsl:template[@match]" mode="tr:assemble-schematron"/>
    </schema> 
  </xsl:template>
  
  <xsl:function name="tr:most-important-element" as="element()?">
    <xsl:param name="current-group" as="element()*"/>
    <xsl:sequence select="
      if($current-group[@is-included-non-a9s] and $current-group[not(@is-included-non-a9s)]) 
      then $current-group[not(@is-included-non-a9s)][1] 
      else $current-group[1]
      "/>
  </xsl:function>
  
  <xsl:template match="s:pattern | s:let" mode="tr:assemble-schematron">
    <xsl:text>&#xa;&#xa;   </xsl:text>
    <xsl:text>&#xa;   </xsl:text>
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
      <!-- The origin of the element, formerly as comment -->
      <xsl:processing-instruction name="origin">
        <xsl:value-of select="(@include-href, base-uri(.))[1]"/>
      </xsl:processing-instruction>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
  </xsl:template>
	
	<xsl:template match="s:assert | s:report" mode="tr:assemble-schematron">
		<xsl:choose>
		  <xsl:when test="$schematron-rule-msg eq 'yes' and $debug eq 'yes'">
				<xso:message select="{concat('''', local-name(), ' ', if(@id) then @id else 'no @id found', '''')}"/>		
			</xsl:when>
		</xsl:choose>
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="#current"/>
		  <xsl:if test="not(exists(s:span[@class eq 'srcpath']))">
		    <span class="srcpath"><xso:value-of select="ancestor-or-self::*[@srcpath][1]/@srcpath"/></span>
		  </xsl:if>
			<xsl:apply-templates mode="#current"/>
		</xsl:copy>
	</xsl:template>
  
  <xsl:template match="@role[. = 'warn']" mode="tr:assemble-schematron">
    <xsl:attribute name="{name()}" select="'warning'"/>
  </xsl:template>

  <xsl:template match="@role" mode="tr:assemble-schematron">
    <!-- 'Info' → 'info' -->
    <xsl:attribute name="{name()}" select="lower-case(.)"/>
  </xsl:template>


  <xsl:template match="@* | *" mode="tr:assemble-schematron">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="@is-included" mode="tr:assemble-schematron"/>
  <xsl:template match="@is-included-non-a9s" mode="tr:assemble-schematron"/>
  <xsl:template match="@include-href" mode="tr:assemble-schematron"/>
  
  <xsl:template match="@* | *" mode="tr:expand-includes">
    <xsl:param name="is-included" select="false()" tunnel="yes"/>
    <xsl:param name="is-included-non-a9s" select="false()" tunnel="yes"/>
    <xsl:param name="include-href" tunnel="yes"/>
    <xsl:copy copy-namespaces="no">
      <xsl:if test="$is-included">
        <xsl:attribute name="is-included" select="'true'"/>
        <xsl:if test="$is-included-non-a9s">
          <xsl:attribute name="is-included-non-a9s" select="'true'"/>
        </xsl:if>
        <xsl:attribute name="include-href" select="$include-href"/>
      </xsl:if>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="/s:schema" mode="tr:expand-includes">
    <xsl:document>
      <xsl:copy>
        <xsl:attribute name="xml:base" select="base-uri()"/>
        <xsl:apply-templates select="@*, node()" mode="#current"/>
      </xsl:copy>  
    </xsl:document>
    
  </xsl:template>
  
</xsl:stylesheet>

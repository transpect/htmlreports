<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:s="http://purl.oclc.org/dsdl/schematron"  
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:l10n="http://transpect.io/l10n"
  xmlns:tr="http://transpect.io"
  version="2.0">

<!--  <xsl:param name="interface-language" select="'en'" as="xs:string"/>
  <xsl:param name="file"  as="xs:string?"/>
  <xsl:variable name="html-with-srcpaths" select="collection()[2]" as="document-node(element(html:html))"/>-->
 
  <!--  This XSLT will regroup the asserts and reports by other categories than their family. This shall be helpful 
        for typesetters to see more easily of what kind an error is. (the family is mostly not understood by them)
        The input is the reports/c:error document. If a span with a special class is contained by the asserts/reports 
        they are regrouped. The class is an parameter that shall be set via a parameter document. Its name is 'rule-category-span-class'. 
        Only if it is set and the spans are contained there will be a regrouping.
        
        Every category results in a new schematron-output element. 
        If a report or assert doesn't have a categorisizing span the original schematron-output family is used.
        The categorizing span is discarded afterwards.
        
  -->
  
  <xsl:param name="rule-category-span-class" as="xs:string?"/>
  <xsl:param name="interface-language" as="xs:string?"/>
  <xsl:param name="discard-epub-schematron-svrl" as="xs:string?"/>
  
  <xsl:template match="/*">
    <xsl:copy>
      <xsl:copy-of select="@*, c:errors"/>
      <xsl:choose>
        <xsl:when test="$rule-category-span-class and //*[self::svrl:successful-report or self::svrl:failed-assert]
                                                          [*[self::svrl:text or self::svrl:diagnostic-reference[@xml:lang eq $interface-language]]
                                                            [s:span[@class = $rule-category-span-class]]]">
          <xsl:for-each-group select="//svrl:schematron-output/*[self::svrl:successful-report or self::svrl:failed-assert]" 
                            group-by="if (./*/s:span[@class = $rule-category-span-class]) 
                                      then (svrl:text/s:span[@class = $rule-category-span-class], svrl:diagnostic-reference[@xml:lang eq $interface-language]/s:span[@class = $rule-category-span-class])[1] 
                                      else parent::svrl:schematron-output/@tr:rule-family">
            <xsl:if test="not($discard-epub-schematron-svrl = ('yes', 'true') and (current-grouping-key() = 'epubtools'))">
                  <svrl:schematron-output xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
                    xmlns:schold="http://www.ascc.net/xml/schematron"
                    xmlns:iso="http://purl.oclc.org/dsdl/schematron"
                    xmlns:xhtml="http://www.w3.org/1999/xhtml"
                    tr:rule-family="{if (current-group()[svrl:diagnostic-reference[@xml:lang eq $interface-language]
                    [s:span[@class = $rule-category-span-class]]]) 
                    then (current-group()/svrl:diagnostic-reference[@xml:lang eq $interface-language][s:span[@class = $rule-category-span-class]])[1]/s:span[@class = $rule-category-span-class]//text() 
                    else current-grouping-key()}">
                    <xsl:apply-templates select="current-group()"/>
                  </svrl:schematron-output>
            </xsl:if>
          </xsl:for-each-group>
        </xsl:when>
        <xsl:otherwise>
          <!-- reproduce document if neither param is filled or span with classes appear in c:reports document -->
          <xsl:apply-templates select="node()"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="svrl:schematron-output[@tr:rule-family = 'epubtools']">
    <xsl:if test="$discard-epub-schematron-svrl = 'no'">
      <xsl:next-match/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="/">
    <xsl:copy>
      <xsl:apply-templates select="*"/>
    </xsl:copy>
  </xsl:template>
    
  <xsl:template match="node() | @*">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*, node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="svrl:text">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*"/>
      <xsl:attribute name="tr:step-name" select="ancestor::svrl:schematron-output/@tr:step-name"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="s:span[@class = $rule-category-span-class]">
    <!-- Discards the span to let it not appear in the text -->
  </xsl:template>
  
</xsl:stylesheet>

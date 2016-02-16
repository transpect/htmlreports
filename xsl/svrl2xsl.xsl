<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xslout="bogo"
  xmlns:svrl="http://purl.oclc.org/dsdl/svrl" 
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:s="http://purl.oclc.org/dsdl/schematron" 
  xmlns:aid="http://ns.adobe.com/AdobeInDesign/4.0/"
  xmlns:aid5="http://ns.adobe.com/AdobeInDesign/5.0/" 
  xmlns:idPkg="http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
  xmlns:idml2xml="http://transpect.io/idml2xml" 
  xmlns:tr="http://transpect.io"
  xmlns:c="http://www.w3.org/ns/xproc-step" 
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:l10n="http://transpect.io/l10n" 
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:functx="http://www.functx.com"  
  version="2.0">

  <xsl:import href="http://transpect.io/xslt-util/functx/xsl/functx.xsl"/>

  <xsl:output method="xml" indent="yes"/>

  <xsl:param name="remove-srcpath" select="'yes'"/>
  <xsl:param name="max-errors-per-rule" as="xs:string?"/>
  <xsl:param name="severity-default-name" select="'no-role'" as="xs:string"/>

  <xsl:param name="interface-language" select="'en'" as="xs:string"/>
  <xsl:param name="file" as="xs:string?"/>

  <xsl:param name="report-title" select="'Report'" as="xs:string"/>
  <xsl:param name="show-adjusted-srcpath" select="'yes'" as="xs:string"/>

  <xsl:param name="r-value" as="xs:string" select="'''ff'''"/>
  <xsl:param name="b-value" as="xs:string" select="'''00'''"/>
  
  <xsl:variable name="html-with-srcpaths" select="collection()[2]" as="document-node(element(html:html))"/>

  <xsl:variable name="severity-default-role" as="attribute(role)">
    <xsl:attribute name="role" select="$severity-default-name"/>
  </xsl:variable>
  <xsl:variable name="maxerr" as="xs:integer"
    select="if ($max-errors-per-rule castable as xs:integer) 
                                                      then xs:integer($max-errors-per-rule)
                                                      else 0"/>


  <xsl:namespace-alias stylesheet-prefix="xslout" result-prefix="xsl"/>

  <!--  The messages need to be grouped by their srcpaths, since these paths will translate to individual
        template matching patterns in the generated stylesheet. 
        Another requirement is: The error messages for a given type of error should link to the next
        error message of the same type. 
        We will first wrap each message in a tr:message element with standardized attributes:
        @srcpath, @severity, @type (a coumpound string of the error code, severity, and checking rule family), and @xml:id (a generated id).
        In the next pass, the messages will be grouped by @type. For brevity in the HTML report, each distinct @type
        will translate into @rendered-key, a capital letter ('A', 'B', …) that will be rendered at the error’s location, with a
        background color that depends on severity. Each group’s item will then be linked to its successor message (if available).
        The link target will be in a tr:message/@href attribute, in the form '#target-id'.
        An attribute @occurrence will be added. It is the serial number of this error within all errors of the same type.
        In this pass, the messages will be grouped by their @srcpath. xslout:templates will be output that, when applied
        to the raw HTML report, will create message snippets as preformatted spans at the corresponding error locations (identified
        by the @srcpath attribute that must be present in the HTML).
        
        The input is expected to be a c:reports document element that contains any number of svrl:schematron-output or
        c:errors elements.
        
        The svrl:schematron-output and c:errors elements may have a @tr:rule-family attribute that denotes to which *family*
        of checking rules they belong. These are arbitrary labels that for example suggest to which kind of document,
        at which stage of a larger conversion pipeline, the rules of that family have been applied. I’d probably call 
        them “phases” unless that name had already been taken.
        
        The c:errors element is expected to contain one or more c:error elements. Only those c:error elements that have
        an attribute are considered real errors (plain xsl:message output will appear in a c:error element, too, but without
        any attribute).
        -->

  <xsl:variable name="base-srcpath" as="xs:string?"
    select="$html-with-srcpaths/html:html/html:head/html:meta[@name eq 'source-dir-uri']/@content"/>

  <xsl:variable name="all-document-srcpaths" select="for $s in $html-with-srcpaths//@srcpath 
                                                     return tr:normalize-srcpath($s)"/>
  
  <xsl:variable name="split-document-srcpaths" select="distinct-values(
    for $sp in $all-document-srcpaths[matches(., ';n=\d+$')]
    return replace($sp, ';n=\d+$', ''))" as="xs:string*"/>
  <xsl:function name="tr:normalize-srcpath" as="xs:string*">
    <xsl:param name="srcpath-att" as="xs:string?"/>
    <xsl:variable name="tokenize-srcpath" select="tokenize($srcpath-att, '/')" as="xs:string*"/>

    <xsl:sequence select="for $s in $srcpath-att
                          return for $t in tokenize($s, '\s+')
                                 return if (contains($t, '?xpath=') and not(starts-with($t, 'file:/')))
                                        then string-join(($base-srcpath, $t), '')
                                        else $t"/>
  </xsl:function>

  <xsl:variable name="collected-messages" as="element(tr:message)*">
    <xsl:apply-templates select="//c:error[@*]" mode="collect-messages"/>
    <xsl:apply-templates select="//svrl:text[parent::svrl:successful-report | parent::svrl:failed-assert]"
      mode="collect-messages"/>
  </xsl:variable>

  <xsl:template match="c:error[@*]" mode="collect-messages">
    <tr:message srcpath="BC_orphans" xml:id="BC_{generate-id()}" severity="{@type}"
      type="{parent::c:errors/@tr:rule-family} {@type} {@code}">
      <xsl:copy-of select="ancestor-or-self::*[@tr:step-name][1]/@tr:step-name"/>
      <tr:text>
        <xsl:copy-of select="node()"/>
      </tr:text>
    </tr:message>
  </xsl:template>

  <xsl:template match="svrl:text[tr:ignored-in-html(*:span[@class eq 'srcpath'])]" mode="collect-messages"/>

  <xsl:template match="svrl:text[parent::svrl:successful-report | parent::svrl:failed-assert]
                                [not(tr:ignored-in-html(*:span[@class eq 'srcpath']))]" mode="collect-messages">
    <xsl:variable name="role" as="xs:string" select="(../@role, $severity-default-role)[1]"/>
    <!-- if the schematron doesn't contain spans with srcpath, we use the location attribute as fallback -->
    <xsl:variable name="normalized-srcpath" as="xs:string*" select="tr:normalize-srcpath((s:span[@class eq 'srcpath'], parent::*/@location)[1])"/>
    <xsl:variable name="adjusted-srcpath" as="xs:string*" select="tr:adjust-to-existing-srcpaths($normalized-srcpath, $all-document-srcpaths)"/>
    <tr:message xml:id="BC_{generate-id()}" 
                severity="{$role}" 
                type="{ancestor-or-self::svrl:schematron-output/@tr:rule-family} {$role} {../@id}" 
                srcpath="{if (every $ap in $adjusted-srcpath 
                              satisfies (ends-with($ap, '?xpath='))
                                    )
                                 then $normalized-srcpath
                                 else $adjusted-srcpath}">
      <xsl:copy-of select="ancestor-or-self::*[@tr:step-name][1]/@tr:step-name"/>
      <xsl:if test="not($adjusted-srcpath = $normalized-srcpath)">
        <xsl:attribute name="adjusted-from" select="$normalized-srcpath"/>
      </xsl:if>
      <xsl:copy-of select="., ../svrl:diagnostic-reference"/>
    </tr:message>
  </xsl:template>

  <xsl:function name="tr:adjust-to-existing-srcpaths" as="xs:string+">
    <xsl:param name="message-srcpaths" as="xs:string*"/>
    <xsl:param name="document-srcpaths" as="xs:string*"/>
    <xsl:variable name="matching" as="xs:string*" select="$message-srcpaths[. = $document-srcpaths]"/>
    <xsl:variable name="with-xpath" select="$message-srcpaths[contains(., '?xpath=/')]" as="xs:string*"/>
    <xsl:variable name="without-xpath" select="$message-srcpaths[not(contains(., '?xpath=/'))]" as="xs:string*"/>
    <!-- This is for srcpaths that are have been derived from generated IDs rather than xpath locations
      but have been prefixed with the document’s common source dir uri by a Schematron rule: -->
    <xsl:variable name="only-lastword" as="xs:string*"
      select="for $sp in $without-xpath return replace($sp, '^.+/', '')"/>
    <xsl:choose>
      <xsl:when test="exists($matching)">
        <xsl:sequence select="$matching"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$without-xpath = $message-srcpaths">
            <xsl:sequence select="$without-xpath[. = $message-srcpaths]"/>
          </xsl:when>
          <xsl:when test="exists($with-xpath)">
            <!-- Backtrack – cut away XPath steps from the end and see whether the more comprehensive path
              exists in the document. Scenario: a phrase was dissolved after its srcpath found its way to 
              a report. 
            -->
            <xsl:choose>
              <xsl:when test="$with-xpath = $split-document-srcpaths">
                <!-- Additional complication: In InDesign, if a ParagraphStyleRange may comprise several paragraphs,
                     ';n=1', ';n=2', etc. will be appended to each paragraph’s srcpath. Cutting away '/CharacterStyleRange[…]'
                     at the end won’t give a srcpath that matches either of these paragraphs. -->
                <xsl:sequence
                  select="(
                                        $all-document-srcpaths[some $dsp in $with-xpath 
                                                               satisfies (starts-with(., concat($dsp, ';n=')))
                                                              ]
                                      )[last()]"/>
                <!-- last() is arbitrary, could be any of them -->
              </xsl:when>
              <xsl:otherwise>
                <xsl:variable name="remove-tails" as="xs:string*"
                  select="distinct-values(
                            for $sp in $with-xpath 
                            return replace($sp, '/[^/]+$', '')
                          )[not(. = $message-srcpaths)]"/>
                <xsl:choose>
                  <xsl:when test="empty($remove-tails)">
                    <xsl:sequence select="'BC_orphans'"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:sequence select="tr:adjust-to-existing-srcpaths($remove-tails, $document-srcpaths)"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="'BC_orphans'"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:variable name="messages-grouped-by-type" as="document-node(element(tr:document))">
    <xsl:document>
      <tr:document>
        <xsl:for-each-group select="$collected-messages" group-by="@type">
          <tr:messages type="{current-grouping-key()}">
            <xsl:perform-sort select="current-group()">
              <!-- Make sure that they will be in document order (because of the structure of Saxon’s generated IDs): -->
              <xsl:sort select="@xml:id" collation="http://saxon.sf.net/collation?alphanumeric=yes"/>
            </xsl:perform-sort>
          </tr:messages>
        </xsl:for-each-group>
      </tr:document>
    </xsl:document>
  </xsl:variable>

  <xsl:variable name="message-types" select="$messages-grouped-by-type/tr:document/tr:messages/@type" as="xs:string*"/>

  <xsl:variable name="linked-messages-grouped-by-srcpath" as="document-node(element(tr:document))">
    <xsl:document>
      <tr:document>
        <xsl:for-each-group
          select="$messages-grouped-by-type/tr:document/tr:messages/tr:message[if ($maxerr gt 0) 
                                                                               then (position() le $maxerr)
                                                                               else true()]"
          group-by="tokenize(@srcpath, '\s+')">
          <tr:messages srcpath="{current-grouping-key()}">
            <xsl:apply-templates select="current-group()" mode="link"/>
          </tr:messages>
        </xsl:for-each-group>
      </tr:document>
    </xsl:document>
  </xsl:variable>

  <xsl:template match="tr:message" mode="link">
    <xsl:variable name="pos" select="index-of(../*/@xml:id, @xml:id)" as="xs:integer"/>
    <xsl:variable name="id-plus-pos" as="xs:string"
      select="string-join((@xml:id, string((index-of(tokenize(@srcpath, '\s+'), current-grouping-key()))[1])), '_')"/>
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:if test="$pos lt $maxerr and exists(following-sibling::tr:message)">
        <xsl:attribute name="href" select="concat('#', following-sibling::tr:message[1]/@xml:id)"/>
      </xsl:if>
      <xsl:attribute name="rendered-key">
        <xsl:number value="index-of($message-types, @type)" format="A"/>
      </xsl:attribute>
      <xsl:attribute name="xml:id" select="$id-plus-pos"/>
      <xsl:attribute name="occurrence" select="$pos"/>
      <xsl:copy-of select="*"/>
    </xsl:copy>
  </xsl:template>



  <!-- overwrite these templates in your project svrl2xsl to insert extra CSS or JavaScript -->
  <xsl:template name="project-specific-css" xmlns="http://www.w3.org/1999/xhtml"/>
  <xsl:template name="project-specific-js" xmlns="http://www.w3.org/1999/xhtml"/>

  <xsl:template match="tr:messages" mode="create-fallback" xmlns="http://www.w3.org/1999/xhtml">
    <xsl:for-each select="tokenize(@srcpath,'\s+')">
      <p>
        <s-p>
          <xsl:value-of select="."/>
        </s-p>
        <xsl:call-template name="l10n:fallback-for-removed-content"/>
        <span class="BC_srcpath">
          <xsl:value-of select="."/>
        </span>
      </p>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="l10n:fallback-for-removed-content" xmlns="http://www.w3.org/1999/xhtml">
    <span>The content that this message pertains to has not been included in the HTML rendering, or it does not provide
      information about its origin. This may be due to a flaw in the conversion pipeline. Sorry for that. Here’s the
      so-called <em>srcpath</em> for diagnostic purposes: </span>
  </xsl:template>

  <xsl:template match="/" mode="#default">
    <xsl:result-document href="messages-grouped-by-type.xml">
      <xsl:sequence select="$messages-grouped-by-type"/>
    </xsl:result-document>
    <xsl:result-document href="linked-messages-grouped-by-srcpath.xml">
      <xsl:sequence select="$linked-messages-grouped-by-srcpath"/>
    </xsl:result-document>
    <xslout:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
      xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
      xmlns:css="http://www.w3.org/1996/css" xmlns:s="http://purl.oclc.org/dsdl/schematron"
      xmlns:html="http://www.w3.org/1999/xhtml" xmlns:tr="http://transpect.io" xmlns:cx="http://xmlcalabash.com/ns/extensions" 
      exclude-result-prefixes="svrl s xs html tr css aid aid5 idPkg idml2xml c cx l10n"
      xmlns="http://www.w3.org/1999/xhtml">

      <xslout:import href="http://transpect.io/xslt-util/hex/xsl/hex.xsl"/>

      <xslout:output method="xhtml" cdata-section-elements="script"/>
      <xslout:function name="tr:contains-token" as="xs:boolean">
        <xslout:param name="space-separated-list" as="xs:string?"/>
        <xslout:param name="token" as="xs:string?"/>
        <xslout:sequence select="$token = tokenize($space-separated-list, '\s+')"/>
      </xslout:function>

      <xslout:variable name="src-dir-uri" select="/html:html/html:head/html:meta[@name eq 'source-dir-uri']/@content" as="xs:string?"/>
      
      <xslout:variable name="r-value" as="xs:string" select="{$r-value}"/>
      <xslout:variable name="b-value" as="xs:string" select="{$b-value}"/>
      
      <xslout:template match="*[@srcpath]" mode="create-fallback">
        <xslout:variable name="expanded" as="xs:string*">
          <xslout:for-each select="tokenize(@srcpath, '\s+')">
            <xslout:choose>
              <xslout:when test=". = 'BC_orphans'">
                <xslout:sequence select="."/>
              </xslout:when>
              <xslout:when test="starts-with(., 'file:/')">
                <xslout:sequence select="."/>
                <xslout:sequence select="replace(., ';n=\d+$', '')"/>
              </xslout:when>
              <xslout:when test="empty(.)">
                <xslout:sequence select="'BC_orphans'"/>
              </xslout:when>
              <xslout:when test=". = $src-dir-uri">
                <xslout:sequence select="'BC_orphans'"/>
              </xslout:when>
              <xslout:when test="contains(., '?xpath=')">
                <!-- relative URI (fully qualified srcpaths should have been cought by the 'file:/' case) -->
                <xslout:sequence select="string-join(($src-dir-uri, .), '')"/>
                <xslout:sequence select="string-join(($src-dir-uri, replace(., ';n=\d+$', '')), '')"/>
              </xslout:when>
              <xslout:otherwise>
                <xslout:sequence select="."/>
                <xslout:if test="$src-dir-uri">
                  <xslout:sequence select="concat($src-dir-uri, .)"/>
                </xslout:if>
              </xslout:otherwise>
            </xslout:choose>
          </xslout:for-each>
        </xslout:variable>
        <xslout:choose>
          <xslout:when test="local-name() = ('br', 'a', 'span', 'sub', 'sup', 'img')">
            <xslout:for-each select="distinct-values($expanded)">
              <s-p>
                <xslout:sequence select="."/>
              </s-p>
            </xslout:for-each>
            <xslout:copy>
              <xslout:apply-templates select="@*" mode="#current"/>
              <xslout:apply-templates mode="#current"/>
            </xslout:copy>
          </xslout:when>
          <xslout:otherwise>
            <xslout:copy>
              <xslout:apply-templates select="@*" mode="#current"/>
              <xslout:for-each select="distinct-values($expanded)">
                <s-p>
                  <xslout:sequence select="."/>
                </s-p>
              </xslout:for-each>
              <xslout:apply-templates mode="#current"/>
            </xslout:copy>
          </xslout:otherwise>
        </xslout:choose>

      </xslout:template>

      <xslout:key name="by-srcpath" match="*[html:s-p]" use="html:s-p"/>

      <xslout:template match="* | @*" mode="create-fallback remove-fallback #default">
        <xslout:copy>
          <xslout:apply-templates select="@*, node()" mode="#current"/>
        </xslout:copy>
      </xslout:template>

      <xslout:template match="html:body" mode="create-fallback">
        <xslout:copy>
          <xslout:apply-templates select="@*, node()" mode="#current"/>
          <script type="text/javascript">
            $( document ).ready(function() {
            
            
              
              /* exchange +/- at collapse */
              
              $(".BC_family-label-collapse").click(function () {
                if($(this).text() == '–'){
                  $(this).html('+');
                } else {
                  $(this).html('–');                }
              });
              
              /* show warning messages in container with id BC_msg */
              
              $(".BC_marker").click(function () {
                var message = $(this).next().clone();
                message.toggle();
                $("#BC_msg").empty().append(message);
              });
              
              
              $("a.BC_link").click(function () {
                var content = $(this).attr('href');
                var message = $("span" + content).next().clone();
                message.toggle();
                $("#BC_msg").empty().append(message);
              });
              
              
              /* checkbox: toggle elements with class BC_tooltip.NAME */
              
              $(".BC_toggle").change(function () {
                if($(this).is(':checked')){
                  $(".BC_tooltip." + this.id.replace(/BC_toggle_/, "")).show();
                  $(this).next().show();
                } else {
                  $(".BC_tooltip." + this.id.replace(/BC_toggle_/, "")).hide();
                  $(this).next().hide();
                }
              });
              
              /* button: toggle elements with class BC_tooltip.NAME */
              
              $("button.BC_toggle").click(function () {
                if($(this).hasClass('active')){
                  $(".BC_tooltip." + this.id.replace(/BC_toggle_/, "")).hide();
                  $(this).removeClass('active')
                } else {
                  $(".BC_tooltip." + this.id.replace(/BC_toggle_/, "")).show();
                  $(this).addClass('active')
                }
              });
              
              
            });
          </script>
        </xslout:copy>
      </xslout:template>

      <xslout:template match="html:*[@id eq 'tr-content']" mode="create-fallback">
        <xslout:copy>
          <xslout:apply-templates select="@*, node()" mode="#current"/>
          <div class="BC_fallback" xmlns="http://www.w3.org/1999/xhtml">
            <xsl:apply-templates select="$linked-messages-grouped-by-srcpath/tr:document/tr:messages"
              mode="create-fallback"/>
          </div>
        </xslout:copy>
      </xslout:template>

      <xslout:template match="html:div[@class = 'BC_fallback']/html:p[not(descendant::html:span[contains(@class, 'BC_marker')])]" mode="remove-fallback"/>
      
      <xslout:template match="html:div[@id = 'BC_orphans'][not(html:p/node())]" mode="remove-fallback"/>

      <xslout:key name="message-link-target-without-srcpath-position"
        match="html:span[matches(@id, '^BC_[de\d]+_\d+$')]" use="concat('#', replace(@id, '^(.+)_\d+$', '$1'))"/>

      <!-- href is always generated without positional suffix while the IDs contain such a suffix.
        Look for the last ID with the same base and a suffix and adjust href accordingly -->
      <xslout:template match="html:a[@class = 'BC_link'][key('message-link-target-without-srcpath-position', @href)]"
        mode="remove-fallback">
        <xslout:copy>
          <xslout:attribute name="href"
            select="concat('#', (key('message-link-target-without-srcpath-position', @href))[last()]/@id)"/>
          <xslout:apply-templates select="@* except @href, node()" mode="#current"/>
        </xslout:copy>
      </xslout:template>

      <!-- avoid duplicate message markers when there were two matching srcpaths. The last marker prevails -->
      <xslout:template
        match="html:span[tr:contains-token(@class, 'BC_tooltip')]
                                        [
                                          html:span[matches(@id, '^BC_[de\d]+_\d+$')]
                                                   [ 
                                                     some $same-id-marker in
                                                     key(
                                                       'message-link-target-without-srcpath-position', 
                                                       concat('#', replace(@id, '^(.+)_\d+$', '$1'))
                                                     ) 
                                                     satisfies ($same-id-marker &gt;&gt; .)
                                                     (: &gt;&gt; corresponds with [last()] in the preceding template :)
                                                   ]
                                        ]"
        mode="remove-fallback"/>

      <!-- main processing in default mode: -->
      <xslout:template match="/*">
        <xslout:copy copy-namespaces="no">
          <xsl:apply-templates select="svrl:ns-prefix-in-attribute-values" mode="#default"/>
          <xslout:apply-templates select="@* | node()" mode="#current"/>
        </xslout:copy>
      </xslout:template>

      <xslout:template match="@xml:base"/>

      <xsl:if test="$remove-srcpath = 'yes'">
        <xslout:template match="@srcpath"/>
      </xsl:if>

      <xslout:template match="html:s-p"/>

      <xslout:template match="html:head">
        <xslout:copy copy-namespaces="no">
          <xslout:apply-templates mode="#current"/>
          <style type="text/css">
            button.fatal-error, button.fatal-error_notoggle, .BC_message.fatal-error, #BC_toggle_fatal-error.active{
              color:#f2dede; 
              background-color:#a94442;
              border-color:#ebccd1;
              font-weight:bold
            }
            button.fatal-error:hover, .fatal-error_notoggle:hover, #BC_toggle_fatal-error.active:hover{
              background-color:#a94442;
              color:#fff;
            }
            button.error, button.error_notoggle, .BC_message.error, #BC_toggle_error.active{
              background-color:#fc9a8d; 
              color:#973433;
              border-color:#ebccd1;
              font-weight:bold
            }
            button.error:hover, .error_notoggle:hover, #BC_toggle_error.active:hover{
              background-color:#fc9a8d;
              color:#fff;
            }
            button.warning, .warning_notoggle, .BC_message.warning, #BC_toggle_warning.active{
              background-color:#ffe082;
              color:#e67000;
              border-color:#ffe082;
              font-weight:bold
            }
            button.warning:hover, .warning_notoggle:hover, #BC_toggle_warning.active:hover{
              background-color:#ffe082;
              color:#fff;
            }
            button.info, .info_notoggle, .BC_message.info, #BC_toggle_info.active{
              background-color:#d9edf7;
              color:#31708f;
              border-color:#bce8f1;
              font-weight:bold
            }
            button.info:hover, .info_notoggle:hover, #BC_toggle_info.active:hover{
              background-color:#d9edf7;
              color:#fff;
            }
            .BC_no-messages{
              color:#33691e 
              }
          </style>
          <style type="text/css" id="project-specific-css">
            <xsl:call-template name="project-specific-css"/>
          </style>
          <script type="text/javascript" id="project-specific-js">
            <xsl:call-template name="project-specific-js"/>  
          </script>
        </xslout:copy>
      </xslout:template>


      <!--  *
            * custom title
            * -->

      <xslout:template match="html:*[@id eq 'tr-headline']">
        <xslout:copy copy-namespaces="no">
          <xslout:apply-templates select="@*"/>
          <a href="#" id="BC_title"><xsl:value-of select="$report-title"/></a>
        </xslout:copy>
      </xslout:template>
      
      <xslout:template match="html:title">
        <xsl:value-of select="$report-title"/>
      </xslout:template>
      
      <!--  *
            * report menu
            * -->

      <xslout:template match="html:*[@id eq 'tr-report']">
        <xslout:copy copy-namespaces="no">
          <xslout:apply-templates select="@*"/>
          <div class="BC_summary">
            <xsl:if test="//*:text[parent::svrl:successful-report | parent::svrl:failed-assert][not(../@role)]">
              <xsl:message>INFO: There are messages without a role attribute. These are moved to severity
                  &quot;<xsl:value-of select="$severity-default-role"/>&quot;.</xsl:message>
            </xsl:if>

            <!--  *
                  * report: severity filter 
                  * -->

            <div class="BC_severity">
              <xsl:for-each-group
                select="  //*:text[parent::svrl:successful-report | parent::svrl:failed-assert]
                [not(tr:ignored-in-html(*:span[@class eq 'srcpath']))] 
                | //*:error"
                group-by="(@type, ../@role, $severity-default-role)[1]">
                
                <button type="button" class="btn btn-sm active BC_toggle" id="BC_toggle_{current-grouping-key()}" name="{current-grouping-key()}">
                  <xsl:value-of select="l10n:severity-role-label(current-grouping-key())"/>
                </button>
                
              </xsl:for-each-group>
            </div>

            <!--  *
                  * report: individual reports grouped by family 
                  * -->

            <xsl:for-each select="/c:reports/*[not(self::c:not-applicable)]">
              <xsl:variable name="family" as="xs:string" select="(@tr:rule-family, 'unknown')[1]"/>
              <!-- c:errors without attributes are only informational (an xsl:message terminate="no" will create such a c:error) -->
              <xsl:variable name="msgs" as="element(*)*"
                select=".//svrl:text[parent::svrl:successful-report | parent::svrl:failed-assert]
                [not(tr:ignored-in-html(*:span[@class eq 'srcpath']))] 
                | .//c:error[@*]"/>
              <div class="BC_family-label panel-heading">
                <xsl:value-of select="$family"/>
                <a class="pull-right btn btn-default btn-xs BC_family-label-collapse" role="button"
                  data-toggle="collapse" href="#fam_{$family}" aria-expanded="false" aria-controls="{$family}">–</a>
              </div>
              <div class="collapse in" id="fam_{$family}">
                <ul class="list-group BC_family-summary">
                  <xsl:choose>
                    <xsl:when test="exists($msgs)">
                      <xsl:variable name="svrl-text-without-srcpath" as="element(svrl:text)*"
                        select=".//svrl:text[parent::svrl:successful-report|parent::svrl:failed-assert][not(s:span[@class eq 'srcpath'] ne '')]"/>
                      <xsl:if test="exists($svrl-text-without-srcpath)">
                        <xsl:message select="concat('[WARNING] Schematron rule family: ''',
                          @tr:rule-family,
                          ''', rule(s): ',
                          string-join(distinct-values(for $a in *[local-name() = ('successful-report', 'failed-assert')][svrl:text[not(s:span[@class eq 'srcpath'] ne '')]] return concat('''', $a/@id, '''')), ', '),
                          '&#xa;No srcpath-span found. Using Schematron location @attribute as fallback.'
                          )"/>
                        <!--<xsl:message>WARNING: You forgot to add srcpath-span elements to your error messages or the
                          extraction went wrong. These Messages are not displayed correctly. <xsl:sequence
                            select="concat('Rule-family:', @tr:rule-family, ' ||| rule(s): ', string-join(distinct-values(for $a in *[local-name() = ('successful-report', 'failed-assert')][svrl:text[not(s:span[@class eq 'srcpath'] ne '')]] return $a/@id), ' :: '))"/>
                          <xsl:sequence select="$svrl-text-without-srcpath"/>
                        </xsl:message>-->
                      </xsl:if>
                      <xsl:for-each-group select="$msgs"
                        group-by="string-join((
                          if(self::svrl:text and not(../@id))
                          then concat(
                          'To the Schematron author: no &lt;span class=&quot;srcpath&quot;&gt; or id for this message in pattern: &quot;', ../preceding::svrl:active-pattern[1]/@id, 
                          '&quot;, context: &quot;', ../preceding::svrl:fired-rule[1]/@context, '&quot;'
                          )
                          else ../@id
                          | self::c:error/@code,
                          (../@role, $severity-default-role)[1]
                          ), '__')">
                        <xsl:variable name="msgid" select="(../@id, @code, '')[1]" as="xs:string"/>
                        <xsl:variable name="current-severity" select="(@type, ../@role, $severity-default-role)[1]"
                          as="xs:string"/>
                        <xsl:variable name="span-title" select="string-join(($family, $current-severity, $msgid), ' ')"
                          as="xs:string"/>
                        <xsl:variable name="href-id"
                          select="$messages-grouped-by-type/tr:document/tr:messages[@type eq $span-title]/tr:message[1]/@xml:id"
                          as="xs:string"/>
                        <li class="list-group-item BC_tooltip {$current-severity}">
                          <div class="checkbox">
                            <label class="checkbox-inline">
                              <input type="checkbox" checked="checked" class="BC_toggle {$current-severity}"
                                id="BC_toggle_{current-grouping-key()}" name="{current-grouping-key()}"/>
                            </label>
                            <a class="BC_link" href="#{$href-id}">
                              <xsl:value-of select="$msgid"/>
                              <span class="BC_whitespace">
                                <xslout:text>&#xa0;</xslout:text>
                              </span>
                              <span class="BC_error_count badge {$current-severity}">
                                <xsl:value-of
                                  select="count($messages-grouped-by-type/tr:document/tr:messages[@type eq $span-title]/*)"
                                />
                              </span>
                            </a>
                            <div class="pull-right">
                              <a class="BC_link" href="#{$href-id}">
                                <button type="button" class="btn btn-default btn-xs {$current-severity}">
                                  <xsl:number value="index-of($message-types, $span-title)" format="A"/>
                                  <span class="BC_arrow-down">&#x25be;</span>
                                </button>
                              </a>
                              <span title="{$span-title}" class="BC_marker {$span-title}"/>
                            </div>
                          </div>
                        </li>
                      </xsl:for-each-group>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:call-template name="l10n:message-empty"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </ul>
              </div>
            </xsl:for-each>

            <!--  *
                  * report: message panel
                  * -->

            <div xml:id="BC_msg_container" id="BC_msg_container" class="BC_top">
              <div xml:id="BC_msg" id="BC_msg"/>
            </div>
          </div>

        </xslout:copy>
      </xslout:template>

      <!--  *
            * generate mini-toc and patch headlines
            * -->
      
      <xslout:variable name="headlines" select="//html:*[@id eq 'tr-content']//html:*[local-name() = ('h1', 'h2')]"/>

      <xslout:template match="html:*[@id eq 'tr-content']//html:*[local-name() = ('h1', 'h2')]">
        <xslout:copy>
          <xslout:apply-templates select="@*|node()[not(self::*:img)]" mode="#current"/>
          <span>
            <xslout:attribute name="id" select="concat('scroll-', generate-id(.))"/>
          </span>
        </xslout:copy>
      </xslout:template>

      <xslout:template match="html:*[@id eq 'tr-minitoc']">
        <xslout:variable name="factor" select="5" as="xs:integer"/>
        <xslout:copy>
          <xslout:apply-templates select="@*|node()"/>
          <ul class="BC_minitoc nav">
            <li class="hidden active">
              <a class="page-scroll" href="#page-top"/>
            </li>
            <xslout:for-each select="$headlines">
              <xslout:variable name="color-value" select="tr:dec-to-hex(position() * $factor)"/>
              <xslout:variable name="fill-value" select="string-join(for $i in (string-length($color-value) to 1)  return '0', '')"/>
              
              <xslout:variable name="href" select="concat('#scroll-', generate-id(.))"/>
              <xslout:variable name="class" select="concat('BC_minitoc-item BC_minitoc-level-', local-name())"/>
              <li>
                <xslout:attribute name="style" select="concat('border-left: 2px solid #', $r-value, $fill-value, $color-value, $b-value)"/>
                <xslout:attribute name="class" select="$class"/>
                <a class="page-scroll">
                  <xslout:attribute name="href" select="$href"/>
                  <xslout:apply-templates mode="#current"/>
                </a>
              </li>
            </xslout:for-each>
          </ul>
        </xslout:copy>
      </xslout:template>



      <!--  *
            * process main content
            * -->

      <xslout:template match="html:*[@id eq 'tr-content']">
        <xslout:copy copy-namespaces="no">
          <xslout:apply-templates select="@*" mode="#current"/>
          <div xml:id="BC_content" id="BC_content">
            <xslout:apply-templates mode="#current"/>
          </div>
        </xslout:copy>
      </xslout:template>

      <xsl:apply-templates select="$linked-messages-grouped-by-srcpath/tr:document/tr:messages" mode="create-template"/>

    </xslout:stylesheet>
  </xsl:template>

  <xsl:template name="l10n:message-empty" xmlns="http://www.w3.org/1999/xhtml">
    <li class="BC_no-messages list-group-item">✓<span class="sr-only">Error:</span></li>
  </xsl:template>

  <xsl:function name="tr:ignored-in-html" as="xs:boolean">
    <xsl:param name="report-srcpath" as="xs:string?"/>
    <xsl:choose>
      <xsl:when test="$report-srcpath">
        <xsl:variable name="html-element" as="element(*)*"
          select="key('html-element-by-srcpath', $report-srcpath, $html-with-srcpaths)"/>
        <xsl:sequence
          select="some $a in $html-element/ancestor-or-self::* satisfies (tr:contains-token($a/@class, 'bc_ignore'))"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="false()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="tr:contains-token" as="xs:boolean">
    <xsl:param name="space-separated-list" as="xs:string?"/>
    <xsl:param name="token" as="xs:string?"/>
    <xsl:sequence select="$token = tokenize($space-separated-list, '\s+')"/>
  </xsl:function>

  <xsl:key name="html-element-by-srcpath" match="*[@srcpath]"
    use="string-join((/html:html/html:head/html:meta[@name eq 'source-dir-uri']/@content, @srcpath), '')"/>

  <xsl:template match="tr:messages" mode="create-template">
    <xsl:variable name="tokenized" as="xs:string" select="(tokenize(@srcpath,'\s+'), '')[1]"/>
    <xsl:if test="contains($tokenized, '?xpath=') and not(starts-with($tokenized, 'file:/'))">
      <xsl:message
        select="'svrl2xsl.xsl WARNING: srcpath in message typed ', 
  			string-join(for $dv in distinct-values(tr:message/@type) return concat('''', $dv, ''''), ', '), 
  			' should start with ''file:/''. Found: ', $tokenized"
      />
    </xsl:if>
    <!-- We ditched match="key('by-srcpath', …)" because of a possible Saxon bug, 
      http://saxon.markmail.org/message/freszzsbtuniw5o3 -->
    
    <xslout:template match="html:s-p[{string-join(for $i in $tokenized 
                                      return concat(
                                                    'matches(.,''^', 
                                                    replace(functx:escape-for-regex($i), '''', ''''''), 
                                                    '$'')'),
                                                    ' or ')}]" 
                     priority="{position()}">
      <xslout:variable name="same-key-elements" as="element(*)*" select="key('by-srcpath', .)"/>
      <xslout:if test=".. is ($same-key-elements)[1]">
        <xsl:apply-templates mode="#current"/>
      </xslout:if>
    </xslout:template>
  </xsl:template>

  <!-- this template is used to create the error marker
    which appears in the content section of the HTML report -->

  <xsl:template match="tr:message" mode="create-template" xmlns="http://www.w3.org/1999/xhtml">
    <xsl:variable name="type" select="@type" as="attribute(type)"/>
    <span class="BC_tooltip {string-join(($type, @severity), '__')}">
      <button class="btn btn-default btn-xs {string-join(($type, @severity), '__')}" type="button"
        data-toggle="collapse" data-target="#msg_{@xml:id}" aria-expanded="false" aria-controls="msg_{@xml:id}">
        <xsl:value-of select="@rendered-key"/>
        <xsl:value-of select="@occurrence"/>
      </button>
      <xsl:variable name="previous-message" select="preceding::tr:message[@type eq $type][1]" as="element(tr:message)?"/>
      
      <xsl:if test="exists($previous-message)">
        <a class="BC_link" href="#{$previous-message/@xml:id}">
          <button class="btn btn-default btn-xs BC_arrow-up {string-join(($previous-message/@type, $previous-message/@severity), '__')}">
            <span>&#x25b4;</span>
          </button>
        </a>
      </xsl:if>
      <xsl:if test="@href">
        <a class="BC_link" href="{@href}">
          <button class="btn btn-default btn-xs BC_arrow-down {string-join((@type, @severity), '__')}">
            <span>&#x25be;</span>
          </button>
        </a>
      </xsl:if>
      <span title="{@type}" class="BC_marker {@type}" id="{@xml:id}"/>
      <div class="collapse" id="msg_{@xml:id}">
        <div class="well BC_message {@severity}">
          <div class="BC_message-text">
            <xsl:apply-templates select="(svrl:diagnostic-reference[@xml:lang eq $interface-language], *:text)[1]"
              mode="#current"/>
          </div>
          <xsl:if test="$show-adjusted-srcpath eq 'yes' and @adjusted-from">
              <xsl:call-template name="l10n:adjusted-srcpath"/>
          </xsl:if>
          <!-- if the @tr:step-name attribute was declared, we provide step name information -->
          <xsl:if test="@tr:step-name">
            <xsl:call-template name="l10n:step-name"/>
          </xsl:if>
        </div>
      </div>

    </span>
    <xsl:text>&#x200b;</xsl:text>
    <!-- allow line breaks -->
  </xsl:template>


  <!--  *
        * named templates for customization: import this stylesheet and overwrite the templates.
        * -->

  <xsl:template name="l10n:step-name" xmlns="http://www.w3.org/1999/xhtml"> 
    <p class="BC_step-name">
      Conversion step: <xsl:value-of select="@tr:step-name"/>
    </p>
  </xsl:template>

  <xsl:template name="l10n:adjusted-srcpath" xmlns="http://www.w3.org/1999/xhtml">
    <p class="BC_srcpath_msg" title="srcpath {@adjusted-from} was removed">Note: This message originated from a location within the document
      that did not retain its location information during conversion. The message might now be attached to the
      surrounding paragraph or even to another paragraph nearby.</p>
  </xsl:template>

  <!-- Allow HTML markup in the XHTML namespace in messages: -->
  <xsl:template match="html:* | @*" mode="create-template render-message" xmlns="http://www.w3.org/1999/xhtml">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*:span[@class eq 'srcpath']" mode="create-template"/>

  <xsl:template match="svrl:ns-prefix-in-attribute-values">
    <xslout:namespace name="{@prefix}" select="@uri"/>
  </xsl:template>

  <xsl:template match="svrl:text[span[@class eq 'srcpath'] eq '']" mode="#default"/>

  <xsl:function name="l10n:severity-role-label" as="xs:string">
    <xsl:param name="role" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$interface-language eq 'en' and $role eq 'error'">
        <xsl:value-of select="'Error'"/>
      </xsl:when>
      <xsl:when test="$interface-language eq 'en' and $role eq 'warning'">
        <xsl:value-of select="'Warning'"/>
      </xsl:when>
      <xsl:when test="$interface-language eq 'en' and $role eq 'info'">
        <xsl:value-of select="'Info'"/>
      </xsl:when>
      <xsl:when test="$interface-language eq 'en' and $role eq 'fatal-error'">
        <xsl:value-of select="'Fatal Error'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$role"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

</xsl:stylesheet>
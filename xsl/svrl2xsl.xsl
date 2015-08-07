<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xslout="bogo"
  xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:s="http://purl.oclc.org/dsdl/schematron"
  xmlns:aid   = "http://ns.adobe.com/AdobeInDesign/4.0/"
  xmlns:aid5  = "http://ns.adobe.com/AdobeInDesign/5.0/"
  xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
  xmlns:idml2xml  = "http://transpect.io/idml2xml"
  xmlns:tr="http://transpect.io"  
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:l10n="http://transpect.io/l10n"
  version="2.0"
  >

  <xsl:output method="xml" indent="yes"  />

  <xsl:param name="remove-srcpath" select="'yes'"/>
  <xsl:param name="max-errors-per-rule" as="xs:string?"/>
  <xsl:param name="severity-default-name" select="'no-role'" as="xs:string"/>
<!--  <xsl:param name="jQuery-uri" select="'https://ajax.googleapis.com/ajax/libs/jquery/1.10.2/jquery.min.js'"/>
-->
  <xsl:param name="interface-language" select="'en'" as="xs:string"/>
  <xsl:param name="file"  as="xs:string?"/>
  
  <xsl:param name="report-title" select="'Report'" as="xs:string"/>
  
  <xsl:variable name="html-with-srcpaths" select="collection()[2]" as="document-node(element(html:html))"/>
  
  <xsl:variable name="severity-default-role" as="attribute(role)">
    <xsl:attribute name="role" select="$severity-default-name"/>
  </xsl:variable>
  <xsl:variable name="maxerr" as="xs:integer" select="if ($max-errors-per-rule castable as xs:integer) 
                                                      then xs:integer($max-errors-per-rule)
                                                      else 0"/>


  <xsl:variable name="doge" as="element(html:img)" select="collection()/html:img[@id = 'doge']"/>
  <xsl:variable name="jquery" as="element(html:script)" select="collection()/html:script[@id = 'jquery']"/>
  <xsl:variable name="keypress" as="element(html:script)" select="collection()/html:script[@id = 'keypress']"/>
  <xsl:variable name="mathjax" as="element(html:script)" select="collection()/html:script[@id = 'mathjax']"/>
  
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
  
  <xsl:variable name="srcpath-matching-templates" as="element(tr:message)*">
    <xsl:apply-templates select="//c:error[@*]" mode="collect-messages"/>
    <xsl:apply-templates select="//svrl:text[s:span[@class eq 'srcpath'] ne '']
                                            [parent::svrl:successful-report | parent::svrl:failed-assert]" 
                         mode="collect-messages"/>
  </xsl:variable>

  <xsl:template match="c:error[@*]" mode="collect-messages">
    <tr:message srcpath="BC_orphans" xml:id="BC_{generate-id()}" severity="{@type}" 
      type="{parent::c:errors/@tr:rule-family} {@type} {@code}">
      <tr:text>
        <xsl:copy-of select="node()"/>  
      </tr:text>
    </tr:message>
  </xsl:template>
  
  <xsl:template match="svrl:text[tr:ignored-in-html(*:span[@class eq 'srcpath'])]" mode="collect-messages"/>  
    
  <xsl:template match="svrl:text[parent::svrl:successful-report | parent::svrl:failed-assert]
                                [not(tr:ignored-in-html(*:span[@class eq 'srcpath']))]" mode="collect-messages">
    <xsl:variable name="role" as="xs:string"
      select="(../@role, $severity-default-role)[1]"/>
    <tr:message srcpath="{s:span[@class eq 'srcpath']}" xml:id="BC_{generate-id()}" 
      severity="{$role}"
      type="{ancestor-or-self::svrl:schematron-output/@tr:rule-family} {$role} {../@id}">
      <xsl:copy-of select="., ../svrl:diagnostic-reference"/>
    </tr:message>
  </xsl:template>
  
  <xsl:variable name="messages-grouped-by-type" as="document-node(element(tr:document))">
    <xsl:document>
      <tr:document>
        <xsl:for-each-group select="$srcpath-matching-templates" group-by="@type">
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
                                                                               else true()]" group-by="tokenize(@srcpath, '\s+')">
          <tr:messages srcpath="{current-grouping-key()}">
            <xsl:apply-templates select="current-group()" mode="link"/>
          </tr:messages>
        </xsl:for-each-group>
      </tr:document>
    </xsl:document>
  </xsl:variable>
    
  <xsl:template match="tr:message" mode="link">
    <xsl:variable name="pos" select="index-of(../*/@xml:id, @xml:id)"/>
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:if test="$pos lt $maxerr and exists(following-sibling::tr:message)">
        <xsl:attribute name="href" select="concat('#', following-sibling::tr:message[1]/@xml:id)"/>
      </xsl:if>
      <xsl:attribute name="rendered-key">
        <xsl:number value="index-of($message-types, @type)" format="A"/>
      </xsl:attribute>
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
        <span class="BC_srcpath"><xsl:value-of select="."/></span>
      </p>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="l10n:fallback-for-removed-content" xmlns="http://www.w3.org/1999/xhtml">
    <span>The content that this message pertains to has not been included in the HTML rendering, 
    	or it does not provide information about its origin. This may be due to a flaw in the conversion pipeline. 
    	Sorry for that. Here’s the so-called <em>srcpath</em> for diagnostic
      purposes: </span>
  </xsl:template>

  <xsl:template match="/" mode="#default">
    <xsl:result-document href="messages-grouped-by-type.xml">
      <xsl:sequence select="$messages-grouped-by-type"/>
    </xsl:result-document>
    <xsl:result-document href="linked-messages-grouped-by-srcpath.xml">
      <xsl:sequence select="$linked-messages-grouped-by-srcpath"/>
    </xsl:result-document>
    <xslout:stylesheet
      version="2.0"
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
      xmlns:xs="http://www.w3.org/2001/XMLSchema" 
      xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
      xmlns:css="http://www.w3.org/1996/css"
      xmlns:s="http://purl.oclc.org/dsdl/schematron"
      xmlns:html="http://www.w3.org/1999/xhtml"
      xmlns:tr="http://transpect.io"  
      exclude-result-prefixes="svrl s xs html transpect css aid aid5 idPkg idml2xml c bc l10n"
      xmlns="http://www.w3.org/1999/xhtml"
      >
  
      <xslout:output method="xhtml" cdata-section-elements="script"/>
      
      <xslout:variable name="src-dir-uri" select="/html:html/html:head/html:meta[@name eq 'source-dir-uri']/@content" as="xs:string?"/>
      <!--<xslout:key name="by-srcpath" match="*[@srcpath]" 
        use="for $s in
               if ($src-dir-uri) 
               then 
                 if (@srcpath = 'BC_orphans') 
                 then 'BC_orphans'
                 else 
                   if (@srcpath = '')
                   then $src-dir-uri
                   else for $s in tokenize(@srcpath, '\s+') 
                        return string-join(($src-dir-uri[not(starts-with($s, 'file:'))], $s), '') 
               else tokenize(@srcpath, '\s+')
             return ($s, replace($s, ';n=\d+$', ''))"/>-->
      
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
        <xslout:copy>
          <xslout:apply-templates select="@*" mode="#current"/>
          <xslout:for-each select="distinct-values($expanded)">
            <s-p>
              <xslout:sequence select="."/>
            </s-p>
          </xslout:for-each>
          <xslout:apply-templates mode="#current"/>
        </xslout:copy>
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
          <div class="BC_fallback" xmlns="http://www.w3.org/1999/xhtml">
            <xsl:apply-templates select="$linked-messages-grouped-by-srcpath/tr:document/tr:messages"
              mode="create-fallback"/>
          </div>
        </xslout:copy>
      </xslout:template>
      
      <xslout:template mode="remove-fallback"
        match="html:div[@class = 'BC_fallback']/html:p[not(descendant::html:span[contains(@class, 'BC_marker')])]"/>

      <!-- main processing in default mode: -->
      <xslout:template match="/*">
        <xslout:copy copy-namespaces="no">
          <xsl:apply-templates select="svrl:ns-prefix-in-attribute-values" mode="#default"/>
          <xslout:apply-templates select="@* | node()" mode="#current" />
        </xslout:copy>
      </xslout:template>

      <xslout:template match="@xml:base"/>

      <xsl:if test="$remove-srcpath = 'yes'">
        <xslout:template match="@srcpath"/>
      </xsl:if>
      
      <xslout:template match="html:s-p"/>

      <xslout:template match="html:head">
        <xslout:copy copy-namespaces="no">
          <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
          <meta http-equiv="cache-control" content="no-cache" />
          <meta http-equiv="pragma" content="no-cache" />
          <xslout:copy-of select="@*, node()" copy-namespaces="no"/>
          <style type="text/css">
            /* 
             *  General Layout 
             */
            body{background-color:#333; margin:0}
            /* 
             *  General Layout 
             */
            #BC_header{padding: 0.5% 3% 0.5% 3%; background-color:#231f20; color:#fff; }
            #BC_logo{top: 1%; left:3%; position:absolute;  height:40px; width:200px}
            #BC_mainwrapper{margin:2% 3% 2% 3%;}
            /* 
             *  Content Layout
             */
            #BC_orphans { margin-bottom: 1em; background-color: #EFEFEF;
             background: repeating-linear-gradient(135deg, #DDDDDD, #DDDDDD 10px, #EEEEEE 10px, #EEEEEE 20px) repeat scroll 0 0 rgba(0, 0, 0, 0);
             border-radius: 0.4em; min-height: 3em; margin-bottom: 1em;  padding: 0.25em 1em; vertical-align: middle; box-shadow:0.2em 0.2em 0.15em #999; overflow-y:auto; overflow-x:hidden;}
            #BC_orphans span.tooltip { float:left; margin-bottom:0.2em; }
            #BC_reportmenu, #BC_reportswitch { position:fixed; left:65%; display:block; float:right; width:35%; 
            z-index:101; font-family:Calibri, Helvetica, sans-serif;}
            #BC_reportswitch {display:none; color: #eee; margin-top: -1.5%; text-align: right;}
            #BC_reportswitch-btn {cursor:pointer; margin-right:2%; font-size:0.8em; font-family:Calibri, Helvetica, sans-serif; background-color:#333; font-weight:bold; border-radius:0.4em; padding:1%}
            #BC_content{ float:left; width:60%; background-color:#fff; padding:1% 2% 1% 2%; margin:0 0 1% 0;  } 
            #BC_content, #BC_nav, #BC_msg_container{border-radius:0.4em; box-shadow:0.2em 0.2em 0.15em #000;}
            .BC_content_wide {width:95% !important}
            #BC_nav, #BC_msg_container{background-color:#efefef; margin:0 0 7% 0; padding:1% 2% 1% 2%; max-height:20em;
            overflow-y:scroll; overflow-x:hidden; font-family:Calibri, Helvetica, sans-serif;}
            #BC_msg_container a { color: #aaf; }
            #BC_nav ul { padding: 0; margin: 0.4em 0}
            #BC_nav p.BC_family-label { margin: 0.5em 0.2em 0.2em 0 }
            #BC_reportmenu h3{font-size:0.8em; font-weight:bold; margin: 0.8em 0; text-transform:uppercase; font-family:Cambria, serif; }
            #clear-float{clear:both}
            /* 
             *  Page Title
             */
             #BC_title{font-size:0.9em; text-align:right; font-family: Calibri, Helvetica, sans-serif; }
            /* 
             *  Logo
             */
            #BC_logo{background-image:url('logo.png'); background-repeat:no-repeat;}
            
            .wow { font-family: "Comic Sans", "Comic Sans MS", cursive; font-size: larger; color: fuchsia }
            .doge { display:none; font-family: "Comic Sans", "Comic Sans MS", cursive; z-index: 1337; }
            #BC_logo img {position: fixed; z-index: 22222 }
            #doge1 { position: fixed; top: 0%; left:25%; color: #0f0; font-size:640%; text-shadow: 5px 4px 0 #eee,7px 6px 0 #707070;}
            #doge2 { position: fixed; top: 10%; left:50%; color: magenta; font-size:540%; font-weight:bold; text-shadow: 0 0 10px #fff, 0 0 20px #fff, 0 0 30px #fff, 0 0 40px #ff00de, 0 0 70px #ff00de, 0 0 80px #ff00de, 0 0 100px #ff00de, 0 0 150px #ff00de;}
            #doge3 { position: fixed; bottom: 5%; left:45%; color: yellow; font-size:480%; font-weight:bold; text-shadow: 3pt 2pt goldenrod; letter-spacing:.5em; }
            #doge4 { position: fixed; top: 40%; left:20%; color: cyan; font-size:420%; color: rgba(0,168,255,0.5); text-shadow:
            3px 2px 0 rgba(255,0,180,0.5); }
            #doge5 { position: fixed; bottom: 10%; left:12%; color: red; font-size:720%; font-weight:bold ; text-shadow: 3pt 2pt yellow; -moz-transform: rotate(30deg); -ms-transform: rotate(30deg); -o-transform: rotate(30deg); -webkit-transform: rotate(30deg); }
            #doge6 { position: fixed; bottom: 20%; right:5%; color: #a54a2a; font-size:540%; text-shadow: 3pt 2pt #cb4 }
            /* start report bar*/
            .BC_family{text-transform:uppercase}
            .BC_family, .BC_severity, #BC_msg{font-size:0.8em}
            .BC_severity li, .BC_warning, li.no-messages{text-indent:1em; text-transform:none}
            li.no-messages{ color:#5aba16; font-weight:bold; }
            span.tooltip_description span.label { font-weight:bold; font-size:114%; display:inline-block; padding:0.25em; margin:0em 0em 0.5em 0em;}
            
            /* fallback for removed content */
            div.BC_fallback { margin-top: 1em; background-color: #EFEFEF;
             background: repeating-linear-gradient(135deg, #DDDDDD, #DDDDDD 10px, #EEEEEE 10px, #EEEEEE 20px) repeat scroll 0 0 rgba(0, 0, 0, 0);
             border-radius: 0.4em; min-height: 3em; margin-bottom: 1em;  padding: 0.25em 1em; vertical-align: middle; box-shadow:0.2em 0.2em 0.15em #999; overflow-y:auto; overflow-x:hidden;}
            div.BC_fallback span.BC_srcpath { font-size:small; font-family: monospace; }
            
            /* warning messages */
            .tooltip{background-color:#eed; }
            .tooltip_description{display:none}
            .error_notoggle{ color:#df0101; font-weight:bold}
            .error{background-color:#ff4400; }
            
            input.BC_toggle{ padding-right:0.2em; width:15px;height:15px; vertical-align:middle;}
            .fatal-error, .fatal-error_notoggle, .fatal-error_notoggle ul { background-color:#c23; color:#fff; font-weight:bold; text-indent:0em;}
            .warning, .warning_notoggle{ background-color:#ff6; text-indent:0em;}
            .Info, .Info_notoggle, .info, .info_notoggle{ background-color:#79D0DB; text-indent:0em; }
            .BC_top ul li{list-style-type:none; margin-top:0.3em;}
            .BC_top li p{margin-top:0;margin-bottom:0}
            .tooltip_description.fatal-error_notoggle, .tooltip_description.warning_notoggle, .tooltip_description.error_notoggle, .tooltip_description.Info_notoggle, .tooltip_description.info_notoggle{ text-indent:0em; display:none; }
            .BC_link{ font-size:small; background-color:#f7f7f7; text-decoration:none; opacity:0.8 }
            .BC_link:hover{ background-color:#ddd; }
            span.tooltip{ font-family:Calibri, Helvetica, sans-serif; font-size:10pt; font-weight:normal; padding:0 0.4em; width:2.5em; margin-right:0.5em;}
            ul.BC_severity li{ list-style-type:none; display:inline-block; margin-right:2em; }
            
            p.BC_family-label a:before {
              content: "−";
              color: #eee;
              background-color: #666;
              padding: 0 0.2em;
              margin-right: 0.2em;
            }
            p.BC_family-label a.fold:before {
              content: "+";
            }

            /* misc. good default values */
            img {max-width:100%}
            
            /* end report bar*/
            <xsl:call-template name="project-specific-css"/>
          </style>

          <xsl:sequence select="$keypress"/>
          <xslout:text>&#xa;</xslout:text>
          <xsl:sequence select="$mathjax"/>
          <xslout:text>&#xa;</xslout:text>
          <xsl:sequence select="$jquery"/>
          
          <script type="text/javascript">
            <xsl:call-template name="project-specific-js"/>
            $(document).ready(function() {
        
               $("span.BC_marker").click(function () {
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
                  
              <!-- toggle messages of types fatal error, error, warning, $severity-default-name and other -->
              $("ul.BC_severity li input").change(function () {
                severityname = $(this).attr("name");
                if ($(this).is(':checked')){
                  $("input." + severityname).prop('checked', true);
                } else { 
                  $("input." + severityname).prop('checked', false);
                }
              });

              $(".BC_toggle").change(function () {
                if($(this).is(':checked')){
                  $("span.tooltip." + this.id.replace(/BC_toggle_/, "")).show();
                  $(this).next().show();
                }
                else {
                 $("span.tooltip." + this.id.replace(/BC_toggle_/, "")).hide();
                 $(this).next().hide();
                }
               
              });  
            
              $("#BC_reportswitch").show();
              $("#BC_reportswitch").click(function(){
                $("#BC_reportmenu").toggle();
                $("#BC_content").toggleClass("BC_content_wide");
              });
              
              $('li.BC_family p').click(function () {
                $(this).siblings('ul').slideToggle();
                $(this).find('a').toggleClass('fold');
              });
              
              keypress.sequence_combo("w o w", function() {
                $(".doge").toggle();
              }, false);
            });
          </script>
        </xslout:copy>
      </xslout:template>
            
      <xslout:template match="html:body">
        <xslout:copy copy-namespaces="no">
          <xslout:copy-of select="@*"/>
          <div id="BC_header" xmlns="http://www.w3.org/1999/xhtml">
            <p id="BC_title">
              <xsl:value-of select="$report-title"/>
            </p>
          </div>

          <div id="doge1" class="doge">very check</div>
          <div id="doge2" class="doge">so demo</div>
          <div id="doge3" class="doge">amaze</div>
          <div id="doge4" class="doge">such open sauce</div>
          <div id="doge5" class="doge">wow</div>
          <div id="doge6" class="doge">much 
            <xsl:value-of select="if ($file) then replace($file, '^.+\.', '') else 'data'"/>
          </div>

          <div id="BC_logo" xmlns="http://www.w3.org/1999/xhtml">
            <xsl:sequence select="$doge"/>
          </div>
          <div id="BC_mainwrapper" xmlns="http://www.w3.org/1999/xhtml">
            <div id="BC_reportswitch">
              <xsl:call-template name="l10n:report-toggle-label"/>
            </div>
            <div id="BC_reportmenu">
              <div id="BC_nav" class="BC_top">
                <xsl:call-template name="l10n:severity-heading"/>
                <xsl:if test="//*:text[parent::svrl:successful-report | parent::svrl:failed-assert][not(../@role)]">
                  <xsl:message>INFO: There are messages without a role attribute. These are moved to severity
                      &quot;<xsl:value-of select="$severity-default-role"/>&quot;.</xsl:message>
                </xsl:if>
                <ul class="BC_severity">
                  <xsl:for-each-group select="  //*:text[parent::svrl:successful-report | parent::svrl:failed-assert]
                                                        [not(tr:ignored-in-html(*:span[@class eq 'srcpath']))] 
                                              | //*:error" group-by="(@type, ../@role, $severity-default-role)[1]">
                    <li>
                      <input type="checkbox" checked="checked" class="BC_toggle" id="BC_toggle_{current-grouping-key()}"
                        name="{current-grouping-key()}"/>
                      <xsl:text>&#x2002;</xsl:text>
                      <xsl:value-of select="l10n:severity-role-label(current-grouping-key())"/>
                    </li>
                  </xsl:for-each-group>
                </ul>

                <xsl:call-template name="l10n:rules-heading">
                  <xsl:with-param name="display-note" as="xs:boolean"
                    select="$maxerr gt 0
                    and (
                    some $count in (
                    for $m in $messages-grouped-by-type/tr:document/tr:messages 
                    return count($m/tr:message)
                    )
                    satisfies ($count gt $maxerr)
                    )"/>
                  <xsl:with-param name="max-errors" as="xs:string" select="$max-errors-per-rule"/>
                </xsl:call-template>
                
                <ul class="BC_summary">
                  <xsl:for-each select="/c:reports/*[not(self::c:not-applicable)]">
                    <xsl:variable name="family" as="xs:string" select="(@tr:rule-family, 'unknown')[1]"/>
                    <li class="BC_family">
                      <p class="BC_family-label" title="toggle">
                        <a>
                          <xsl:value-of select="$family"/>
                        </a>
                      </p>
                      <ul class="BC_family-summary">
                        <!-- c:errors without attributes are only informational (an xsl:message terminate="no" will create such a c:error) -->
                        <xsl:variable name="msgs" as="element(*)*" select=".//svrl:text[parent::svrl:successful-report | parent::svrl:failed-assert]
                                                                                       [not(tr:ignored-in-html(*:span[@class eq 'srcpath']))] 
                                                                           | .//c:error[@*]"/>
                        <xsl:choose>
                          <xsl:when test="exists($msgs)">
                            <xsl:variable name="svrl-text-without-srcpath" as="element(svrl:text)*" 
                              select=".//svrl:text[parent::svrl:successful-report | parent::svrl:failed-assert][not(s:span[@class eq 'srcpath'] ne '')]"/>
                            <xsl:if test="exists($svrl-text-without-srcpath)">
                              <xsl:message>WARNING: You forgot to add srcpath-span elements to your error messages or the extraction went wrong. These Messages are not displayed correctly. 
                                <xsl:sequence select="concat('Rule-family:', @tr:rule-family, ' ||| rule(s): ', string-join(distinct-values(for $a in *[local-name() = ('successful-report', 'failed-assert')][svrl:text[not(s:span[@class eq 'srcpath'] ne '')]] return $a/@id), ' :: '))"/>
                                <xsl:sequence select="$svrl-text-without-srcpath"/>
                              </xsl:message>
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
                                                            ../@role
                                                           ), '__')">
                              <xsl:variable name="msgid" as="xs:string" select="(../@id, @code, '')[1]"/>
                              <li class="BC_warning">
                                <input type="checkbox" checked="checked"
                                  class="BC_toggle {(@type, ../@role, $severity-default-role)[1]}"
                                  id="BC_toggle_{current-grouping-key()}"
                                  name="{current-grouping-key()}"/>
                                <xsl:value-of select="$msgid"/>
                                <xsl:text>&#x2002;</xsl:text>
                                <xsl:variable name="span-title"
                                  select="string-join(($family, (@type, ../@role, $severity-default-role)[1], $msgid), ' ')"
                                  as="xs:string"/>
                                <span class="tooltip {(@type, ../@role, $severity-default-role)[1]}">
                                  <a class="BC_link"
                                    href="#{$messages-grouped-by-type/tr:document/tr:messages[@type eq $span-title]/tr:message[1]/@xml:id}">
                                    <xsl:number value="index-of($message-types, $span-title)" format="A"/>
                                    <xsl:text>&#x2193;</xsl:text>
                                  </a>
                                  <span title="{$span-title}" class="BC_marker {$span-title}">

                                    <xsl:text>&#x2002;</xsl:text>
                                  </span>
                                </span>

                                <xsl:text>&#x2002;(</xsl:text>
                                <xsl:value-of
                                  select="count($messages-grouped-by-type/tr:document/tr:messages[@type eq $span-title]/*)"/>
                                <xsl:text>)</xsl:text>

                              </li>
                            </xsl:for-each-group>
                          </xsl:when>
                          <xsl:otherwise>
                            <xsl:call-template name="l10n:message-empty"/>
                          </xsl:otherwise>
                        </xsl:choose>
                      </ul>
                    </li>
                  </xsl:for-each>
                </ul>
              </div>
              <div xml:id="BC_msg_container" id="BC_msg_container" class="BC_top">
                <xsl:call-template name="l10n:message-heading"/>
                <div xml:id="BC_msg" id="BC_msg"/>
              </div>
            </div>
            <!-- process main content -->

            <div xml:id="BC_content" id="BC_content">
              <xslout:apply-templates mode="#current"/>
            </div>
            <!-- clear float div -->
            <div id="clear-float"/>
          </div>

        </xslout:copy>
      </xslout:template>

      <xsl:apply-templates select="$linked-messages-grouped-by-srcpath/tr:document/tr:messages" mode="create-template"/>
    </xslout:stylesheet>
  </xsl:template>

  <xsl:template name="l10n:rules-heading" xmlns="http://www.w3.org/1999/xhtml">
    <xsl:param name="display-note" as="xs:boolean"/>
    <xsl:param name="max-errors" as="xs:string"/>
    <h3>Rules</h3>
    <xsl:if test="$display-note">
      <p style="font-size:0.8em; margin: 0 0 0.8em 0">Please note that no more than <xsl:value-of
        select="$max-errors-per-rule"/> messages will be displayed for each rule.</p>
    </xsl:if>
  </xsl:template>
  
  <xsl:template name="l10n:message-heading" xmlns="http://www.w3.org/1999/xhtml">
    <h3>Message</h3>
  </xsl:template>

  <xsl:template name="l10n:severity-heading" xmlns="http://www.w3.org/1999/xhtml">
    <h3>Severity</h3>
  </xsl:template>

  <xsl:template name="l10n:message-empty" xmlns="http://www.w3.org/1999/xhtml">
    <li class="no-messages">OK</li>
  </xsl:template>

  <xsl:template name="l10n:report-toggle-label" xmlns="http://www.w3.org/1999/xhtml">
    <span id="BC_reportswitch-btn">hide&#x2009;/&#x2009;show report</span>
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
  		<xsl:message select="'svrl2xsl.xsl WARNING: srcpath in message typed ', 
  			string-join(for $dv in distinct-values(tr:message/@type) return concat('''', $dv, ''''), ', '), 
  			' should start with ''file:/''. Found: ', $tokenized"/>
  	</xsl:if>
    <!-- We ditched match="key('by-srcpath', …)" because of a possible Saxon bug, 
      http://saxon.markmail.org/message/freszzsbtuniw5o3 -->
  	<xslout:template match="*[html:s-p = '{$tokenized}']" priority="{position()}">
    	<xslout:variable name="same-key-elements" as="element(*)*" 
        select="key('by-srcpath', '{$tokenized}')"/>
      <xslout:choose>
        <xslout:when test=". is ($same-key-elements)[1]">
          <xslout:choose>
            <!-- render message in front of an anchor or a linebreak, otherwise link wont work / message wont show -->
            <xslout:when test="self::*:a or self::*:br or self::*:span or self::*:img">
              <xsl:apply-templates mode="#current"/>
              <xslout:copy copy-namespaces="no">
                <xslout:apply-templates select="@*" mode="#current"/>
                <xslout:apply-templates mode="#current"/>
              </xslout:copy>    
            </xslout:when>
            <xslout:otherwise>
              <xslout:copy copy-namespaces="no">
                <xslout:apply-templates select="@*" mode="#current"/>
                <xsl:apply-templates mode="#current"/>
                <xslout:apply-templates mode="#current"/>
              </xslout:copy>
            </xslout:otherwise>
          </xslout:choose>
        </xslout:when>
        <xslout:otherwise>
          <xslout:next-match/>
        </xslout:otherwise>
      </xslout:choose>
    </xslout:template>
  </xsl:template>
  
  <xsl:template match="tr:message" mode="create-template" xmlns="http://www.w3.org/1999/xhtml">
    <span class="tooltip {string-join((@type, @severity), '__')}">
      <xsl:choose>
        <xsl:when test="@href">
          <xsl:apply-templates select="@href" mode="#current"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@rendered-key"/>
        </xsl:otherwise>
      </xsl:choose>
     
     <xsl:variable name="srcpathindex" as="xs:integer" select="(index-of(tokenize(@srcpath, '\s+'), ../@srcpath))[1]"/>
     
      <span title="{@type}"
        class="BC_marker {@type}"
        id="{@xml:id}{if ($srcpathindex &gt; 1) then concat('_srcpathindex', $srcpathindex) else ''}">
        <xsl:value-of select="@occurrence"/> 
      </span>
      <span class="tooltip_description {@severity}_notoggle" title="{@type}">
        <span class="label {@severity}">
          <xsl:value-of select="@rendered-key"/>
          <xsl:value-of select="@occurrence"/>
        </span>
        <br/>
        <xsl:apply-templates select="(svrl:diagnostic-reference[@xml:lang eq $interface-language], *:text)[1]" mode="#current"/>
      </span>
    </span>
  </xsl:template>
  
  <!-- unwrap rich text messages that are wrapped in a p -->
  <xsl:template match="*:text/html:p" mode="create-template">
    <xsl:apply-templates mode="render-message"/>
  </xsl:template>
  
  <!-- Allow HTML markup in the XHTML namespace in messages: --> 
  <xsl:template match="html:* | @*" mode="create-template render-message" xmlns="http://www.w3.org/1999/xhtml">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="tr:message/@href" mode="create-template" xmlns="http://www.w3.org/1999/xhtml">
    <a class="BC_link">
      <xsl:copy-of select="."/>
      <xsl:value-of select="../@rendered-key"/>
      <xsl:text>&#x2193;</xsl:text>
    </a>
  </xsl:template>
  
  <xsl:template match="*:span[@class eq 'srcpath']" mode="create-template"/>
  
  <xsl:template match="svrl:ns-prefix-in-attribute-values">
    <xslout:namespace name="{@prefix}" select="@uri" />    
  </xsl:template>

  <xsl:template match="svrl:text[span[@class eq 'srcpath'] eq '']" mode="#default" />

  <xsl:function name="l10n:severity-role-label" as="xs:string">
    <xsl:param name="role" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$interface-language eq 'en' and $role eq 'error'">
        <xsl:value-of select="'Error'"/>
      </xsl:when>
      <xsl:when test="$interface-language eq 'en' and $role eq 'warning'">
        <xsl:value-of select="'Warning'"/>
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
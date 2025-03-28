<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
  xmlns:tr="http://transpect.io" 
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:s="http://purl.oclc.org/dsdl/schematron"
  xmlns:sc="http://transpect.io/schematron-config"
  xmlns="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="#all"
  version="2.0">

  <xsl:param name="interface-language" select="'en'" as="xs:string"/>
  <xsl:param name="title" select="'Checking Rules'" as="xs:string"/>

  <xsl:template name="main">
    <html>
      <head>
        <title>
          <xsl:value-of select="$title"/>
        </title>
        <meta charset="utf-8"/>
        <xsl:call-template name="list-checking-rules-css"/>
      </head>
      <body>
        <h1>
          <xsl:value-of select="$title"/>
        </h1>
        <h4>
          <xsl:value-of select="format-dateTime(current-dateTime(), '[Y]-[M01]-[D01] [H01]:[m01]')"/>
        </h4>
        
        <!-- list all schematron rules -->
        <xsl:call-template name="output-all-schematron-messages"/>
        
        <!-- brief overview -->
        <xsl:call-template name="output-brief-overview"/>

      </body>
    </html>
  </xsl:template>

  <xsl:template name="output-brief-overview">
    <!--<h2>
      <xsl:choose>
        <xsl:when test="matches($interface-language, '^de(-\p{Lu}+)?$')">
          <xsl:text>Übersicht</xsl:text>    
        </xsl:when>
        <xsl:when test="matches($interface-language, '^fr(-\p{Lu}+)?$')">
          <xsl:text>Synopsis</xsl:text>    
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>Overview</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </h2>-->
    <xsl:apply-templates select="collection()//tr:document" mode="tr:brief-report"/>
    <xsl:if test="some $msgs in collection()//tr:document//tr:messages satisfies (count($msgs/tr:message) gt 1)">
      <p class="note">
        <xsl:choose>
          <xsl:when test="$interface-language = 'de'">Ist oben ein <i>[+ X]</i> angegeben, können Sie die weiteren 
          Meldungen des jeweiligen Typs im ausführlichen HTML-Report sehen.</xsl:when>
          <xsl:when test="$interface-language = 'en'">If you see <i>[+ X]</i> in the list above, please look at the
          HTML rendering of the complete document that contains all error messages.</xsl:when>
          <xsl:when test="$interface-language = 'fr'">En cas <i>[+ X]</i> est donnée dans la liste ci-dessus, veuillez 
            consulter la présentation du document en HTML complette.</xsl:when>
        </xsl:choose>
      </p>
    </xsl:if>
  </xsl:template>

  <xsl:template name="output-all-schematron-messages">
    <!-- old list-checking-rules:
    <xsl:apply-templates select="collection()/s:schema" mode="tr:list-checking-rules"/>-->
    <xsl:param name="all-schemas" as="element(s:schema)*" select="collection()//s:schema"/>
    <xsl:param name="exists-family" select="exists($all-schemas/@tr:rule-family)" as="xs:boolean"/>
    <xsl:variable name="all-rules" as="element(*)*" select="$all-schemas//(s:report union s:assert)"/>
    <xsl:if test="exists($all-rules)">
      <div class="total">
        <span class="label">Total: </span>
        <span class="value">
          <xsl:value-of select="count($all-schemas//(s:report union s:assert))"/>
        </span>
      </div>
    </xsl:if>
    <xsl:for-each-group select="$all-schemas//(s:report union s:assert)" group-by="(@role, 'error')[1]">
      <xsl:sort select="tr:severity-sortkey(.)"/>
      <div class="role-group {(@role, 'error')[1]}">
        <div class="heading">
          <div class="role-name"><xsl:value-of select="tr:get-l10n-severity(current-grouping-key())"/></div>
          <div class="message-count"><xsl:value-of select="count(current-group())"/></div>
        </div>
        <div class="collapse">
            <a class="label plus" 
               onclick="this.blur();
                        switches = this.parentNode.parentNode.getElementsByClassName('switch-info');
                        for (i = 0; i &lt; switches.length; i++)
                        {{
                          if(this.classList.contains('expanded')){{
                            switches[i].classList.add('active-message-info');
                            switches[i].classList.remove('active-message-info')
                          }}else{{
                            switches[i].classList.remove('active-message-info');
                            switches[i].classList.add('active-message-info')}}
                        }};
                        this.classList.toggle('expanded'); return false">&#9660;</a>
            </div>
        <ul>
          <xsl:for-each-group 
            select="$all-schemas//(s:report union s:assert)[(@role, 'error')[1] = current-grouping-key()]" 
            group-by="normalize-space(string-join(.//text(), ''))">
            <!-- no xsl:sort - input order is output order -->
            <li>
              <a href="#" class="switch-info" onclick="this.blur(); this.classList.toggle('active-message-info'); return false">
                <div class="message-group {name(.)}">
                  <div class="message-text"><xsl:sequence select="tr:output-message(.)"/></div>
                  <div class="message-info">
                    <div class="message-id">
                      <xsl:choose>
                        <xsl:when test="@id">
                          <span class="label">id: </span>
                          <span class="value"><xsl:value-of select="@id"/></span>
                        </xsl:when>
                        <xsl:when test="parent::s:rule/@id">
                          <span class="label">(rule id: </span>
                          <span class="value"><xsl:value-of select="../@id"/>)</span>
                        </xsl:when>
                        <xsl:when test="../parent::s:pattern/@id">
                          <span class="label">(pattern id: </span>
                          <span class="value"><xsl:value-of select="../../@id"/>)</span>
                        </xsl:when>
                        <xsl:otherwise>
                          <span class="label">(without id)</span>
                        </xsl:otherwise>
                      </xsl:choose>
                    </div>
                    <xsl:if test="$exists-family">
                      <div class="message-family">
                        <span class="label">family: </span>
                        <span class="value"><xsl:value-of select="ancestor::s:schema/@tr:rule-family"/></span>
                      </div>  
                    </xsl:if>
                    <div class="message-context">
                      <span class="label">context: </span>
                      <span class="value"><xsl:value-of select="parent::s:rule/@context"/></span>
                    </div>
                    <div class="message-element">
                      <span class="label">element: </span>
                      <span class="value"><xsl:sequence select="local-name()"/></span>
                    </div>
                    <xsl:if test="count(current-group()) ge 2">
                      <div class="message-count">
                        <span class="label">same msg text count: </span>
                        <span class="value"><xsl:value-of select="count(current-group())"/></span>
                      </div>
                    </xsl:if>
                    <xsl:if test="current-group()/sc:xsl-fix">
                      <div class="message-fix">
                        <span class="label">XSLT fix: </span>
                        <span class="value"><xsl:value-of 
                          select="string-join(for $scf in current-group()/sc:xsl-fix
                                              return concat($scf/@href, '@', $scf/@mode),
                                              '; ')"/></span>
                      </div>
                    </xsl:if>
                    <xsl:variable name="origin-info" as="item()*" 
                      select="(ancestor::s:pattern/processing-instruction('origin'), ancestor::s:pattern/@xml:base)"/>
                    <xsl:if test="exists($origin-info)">
                      <div class="message-origin hideme">
                        <span class="label">origin: </span>
                        <span class="value"><xsl:value-of select="$origin-info[1]"/></span>
                      </div>  
                    </xsl:if>
                  </div>
                </div>
              </a>
            </li>
          </xsl:for-each-group>
        </ul>
      </div>
    </xsl:for-each-group>    
  </xsl:template>

  <xsl:function name="tr:severity-sortkey" as="xs:anyAtomicType">
    <xsl:param name="node"/>
    <xsl:choose>
      <xsl:when test="$node/@role = 'fatal-error'">1</xsl:when>
      <xsl:when test="$node/@role = 'error'">2</xsl:when>
      <xsl:when test="empty($node/@role)">2</xsl:when>
      <xsl:when test="$node/@role = 'warning'">3</xsl:when>
      <xsl:when test="$node/@role = 'info'">4</xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$node/@role"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="tr:output-message" as="node()*">
    <xsl:param name="rule" as="element()"/><!-- s:assert or s:report-->
    <xsl:apply-templates select="$rule" mode="tr:output-message"/>
  </xsl:function>
  
  <xsl:template match="*" mode="tr:output-message">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="*:value-of" mode="tr:output-message">
    <span class="value-of" title="{@select}">[…]</span>
  </xsl:template>
  
  <xsl:template match="s:name" mode="tr:output-message">
    [name]
  </xsl:template>

  <xsl:template match="s:span[@class = 'srcpath']" mode="tr:output-message"/>
  
  <xsl:template match="s:span[@class = 'rule-base-uri']" mode="tr:output-message">
    <span title="{string(.)}" class="rule-base-uri">
      <xsl:value-of select="tokenize(., '/')[last()]"/>
    </span>
  </xsl:template>
  

  <xsl:template name="list-checking-rules-css">
    <style type="text/css">
body {margin-bottom:2em}

div.role-group {border:3px solid #ddd; margin:1em 0; padding:.25em; border-radius:10px}
div.role-group * {color:#000}
div.role-group > div.heading {display:inline-block; width:97%}
div.role-group.fatal-error {border:3px solid #444}
div.role-group.fatal-error > div.heading > *, .tr-message.fatal-error b {color:#444}
div.role-group.error {border:3px solid #fc9a8d}
div.role-group.error > div.heading > *, .tr-message.error b {color:#973433}
div.role-group.warning {border:3px solid #ffe082}
div.role-group.warning > div.heading > *, .tr-message.warning b {color:#e67000}
div.role-group.info {border:3px solid #d9edf7}
div.role-group.info div.heading > *, .tr-message.info b {color:#31708f}
div.role-group div.role-name, div.role-group div.heading div.message-count {font-weight:bold; font-size:1.2em; display:inline; margin-left:.25em}
div.role-group div.heading div.message-count:before {content:"("}
div.role-group div.heading div.message-count:after {content:")"}

div.role-group li a {text-decoration:none; display:block; width:98%; margin-top:.25em}
.message-info {display:none; margin:0 .25em .25em .8em}
.switch-info {padding-left:.em}
a.active-message-info {padding:0 .2em}
a.active-message-info .message-info {display:block}
a.active-message-info {margin-bottom:.5em;}
div.message-context span.value {font-family:Courier}

div.role-group.fatal-error a.active-message-info {border:1px solid ; color:#444; border-radius:3px}
div.role-group.error a.active-message-info {border:1px solid #973433; color: #973433; border-radius:3px}
div.role-group.warning a.active-message-info {border:1px solid #e67000; color:#e67000; border-radius:3px}
div.role-group.info a.active-message-info {border:1px solid #31708f; color:#31708f; border-radius:3px}

div.role-group.fatal-error a.active-message-info .label {color:#333}
div.role-group.error a.active-message-info .label {color:#973433}
div.role-group.warning a.active-message-info .label {color:#e67000}
div.role-group.info a.active-message-info .label {color:#31708f}

.hideme{display:none}
.tr-message {margin-bottom:0}
div.collapse {display:inline; text-align:right}
div.collapse:hover {cursor:pointer; text-decoration: underline}

span.label {font-weight:bold}
span.value-of {border-bottom:1px dotted #555}
span.rule-base-uri {background-color:#ddd}
    </style>
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

  <xsl:function name="tr:get-l10n-severity" as="xs:string">
    <xsl:param name="severity"/>
    <xsl:choose>
      <xsl:when test="$severity = 'fatal-error'">
        <xsl:choose>
          <xsl:when test="matches($interface-language, '^de(-\p{Lu}+)?$')">
            <xsl:text>Abbruchfehler</xsl:text>
          </xsl:when>
          <xsl:when test="matches($interface-language, '^fr(-\p{Lu}+)?$')">
            <xsl:text>Erreurs fatales</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>Fatal errors</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="$severity = 'error'">
        <xsl:choose>
          <xsl:when test="matches($interface-language, '^de(-\p{Lu}+)?$')">
            <xsl:text>Fehler</xsl:text>
          </xsl:when>
          <xsl:when test="matches($interface-language, '^fr(-\p{Lu}+)?$')">
            <xsl:text>Erreurs</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>Errors</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="$severity = 'warning'">
        <xsl:choose>
          <xsl:when test="matches($interface-language, '^de(-\p{Lu}+)?$')">
            <xsl:text>Warnungen</xsl:text>
          </xsl:when>
          <xsl:when test="matches($interface-language, '^fr(-\p{Lu}+)?$')">
            <xsl:text>Alertes</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>Warnings</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="$severity = 'info'">
        <xsl:choose>
          <xsl:when test="matches($interface-language, '^de(-\p{Lu}+)?$')">
            <xsl:text>Informationen</xsl:text>
          </xsl:when>
          <xsl:when test="matches($interface-language, '^fr(-\p{Lu}+)?$')">
            <xsl:text>Informations</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>Information</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$severity"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- messages-grouped-by-type.xml input -->

  <xsl:template match="tr:document" mode="tr:brief-report">
    <xsl:if test="count(tr:messages/tr:message[@severity = 'fatal-error']) gt 1">
      <p>
        <xsl:sequence select="tr:get-l10n-severity('fatal-error')"/>
        <xsl:text>:&#x20;</xsl:text>
        <xsl:value-of select="count(tr:messages/tr:message[@severity = 'error'])"/>
      </p>
    </xsl:if>
    <p>
      <xsl:sequence select="tr:get-l10n-severity('error')"/>
      <xsl:text>:&#x20;</xsl:text>
      <xsl:value-of select="count(tr:messages/tr:message[@severity = 'error'])"></xsl:value-of>
    </p>
    <p>
      <xsl:sequence select="tr:get-l10n-severity('warning')"/>
      <xsl:text>:&#x20;</xsl:text>
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
    <p class="tr-message {@severity}">
      <b>
        <xsl:apply-templates select="@severity" mode="#current"/>
      </b>
      <xsl:text>&#x2002;</xsl:text>
      <xsl:apply-templates select="(svrl:diagnostic-reference[@xml:lang = $interface-language], svrl:text)[1]" mode="#current"/>
    </p>    
  </xsl:template>
  

</xsl:stylesheet>

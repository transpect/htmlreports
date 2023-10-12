<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:tr="http://transpect.io"
  xmlns="http://www.w3.org/1999/xhtml"
  xpath-default-namespace="http://www.w3.org/1999/xhtml"
  version="2.0">
  
  <!-- Stylesheet for xpl/htmlreports-summary.xpl -->
  
  <xsl:param name="report-dir"/>
  <xsl:param name="recursive"/>
  <xsl:param name="htmlreport-file-regex"/>
  <xsl:param name="language" select="'en'"/>
  
  <xsl:template name="main">
    <html>
      <title><xsl:sequence select="tr:local('html-title')"/></title>
      <head>
        <style type="text/css">
          * {font-family:sans-serif;}
          h1 {font-size:1.5em}
          p.created, p.directory, p.files, h1 {text-align:center}
          p.no-htmlreports {padding-top:2em;font-weight:bold; font-style:italic}
          p.quick-overview.header {font-weight:bold;margin-bottom:.2em}
          p.quick-overview.text {font-size:.9em;margin-top:0}
          p.quick-overview.text span.counter {margin-right:.2em;font-weight:bold;padding-left:.1em;padding-right:.1em}
          p.quick-overview.text span.id {background-color:#fff}
          p.quick-overview.text span.counter::after {content:"x:"}
          p.quick-overview.text span.qo-group {margin-left:.5em}
          p.quick-overview .detail-error .counter,p.quick-overview .detail-fatal-error .counter {color:#fff}
          p.quick-overview, table.summary {margin-left:auto;margin-right:auto;width:90%}
          table.summary {width:90%;border-bottom:1px solid #ccc; margin-top:2em}
          div a#tr_info-report_contains_no_errors {text-decoration:none }
          div a#tr_info-report_contains_errors {text-decoration:line-through }
          tr.header th:first-child {text-align: left}
          tr.header th {border-bottom:1px solid #ccc}
          tr.footer {background-color:#bbb}
          tr.footer td {font-weight:bold; border:1px solid #ccc;font-size:1.1em;padding:.3em;}
          tr.short {background-color:#eee;font-weight:bold;font-size:1.1em}
          tr.short td:first-child {border-left:1px solid #ccc;}
          tr.short td:last-child {border-right:1px solid #ccc;}
          tr.long {background-color:#fefefe;}
          tr.long td {border-right:1px solid #ccc; border-left:1px solid #ccc}
          td.num-warnings, td.num-others, td.num-errors, td.num-fatal-errors, tr.footer td {text-align:center}
          td.num-warnings.none, td.num-errors.none, td.num-fatal-errors.none {background-color:#A9F5A9}
          td.num-warnings.exists {background-color:#F7FE2E}
          td.num-others.exists {background-color:#ccc}
          td.num-errors.exists {background-color:#FF4000}
          td.num-fatal-errors.exists, span.qo-group.fatal {background-color:#a94442}
          td.filename {padding:.3em}
          span.badge {padding-left:1em;font-weight:bold}
          td.filename a {color:#000; text-decoration:none}
          div.collapse + div.BC_family-label {border-top:1px solid #ccc}
          .detail-other *, .detail-warning *, .detail-error * {color:#000;text-decoration:none}
          .detail-other * {background-color:#ccc;}
          .detail-warning * {background-color:#F7FE2E;}
          .detail-error * {background-color:#FF4000;}
          .detail-fatal-error * {background-color:#a94442}
          ul.list-group {margin-top:0}
          div.BC_family-label {margin-top:1em}
          div.BC_summary {margin-left:1.5em}
        </style>
      </head>
      <body>
        <h1><xsl:sequence select="tr:local('body-title')"/></h1>
        <p class="created"><xsl:sequence select="tr:local('meta-created')"/> <xsl:value-of select="current-dateTime()"/></p>
        <!--<p class="directory" title="(RegEx: '{$htmlreport-file-regex}', Rekursiv: '{$recursive}')"
          >Verzeichnis: <xsl:value-of select="$report-dir"/></p>-->
        <p class="files"><xsl:sequence select="tr:local('meta-number-of-files')"/> <xsl:value-of select="count(/*/html)"/></p>
        <xsl:choose>
          <xsl:when test="not(/*/html)">
            <p class="no-htmlreports"><xsl:sequence select="tr:local('meta-no-files')"/> </p>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="all-file-summaries" as="element(*)*">
              <xsl:for-each select="/*/html">
                <xsl:sort select="@c:report-filename"/>
                <xsl:variable name="filename" as="xs:string"
                  select="@c:report-filename"/>
                <xsl:variable name="fatal-errors" as="element()*" 
                  select=".//span[contains(@class, 'BC_marker')][not(ancestor::div[@class eq 'BC_summary'])]
                            [contains(@class, 'fatal-error')]"/>
                <xsl:variable name="errors" as="element()*" 
                  select=".//span[contains(@class, 'BC_marker')][not(ancestor::div[@class eq 'BC_summary'])]
                            [matches(@class, '[^-]error')]"/>
                <xsl:variable name="warnings" as="element()*" 
                  select=".//span[contains(@class, 'BC_marker')][not(ancestor::div[@class eq 'BC_summary'])]
                            [contains(@class, 'warning')]"/>
                <xsl:variable name="others" as="element()*" 
                  select=".//span[contains(@class, 'BC_marker')][not(ancestor::div[@class eq 'BC_summary'])]
                            [not(contains(@class, 'warning')) and not(contains(@class, 'error'))]"/>
                <tr class="short">
                  <td class="filename">
                    <a href="{$filename}">
                      <xsl:value-of select="replace($filename, '\.xhtml$', '')"/>
                    </a>
                  </td>
                  <td>
                    <xsl:choose>
                      <xsl:when test="exists($others)">
                        <xsl:attribute name="class" select="'num-others exists'"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:attribute name="class" select="'num-others none'"/>
                      </xsl:otherwise>
                    </xsl:choose>
                    <xsl:value-of select="count($others)"/>
                  </td>
                  <td>
                    <xsl:choose>
                      <xsl:when test="exists($warnings)">
                        <xsl:attribute name="class" select="'num-warnings exists'"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:attribute name="class" select="'num-warnings none'"/>
                      </xsl:otherwise>
                    </xsl:choose>
                    <xsl:value-of select="count($warnings)"/>
                  </td>
                  <td>
                    <xsl:choose>
                      <xsl:when test="exists($errors)">
                        <xsl:attribute name="class" select="'num-errors exists'"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:attribute name="class" select="'num-errors none'"/>
                      </xsl:otherwise>
                    </xsl:choose>
                    <xsl:value-of select="count($errors)"/>
                  </td>
                  <td>
                    <xsl:choose>
                      <xsl:when test="exists($fatal-errors)">
                        <xsl:attribute name="class" select="'num-fatal-errors exists'"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:attribute name="class" select="'num-fatal-errors none'"/>
                      </xsl:otherwise>
                    </xsl:choose>
                    <xsl:value-of select="count($fatal-errors)"/>
                  </td>
                </tr>
                <tr class="long">
                  <td class="summary" colspan="5">
                    <xsl:apply-templates select=".//div[contains(@class, 'BC_summary')]"/>
                  </td>
                </tr>
              </xsl:for-each>
            </xsl:variable>
            
            <!-- build short overview in front of detailed overview -->
            <xsl:variable name="all-messages" select="$all-file-summaries//div[@class = 'BC_summary']//li"/>
            <!-- https://redmine.le-tex.de/issues/15103 -->
            <p class="quick-overview header"><xsl:sequence select="tr:local('quick-overview-title')"/></p>
            <p class="quick-overview text">
              <xsl:if test=".//span[contains(@class, 'BC_marker')][not(ancestor::div[@class eq 'BC_summary'])][contains(@class, 'fatal-error')]">
                <xsl:text>(</xsl:text>
                <span class="qo-group fatal">
                  <span class="counter">
                    <xsl:value-of select="count(.//span[contains(@class, 'BC_marker')][not(ancestor::div[@class eq 'BC_summary'])][contains(@class, 'fatal-error')])"/>
                  </span>
                  <span class="id">
                    <xsl:text>&#x20;</xsl:text>
                    <xsl:sequence select="tr:local('fatal-errors')"/>
                  </span>
                </span>
                <xsl:text>)</xsl:text>
              </xsl:if>
              <xsl:for-each-group select="$all-messages" 
                group-by="string-join(.//text()[not(ancestor::span[contains(@class, 'badge')])], '')">
                <xsl:sort select="sum(current-group()//text()[ancestor::span[contains(@class, 'badge')]])" order="descending"/>
                <span class="qo-group {@class}">
                  <span class="counter">
                    <xsl:value-of select="sum(current-group()//text()[ancestor::span[contains(@class, 'badge')]])"/>
                  </span>
                  <xsl:text>&#x20;</xsl:text>
                  <span class="id">
                    <xsl:value-of select="current-group()[1]//text()[not(ancestor::span[contains(@class, 'badge')])]"/>
                  </span>
                </span>
              </xsl:for-each-group>
            </p>
            
            <table class="summary">
              <tr class="header">
                <th><xsl:sequence select="tr:local('th-filename')"/></th>
                <th><xsl:sequence select="tr:local('th-informations')"/></th>
                <th><xsl:sequence select="tr:local('th-warnings')"/></th>
                <th><xsl:sequence select="tr:local('th-errors')"/></th>
                <th><xsl:sequence select="tr:local('th-fatal-errors')"/></th>
              </tr>
              <xsl:sequence select="$all-file-summaries"/>
              <tr class="footer">
                <td style="text-align:right;background-color:#fff"><th><xsl:sequence select="tr:local('td-summaries')"/></th></td>
                <td>
                  <xsl:variable name="others-sum" as="xs:double"
                    select="sum($all-file-summaries//td[@class = 'num-others exists'])"/>
                  <xsl:attribute name="class" select="if($others-sum = 0) then 'num-others' else 'num-others.exists'"/>
                  <xsl:value-of select="$others-sum"/>
                </td>
                <td>
                  <xsl:variable name="warnings-sum" as="xs:double"
                    select="sum($all-file-summaries//td[@class = 'num-warnings exists'])"/>
                  <xsl:attribute name="class" select="if($warnings-sum = 0) then 'num-warnings' else 'num-warnings.exists'"/>
                  <xsl:value-of select="$warnings-sum"/>
                </td>
                <td>
                  <xsl:variable name="errors-sum" as="xs:double"
                    select="sum($all-file-summaries//td[@class = 'num-errors exists'])"/>
                  <xsl:attribute name="class" select="if($errors-sum = 0) then 'num-errors' else 'num-errors.exists'"/>
                  <xsl:value-of select="$errors-sum"/>
                </td>
                <td>
                  <xsl:variable name="fatal-errors-sum" as="xs:double"
                    select="sum($all-file-summaries//td[@class = 'num-fatal-errors exists'])"/>
                  <xsl:attribute name="class" select="if($fatal-errors-sum = 0) then 'num-fatal-errors' else 'num-fatal-errors.exists'"/>
                  <xsl:value-of select="$fatal-errors-sum"/>
                </td>
              </tr>
            </table>
          </xsl:otherwise>
        </xsl:choose>
      </body>
    </html>
  </xsl:template>
  <xsl:template match="li[contains(@class, 'BC_tooltip')]">
    <xsl:copy>
      <xsl:attribute name="class" 
        select="if(contains(@class, 'error')) then 'detail-error' else 
                if(contains(@class, 'warning')) then 'detail-warning' else 'detail-other'"/>
      <a href="{concat(ancestor::html/@c:report-filename, (.//a/@href)[1])}">
        <xsl:apply-templates mode="#current"/>
      </a>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="div[@class eq 'BC_severity'] | *[contains(@class, 'pull-right')]"/>
  <xsl:template match="div[@class eq 'checkbox'] | a[@class eq 'BC_link']">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  <xsl:template match="div[contains(@class, 'BC_family-label')][following-sibling::*[1][.//li[contains(@class, 'BC_no-messages')]]]"/>
  <xsl:template match="div[contains(@class, 'collapse')][.//li[contains(@class, 'BC_no-messages')]]"/>
  <xsl:template match="input | li[@class eq 'BC_warning']//a | @alt | @title"/>
  <xsl:template match="node() | @*" priority="-1">
    <xsl:copy><xsl:apply-templates select="@*, node()" mode="#current"/></xsl:copy>
  </xsl:template>
  
  <xsl:function name="tr:local">
    <xsl:param name="pattern"/>
    <xsl:variable name="resolved-pattern"
       select="document('')//tr:localisation/tr:language[ @xml:lang eq $language ]/tr:text[ @p eq $pattern ]/node()"/>
    <xsl:if test="empty($resolved-pattern)">
      <xsl:if test="empty(document('')//tr:localisation/tr:language[@xml:lang eq $language ])">
        <xsl:message select="'ERROR: value', $language, 'for language param is not available!'"/>
        <xsl:for-each select="document('')//tr:localisation/tr:language/@xml:lang">
          <xsl:message select="concat(' ', current())"/>
        </xsl:for-each>
        <xsl:message select="'Please select one of the above displayed.'" terminate="yes"/>
      </xsl:if>
      <xsl:message select="'WARNING: pattern', $pattern, 'for language param', $language, 'not set, yet!'"/>
    </xsl:if>
    <xsl:sequence select="$resolved-pattern"/>
  </xsl:function>
  
  <tr:localisation>
    <tr:language xml:lang="en">
      <tr:text p="html-title">Total report</tr:text>
      <tr:text p="body-title">Total report</tr:text>
      <tr:text p="meta-created">Created:</tr:text>
      <tr:text p="meta-number-of-files">Count of files:</tr:text>
      <tr:text p="meta-no-files">No htmlreport files found!</tr:text>
      <tr:text p="quick-overview-title">Quick overview:</tr:text>
      <tr:text p="fatal-errors">fatal errors</tr:text>
      <tr:text p="th-filename">filename</tr:text>
      <tr:text p="th-informations">infos.</tr:text>
      <tr:text p="th-warnings">warns</tr:text>
      <tr:text p="th-errors">errors</tr:text>
      <tr:text p="th-fatal-errors">fatals</tr:text>
      <tr:text p="td-summaries">sums:</tr:text>
    </tr:language>
    <tr:language xml:lang="de">
      <tr:text p="html-title">Gesamt-Report</tr:text>
      <tr:text p="body-title">Gesamt-Report</tr:text>
      <tr:text p="meta-created">Erstellt:</tr:text>
      <tr:text p="meta-number-of-files">Anzahl Dateien:</tr:text>
      <tr:text p="meta-no-files">Keine HTML-Report-Dateien gefunden!</tr:text>
      <tr:text p="quick-overview-title">Schnellübersicht:</tr:text>
      <tr:text p="fatal-errors">Fatale Fehler</tr:text>
      <tr:text p="th-filename">Dateiname</tr:text>
      <tr:text p="th-informations">Infos</tr:text>
      <tr:text p="th-warnings">Warnungen</tr:text>
      <tr:text p="th-errors">Fehler</tr:text>
      <tr:text p="th-fatal-errors">Fatal</tr:text>
      <tr:text p="td-summaries">Summen:</tr:text>
    </tr:language>
  </tr:localisation>
  
</xsl:stylesheet>

<?xml version="1.0" encoding="utf-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:c="http://www.w3.org/ns/xproc-step" 
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:tr="http://transpect.io"
  version="1.0" 
  name="htmlreports-summary"
  type="tr:htmlreports-summary">
  
  <p:documentation>Pipeline for creating a meta HTML Report file: summarize all reports in one file.</p:documentation>

  <p:option name="report-dir" required="true">
    <p:documentation>Absolute path to the report directory. Where all reports are stored in. 
      Example: /data/home/me/reports/</p:documentation>
  </p:option>
  <p:option name="recursive" required="false" select="'no'">
    <p:documentation>Search recursively in report-dir for htmlreport files.</p:documentation>
  </p:option>
  <p:option name="htmlreport-file-regex" required="false" select="'^.*.report.xhtml$'">
    <p:documentation>RegEx for finding all htmlreport files in report-dir.</p:documentation>
  </p:option>
  <p:option name="htmlreport-file-exclude-regex" required="false" select="'^_ltx-bogo_$'">
    <p:documentation>RegEx for files in report-dir which will NOT included in reports.xhtml.</p:documentation>
  </p:option>
  <p:option name="summary-report-filename" required="false" select="'reports.xhtml'"/>
  <p:option name="language" required="false" select="'en'"/>
  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="resolve-uri('debug')"/>
  <p:option name="status-dir-uri" required="false" select="'status'"/>

  <p:input port="source"><p:empty/></p:input>
  
  <p:input port="stylesheet">
    <p:document href="../xsl/htmlreports-summary.xsl"/>
  </p:input>
  
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>
  <p:import href="http://transpect.io/xproc-util/recursive-directory-list/xpl/recursive-directory-list.xpl"/>

  <p:choose name="recursive-option">
    <p:when test="$recursive = 'yes'">
      <tr:recursive-directory-list name="find-reports">
      <p:with-option name="path" select="$report-dir"/>
      <p:with-option name="include-filter" select="$htmlreport-file-regex"/>
      <p:with-option name="exclude-filter" select="$htmlreport-file-exclude-regex"/>
    </tr:recursive-directory-list>
    </p:when>
    <p:otherwise>
      <p:directory-list name="find-reports">
        <p:with-option name="path" select="$report-dir"/>
        <p:with-option name="include-filter" select="$htmlreport-file-regex"/>
        <p:with-option name="exclude-filter" select="$htmlreport-file-exclude-regex"/>
      </p:directory-list>
    </p:otherwise>
  </p:choose>
  
  <cx:message>
    <p:with-option name="message" 
      select="concat('htmlreports-summary info: Looking into ', $report-dir, ' (recursive: ', 
                     $recursive, ') for files matching ''', $htmlreport-file-regex, 
                     ''' and creating report with language=', $language)"/>
  </cx:message>

  <tr:store-debug pipeline-step="report-summary/directory-list">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>

  <p:for-each name="load-reports">
    <p:iteration-source select="//c:file"/>
    <p:try>
      <p:group>
        <p:load>
          <p:with-option name="href" select="concat('file:', $report-dir, '/', /*/@name)"/>
        </p:load>
        <p:add-attribute name="add-filename" match="/*" attribute-name="c:report-filename">
          <p:with-option name="attribute-value" select="/*/@name">
            <p:pipe port="current" step="load-reports"/>
          </p:with-option>
        </p:add-attribute>
      </p:group>
      <p:catch>
        <p:add-attribute name="add-filename" match="/*" attribute-name="c:report-filename">
          <p:with-option name="attribute-value" select="/*/@name">
            <p:pipe port="current" step="load-reports"/>
          </p:with-option>
          <p:input port="source">
            <p:inline>
              <html xmlns="http://www.w3.org/1999/xhtml">
                <body xmlns="http://www.w3.org/1999/xhtml" id="report-load-problem">
                  <span xmlns="http://www.w3.org/1999/xhtml" class="BC_marker fatal-error">Report file problem!</span>
                  <div xmlns="http://www.w3.org/1999/xhtml" class="BC_summary"><span xmlns="http://www.w3.org/1999/xhtml" style="color:#fff;font-weight:bold;background-color:#a94442">The report file could not be loaded! Please check if the report is completely written and well-formed.</span></div>
                </body>
              </html>
            </p:inline>
          </p:input>
        </p:add-attribute>
      </p:catch>
    </p:try>
  </p:for-each>
  
  <p:wrap-sequence name="wrap-reports" wrapper="c:html-reports"/>

  <p:xslt name="build-summary-report" template-name="main">
    <p:with-param name="report-dir" select="$report-dir"/>
    <p:with-param name="recursive" select="$recursive"/>
    <p:with-param name="htmlreport-file-regex" select="$htmlreport-file-regex"/>
    <p:with-param name="language" select="$language"/>
    <p:input port="stylesheet">
      <p:pipe port="stylesheet" step="htmlreports-summary"></p:pipe>
    </p:input>
    <p:input port="parameters"><p:empty/></p:input>
  </p:xslt>

  <cx:message>
    <p:with-option name="message" select="concat('htmlreports-summary info: ', count(/*/*), ' reports found.&#xa;Saving summary file to: ', $report-dir, '/', $summary-report-filename)">
      <p:pipe port="result" step="wrap-reports"/>
    </p:with-option>
  </cx:message>

  <p:store name="write-to-disk" method="xhtml" encoding="utf-8" media-type="html" cx:depends-on="build-summary-report">
    <p:with-option name="href" select="concat($report-dir, '/', $summary-report-filename)"/>
  </p:store>
  
</p:declare-step>

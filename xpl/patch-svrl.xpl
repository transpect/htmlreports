<?xml version="1.0" encoding="utf-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:html="http://www.w3.org/1999/xhtml" 
  xmlns:tr="http://transpect.io"
  exclude-inline-prefixes="#all" 
  version="1.0" 
  type="tr:patch-svrl" 
  name="patch-svrl">

  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" select="'debug'"/>
  <p:option name="status-dir-uri" select="'status'"/>
  <p:option name="max-errors-per-rule" required="false" select="'200'"/>
  <p:option name="severity-default-name" required="false" select="'no-role'"/>
  <p:option name="report-title" required="false" select="''"/>

  <p:input port="source" primary="true">
    <p:documentation>An XML document with srcpath attributes. Typically an XHTML rendering.</p:documentation>
  </p:input>
  <p:input port="reports" sequence="true">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p>SVRL outputs that carry @tr:rule-family attributes on their top-level
        elements or c:errors elements with try/catch results. Only <code>c:errors/c:error[@code]</code>
        errors will be visualized in the HTML report (i.e., they need a code attribute).</p>
      <p>The reports may either be supplied as a sequence of documents or as a single document,
        wrapped in a c:reports element. The latter will facilitate debugging since it makes standalone
      invocation easier – you only need to supply the htmlreports/reports.xml document of a previous
      run’s debug directory.</p>
    </p:documentation>
  </p:input>
  <p:input port="params" kind="parameter" primary="true"/>

  <p:output port="result" primary="true">
    <p:pipe step="remove-fallback" port="result"/>
  </p:output>
  <p:output port="secondary" sequence="true">
    <p:documentation>messages-grouped-by-type.xml, linked-messages-grouped-by-srcpath.xml
    for further processing (e.g., list of all message types)</p:documentation>
    <p:pipe step="create-patch-xsl" port="secondary"/>
  </p:output>

  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="http://transpect.io/cascade/xpl/load-cascaded.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl" />
  <p:import href="http://transpect.io/xproc-util/simple-progress-msg/xpl/simple-progress-msg.xpl"/>
  
  <tr:simple-progress-msg name="start-msg" file="patch-svrl-start.txt">
    <p:input port="msgs">
      <p:inline>
        <c:messages>
          <c:message xml:lang="en">Patching messages into HTML rendering</c:message>
          <c:message xml:lang="de">Montiere die Meldungen in das HTML-Rendering</c:message>
        </c:messages>
      </p:inline>
    </p:input>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
  </tr:simple-progress-msg>

  <p:sink/>

  <p:split-sequence initial-only="true" test="position() = 1">
    <p:input port="source">
      <p:pipe port="reports" step="patch-svrl"/>  
    </p:input>
  </p:split-sequence>
  
  <p:choose name="reports">
    <p:when test="/c:reports">
      <p:output port="result" primary="true"/>
      <p:identity>
        <p:input port="source">
          <p:pipe port="reports" step="patch-svrl"/>
        </p:input>
      </p:identity>
    </p:when>
    <p:otherwise>
      <p:output port="result" primary="true"/>
      <p:wrap-sequence wrapper="c:reports">
        <p:input port="source">
          <p:pipe port="reports" step="patch-svrl"/>
        </p:input>
      </p:wrap-sequence>
    </p:otherwise>
  </p:choose>

  <p:sink/>
  
  <p:xslt name="reorder-messages-by-category">
    <p:documentation>This XSLT will regroup the messages using a span in the asserts/reports. 
      The span's class used to regroup can be defined as te content of param name 'rule-category-span-class' in the parameter set. (For example ina  project specific transpect-conf.xml)
      The span's content will appear as a heading in the html report.
      If it isn't defined or no such spans occur the reports document will be reproduced. 
      If not every assert/report has a span with that class the original rule-family is used.</p:documentation>
    <p:input port="source">
      <p:pipe port="result" step="reports"/>
    </p:input>
    <p:input port="parameters">
      <p:pipe port="params" step="patch-svrl"/>
    </p:input>
    <p:input port="stylesheet">
      <p:document href="../xsl/regroup-messages-to-category.xsl"/>
    </p:input>
  </p:xslt>
  
  <p:sink/>

  <p:delete name="filter-document" match="@xml:base">
    <p:input select="/html:html" port="source">
      <p:pipe port="source" step="patch-svrl"/>
    </p:input>
    <p:documentation>Just in case that there are blank lines in front of the XHTML -- these
    will constitute an empty document by themselves. In addition, @xml:base attributes 
    will give a funny link click experience.</p:documentation>
  </p:delete>

  <tr:store-debug pipeline-step="htmlreports/filtered">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>

  <p:sink/>

  <tr:store-debug pipeline-step="htmlreports/reports">
    <p:input port="source">
      <p:pipe step="reports" port="result"/>
    </p:input>
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>

  <p:sink/>
  
  <tr:store-debug pipeline-step="htmlreports/reports-regrouped">
    <p:input port="source">
      <p:pipe step="reorder-messages-by-category" port="result"/>
    </p:input>
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>
  
  <p:sink/>

  <tr:load-cascaded name="load-svrl2xsl" filename="htmlreports/svrl2xsl.xsl"
    fallback="http://transpect.le-tex.de/htmlreports/xsl/svrl2xsl.xsl">
    <p:input port="paths">
      <p:pipe port="params" step="patch-svrl"/>
    </p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:load-cascaded>

  <p:sink/>

  <!-- jquery -->
  <p:identity>
    <p:input port="source">
      <p:data href="../js/jquery.min.js" content-type="application/octet-stream"/>
    </p:input>
  </p:identity>
  <p:add-attribute match="html:script" attribute-name="src" name="jquery-script">
    <p:input port="source">
      <p:inline><script xmlns="http://www.w3.org/1999/xhtml" id="jquery"/></p:inline>
    </p:input>
    <p:with-option name="attribute-value"
      select="concat('data:application/x-javascript;base64,', replace(/*/node(), '\s+', ''))"/>
  </p:add-attribute>

  <p:sink/>
  
  <!-- mathjax for mathml browser rendering -->
  <p:add-attribute match="html:script" attribute-name="src" name="mathjax-script">
    <p:input port="source">
      <p:inline><script xmlns="http://www.w3.org/1999/xhtml" id="mathjax"/></p:inline>
    </p:input>
    <p:with-option name="attribute-value" select="'http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML'"/>
  </p:add-attribute>
  
  <p:sink/>

  <!-- keypress to support browser hotkeys -->
  <p:identity>
    <p:input port="source">
      <p:data href="../js/keypress.min.js" content-type="application/octet-stream"/>
    </p:input>
  </p:identity>
  <p:add-attribute match="html:script" attribute-name="src" name="keypress-script">
    <p:input port="source">
      <p:inline><script xmlns="http://www.w3.org/1999/xhtml" id="keypress"/></p:inline>
    </p:input>
    <p:with-option name="attribute-value"
      select="concat('data:application/x-javascript;base64,', replace(/*/node(), '\s+', ''))"/>
  </p:add-attribute>
  
  <p:sink/>
  
  <p:identity>
    <p:input port="source">
      <p:data href="../icons/doge.png" content-type="image/png"/>
    </p:input>
  </p:identity>
  <p:add-attribute match="html:img" attribute-name="src" name="doge-img">
    <p:input port="source">
      <p:inline><img xmlns="http://www.w3.org/1999/xhtml" id="doge" class="doge" alt="wow"/></p:inline>
    </p:input>
    <p:with-option name="attribute-value"
      select="concat('data:image/png;base64,', replace(/*/node(), '\s+', ''))"/>
  </p:add-attribute>
  
  <p:sink/>

  <p:xslt name="create-patch-xsl">
    <p:input port="source">
      <p:pipe step="reorder-messages-by-category" port="result"/>
      <p:pipe step="filter-document" port="result">
        <p:documentation>To be able to avoid some messages to be rendered in special sections of the XML 
          (for example sections that will be discarded later) a HTML @class 'bc_ignore' can be added to 
          the content. Those elements and its children will not carry messages in the htmlreport.</p:documentation>
      </p:pipe>
      <p:pipe port="result" step="jquery-script"/>
      <p:pipe port="result" step="keypress-script"/>
      <p:pipe port="result" step="mathjax-script"/>
      <p:pipe port="result" step="doge-img"/>
    </p:input>
    <p:input port="stylesheet">
      <p:pipe step="load-svrl2xsl" port="result"/>
    </p:input>
    <p:input port="parameters">
      <p:pipe port="params" step="patch-svrl"/>
    </p:input>
    <p:with-param name="report-title" select="$report-title"/>
    <p:with-param name="severity-default-name" select="$severity-default-name"/>
    <p:with-param name="max-errors-per-rule" select="$max-errors-per-rule"/>
    <p:with-param name="jQuery-uri" select="'jquery.min.js'">
      <p:documentation>If you use a file: URI, don’t forget to copy the file into the htmlreport directory (e.g. in your
        Makefile, since you don’t know inside XProc where the htmlreport port output will be stored). You don’t have to specify
        this parameter at all if you pass a base64-encoded JS file wrapped in a c:data document as the 2nd document on the
        source port. It will be used as data: URI then. </p:documentation>
    </p:with-param>
  </p:xslt>

  <tr:store-debug pipeline-step="htmlreports/patch-svrl" extension="xsl">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>

  <p:sink/>

  <p:for-each>
    <p:iteration-source>
      <p:pipe step="create-patch-xsl" port="secondary"/>
    </p:iteration-source>
    <tr:store-debug>
      <p:with-option name="pipeline-step" select="concat('htmlreports', replace(base-uri(), '^.+(/.+?).xml', '$1'))"/>
      <p:with-option name="active" select="$debug"/>
      <p:with-option name="base-uri" select="$debug-dir-uri"/>
    </tr:store-debug>
    <p:sink/>
  </p:for-each>

  <p:insert match="/*/*:body" position="first-child" name="create-element-for-orphaned-messages">
    <p:input port="source">
      <p:pipe step="patch-svrl" port="source"/>
    </p:input>
    <p:input port="insertion">
      <p:inline>
        <div xmlns="http://www.w3.org/1999/xhtml" id="BC_orphans">
          <p srcpath="BC_orphans"/>
          <p style="text-indent:0em" srcpath=""/>
        </div>
      </p:inline>
    </p:input>
  </p:insert>

  <tr:store-debug pipeline-step="htmlreports/pre-patch" extension="xhtml">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>

  <p:xslt name="create-fallback" initial-mode="create-fallback">
    <p:input port="stylesheet">
      <p:pipe step="create-patch-xsl" port="result"/>
    </p:input>
    <p:input port="parameters">
      <p:pipe port="params" step="patch-svrl"/>
    </p:input>
  </p:xslt>

  <tr:store-debug pipeline-step="htmlreports/1.create-fallback" extension="xhtml">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>

  <p:xslt name="patch">
    <p:input port="stylesheet">
      <p:pipe step="create-patch-xsl" port="result"/>
    </p:input>
    <p:input port="parameters">
      <p:pipe port="params" step="patch-svrl"/>
    </p:input>
  </p:xslt>
  
  <tr:store-debug pipeline-step="htmlreports/2.patch-main" extension="xhtml">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>

  <p:xslt name="remove-fallback" initial-mode="remove-fallback">
    <p:input port="stylesheet">
      <p:pipe step="create-patch-xsl" port="result"/>
    </p:input>
    <p:input port="parameters">
      <p:pipe port="params" step="patch-svrl"/>
    </p:input>
  </p:xslt>
  
  <tr:store-debug pipeline-step="htmlreports/3.remove-fallback" extension="xhtml">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>

  <p:sink/>

  <p:identity name="messages-grouped-by-type">
    <p:input port="source" select="/*[ends-with(base-uri(), 'messages-grouped-by-type.xml')]">
      <p:pipe port="secondary" step="create-patch-xsl"/>
    </p:input>
  </p:identity>

  <p:xslt name="create-success-messages">
    <p:input port="stylesheet">
      <p:document href="../xsl/create-success-messages.xsl"/>
    </p:input>
    <p:input port="parameters">
      <p:pipe port="params" step="patch-svrl"/>
    </p:input>
  </p:xslt>

  <tr:simple-progress-msg name="success-msg" file="patch-svrl-success.txt">
    <p:input port="msgs">
      <p:pipe port="result" step="create-success-messages"/>
    </p:input>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
  </tr:simple-progress-msg>

  <p:sink/>
</p:declare-step>

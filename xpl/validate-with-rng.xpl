<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:tr="http://transpect.io"
  version="1.0" 
  name="validate-with-rng"
  type="tr:validate-with-rng">
  
  <p:documentation>
    This step validates an XML document with a RelaxNG schema and 
    provides the validation results as schematron report. The source 
    XML document is also the primary output. The report output port
    provides the schematron report. The report is optionally wrapped 
    with an incoming schematron report if one is provided at the 
    report-in port.
  </p:documentation>
  
  <p:input port="source" primary="true">
    <p:documentation>
      The source port expects the xml document to be validated.</p:documentation>
  </p:input>
  <p:input port="schema" primary="false">
    <p:documentation>
      A RelaxNG-XML-schema is expected to arrive at the schema port.
    </p:documentation>
  </p:input>
  
  <p:output port="report">
    <p:documentation>
      The schematron document.
    </p:documentation>
    <p:pipe step="errorPI2svrl" port="report"/>
  </p:output>
  <p:output port="result" primary="true">
    <p:documentation>
      The source XML file
    </p:documentation>
    <p:pipe step="errorPI2svrl" port="result"/>
  </p:output>

  <p:option name="debug" select="'yes'"/>
  <p:option name="debug-dir-uri" select="'debug'"/>
  <p:option name="status-dir-uri" select="'status'"/>
  
  <p:import href="errorPI2svrl.xpl"/>
  <p:import href="http://transpect.io/calabash-extensions/rng-extension/xpl/rng-validate-to-PI.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl" />
  
  <tr:validate-with-rng-PI name="rng2pi">
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
    <p:input port="schema">
      <p:pipe port="schema" step="validate-with-rng"/>
    </p:input>
  </tr:validate-with-rng-PI>
  
  <tr:store-debug pipeline-step="rngvalid/global/with-PIs">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>
    
  <tr:errorPI2svrl name="errorPI2svrl" severity="error">
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
  </tr:errorPI2svrl>
  
</p:declare-step>
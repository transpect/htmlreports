<?xml version="1.0" encoding="utf-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"   
  xmlns:tr="http://transpect.io"
  version="1.0"
  type="tr:assemble-schematron"
  name="assemble-schematron">
  
  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" />
	<p:option name="schematron-rule-msg" select="'no'">
		<p:documentation>Prints a status message with the Id of the currently fired schematron report or assert.</p:documentation>
	</p:option>
  
  <p:input port="paths" kind="parameter" primary="true"/>
  <p:output port="result" primary="true">
    <p:pipe port="result" step="xslt"/>
  </p:output>
  <p:output port="report" primary="false">
    <p:pipe port="report" step="validate-with-rng"/>
  </p:output>

  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="validate-with-rng.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>
  
  <p:parameters name="cons">
    <p:input port="parameters">
      <p:pipe port="paths" step="assemble-schematron"/>
    </p:input>
  </p:parameters>
  
  <p:xslt name="xslt">
    <p:input port="source">
      <p:pipe step="cons" port="result"/>
    </p:input>
    <p:input port="stylesheet">
      <p:document href="../xsl/assemble-schematron.xsl"/>
    </p:input>
    <p:input port="parameters">
      <p:pipe port="result" step="cons"/>
    </p:input>
  	<p:with-param name="schematron-rule-msg" select="$schematron-rule-msg"/>
  </p:xslt>
  
  <tr:store-debug>
    <p:with-option name="pipeline-step" select="concat('schematron/', /c:param-set/c:param[@name eq 'family']/@value)" >
      <p:pipe step="cons" port="result"/>
    </p:with-option>
    <p:with-option name="active" select="$debug" />
    <p:with-option name="base-uri" select="$debug-dir-uri" />
  </tr:store-debug>
  
  <tr:validate-with-rng name="validate-with-rng">
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:input port="schema">
      <p:document href="http://transpect.io/schema-schematron/1.0/rng/iso-schematron.rng"/>
    </p:input>
  </tr:validate-with-rng>

  <tr:store-debug>
    <p:input port="source">
      <p:pipe port="report" step="validate-with-rng"/>
    </p:input>
    <p:with-option name="pipeline-step" 
      select="concat('schematron/', /c:param-set/c:param[@name eq 'family']/@value, '-sch-validation-errors')" >
      <p:pipe step="cons" port="result"/>
    </p:with-option>
    <p:with-option name="active" select="$debug" />
    <p:with-option name="base-uri" select="$debug-dir-uri" />
  </tr:store-debug>

  <p:sink/>
</p:declare-step>

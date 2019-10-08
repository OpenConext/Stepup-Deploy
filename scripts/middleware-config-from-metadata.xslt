<xsl:stylesheet
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
	xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
	version="1.0"
>

<xsl:output method="text" omit-xml-declaration="yes"/>
<xsl:strip-space elements="*"/>

<xsl:template match="/">
<xsl:apply-templates select="//md:EntityDescriptor[md:SPSSODescriptor]"/>
</xsl:template>

<xsl:template match="md:EntityDescriptor">      {
        "entity_id": "<xsl:value-of select="//@entityID"/>",<xsl:apply-templates select="md:SPSSODescriptor"/>      }
</xsl:template>
  
<xsl:template match="md:SPSSODescriptor">
  <xsl:apply-templates select="md:KeyDescriptor"/>
        "acs": [<xsl:apply-templates select="md:AssertionConsumerService[@Binding='urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST']"/>     
        ],
        "loa": {
          "__default__": "{{ stepup_uri_loa2 }}"
        },
        "assertion_encryption_enabled": false,
        "second_factor_only": false,
        "second_factor_only_nameid_patterns": [],
        "blacklisted_encryption_algorithms": []
</xsl:template>  

<xsl:template match="md:KeyDescriptor[not(@use) or @use='signing']">
  <xsl:apply-templates select="ds:KeyInfo/ds:X509Data/ds:X509Certificate"/>
</xsl:template>
  
<xsl:template match="md:KeyDescriptor[@use!='signing']" />  


<xsl:template match="ds:X509Certificate">
        "public_key": "<xsl:value-of select="translate(normalize-space(.),' ','')"/>",</xsl:template>

<xsl:template match="md:AssertionConsumerService[@Binding='urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST']">           
          "<xsl:value-of select="@Location"/>"<xsl:if test="position() != last()">
    <xsl:text>,</xsl:text>
  </xsl:if>        
</xsl:template>

</xsl:stylesheet>

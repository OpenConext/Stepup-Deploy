<?php

/**
 * Copyright 2018 SURFnet bv
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/* Installation: copy this file to the "modules/saml/lib/Auth/Source/" directory of your SimpleSAMLphp installation
   Usage:
   - In authsourcesphp use "DebugSP:SP" where you would otherwise use "saml:SP"
   - In the call to AuthSimple::requireAuth($params), AuthSimple::login($params) set 'saml:AssertionConsumerServiceURL'
     and 'DebugSP:extraPOSTvars' to the desired values.
     E.g.:
     $params=array(
        'DebugSP:AssertionConsumerServiceURL' => 'https://...',
        'DebugSP:extraPOSTvars' => array(
           'SomePOSTvariable'    => 'SomeValue',
           'AnotherPOSTvariable' => 'AnotherValue'
        ),
     );
     $as->login($params);
*/

// Extend from the SimpleSAMLphp SAML 2.0 authentication source "saml:SP"
class sspmod_DebugSP_Auth_Source_SP extends sspmod_saml_Auth_Source_SP {

    public function __construct($info, $config) {
        parent::__construct($info, $config);
    }

    public function sendSAML2AuthnRequest(array &$state, \SAML2\Binding $binding, \SAML2\AuthnRequest $ar) {

        if ( isset( $state['DebugSP:AssertionConsumerServiceURL'] ) ) {
            // Set the AssertionConsumerServiceURL in the AuthnRequest
            $ar->setAssertionConsumerServiceURL( $state['DebugSP:AssertionConsumerServiceURL'] );
        }

        if ($binding instanceof \SAML2\HTTPPost) {
            // replicate \SAML2\HTTPPost::send(Message $message) so we can set additional POST variables
            $destination = $ar->getDestination();
            $relayState = $ar->getRelayState();
            $post = array();

            // Set extra POST variables
            if (isset($state['DebugSP:extraPOSTvars'])) {
                assert(is_array($state['DebugSP:extraPOSTvars']), 'DebugSP:extraPOSTvars must be array()');
                foreach ($state['DebugSP:extraPOSTvars'] as $key => $value) {
                    $post[$key] = $value;
                }
            }

            // Create SAMLRequest
            $msgStr = $ar->toSignedXML();
            $msgStr = $msgStr->ownerDocument->saveXML($msgStr);

            \SAML2\Utils::getContainer()->debugMessage($msgStr, 'out');

            $post['SAMLRequest'] = base64_encode($msgStr);

            if ($relayState !== null) {
                $post['RelayState'] = $relayState;
            }

            \SAML2\Utils::getContainer()->postRedirect($destination, $post);

            return;
        }

        // Use partent implementation
        parent::sendSAML2AuthnRequest($state, $binding, $ar);
    }
}
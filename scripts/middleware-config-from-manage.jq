# Copyright 2019 SURFnet B.V.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# jq filter for use with OpenConext manage. See middleware-config-from-manage.sh

# Show error when the result does not have an index 0 (i.e. when manage did not return any results)
# This typically happens when the EntityID does not exist in manage
if has(0) then . else error("Query did not return any results. Does the EntityID exist in OpenConext-Manage?") end

# Select the first (should always match one) SP entity in $sp_entity
| (.[] | select(.data.type | contains("saml20-sp"))) as $sp_entity

# Should never happen
| $sp_entity.data | if has("entityid") then . else error("Service Provider not found") end

# Find all "AssertionConsumerService:<number>:Binding" metadata keys with value "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
# Then store the corresponding AssertionConsumerService:<number>:Location keys in $acs_post_localtion_keys
| ( $sp_entity.data.metaDataFields | with_entries( select( .key | test("AssertionConsumerService:.:Binding") ) )
  | with_entries( select( .value == "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST")  )
    | keys | .[] | match("AssertionConsumerService:.").string+":Location" ) as $acs_post_location_keys

# certData is required
| if $sp_entity.data.metaDataFields["certData"] then . else error("Missing certData") end
# A second certificate is not supported by Stepup
# | if $sp_entity.data.metaDataFields["certData2"] then error("certData2 is not supported") else . end

# Construct SP definition for in the stepup middleware config
| $sp_entity.data.metaDataFields
  | {
      entity_id:  $sp_entity.data.entityid,
      public_key: .certData,
      acs:        [.[$acs_post_location_keys]],
      loa: {
        __default__: "{{ stepup_uri_loa2 }}"
      },
      assertion_encryption_enabled: false,
      second_factor_only: false,
      second_factor_only_nameid_patterns: [],
      blacklisted_encryption_algorithms: []
    }

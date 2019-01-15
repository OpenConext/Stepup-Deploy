<?php
/**
 * Copyright 2018 SURFnet B.V.
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

namespace Surfnet\StepupBehat\ValueObject;

use Exception;

class InstitutionConfiguration
{
    private $configuration = [];

    /**
     * @return array
     */
    private function getRoles()
    {
        return ['use_ra', 'use_raa', 'select_raa'];
    }

    /**
     * @param $institution
     * @param $role
     * @param $raInstitution
     * @throws Exception
     */
    public function addRole($institution, $role, $raInstitution)
    {
        if (!in_array($role, $this->getRoles())) {
            throw new Exception('Invalid role requested');
        }

        if (!isset($this->configuration[$institution])) {
            $this->configuration[$institution] = [];
        }

        if (!isset($this->configuration[$institution][$role])) {
            $this->configuration[$institution][$role] = [];
        }

        if (!in_array($raInstitution, $this->configuration[$institution][$role])) {
            $this->configuration[$institution][$role][] = $raInstitution;
        }
    }


    /**
     * @return string
     */
    public function getPayload()
    {
        $payload = [];
        foreach ($this->configuration as $institutionName => $institutionConfiguration) {

            // build permission payload
            foreach ($this->getRoles() as $role) {
                if (!isset($institutionConfiguration[$role])) {
                    $institutionConfiguration[$role] = [];
                }
            }
            $permissions = $this->buildPermissionPayload($institutionConfiguration);

            // build institution payload
            $payload[$institutionName] = sprintf('
                "%s": {
                    "use_ra_locations": true,
                    "show_raa_contact_information": true,
                    "verify_email": true,
                    "number_of_tokens_per_identity": 2,
                    "allowed_second_factors": [],
                    %s
                }', $institutionName, $permissions);
        }

        $result = '{'.implode(',', $payload)."\n}";

        return $result;
    }

    /**
     * @param $institutions
     * @return bool|string
     */
    private function buildPermissionPayload($institutions)
    {
        return substr(json_encode($institutions), 1, -1);
    }
}

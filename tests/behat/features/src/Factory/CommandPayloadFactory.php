<?php

namespace Surfnet\StepupBehat\Factory;

use Ramsey\Uuid\Uuid;
use Surfnet\StepupBehat\ValueObject\Identity;
use Surfnet\StepupBehat\ValueObject\SecondFactorToken;

class CommandPayloadFactory
{
    public function build($requestName, Identity $context)
    {
        switch ($requestName) {
            case "Identity:CreateIdentity":
                $identityCreatedPayload = '{
                    "meta": {
                        "actor_id": null,
                        "actor_institution": null
                    },
                    "command": {
                        "name":"Identity:CreateIdentity",
                        "uuid":"%s",
                        "payload":{
                            "id": "%s",
                            "name_id": "%s",
                            "institution": "%s",
                            "email": "foo@bar.com",
                            "common_name": "%s",
                            "preferred_locale": "en_GB"
                        }
                    }
                }';

                return sprintf(
                    $identityCreatedPayload,
                    (string)Uuid::uuid4(),
                    $context->identityId,
                    $context->nameId,
                    $context->institution,
                    $context->commonName
                );
                break;

            case "Identity:ProveYubikeyPossession":

                /** @var SecondFactorToken $token */
                $token = $context->tokens[0];

                $payload = '{
                    "meta": {
                        "actor_id": "%s",
                        "actor_institution": "%s"
                    },
                    "command": {
                        "name":"Identity:ProveYubikeyPossession",
                        "uuid":"%s",
                        "payload": {
                            "identity_id": "%s",
                            "second_factor_id": "%s",
                            "yubikey_public_id": "%s"
                        }
                    }
                }';

                return sprintf(
                    $payload,
                    $context->identityId,
                    $context->institution,
                    (string)Uuid::uuid4(),
                    $context->identityId,
                    $token->tokenId,
                    $token->identifier
                );
                break;

            case "Identity:VerifyEmail":
                /** @var SecondFactorToken $token */
                $token = $context->tokens[0];

                $payload = '{
                    "meta": {
                        "actor_id": "%s",
                        "actor_institution": "%s"
                    },
                    "command": {
                        "name":"Identity:VerifyEmail",
                        "uuid":"%s",
                        "payload": {
                            "identity_id": "%s",
                            "verification_nonce": "%s"
                        }
                    }
                }';

                return sprintf(
                    $payload,
                    $context->identityId,
                    $context->institution,
                    (string)Uuid::uuid4(),
                    $context->identityId,
                    $token->nonce
                );

                break;
            case "Identity:VetSecondFactor":
                /** @var SecondFactorToken $token */
                $token = $context->tokens[0];

                $payload = '{
                    "meta": {
                        "actor_id": "%s",
                        "actor_institution": "%s"
                    },
                    "command": {
                        "name":"Identity:VetSecondFactor",
                        "uuid":"%s",
                        "payload": {
                            "authority_id": "%s",
                            "identity_id": "%s",
                            "second_factor_id": "%s",
                            "registration_code": "%s",
                            "second_factor_type": "yubikey",
                            "second_factor_identifier": "%s",
                            "document_number": "123456",
                            "identity_verified": true
                        }
                    }
                }';

                return sprintf(
                    $payload,
                    $context->activationContext->actorId,
                    $context->institution,
                    (string)Uuid::uuid4(),
                    $context->activationContext->actorId,
                    $context->identityId,
                    $token->tokenId,
                    $context->activationContext->registrationCode,
                    $token->identifier
                );

                break;
        }
    }

    public function buildRolePayload($actorId, $identity, $institution, $role, $raInstitution)
    {
        $payload = '{
                    "meta": {
                        "actor_id": "%s",
                        "actor_institution": "%s"
                    },
                    "command": {
                        "name":"Identity:AccreditIdentity",
                        "uuid":"%s",
                        "payload": {
                            "identity_id": "%s",
                            "institution": "%s",
                            "role": "%s",
                            "location": "Location A",
                            "contact_information": "Contact INFO",
                            "ra_institution": "%s"
                        }
                    }
                }';

        return sprintf(
            $payload,
            $actorId,
            $institution,
            (string)Uuid::uuid4(),
            $identity,
            $institution,
            $role,
            $raInstitution
        );
    }
}
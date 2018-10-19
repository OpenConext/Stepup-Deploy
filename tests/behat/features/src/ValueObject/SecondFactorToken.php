<?php

namespace Surfnet\StepupBehat\ValueObject;

final class SecondFactorToken
{
    public $tokenId;
    public $type;
    public $identifier;
    public $nonce;

    /**
     * @param string $tokenId UUIDv4
     * @param string $type the token type yubikey, sms, dummy, ..
     * @param string $identifier for example a yubikey public key, or a phone number in case of an SMS token.
     * @return SecondFactorToken
     */
    public static function from($tokenId, $type, $identifier)
    {
        $token = new self();
        $token->tokenId = $tokenId;
        $token->type = $type;
        $token->identifier = $identifier;

        return $token;
    }
}
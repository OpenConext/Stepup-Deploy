<?php

namespace Surfnet\StepupBehat\ValueObject;

final class Identity
{
    public $identityId;
    public $nameId;
    public $commonName;
    public $institution;
    public $tokens = [];

    /**
     * @var ActivationContext
     */
    public $activationContext;

    /**
     * @param string $identityId UUIDv4
     * @param string $nameId
     * @param string $commonName
     * @param string $institution
     * @param SecondFactorToken[] $tokens
     * @return Identity
     */
    public static function from($identityId, $nameId, $commonName, $institution, array $tokens)
    {
        $identity = new self();
        $identity->identityId = $identityId;
        $identity->nameId = $nameId;
        $identity->commonName = $commonName;
        $identity->institution = $institution;
        $identity->tokens = $tokens;

        return $identity;
    }
}
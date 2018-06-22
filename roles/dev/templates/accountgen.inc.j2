<?php

/*
Generate accounts for simpleSAMLphp "example-userpass" auth source

$config: simplesaml php config array
$prefix: account name prefix
$email: An existing email address, if you want to receive mail
$scope: Used as schachome, EPPN scope and names
$slugs: array of account variants
*/

function account_gen(&$config, $prefix, $email, $scope, $slugs)
{
    foreach($slugs as $slug)
    {
        $uid=$prefix.$slug;
        $account=array(
            'NameID' => 'urn:collab:person:'.$scope.':'.$uid,
            'uid' => array($uid),
            'eduPersonPrincipalName' => $uid.'@'.$scope,
            'givenName' => 'gn-'.$uid,
            'sn' => 'sn-'.$scope,
            'cn' => $uid.' '.$scope,
            'mail' => str_replace('@', '+'.$uid.'@', $email),
            'displayName' => 'd-'.$uid.' '.$scope,
            'eduPersonAffiliation' => array('student'),
            'schacHomeOrganization' => $scope,
            'schacHomeOrganizationType' => 'urn:mace:terena.org:schac:homeOrganizationType:int:university',
        );
        $config['example-userpass'][$uid.':'.$uid]=$account;
    }

    // Without SHO
    $uid=$prefix.'-nosho';
    $account=array(
        'NameID' => 'urn:collab:person:'.$scope.':'.$uid,
        'uid' => array($uid),
        'eduPersonPrincipalName' => $uid.'@'.$scope,
        'givenName' => 'gn-'.$uid,
        'sn' => 'sn-'.$scope,
        'cn' => $uid.' '.$scope,
        'mail' => str_replace('@', '+'.$uid.'@', $email),
        'displayName' => 'd-'.$uid.' '.$scope,
        'eduPersonAffiliation' => array('student'),
        //'schacHomeOrganization' => $scope,
        'schacHomeOrganizationType' => 'urn:mace:terena.org:schac:homeOrganizationType:int:university',
    );
    $config['example-userpass'][$uid.':'.$uid]=$account;

    // Without mail
    $uid=$prefix.'-nomail';
    $account=array(
        'NameID' => 'urn:collab:person:'.$scope.':'.$uid,
        'uid' => array($uid),
        'eduPersonPrincipalName' => $uid.'@'.$scope,
        'givenName' => 'gn-'.$uid,
        'sn' => 'sn-'.$scope,
        'cn' => $uid.' '.$scope,
        //'mail' => str_replace('@', '+'.$uid.'@', $email),
        'displayName' => 'd-'.$uid.' '.$scope,
        'eduPersonAffiliation' => array('student'),
        'schacHomeOrganization' => $scope,
        'schacHomeOrganizationType' => 'urn:mace:terena.org:schac:homeOrganizationType:int:university',
    );
    $config['example-userpass'][$uid.':'.$uid]=$account;

    // Without cn
    $uid=$prefix.'-nocn';
    $account=array(
        'NameID' => 'urn:collab:person:'.$scope.':'.$uid,
        'uid' => array($uid),
        'eduPersonPrincipalName' => $uid.'@'.$scope,
        'givenName' => 'gn-'.$uid,
        'sn' => 'sn-'.$scope,
        //'cn' => $uid.' '.$scope,
        'mail' => str_replace('@', '+'.$uid.'@', $email),
        'displayName' => 'd-'.$uid.' '.$scope,
        'eduPersonAffiliation' => array('student'),
        'schacHomeOrganization' => $scope,
        'schacHomeOrganizationType' => 'urn:mace:terena.org:schac:homeOrganizationType:int:university',
    );
    $config['example-userpass'][$uid.':'.$uid]=$account;

}
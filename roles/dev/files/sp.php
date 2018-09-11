<?php

/* This is a SAML service provider (web interface) that uses using SimpleSAMLphp for testing authentication
 * The interface allows changing many of the SP configuration parameters
*/


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// List of the available remote SAML 2.0 identity providers in the SP interface
// The SP interface allows selection of the IdP and the (Requested) AuthnContextClassRef
// The IdP must be configured in saml20-idp-remote.php

require_once('sp-config.inc');


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/* Set php global variables from the received request parameters
   These variables are then used in authsources.php to make the configuration of the the hosted SP dynamic

   * $GLOBALS['gSP_redirect_sign'] -- Whether to sign the authentication request (true) or not (false)
   * $GLOBALS['gSP_secondary_key'] -- Which key to use to sign the authentication request. Use first key (false)
                                      or use the second key (true)
   * $GLOBALS['gSP_signature_algorithm'] -- Identifier of the signature algorithm to use to sign the authentication
                                            request
   * $GLOBALS['gSP_ProtocolBinding'] -- The ProtocolBinding to put in the authentication request (i.e. the binding that
                                        this SP requests the IdP to use for sending back the SAML Response to us)
   * $GLOBALS['gSP_SSOBinding'] -- The binding to use for sending the authentication request to the IdP
*/

$signing='rsa-sha256';
$key='default';
$sp = 'default-sp';

$GLOBALS['gSP_redirect_sign']=TRUE;
$GLOBALS['gSP_signature_algorithm']='http://www.w3.org/2001/04/xmldsig-more#rsa-sha256';
$GLOBALS['gSP_secondary_key']=FALSE;
$GLOBALS['gSP_ProtocolBinding']='urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST';
$GLOBALS['gSP_SSOBinding']='urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect';

if ( isset($_REQUEST['signing'] ) ) {
    switch ($_REQUEST['signing']) {
        case 'none':
            $GLOBALS['gSP_redirect_sign']=FALSE;
            $GLOBALS['gSP_signature_algorithm']='';
            break;
        case 'rsa-sha256':
            break;
        case 'rsa-sha1':
            $GLOBALS['gSP_signature_algorithm']='http://www.w3.org/2000/09/xmldsig#rsa-sha1';
            break;
        case 'rsa-sha384':
            $GLOBALS['gSP_signature_algorithm']='http://www.w3.org/2001/04/xmldsig-more#rsa-sha384';
            break;
        case 'rsa-sha512':
            $GLOBALS['gSP_signature_algorithm']='http://www.w3.org/2001/04/xmldsig-more#rsa-sha512';
            break;
        default:
            $_REQUEST['signing']='rsa-sha256';
            break;
    }
    $signing=$_REQUEST['signing'];
}

if ( isset($_REQUEST['key']) && $_REQUEST['key']=='secondary' ) {
    $GLOBALS['gSP_secondary_key']=TRUE;
    $key='secondary';
}

//if ( isset($_REQUEST['ProtocolBinding'])) {
//    $GLOBALS['gSP_ProtocolBinding'] = $_REQUEST['gSP_ProtocolBinding'];
//}
//$protocolBinding=$GLOBALS['gSP_ProtocolBinding'];

if ( isset($_REQUEST['ssobinding'])) {
    switch ($_REQUEST['ssobinding'])
    {
        case 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST':
        case 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect':
            $GLOBALS['gSP_SSOBinding'] = $_REQUEST['ssobinding'];
            break;
        default:
            $_REQUEST['ssobinding']='urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect';
            break;
    }
}
$ssobinding=$GLOBALS['gSP_SSOBinding'];


if ( isset($_REQUEST['sp'] ) ) {
    $sp=$_REQUEST['sp'];
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Load SimpleSAMLphp
// Note we do this *after* we have set the $GLOBALs for use in the SSP config.

require_once('/usr/local/share/simplesamlphp/lib/_autoload.php');

// Include some utility functions
require_once('sp-utils.inc');


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MAIN

// 1) Process HTTP request
// 2) Output HTML


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Process HTTP request

$as = new SimpleSAML\Auth\Simple($sp);

$session = SimpleSAML_Session::getSessionFromRequest();

$bIsAuthenticated = $as->isAuthenticated();

// Build return URL. This is where ask simplesamlPHP to direct the browser to after login or logout
// Point to this script, but without any request parameters so we won't trigger an login again (and again, and again, and ...)
$returnURL = ($_SERVER['HTTPS'] == 'on') ? 'https://' : 'http://';
$returnURL .= $_SERVER['HTTP_HOST'];
$returnURL .= $_SERVER['SCRIPT_NAME'];
$returnURL .= '?sp='.urlencode($sp);

// Process login and logout actions. Neither login nor logout return
if (isset($_REQUEST['action']) && $_REQUEST['action'] == 'login' ) {

    // Save submitted form in session
    $params_to_save=$_REQUEST;
    unset($params_to_save['action']);
    $session->setData('array', 'SSP_DEMO_SP_FORM_DATA', $params_to_save);

    // Unset existing RequiredAuthnContextClassRef first
    $session->deleteData('string', 'RequiredAuthnContextClassRef');
    $bForceAuthn = false;
    if ( (isset($_REQUEST['forceauthn'])) && ($_REQUEST['forceauthn'] == 'true') )
        $bForceAuthn = true;

    // For use by SAML2Keeper callback function
    $session->setData('string', 'SAML2Keeper_ReturnTo', $returnURL);

    $context = array(
        'ReturnTo' => $returnURL,
        'ReturnCallback' => array('sspmod_saml2keeper_SAML2Keeper','loginCallback'),
        'ForceAuthn' => $bForceAuthn,
        'saml:NameIDPolicy' => null,
    );

    // IdP
    if ( (isset($_REQUEST['idp'])) ) {
        $context['saml:idp'] = $_REQUEST['idp'];
    }

    // LOA
    if ( isset($_REQUEST['loa']) && isset($_REQUEST['idp']) && isset($gIDPmap[$_REQUEST['idp']]['loa'][$_REQUEST['loa']]) ) {
        $loa = $gIDPmap[$_REQUEST['idp']]['loa'][$_REQUEST['loa']];
        // Store the requested LOA in the session so we can verify it later
        $session->setData('string', 'RequiredAuthnContextClassRef', $loa);
        $context['saml:AuthnContextClassRef'] = $loa;  // Specify LOA
    }

    // Scoping IdPList
    if ( isset($_REQUEST['scopingIDP']) && strlen($_REQUEST['scopingIDP']) > 0 ) {
        $context['saml:IDPList'] = array($_REQUEST['scopingIDP']);

        if ( isset($_REQUEST['scopingIDP2']) && strlen($_REQUEST['scopingIDP2']) > 0 ) {
            $context['saml:IDPList'][]=$_REQUEST['scopingIDP2'];
        }
    }

    // RequesterID
    if ( isset($_REQUEST['requesterid']) && strlen($_REQUEST['requesterid']) > 0 ) {
        $context['saml:RequesterID'] = array($_REQUEST['requesterid']);

        if ( isset($_REQUEST['requesterid2']) && strlen($_REQUEST['requesterid2']) > 0 ) {
            $context['saml:RequesterID'][] = $_REQUEST['requesterid2'];
        }
    }

    // NameIDPolicy
    if ( isset($_REQUEST['nameidpolicy']) && strlen($_REQUEST['nameidpolicy']) > 0 ) {
        $context['saml:NameIDPolicy'] = $_REQUEST['nameidpolicy'];
    }

    // Subject NameID
    if ( isset($_REQUEST['subject']) && strlen($_REQUEST['subject']) > 0 ) {
        $context['saml:NameID'] = array(
            'Value' => $_REQUEST['subject'],
            'Format' => SAML2_Const::NAMEID_UNSPECIFIED,
            'Format' => SAML2_Const::NAMEID_UNSPECIFIED,
        );
    }

    // AssertionConsumerServiceURL
    if ( isset($_REQUEST['acsurl']) && strlen($_REQUEST['acsurl']) > 0 ) {
        $context['DebugSP:AssertionConsumerServiceURL'] = $_REQUEST['acsurl'];
    }

    // Emulate ADFS
    if ( (isset($_REQUEST['emulateadfs'])) && ($_REQUEST['emulateadfs'] == 'true') )
    {
        $context['DebugSP:extraPOSTvars'] = array(
            'AuthMethod' => 'ADFS.SCSA',
            'Context' => '<EncryptedData Type="http://www.w3.org/2001/04/xmlenc#Content" xmlns="http://www.w3.org/2001/04/xmlenc#"><EncryptionMethod Algorithm="http://www.w3.org/2001/04/xmlenc#aes256-cbc" /><KeyInfo xmlns="http://www.w3.org/2000/09/xmldsig#"><EncryptedKey xmlns="http://www.w3.org/2001/04/xmlenc#"><EncryptionMethod Algorithm="http://www.w3.org/2001/04/xmlenc#rsa-1_5" /><KeyInfo xmlns="http://www.w3.org/2000/09/xmldsig#"><KeyName>1C63828278F1B0AC2FE61429E099FFA7AC94917C</KeyName></KeyInfo><CipherData><CipherValue>Qe1t1xgG78zLHhUxBXm0ous4yl0zfQumsKI79lrHMOIjdTdeF/i1Yx+pQ+mgnubT9mh+DfBYMs7wU1g+eXiAs2gnwKWmnMzeuxgG+m5Nky5Wd63NcEgLZ2zNTYuW70X514HMtLAw+l1H8cptQMXfXt9ageHOdY+65eq4IsNwnB0mPhRkua58R9xO3I4MfBzy90GqwgjmDeZAo5vsKgk0iZRgZ1CS4hPyIWX+ryU2tnYp5UEuDE9gGlR9cQr2uHW10LOG22ZfEy8rJie2T2A2bCQVyF47nmBnvoKYV6YyEDpozSYJpUqHmIgvaWgFu5dvDvZ0fvrVQaQ1ZUKHTT76Cg==</CipherValue></CipherData></EncryptedKey></KeyInfo><CipherData><CipherValue>6SO/qvyH0bmayeNGyzqAy/Oim2UAOvhxm18rTs+72Qm2fSK6Pfo1ZEDNKmLRk6IemCvkUYWMa4VmxIdATswREx/aSrp4YS3QejDBoZlCwz4LqFWJMiqTPxJfWhahP0hBNEORN8cU5vBQXXIahWqlkaHzs6IPjH4WoMe5vsSKVTetaOMbMC3ZML67BWpAnEXKWoR/gar1jH5v961ljdKJozzgwsJIAY4TNSoB+AEzRd4C3wLSTCott1DyRtMmEmS5DpaDOaxmZ/X+z16t1hb9VKgEqt1xZJ0uw451d5oeuisN9zSqbWQzyiJdkk6k11YU9q2rvg342qLJk6xeTtRc6+DLQ24vZIHC8RU2jcHveLDJvOq89BBJ0LHtnV/7PJpb4PGf1OUqWZidnRAS0/dqprEVzPEnvdzIJ8vPRGzE0dkQhgzDi+cbMsuZrDqYWaMuodvDbGrETxZ9hu0MI3l9pgjuIh8xF7TT/6qTJnGExRaGFebcjMXC99thZ3A7XeJESDNXNxgDgFQf6OwHLjLuhw==</CipherValue></CipherData><Signature xmlns="http://www.w3.org/2000/09/xmldsig#"><SignedInfo><CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315" /><SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1" /><Reference URI=""><Transforms><Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature" /></Transforms><DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1" /><DigestValue>va+cZ6Y7NIyBU9vCVb+qRGSx0Yk=</DigestValue></Reference></SignedInfo><SignatureValue>DNF3KVEb8ju/T+ise1j0QBS2OYsepwzgWaUtOASvUPI6NPlvyQIHxX1Py6oHcUkbWP1jaVTzwEGadaq428nPMWSeU/MDWqyz2jyrwuIUWglc64AMlcXd0BOdT1I6khKMsUGY8CSa1tRD2arcIH1TUrrk7jY3qfAGtgNbFlElPwc/2l4dkN7QXdHRcmntFp4D/9yEG9FkWzTyXLvCvGqcQeu8L1fKTwq8Upqk9iT2PKnmT/gH+IUt3votmCMV9bxYols0aQWfv2RX2HX3Gow9xKZuOn+ckjZRqBJ1Kp9wGMAB65XQPli5UQzezEHX28oUPH/PEgnu6RKDgsN55h22ag==</SignatureValue><KeyInfo><KeyName>DB540D051F8F73EA2F3B5190BFC0F349E595EB34</KeyName></KeyInfo></Signature></EncryptedData> SAMLRequest: PHNhbWwycDpBdXRoblJlcXVlc3QgeG1sbnM6c2FtbDJwPSJ1cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6cHJvdG9jb2wiIHhtbG5zOnNhbWwyPSJ1cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6YXNzZXJ0aW9uIiBJRD0iXzkwZWFkMWNlLTM3NmMtNGE1ZC05ODAzLWQ5Y2M4MDA2M2Q0ZiIgVmVyc2lvbj0iMi4wIiBJc3N1ZUluc3RhbnQ9IjIwMTgtMDQtMjNUMTM6NDk6NTBaIiBEZXN0aW5hdGlvbj0iaHR0cHM6Ly9zYS1ndy50ZXN0Mi5zdXJmY29uZXh0Lm5sL3NlY29uZC1mYWN0b3Itb25seS9zaW5nbGUtc2lnbi1vbiIgQXNzZXJ0aW9uQ29uc3VtZXJTZXJ2aWNlVVJMPSJodHRwczovL2FkZnMtMjAxMi50ZXN0Mi5zdXJmY29uZXh0Lm5sOjQ0My9hZGZzL2xzLz9TQU1MUmVxdWVzdD1wVkpOanhNeERQMHJvOXpubzVscFlhTzJVdGtLVVdtQmFsczRjRUZ1eGtNalpaSWhkbUQ1OTZRcGlJVkRMNXdTUGZzOVB6OTVTVERhU1cwaW45MGpmbzFJWER5TjFwSEtoWldJd1NrUFpFZzVHSkVVYTNYWXZIMVFzbXJVRkR4NzdhMTRScm5OQUNJTWJMd1R4VzY3RXAlMkZiMmVtdTBYTG90SnpMUmklMkJHV1R1SHJwJTJGTCUyQlFKMXYyaFBKOTNjZFMwTUlJcVBHQ2d4VnlJSkpUcFJ4SjBqQnNjSmFtWXZ5NllyWlh1Y3RhcGJxUGJGSjFGczB6YkdBV2ZXbVhraVZkZlFEMVNtZmxseEtzdUtZaGkwZCUyRmpFbGJPNVdsdXFSYkg1YmZYZU80b2poZ09HYjBiamg4ZUhQMktUUWNaUUFaaXM0ekNMa0Jrbml6bkE4MVNQdm84V3E4djNBdFYwZldVSm1qTGE0d0RSY2ttVEtQYSUyRkluMWxYRyUyRmNsOXRwbnE1TnBONGNqJTJGdHklMkYlMkY1d0ZPdmxSVnZsZE1MNlAyMk95TkFEd3o4dWwlMkZYekdjdnJCYjFMN25iYnZiZEclMkZ5aGUlMkJ6QUMzelolMkZRVXhmRHJsVmNRQkhCaDJuNEszMTMlMkI4REF1TktjSWdvNnZWMTVOOTN1djRKJmFtcDtSZWxheVN0YXRlPWh0dHBzJTNBJTJGJTJGcGlldGVyLmFhaS5zdXJmbmV0Lm5sJTJGc2ltcGxlc2FtbHBocCUyRnNwLnBocCUzRnNwJTNEZGVmYXVsdC1zcCZhbXA7U2lnQWxnPWh0dHAlM0ElMkYlMkZ3d3cudzMub3JnJTJGMjAwMSUyRjA0JTJGeG1sZHNpZy1tb3JlJTIzcnNhLXNoYTI1NiZhbXA7U2lnbmF0dXJlPUt6TzhYV0liVTZGdUVWZVZ4RFlNZzJ1T2xoZTlBQVAwd09uWlZVM3RVMU1ibWNKUDlXa3Q1Z0R3a2RKcXhDbUlJWGVDdnBhNDVLWUdlTzNFNWppampSOHlMUFpTalJUalJRem81V2h5bzJTaXRjTkxOZzZ4WFdZY0Z6bmdIcEdKeGRyJTJGVmxjSTR0RXFUNFZSN0VwbXp3amJtd1RaRGMyOW9hdEtZRGNUUjBjTjh2M0VtMVRIR0ZOc1B0bERvRVd5c0laWjFONkRpRVAxYmE4aTE5OVhoRiUyQldXZzVzNHdqMXltMnBDendQelJkYyUyRmpreDRQcG1MTyUyQjNVY3R3amoySG5RNmNiJTJCeHBsJTJCJTJCVUFwalZ1a3ZlNWdiempMbzI4JTJCUGklMkZXQmJ0Ym0lMkZrMzE5UlZ2dWFEdVVvJTJGM3VTUU1BJTJCbHR6b0ZIOGEwRTJ0Q0pNVGg1TWRnUm10ZyUzRCUzRCI+DQogIDxzYW1sMjpJc3N1ZXI+aHR0cDovL2FkZnMtMjAxMi50ZXN0Mi5zdXJmY29uZXh0Lm5sPC9zYW1sMjpJc3N1ZXI+PFNpZ25hdHVyZSB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnIyI+PFNpZ25lZEluZm8+PENhbm9uaWNhbGl6YXRpb25NZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxLzEwL3htbC1leGMtYzE0biMiIC8+PFNpZ25hdHVyZU1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDEvMDQveG1sZHNpZy1tb3JlI3JzYS1zaGEyNTYiIC8+PFJlZmVyZW5jZSBVUkk9IiNfOTBlYWQxY2UtMzc2Yy00YTVkLTk4MDMtZDljYzgwMDYzZDRmIj48VHJhbnNmb3Jtcz48VHJhbnNmb3JtIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnI2VudmVsb3BlZC1zaWduYXR1cmUiIC8+PFRyYW5zZm9ybSBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDEvMTAveG1sLWV4Yy1jMTRuIyIgLz48L1RyYW5zZm9ybXM+PERpZ2VzdE1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDEvMDQveG1sZW5jI3NoYTI1NiIgLz48RGlnZXN0VmFsdWU+Q2ZKV1hpTXJLU0g0b3pPVWZTL0VNOXBXbFRSc3p2QkpMN2Y3MUZrZ3ZCbz08L0RpZ2VzdFZhbHVlPjwvUmVmZXJlbmNlPjwvU2lnbmVkSW5mbz48U2lnbmF0dXJlVmFsdWU+YzFqakFhdnVjMi9TSHZQYzdJdktJVkRSZUZuZVAzbTlITkZzTzErZEx2bWhxUXl5NkhoN3ZRMlFJalVGb2FybkYxZnJpOUY1RlNxL2JsR1I4RENvNEpndUlxKzNnRXBjN1JYR2EyTWc4dE5CV2tWdUg2UnZBTGM1Qk5DSDNtODVTTHgwcklGbERWc0tzZi9IQ0lTc2taV3Z6VVJGVVRFZnZjRVljWjZZZjNXYURmK1YvbE5jYXpCeVQ0L3RmNVVFN0VIM1JYckc2dUFqbHhjekN4a09UUE1SMnIvNmxwaEF1UmIxcjY1bThYQXFZNVFnbG5SVXBOM3U3ZEt4bGN5VUVaY2xKTW5JN21ya2NyMUdwODV6allkK0N4TmFwanNEQXplVjdSSVNLdHNaY0NFYWhncStIdTZVOEtBUmZHZmdFQ1dZNGY0c2lWRGp2d0NVaTlUME13PT08L1NpZ25hdHVyZVZhbHVlPjxLZXlJbmZvPjxYNTA5RGF0YT48WDUwOUNlcnRpZmljYXRlPk1JSURFekNDQWZ1Z0F3SUJBZ0lRU044elc2Q1lsSUpPQUZ6ZFN0VFQrakFOQmdrcWhraUc5dzBCQVFzRkFEQXNNU293S0FZRFZRUUREQ0Z6YVdkdWFXNW5MbVF5TURFeUxuUmxjM1F5TG5OMWNtWmpiMjVsZUhRdWJtd3dIaGNOTVRjd09USTBNVFl6TkRFM1doY05Nakl3T1RJMU1UWXpOREUzV2pBc01Tb3dLQVlEVlFRRERDRnphV2R1YVc1bkxtUXlNREV5TG5SbGMzUXlMbk4xY21aamIyNWxlSFF1Ym13d2dnRWlNQTBHQ1NxR1NJYjNEUUVCQVFVQUE0SUJEd0F3Z2dFS0FvSUJBUUNkL1RXMUpvY05PV2w1aUZsN1JrWTQwa1A1U2NpQllCNnRJRXl3ZmxGNHRrRUR3S1Jxc1EyRXNaOTN1aWdnQi9wWFVhNlRHdlM3dnpRalJxZGhGZ0Nwb2htaGVwUzlQd3UvL0krcDY4VlpDdHNsdDFVSkd0NjJBRk9ad2FUU1FQbjRlR2RoRHI0c1g5TXIrdVVPU1plZWlEdHVFaGlNSWprZDJJYWJPeVNkOUxTK05Nc29pY1NoWEd5MERZR05yN2gyaHl1L2xUK3VMSnZsUFJ0V29aNDdpS1kwVUdpcVNJN013WlNQQjBoT2p5ZW9wbCsvWExENGhEKzNWVUFDMkttSDZaTzBBYWErc1JRZStNVFlVNHZvN29YTitkaEZoOG9VcFFrNjN4MjBtYTE1N3RSU1lqQlVwTURkclMvdk4vNWQ3c21URnQ1dFV4dlVHTGNGR0E4SkFnTUJBQUdqTVRBdk1BNEdBMVVkRHdFQi93UUVBd0lIZ0RBZEJnTlZIUTRFRmdRVUZ2ZzR3d3ByTDBlWi9ZL09zSDkyVDMrK3RsVXdEUVlKS29aSWh2Y05BUUVMQlFBRGdnRUJBRXEvQ2p5N2J0THFmWnp4dlZwUEJYZnVmYk5RSHJBeFY1QnA2a0QyY0NYUzlWQ0swdUdKdkZsemRVMDNDTE9uME4xYTJBUU5JSmZPZVg2dXlTQ1F1WXE0aDRWeUxVSVUyWE1QS1V3OGF2cWhuM0pxbGx4WUJuOE9XdENiRS9BWTdLU2lMWHk5V1BYcHRhdFpyeTV4T0x1SzYxZCtsSzJrdTlVc2xVcTY5b3BIZHhNZ3VqV0EvOUV1SkRINEVEblJ0c0lDT1oyZmxibEllQng4VU5zemExWjJ3NlIxUmtWQVN3YVZDL3JXOVpJaXhkTjdyQzUxQU1qU2YzUnBUc0cvT1Y2blNFcHJNa2hVWWRoSFdSb09XZk8rUGJmZGE1Sm85SHMyeHZENE43L2hPSjQzdC8wV0o1bng3NkNxMTNHcGlFYmlIbXZIQU1jS3R4aHVBS2M4NEk0PTwvWDUwOUNlcnRpZmljYXRlPjwvWDUwOURhdGE+PC9LZXlJbmZvPjwvU2lnbmF0dXJlPg0KICA8c2FtbDI6U3ViamVjdD4NCiAgICA8c2FtbDI6TmFtZUlEIEZvcm1hdD0idXJuOm9hc2lzOm5hbWVzOnRjOlNBTUw6MS4xOm5hbWVpZC1mb3JtYXQ6dW5zcGVjaWZpZWQiPnVybjpjb2xsYWI6cGVyc29uOmluc3RpdHV0aW9uLWEubmw6cGlldGVyLWExPC9zYW1sMjpOYW1lSUQ+DQogIDwvc2FtbDI6U3ViamVjdD4NCiAgPHNhbWwycDpSZXF1ZXN0ZWRBdXRobkNvbnRleHQgQ29tcGFyaXNvbj0iZXhhY3QiPg0KICAgIDxzYW1sMjpBdXRobkNvbnRleHRDbGFzc1JlZj5odHRwOi8vdGVzdDIuc3VyZmNvbmV4dC5ubC9hc3N1cmFuY2Uvc2ZvLWxldmVsMjwvc2FtbDI6QXV0aG5Db250ZXh0Q2xhc3NSZWY+DQogIDwvc2FtbDJwOlJlcXVlc3RlZEF1dGhuQ29udGV4dD4NCjwvc2FtbDJwOkF1dGhuUmVxdWVzdD4='
        );
    }


    // login
    $as->login( $context );

    exit;   // Added for clarity
}

if( isset($_REQUEST['action']) && $_REQUEST['action'] == 'logout' ) {
    $as->logout( array (
        'ReturnTo' => $returnURL,
    ) );  // Process logout
    exit;   // Added for clarity
}

if( isset($_REQUEST['action']) && $_REQUEST['action'] == 'reset' ) {
    $session->deleteData('array', 'SSP_DEMO_SP_FORM_DATA');
    $_REQUEST=array();
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Output HTML

$saved_parameters = $session->getData('array', 'SSP_DEMO_SP_FORM_DATA');
if (is_array($saved_parameters)) {
    $saved_parameters = array();
}
if (!isset($_REQUEST['idp'])) {
    $_REQUEST=array_merge($saved_parameters, $_REQUEST);
}

$idp=htmlentities(isset($_REQUEST['idp']) ? $_REQUEST['idp'] : "");
$loa=htmlentities(isset($_REQUEST['loa']) ? $_REQUEST['loa'] : "");
$nameidpolicy=htmlentities(isset($_REQUEST['nameidpolicy']) ? $_REQUEST['nameidpolicy'] : "");
$ssobinding=htmlentities(isset($_REQUEST['ssobinding']) ? $_REQUEST['ssobinding'] : "");
$requesterid=htmlentities(isset($_REQUEST['requesterid']) ? $_REQUEST['requesterid'] : "");
$requesterid2=htmlentities(isset($_REQUEST['requesterid2']) ? $_REQUEST['requesterid2'] : "");
$scopingIDP=htmlentities(isset($_REQUEST['scopingIDP']) ? $_REQUEST['scopingIDP'] : "");
$scopingIDP2=htmlentities(isset($_REQUEST['scopingIDP2']) ? $_REQUEST['scopingIDP2'] : "");
$sp=htmlentities(isset($_REQUEST['sp']) ? $_REQUEST['sp'] : "default-sp");
$subject=htmlentities(isset($_REQUEST['subject']) ? $_REQUEST['subject'] : "");
$acsurl=htmlentities(isset($_REQUEST['acsurl']) ? $_REQUEST['acsurl'] : "");

echo <<<head
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
	<head>
		<meta http-equiv="Content-type" content="text/html;charset=UTF-8" />
		<style type="text/css">
		    body {font-family: arial, verdana, sans-serif; margin: 0px}
		    h1,h2,h3,h4 {background-color: lightgray; padding: 2px 10px; border-top: 1px solid; border-bottom: 1px solid; clear: both}
		    table { border-collapse: collapse}
		    table,th,td {border: 1px solid black}
		    th,td {padding 1px; font-size: 12px}
		    label {width:220px; font-size: 14px; margin-right: 10px; display: inline-block; float: left; text-align: right}
		    code {display: inline-block; max-width: 600px; float: left; margin-top: 2px;}
		    small {display: inline-block; max-width: 600px; float: left}
		    p,div {margin: 10px; clear: both}
		    button { border-radius: 4px; font-weight: bold; font-size: 14px; background-color: lightgrey; color: black; border: 1px solid black; padding: 5px 10px}
		    button.login {background-color: darkseagreen}
		    button.logout {background-color: indianred}
		    select {min-width: 150px; font-size: 14px;}
        </style>
		<title>simpleSAMLphp Test SP</title>
	</head>
	<body>
		<h1>simpleSAMLphp Test SP</h1>
head;

$authnInstant = '';
$expire = '';
if ( $bIsAuthenticated ) {
    $attributes = $as->getAttributes();

    /** @var $session SimpleSAML_Session */
    $requestedLOA = htmlentities($session->getData('string', 'RequiredAuthnContextClassRef'));
    $IdPEntityID = htmlentities($as->getAuthData('saml:sp:IdP'));
    $sessionIndex = htmlentities($as->getAuthData('saml:sp:SessionIndex'));
    $authState = $session->getAuthState($sp);
    //echo "<pre>"; print_r($authState); echo "</pre>";
    $authenticationAuthority=$authState['saml:AuthenticatingAuthority'];    // Array of AuthenticatingAuthority's
    $actualLOA = htmlentities($authState['saml:sp:AuthnContext']);
    $nameID = $as->getAuthData('saml:sp:NameID');
    $authnInstant = htmlentities(gmdate('r', $authState['AuthnInstant'] ));
    $expire = htmlentities(gmdate('r', $authState['Expire'] ));

    echo <<<html
        <label>You are logged in to SP:</label><code>{$sp}</code><br />
        <label>IdP EnitytID:</label><code>{$IdPEntityID}</code><br />
        <form id="logout" action="sp.php" method="get">
           <p><button class="logout" type="submit" name="action" value="logout">Logout</button></p>
        </form>
html;

    echo "<h3>Session</h3>\n";

    echo "<p>";
    if (strlen($sessionIndex) > 0) {
        $color=HTMLColorFingerprint($sessionIndex);
        echo "<label>SessionIndex:</label><code style='background-color: {$color}'>{$sessionIndex}</code><br />";
    }
    echo "<label>SimpleSAMLphp session start:</label><code>{$authnInstant}</code><br />";
    echo "<label>SimpleSAMLphp session expire:</label><code>{$expire}</code><br /></p>";

    echo "<h3>LOA</h3>";
    echo "<div><label>Actual LOA is:</label><code>{$actualLOA}</code></div><br />";
    if (strlen($requestedLOA) > 0) {
        echo "<div><label>Requested LOA was:</label><code>{$requestedLOA}</code></div><br />";
    }

    echo "<h3>NameID</h3>\n";
    echo "<p>";
    NameIDArrayToHTML($nameID);
    echo "</p>";

    echo <<<html
        <h3>Attributes</h3>
        <div>
        <table>
        	<tr><th>Attribute</th><th>Value(s)</th></tr>
html;
    foreach ($attributes as $attrName => $attrVal) {
        echo "        	<tr><td>".AttributeNameToHTML($attrName)."</td><td>\n";
        if (is_array($attrVal)) {
            for ($i=0;$i<sizeof($attrVal);$i++) {
                if ($attrVal[$i] instanceof DOMNodeList) {
                    foreach ($attrVal[$i] as $node) {
                        $nameid=SAML2_Utils::parseNameId($node);
                        NameIDArrayToHTML($nameid, true);
                    }
                }
                else {
                    echo "<code style='clear: both'>".htmlentities($attrVal[$i])."</code>";
                }
                if ($i+1<sizeof($attrVal)) {
                    echo "<br />";
                }
            }
        }
        else
            echo htmlentities($attrVal);
        echo "</td>\n";
    }
    echo "</table></div>\n";
} else {
    echo <<<html
        <p><strong>Your are not logged in</strong></p>
html;
}

echo <<<html
        <h3>Login (again)</h3>
        <form id="login" action="sp.php" method="get">
html;

$idpOptions=array();
foreach ($gIDPmap as $i => $v) {
    $idpOptions[$i] = $v['name'];
}
HTML_select('Identity Provider: ', 'idp', $idpOptions, $idp, "Select the IdP to authenticate to");

HTML_select('Request LOA: ', 'loa',
    array(
        "" => "None",
        "1" => "1",
        "2" => "2",
        "3" => "3",
    ),
    $loa,
"Select the level of assurance to include in the AuthnContextClassRef in the AuthnRequest. The value depends on the selected IdP and LoA and is only added when the IdP supports it."
);

echo <<<html
               <p>
                    <button class="login" type="submit" name="action" value="login">Login</button>&nbsp;&nbsp;<button type="submit" name="action" value="reset">Reset</button><br />
               </p>
               <h3>Advanced options</h3>
html;
                // Build direct login link from submitted parameters
                if (isset($_REQUEST['action']) && $_REQUEST['action'] == 'show' ) {
echo <<<html
                <p>
                    <button type="submit" name="action" value="show">Update direct login link</button><br />
                </p>
html;

                    $params=array();
                    foreach ($_REQUEST as $p => $v) {
                        if (strlen($v) > 0) {
                            if ($p=='action') {
                                $v='login';
                            }
                            $params[] = urlencode($p).'='.urlencode($v);
                        }
                    }
                    sort($params);
                    $params=implode('&', $params);
                    $login_link=strlen($_SERVER['HTTPS']) > 0 ? 'https://' : 'http://';
                    $login_link.=$_SERVER['HTTP_HOST'];
                    $login_link.=$_SERVER['SCRIPT_NAME']."?".$params;
                    echo "<p><label><a href='".htmlentities($login_link)."'>Direct login link</a></label>";
                    echo "<small>".htmlentities($login_link)."</small></p><br />\n";
                    echo "<p><br /></p>";
                }
                else {
echo <<<html
                <p>
                    <button type="submit" name="action" value="show">Show direct login link</button><br />
                </p>
html;
                }

                HTML_select("Service Provider EnityID: ", "sp",
                    array(
                        'default-sp'=>'default-sp',
                        'second-sp'=>'second-sp',
                        'third-sp'=>'third-sp',
                        'fourth-sp'=>'fourth-sp'
                    ),
                    $sp,
                "Select the EnitytID to use for this SP. This value goes into the Issuer in the AuthnRequest."
                );
                HTML_select("Signing: ", "signing",
                    array(
                        'none'=>'none',
                        'rsa-sha1'=>'rsa-sha1',
                        'rsa-sha256'=>'rsa-sha256',
                        'rsa-sha384'=>'rsa-sha384',
                        'rsa-sha512'=>'rsa-sha512',
                    ),
                    $signing,
                "Select the signing algorithm the SP must use to sign the AuthnRequest, select 'none' to disable signing."
                );

                HTML_select("Signing key: ", "key",
                    array(
                        'default'=>'default',
                        'secondary'=>'secondary',
                    ),
                    $key,
                    "Select the key the SP must use for signing the AuthnRequest. The default key is the key that is present in the SP metadata."
                );

                HTML_select("NameIDPolicy: ", "nameidpolicy",
                    array(
                        '' => 'None',
                        'urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified' => 'unspecified',
                        'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent' => 'persistent',
                        'urn:oasis:names:tc:SAML:2.0:nameid-format:transient' => 'transient',
                    ),
                    $nameidpolicy,
                    "Select the NameID policy that the SP should request from the IdP. This value is put in the of the Format attribute in the NameIDPolicy in AuthnRequest. 'None' uses the simpleSAMLphp default behaviour based on the metadata SP and IdP metadata."
                );

                HTML_select("SSO Binding: ", "ssobinding",
                    array(
                        'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect' => 'HTTP-Redirect',
                        'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST' => 'HTTP-POST',
                    ),
                    $ssobinding,
                "Specify the SAML Binding that the SP must use to send the AuthnRequest to the IdP."
                );

$commonSPs_datalist=
<<<html
                    <datalist id="commonSPs">
                        <option value="http://localhost/simplesaml/module.php/saml/sp/metadata.php/pieter-local-test-sp"></option>
                    </datalist>
html;
$commonIDPs_datalist=
<<<html
                    <datalist id="commonIDPs">
                        <option value="https://pieter.aai.surfnet.nl/simplesamlphp/saml2/idp/metadata.php"></option>
                        <option value="https://idp.surfnet.nl"></option>
                    </datalist>
html;

$sspACSURL = SimpleSAML\Module::getModuleURL('saml/sp/saml2-acs.php/');
$sspDebugSPACSURL = SimpleSAML\Module::getModuleURL('DebugSP/sp/saml2-acs.php/');

$emulateADFSchecked = isset($_REQUEST['emulateadfs']) && $_REQUEST['emulateadfs'] == 'true' ? ' checked' : '';
$forceAuthnChecked = isset($_REQUEST['forceauthn']) && $_REQUEST['forceauthn'] == 'true' ? ' checked' : '';

echo <<<html
               <p>
                    <label title="Specify up to two SP EntityIDs to put in RequesterID Scoping elements in the AuthnRequest. If left blank no elements are added.">Scoping (RequesterID) 1:</label><input type="text" name="requesterid" list="commonSPs" value="{$requesterid}" size="80" /><br />
{$commonSPs_datalist}
                    <label>2:</label><input type="text" name="requesterid2" list="commonSPs" value="{$requesterid2}" size="80" /><br />
{$commonSPs_datalist}
               </p>
               <p>
                    <label title="Specify up to two IdP EntityIDs to put in IDPList Scoping elements in the AuthnRequest. If left blank no elements are added.">Scoping (IDPList) 1:</label><input type="text" name="scopingIDP" list="commonIDPs" value="{$scopingIDP}" size="80" /><br />
{$commonIDPs_datalist}
                    <label>2:</label><input type="text" name="scopingIDP2" list="commonIDPs" value="{$scopingIDP2}" size="80" /><br />
{$commonIDPs_datalist}
               </p>
               <p>
                   <label title="Specify the value of a NameID to put in a Subject element in the AuthnRequest. If specified a NameID of type 'urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified' is added to the AuthnRequest.">Subject:</label><input type="text" name="subject" list="commonSubjects" value="{$subject}" size="80" />
                   <datalist id="commonSubjects">
                        <option value="urn:collab:person:stepup.example.com:admin" />
                        <option value="urn:collab:person:institution-a.example.com:" />
                        <option value="urn:collab:person:institution-b.example.com:" />
                        <option value="urn:collab:person:institution-c.example.com:" />
                        <option value="urn:collab:person:institution-d.example.com:" />
                        <option value="urn:collab:person:Institution-D.EXAMPLE.COM:" />
                        <option value="urn:collab:person:institution-e.example.com:" />
                        <option value="urn:collab:person:institution-f.example.com:" />
                   </datalist>
               </p>
               <p>
                    <label title="If selected a ForceAuthn is set to true in the AuthnRequest.">Force authentication:</label><input type="checkbox" name="forceauthn" value="true" /><br />
               </p>
               <p>
                   <label title="Optionally override the AssertionConsumerServiceURL to specify in the AuthnRequest. Leave blank to use the default ACS location ({$sspACSURL}...) that is generated by SimpleSAMLphp.">AssertionConsumerServiceURL:</label><input type="text" name="acsurl" list="acsurls" value="{$acsurl}" size="80" />
                   <datalist id="acsurls">                        
                        <option value="{$sspACSURL}default-sp" />
                        <option value="{$sspDebugSPACSURL}default-sp" />
                        <option value="{$sspACSURL}second-sp" />
                        <option value="{$sspDebugSPACSURL}second-sp?SAMLRequest=request&Context=context" />                        
                        <option value="{$sspACSURL}third-sp" />
                        <option value="{$sspDebugSPACSURL}third-sp" />
                        <option value="{$sspACSURL}fourth-sp" />
                        <option value="{$sspDebugSPACSURL}fourth-sp" />
                   </datalist>
               </p>
               <p>
                   <label title="If selected two extra POST variables 'AuthMethod' and 'Context' are added to the AuthnRequest. Only has an effect when the HTTP-POST binding is used.">Emulate ADFS:</label><input type="checkbox" name="emulateadfs" value="true"{$emulateADFSchecked} /><br />
               </p>
                
               <p>
                    <button class="login" type="submit" name="action" value="login">Login</button>&nbsp;&nbsp;<button type="submit" name="action" value="reset">Reset</button><br />
               </p>
        </form>
html;

$SAMLResponse = $session->getData('string', 'SAML2Keeper_SAMLResponse');
if ($SAMLResponse)
{
    echo '<h3>SAMLResponse</h3>';
    $SAMLResponse = base64_decode($SAMLResponse);
    if (false !== $SAMLResponse)
    {
        $document = new DOMDocument();
        $document->loadXML($SAMLResponse);
        $xml = $document->firstChild;

        //$msg = new SAML2_Response($xml);
        $response_IssueInstant = SAML2_Utils::xpQuery($xml, '/saml_protocol:Response/@IssueInstant');
        $assertion_IssueInstant = SAML2_Utils::xpQuery($xml, '/saml_protocol:Response/saml_assertion:Assertion/@IssueInstant');
        $condition_NotBefore = SAML2_Utils::xpQuery($xml, '/saml_protocol:Response/saml_assertion:Assertion/saml_assertion:Conditions/@NotBefore');
        $condition_NotOnOrAfter = SAML2_Utils::xpQuery($xml, '/saml_protocol:Response/saml_assertion:Assertion/saml_assertion:Conditions/@NotOnOrAfter');
        $audience_Restriction = SAML2_Utils::xpQuery($xml, '/saml_protocol:Response/saml_assertion:Assertion/saml_assertion:Conditions/saml_assertion:AudienceRestriction/saml:Audience');
        $assertion_AuthnInstant = SAML2_Utils::xpQuery($xml, '/saml_protocol:Response/saml_assertion:Assertion/saml_assertion:AuthnStatement/@AuthnInstant');
        $SessionNotOnOrAfter = SAML2_Utils::xpQuery($xml, '/saml_protocol:Response/saml_assertion:Assertion/saml_assertion:AuthnStatement/@SessionNotOnOrAfter');
        $SessionIndex = SAML2_Utils::xpQuery($xml, '/saml_protocol:Response/saml_assertion:Assertion/saml_assertion:AuthnStatement/@SessionIndex' );
        echo "<h4>Response</h4>";
        echo "IssueInstant: ".XMLTextNode2HTML_TS($response_IssueInstant)."<br />";
        echo "<h4>Assertion</h4>";
        echo "IssueInstant: ".XMLTextNode2HTML_TS($assertion_IssueInstant)."<br />";
        echo "Condition NotBefore: ".XMLTextNode2HTML_TS($condition_NotBefore)."<br />";
        echo "Condition NotOnOrAfter: ".XMLTextNode2HTML_TS($condition_NotOnOrAfter)."<br />";
        echo "AudienceRestriction: ".XMLTextNode2HTML($audience_Restriction)."<br />";
        echo "AuthnInstant: ".XMLTextNode2HTML_TS($assertion_AuthnInstant)."<br />";
        echo "SessionNotOnOrAfter: ".XMLTextNode2HTML_TS($SessionNotOnOrAfter)."<br />";
        echo "SessionIndex: ".XMLTextNode2HTML($SessionIndex)."<br />";
        echo '<pre>';
        echo htmlentities($SAMLResponse);
        echo '</pre>';
    }
    else
    {
        echo 'Error decoding SAMLResponse (invalid base64)<br />';
    }
}

echo <<<html
    </body>
</html>
html;

